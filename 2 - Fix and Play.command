#!/bin/bash
# ============================================================================
#  Zoo Tycoon (Complete Collection) - repair + launch  -  macOS / Apple Silicon
#
#  METHOD B - the Porting Kit route. Use "0 - Install from Mac Version.command"
#  (Method A) instead if you can: it needs no disc and is far simpler.
#
#  Applies the fixes for four known Porting Kit 7.0.2 packaging bugs.
#  Safe to run as many times as you like: every step checks first.
#
#  Usage:
#     double-click                      -> apply fixes, mount disc, play
#     ... --check                       -> report only, change nothing
# ============================================================================

set -u

CHECK_ONLY=0
[ "${1:-}" = "--check" ] && CHECK_ONLY=1

say()  { printf '%s\n' "$*"; }
ok()   { printf '  [ok]    %s\n' "$*"; }
did()  { printf '  [FIXED] %s\n' "$*"; }
warn() { printf '  [warn]  %s\n' "$*"; }
bad()  { printf '  [FAIL]  %s\n' "$*"; }
todo() { printf '  [todo]  %s\n' "$*"; }
hr()   { printf '%s\n' "------------------------------------------------------------------"; }

say ""
say "Zoo Tycoon repair tool  -  METHOD B (Porting Kit)"
hr
if [ "$CHECK_ONLY" = 1 ]; then
  say "MODE: check only - nothing will be changed and the game will not start."
else
  say "MODE: apply fixes and play"
fi
say ""

# If the simpler method is already installed and patched, say so plainly rather
# than letting someone redo the harder route on top of a working game.
MAW="/Applications/Zoo Tycoon - Complete Collection/.Zoo Tycoon.app"
MAG="$MAW/Contents/Resources/drive_c/Program Files/Microsoft Games/Zoo Tycoon"
if [ -d "$MAW" ] && { [ -f "$MAG/custompatch.ini" ] || [ -f "$MAG/zoo.exe.nocd" ]; }; then
  say "NOTE: the Mac version install (Method A) is already set up and patched."
  say "      That install needs no disc at all."
  say ""
  say "      To play it, just double-click \"Zoo Tycoon\" on your Desktop -"
  say "      you do not need to run anything."
  say ""
  say "      This script is the Porting Kit route (Method B), and is only"
  say "      needed if you specifically want that install instead."
  say ""
  if [ "$CHECK_ONLY" = 0 ]; then
    printf '  Continue with the Porting Kit fixes anyway? (y/n) [n]: '
    read -r go
    case "$go" in
      y|Y) ;;
      *) say ""; say "Nothing changed - enjoy the game."; say ""; exit 0 ;;
    esac
  fi
fi

# ---------------------------------------------------------------- 0. rosetta
hr
say "0. Checking Rosetta 2 (the game engine is Intel code)"
if /usr/bin/pgrep -q oahd 2>/dev/null || /usr/bin/pgrep -q "Rosetta" 2>/dev/null; then
  ok "Rosetta 2 is installed"
else
  warn "Rosetta 2 does not look installed."
  warn "In Terminal, run:  softwareupdate --install-rosetta --agree-to-license"
  warn "Then run this script again."
fi

# ---------------------------------------------------------------- 1. wrapper
hr
say "1. Looking for the installed Zoo Tycoon wrapper"
APP=""
for cand in "$HOME/Applications/Zoo Tycoon.app" "/Applications/Zoo Tycoon.app"; do
  [ -d "$cand" ] && { APP="$cand"; break; }
done
if [ -z "$APP" ]; then
  APP=$(/usr/bin/find "$HOME/Applications" /Applications -maxdepth 2 -iname "Zoo*Tycoon*.app" 2>/dev/null | head -1)
fi
if [ -z "$APP" ]; then
  bad "No Zoo Tycoon wrapper found."
  say ""
  say "Install the Zoo Tycoon port in Porting Kit first (see START HERE.txt,"
  say "steps 2 and 3), then run this script again."
  exit 1
fi
ok "wrapper: $APP"

