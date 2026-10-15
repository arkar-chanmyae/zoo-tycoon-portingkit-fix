#!/bin/bash
# ============================================================================
#  Zoo Tycoon kit - "Check My Mac"
#
#  Reports the state of everything, changes NOTHING. Run it any time.
#  It knows about both install methods:
#    Method A - the Mac version installer   (recommended)
#    Method B - the Porting Kit repair scripts
# ============================================================================

say()  { printf '%s\n' "$*"; }
ok()   { printf '  [ok]    %s\n' "$*"; }
note() { printf '  [info]  %s\n' "$*"; }
warn() { printf '  [warn]  %s\n' "$*"; }
bad()  { printf '  [FAIL]  %s\n' "$*"; }
hr()   { printf '%s\n' "------------------------------------------------------------------"; }

NEEDS=0
NEED_LINES=""

need() { NEEDS=$((NEEDS+1)); NEED_LINES="$NEED_LINES
  - $1"; }

say ""
say "Zoo Tycoon kit - Mac check"
hr

# --- chip -------------------------------------------------------------------
say "CPU"
CHIP=$(/usr/sbin/sysctl -n machdep.cpu.brand_string 2>/dev/null)
ARCH=$(/usr/bin/uname -m)
if [ "$ARCH" = "arm64" ]; then
  ok "Apple Silicon ($CHIP) - this kit is made for this"
else
  warn "This Mac reports as '$ARCH' (Intel)"
  warn "The kit is tested on Apple Silicon only; results may differ"
  need "Kit is validated on Apple Silicon only"
fi

# --- macOS ------------------------------------------------------------------
say ""
say "macOS version"
OSV=$(/usr/bin/sw_vers -productVersion 2>/dev/null)
OSMAJ=${OSV%%.*}
ok "macOS $OSV"
if [ "${OSMAJ:-0}" -ge 26 ] 2>/dev/null; then
  note "on macOS 26/27 a mounted disc image cannot satisfy the game's CD check"
  note "that is why a patch (option A, the Custom Patch) is used instead"
fi

# --- rosetta ----------------------------------------------------------------
say ""
say "Rosetta 2  (required - the game engine is Intel code)"
if /usr/bin/pgrep -q oahd 2>/dev/null; then
  ok "installed"
else
  warn "NOT installed - the game cannot run without it"
  note "open Terminal and run:  softwareupdate --install-rosetta --agree-to-license"
  need "Install Rosetta 2"
fi

# --- disk space -------------------------------------------------------------
say ""
say "Free disk space"
FREE_GB=$(/bin/df -g /System/Volumes/Data 2>/dev/null | /usr/bin/awk 'NR==2{print $4}')
if [ -n "${FREE_GB:-}" ]; then
  if [ "$FREE_GB" -ge 3 ] 2>/dev/null; then
    ok "${FREE_GB} GB free"
  else
    warn "only ${FREE_GB} GB free"
    need "Free up disk space (Method A needs about 3 GB)"
  fi
fi

# ============================================================ METHOD A ======
MA="/Applications/Zoo Tycoon - Complete Collection"
MAW="$MA/.Zoo Tycoon.app"
MAG="$MAW/Contents/Resources/drive_c/Program Files/Microsoft Games/Zoo Tycoon"

say ""
hr
say "METHOD A - Mac version install  (recommended)"
if [ -d "$MAW" ]; then
  ok "installed: $MA"
  MSIZE=$(/usr/bin/du -sh "$MA" 2>/dev/null | /usr/bin/awk '{print $1}')
  note "size on disk: ${MSIZE:-unknown}"

  if [ -d "$MAW/Contents/SharedSupport/wine" ]; then
    note "engine: $(cat "$MAW/Contents/SharedSupport/wine/version" 2>/dev/null || echo unknown)"
  fi

  # which disc-check state is active?
  if [ -f "$MAG/custompatch.ini" ]; then
    ok "disc check: Custom Patch applied - NO disc needed, staff upkeep intact"
    note "this is the best state - nothing more to do"
  elif [ -f "$MAG/zoo.exe.nocd" ] && /usr/bin/cmp -s "$MAG/zoo.exe" "$MAG/zoo.exe.nocd" 2>/dev/null; then
    ok "disc check: No-CD patch - NO disc needed"
    warn "staff upkeep is affected by this patch (keepers may not clean or repair)"
    note "for the better option, apply the LuKeStorm Custom Patch instead"
  elif [ -f "$MAG/zoo.exe.original" ]; then
    warn "disc check: original game files"
    note "the fake MARINE image cannot satisfy the check on macOS 26/27,"
    note "so the game will keep asking for the CD-ROM"
    need "Apply the Custom Patch (rerun the installer, choose A)"
  else
    note "disc check: state not recognised"
  fi

  # entry points
  if [ -L "$HOME/Desktop/Zoo Tycoon" ] || [ -e "$HOME/Desktop/Zoo Tycoon" ]; then
    ok "Desktop shortcut: \"Zoo Tycoon\" - just double-click it to play"
  fi
  if [ -e "$HOME/Desktop/Play Zoo Tycoon.command" ]; then
    note "also have \"Play Zoo Tycoon.command\" (mounts the fake image; only needed for option C)"
  fi
else
  warn "not installed"
  note "this is the easy method - see START HERE.txt, Method A"
  note "you need: Zoo-Tycoon-Complete-Collection_Mac_EN_Repack.zip"
  note "          ZooTycoonCC_CustomPatch.zip  (recommended)"
fi

# ============================================================ METHOD B ======
say ""
hr
say "METHOD B - Porting Kit install  (only needed if you use this method)"
if [ -d "/Applications/Porting Kit.app" ]; then
  PKV=$(/usr/bin/defaults read "/Applications/Porting Kit.app/Contents/Info.plist" CFBundleShortVersionString 2>/dev/null)
  ok "Porting Kit installed (version ${PKV:-unknown})"
else
  note "Porting Kit is not installed"
  note "fine - you only need it for Method B"
fi

PKA=""
for cand in "$HOME/Applications/Zoo Tycoon.app" "/Applications/Zoo Tycoon.app"; do
  [ -d "$cand" ] && { PKA="$cand"; break; }
done
if [ -n "$PKA" ]; then
  ok "Porting Kit wrapper found: $PKA"
  PSIZE=$(/usr/bin/du -sh "$PKA" 2>/dev/null | /usr/bin/awk '{print $1}')
  note "size on disk: ${PSIZE:-unknown}"
  if [ -d "$MAW" ]; then
    note "you have BOTH methods installed - Method A needs no disc, this one does"
  fi
else
  note "no Porting Kit wrapper installed"
fi

# --- disc images ------------------------------------------------------------
say ""
hr
say "Disc images"
if [ -d /Volumes/ZOO_TYCN ]; then
  ok "ZOO_TYCN mounted at /Volumes/ZOO_TYCN   (needed only by Method B)"
else
  ISO=$(/usr/bin/find "$HOME/Downloads" "$HOME/Desktop" -maxdepth 3 -iname "*ZOO_TYCN*.iso" 2>/dev/null | head -1)
  if [ -n "$ISO" ]; then
    note "found ZOO_TYCN.iso (needed only by Method B, not for Method A)"
  else
    note "no ZOO_TYCN.iso - only a problem if you use Method B"
  fi
fi

if [ -d /Volumes/MARINE ]; then
  ok "MARINE is mounted - the repack's launcher does this by itself"
else
  note "MARINE not mounted (normal - with a patch it is not needed at all)"
fi

# --- summary ----------------------------------------------------------------
say ""
hr
if [ "$NEEDS" = 0 ]; then
  say "Everything looks good."
  if [ -d "$MAW" ]; then
    say ""
    say "To play: double-click \"Zoo Tycoon\" on your Desktop."
    say "You do NOT need to run any .command file to play."
  else
    say ""
    say "Next: open START HERE.txt and follow Method A."
  fi
else
  say "$NEEDS thing(s) need attention:$NEED_LINES"
fi
hr
say ""
read -n 1 -s -r -p "Press any key to close this window... "
say ""