# engine + prefix layouts differ between Wineskin versions - detect both
ENGINE=""
for e in "$APP/Contents/SharedSupport/wine" "$APP/Contents/Frameworks/wswine.bundle"; do
  [ -x "$e/bin/wineserver" ] && { ENGINE="$e"; break; }
done
PFX=""
for p in "$APP/Contents/SharedSupport/prefix" "$APP/Contents/Resources"; do
  [ -d "$p/drive_c" ] && { PFX="$p"; break; }
done
[ -n "$ENGINE" ] && ok "engine:  $ENGINE" || warn "engine folder not found (unusual)"
[ -n "$PFX" ]    && ok "prefix:  $PFX"    || warn "prefix folder not found (unusual)"
FRAMEWORKS="$APP/Contents/Frameworks"

# Registry edits are made by editing user.reg directly. We deliberately do NOT
# run "wine reg": that needs a live Wine session and it can crash outright on
# Apple Silicon. Editing the file is safe here, because this tool is meant to be
# run before the game is started (Wine reloads user.reg when it next starts).
REG="$PFX/user.reg"

reg_set_ddraw_builtin() {   # $1 = 1 means report only
  if [ ! -f "$REG" ]; then
    warn "user.reg not found - set the ddraw=builtin override by hand"
    return 0
  fi
  if grep -qF '"*ddraw"="builtin"' "$REG" 2>/dev/null; then
    ok "registry already forces builtin ddraw"
    return 0
  fi
  if [ "$1" = 1 ]; then
    todo "would set  *ddraw = builtin   (registry override)"
    return 0
  fi
  cp "$REG" "$REG.bak" 2>/dev/null
  if grep -qF '"*ddraw"' "$REG" 2>/dev/null; then
    sed -i '' 's/^"\*ddraw"=.*/"*ddraw"="builtin"/' "$REG"
    did "registry: *ddraw entries now read builtin (backup: user.reg.bak)"
  else
    cat >> "$REG" <<'REGOEOF'

[Software\\Wine\\DllOverrides]
"*ddraw"="builtin"
REGOEOF
    did "registry: added  *ddraw = builtin (backup: user.reg.bak)"
  fi
}

reg_clear_gdi_renderer() {  # $1 = 1 means report only
  if [ ! -f "$REG" ]; then
    ok "no registry file to check"
    return 0
  fi
  if ! grep -qF '"renderer"="gdi"' "$REG" 2>/dev/null; then
    ok "no gdi renderer override present"
    return 0
  fi
  if [ "$1" = 1 ]; then
    todo "would remove the gdi renderer override (it blocks Direct3D)"
    return 0
  fi
  cp "$REG" "$REG.bak-gdi" 2>/dev/null
  grep -vF '"renderer"="gdi"' "$REG" > "$REG.tmp" && mv "$REG.tmp" "$REG"
  did "removed the gdi renderer override (Direct3D re-enabled)"
}

# ================================================================ FIX 1 =====
# Porting Kit's recipe installs "cnc-ddraw" as ddraw.dll. It exports
# DirectDrawCreate but NOT DllGetClassObject, so the game (which asks COM for
# DirectDraw) dies at startup. Replace it with Wine's own builtin ddraw.
hr
say "2. DirectDraw (Porting Kit installs a ddraw DLL the game cannot use)"
SYSDIR="$PFX/drive_c/windows/syswow64"
[ -d "$SYSDIR" ] || SYSDIR="$PFX/drive_c/windows/system32"

BUILTIN=""
for b in "$ENGINE/lib/wine/i386-windows/ddraw.dll" "$ENGINE/lib/wine/x86_64-windows/ddraw.dll"; do
  [ -f "$b" ] && { BUILTIN="$b"; break; }
done

if [ -z "$BUILTIN" ]; then
  warn "could not find Wine's own ddraw.dll inside the engine - skipping"
elif [ ! -d "$SYSDIR" ]; then
  warn "no windows system folder in the prefix - skipping"
else
  CUR="$SYSDIR/ddraw.dll"
  if [ -f "$CUR" ] && /usr/bin/cmp -s "$CUR" "$BUILTIN"; then
    ok "ddraw.dll is already Wine's builtin"
  elif [ "$CHECK_ONLY" = 1 ]; then
    todo "would replace $CUR with Wine's builtin ddraw"
  else
    [ -f "$CUR" ] && cp "$CUR" "$CUR.cnc-backup" 2>/dev/null
    mkdir -p "$SYSDIR"
    cp -f "$BUILTIN" "$CUR" && did "installed Wine's builtin ddraw.dll"
  fi
  # registry override: force builtin
  if [ "$CHECK_ONLY" = 1 ]; then
    reg_set_ddraw_builtin 1
  else
    reg_set_ddraw_builtin 0
  fi
fi

# ================================================================ FIX 2 =====
# The engine ships without LC_RPATH, so Wine cannot find libinotify (its own
# helper) or libMoltenVK (the graphics backend). A cold start then dies before
# the game even begins. Add the missing search paths.
hr
say "3. Graphics/library paths missing from the engine's own programs"
if [ -z "$ENGINE" ]; then
  warn "engine not found - skipping"
else
  for exe in "$ENGINE/bin/wineserver" "$ENGINE/bin/wine64" "$ENGINE/bin/wine64-preloader"; do
    [ -f "$exe" ] || continue
    name=$(basename "$exe")
    if ! /usr/bin/otool -L "$exe" 2>/dev/null | grep -q "@rpath/"; then
      ok "$name needs no path fix"
      continue
    fi
    if /usr/bin/otool -l "$exe" 2>/dev/null | grep -q "Frameworks/moltenvkcx"; then
      ok "$name already fixed"
      continue
    fi
    if [ "$CHECK_ONLY" = 1 ]; then
      todo "would add library paths to $name"
      continue
    fi
    /usr/bin/install_name_tool -add_rpath "@executable_path/../../../Frameworks/moltenvkcx" "$exe" 2>/dev/null
    /usr/bin/install_name_tool -add_rpath "@executable_path/../../../Frameworks" "$exe" 2>/dev/null
    /usr/bin/codesign --force --sign - "$exe" >/dev/null 2>&1
    did "added library paths to $name"
  done
  # Wine's Vulkan driver also needs to locate MoltenVK
  /usr/bin/find "$ENGINE/lib" -name "winevulkan.so" 2>/dev/null | while read -r so; do
    /usr/bin/otool -l "$so" 2>/dev/null | grep -q "Frameworks/moltenvkcx" && continue
    if [ "$CHECK_ONLY" = 1 ]; then
      todo "would add library path to $(basename "$(dirname "$so")")/winevulkan.so"
    else
      /usr/bin/install_name_tool -add_rpath "@loader_path/../../../../Frameworks/moltenvkcx" "$so" 2>/dev/null
      /usr/bin/codesign --force --sign - "$so" >/dev/null 2>&1
      did "fixed winevulkan.so ($(basename "$(dirname "$so")"))"
    fi
  done
fi

# ================================================================ FIX 3 =====
# The game asks for an 800x600 fullscreen mode that Retina Macs do not offer,
# then quits. Running it windowed avoids the display switch entirely.
# NOTE: we only ADD settings - never remove the [mgr]/[language] sections,
# because without [language] the game loops forever rewriting this file.
hr
say "4. Game config (must run windowed, and keep all its sections)"
INI_DIRS=""
for d in "$PFX/drive_c/Program Files (x86)/Microsoft Games/Zoo Tycoon" \
         "$PFX/drive_c/Program Files/Microsoft Games/Zoo Tycoon"; do
  [ -d "$d" ] && INI_DIRS="$INI_DIRS$d"$'\n'
done
if [ -z "$INI_DIRS" ]; then
  warn "game folder not found in the prefix - skipping"
else
  printf '%s' "$INI_DIRS" | while IFS= read -r d; do
    [ -n "$d" ] || continue
    case "$d" in
      *"(x86)"*) LBL="Program Files (x86)" ;;
      *)         LBL="Program Files" ;;
    esac
    ini="$d/zoo.ini"
    if [ ! -f "$ini" ]; then
      [ "$CHECK_ONLY" = 1 ] && { todo "would create zoo.ini in $LBL"; continue; }
      printf '[UI]\r\nTooltipDelay=1\r\nTooltipDuration=3000\r\n' > "$ini"
    fi
    if grep -qi '^screenwidth=' "$ini" 2>/dev/null && grep -qi '^fullscreen=0' "$ini" 2>/dev/null; then
      ok "already windowed: $LBL/zoo.ini"
      continue
    fi
    if [ "$CHECK_ONLY" = 1 ]; then
      todo "would set windowed 1024x768 in $LBL/zoo.ini"
      continue
    fi
    if ! command -v perl >/dev/null 2>&1; then
      warn "perl not available - cannot safely edit zoo.ini"
      continue
    fi
    cp "$ini" "$ini.bak" 2>/dev/null
    perl -e '
      my ($f)=@ARGV; local $/;
      open(my $fh,"<",$f) or exit 1; my $s=<$fh>; close $fh;
      $s =~ s/\r\n/\n/g;
      $s =~ s/^\[user\]\n(?:[^\[].*\n)*//mg;      # drop an existing [user] block
      $s =~ s/\n+\z/\n/;
      $s .= "[user]\nfullscreen=0\nscreenwidth=1024\nscreenheight=768\n";
      $s =~ s/\n/\r\n/g;
      open(my $o,">",$f) or exit 1; print $o $s; close $o;
    ' "$ini" && did "set windowed 1024x768 in $LBL/zoo.ini (backup .bak)"
    # guard against the infinite-loop fault
    if ! grep -qi '^\[language\]' "$ini" 2>/dev/null; then
      warn "  this zoo.ini has no [language] section - the game may loop;"
      warn "  reinstall the port in Porting Kit to restore the original file"
    fi
  done
fi

# ================================================================ FIX 4 =====
# A "gdi" DirectDraw renderer blocks Direct3D, which the game needs for terrain.
hr
say "5. Direct3D renderer"
if [ "$CHECK_ONLY" = 1 ]; then
  reg_clear_gdi_renderer 1
else
  reg_clear_gdi_renderer 0
fi

# ================================================================ 6. disc ===
# The port maps d: to a volume named ZOO_TYCN. After a reboot it is gone and
# the game starts then closes with no error.
hr
say "6. Game disc"
if [ -d /Volumes/ZOO_TYCN ]; then
  ok "disc already mounted at /Volumes/ZOO_TYCN"
else
  ISO=""
  if command -v perl >/dev/null 2>&1; then :; fi
  ISO=$(/usr/bin/find "$HOME/Downloads" "$HOME/Desktop" "$HOME/Documents" -maxdepth 3 \
        -iname "*ZOO_TYCN*.iso" 2>/dev/null | head -1)
  [ -z "$ISO" ] && ISO=$(/usr/bin/find "$HOME/Downloads" "$HOME/Desktop" -maxdepth 3 \
        -iname "*.iso" 2>/dev/null | head -1)
  if [ -n "$ISO" ]; then
    if [ "$CHECK_ONLY" = 1 ]; then
      todo "would mount: $ISO"
    else
      if /usr/bin/hdiutil attach "$ISO" -nobrowse -quiet >/dev/null 2>&1; then
        sleep 2
        if [ -d /Volumes/ZOO_TYCN ]; then
          did "mounted $(basename "$ISO")"
        else
          warn "mounted $(basename "$ISO") but no volume named ZOO_TYCN appeared"
          warn "the game checks for the disc label ZOO_TYCN"
        fi
      else
        warn "could not mount $ISO"
      fi
    fi
  else
    warn "No disc image found in Downloads / Desktop / Documents."
    warn "You need the file ZOO_TYCN.iso (see START HERE.txt step 4)."
    warn "Without it the game will start and then close by itself."
  fi
fi

# ================================================================ 7. launch =
hr
say "7. Starting the game"
if [ "$CHECK_ONLY" = 1 ]; then
  say ""
  say "Check complete - nothing was changed."
  say "Run this script again without --check to apply the fixes and play."
  say ""
  exit 0
fi
say "Give it about 30 seconds to reach the menu (the first start is slow)."
/usr/bin/open "$APP"
say ""
say "Done. If the game shows a loading bar and then closes, run this script"
say "again and send the whole window's text to whoever gave you this kit."
say ""
