#!/bin/bash
# ============================================================================
#  Zoo Tycoon Complete Collection - EASY INSTALLER  (Mac version / ZT-CE.dmg)
#
#  Installs the Mac repack "Zoo-Tycoon-Complete-Collection_Mac_EN_Repack.zip",
#  which contains a single "ZT-CE.dmg". That image holds a hidden
#  ".Zoo Tycoon.app" (the real Wineskin wrapper) plus a small "Zoo Tycoon.app"
#  helper that mounts the bundled fake MARINE image and launches the game.
#
#  This script: extracts the dmg, copies the game folder to /Applications,
#  clears macOS quarantine, and optionally applies the No-CD patch.
#
#  Run ONCE. Afterwards use the "Zoo Tycoon" shortcut on your Desktop.
# ============================================================================

set -uo pipefail

say()  { printf '\n%s\n' "$*"; }
ok()   { printf '  [ok]    %s\n' "$*"; }
did()  { printf '  [DONE]  %s\n' "$*"; }
note() { printf '  [info]  %s\n' "$*"; }
warn() { printf '  [warn]  %s\n' "$*"; }
bad()  { printf '  [FAIL]  %s\n' "$*"; }
hr()   { printf '%s\n' "------------------------------------------------------------------"; }

# ---------------------------------------------------------------- config ---
REPACK_NAME="Zoo-Tycoon-Complete-Collection_Mac_EN_Repack.zip"
NOCD_ZIP="$HOME/Desktop/Zoo Tycoon Kit/Zoo-Tycoon-Complete-Collection_NoCD_Win_EN.zip"
DEST="/Applications/Zoo Tycoon - Complete Collection"
WORK_DIR="$HOME/Desktop/Zoo Tycoon Kit/temp_install"
MAC_DL_URL="https://www.myabandonware.com/game/zoo-tycoon-complete-collection-dzx"

# ---------------------------------------------------------------- banner ---
hr
say "Zoo Tycoon Complete Collection - Easy Installer"
hr
printf '  Installs the Mac version to:\n    %s\n' "$DEST"
printf '  Needs about 3 GB of free disk space.\n'

FREE_GB=$(df -g /System/Volumes/Data 2>/dev/null | awk 'NR==2{print $4}')
if [ -n "${FREE_GB:-}" ] && [ "$FREE_GB" -lt 3 ] 2>/dev/null; then
  bad "Only ${FREE_GB} GB free - need about 3 GB."
  printf '  Free some space, then run this again.\n\n'
  read -n 1 -s -r -p "Press any key to close..."
  exit 1
fi
[ -n "${FREE_GB:-}" ] && ok "${FREE_GB} GB free"

# --------------------------------------------------------------- 0. tools --
say "0. Checking tools"
MISSING=""
for t in unzip hdiutil ditto xattr; do
  command -v "$t" >/dev/null 2>&1 || MISSING="$MISSING $t"
done
if [ -n "$MISSING" ]; then bad "Missing:$MISSING"; exit 1; fi
ok "unzip, hdiutil, ditto, xattr all present"

# ------------------------------------------------------- 1. find the zip ---
say "1. Looking for the Mac version"
ZIP=""
for cand in "$HOME/Desktop/Zoo Tycoon Kit/$REPACK_NAME" \
            "$HOME/Downloads/$REPACK_NAME"; do
  [ -f "$cand" ] && { ZIP="$cand"; break; }
done
if [ -z "$ZIP" ]; then
  for pat in "$HOME/Downloads"/*Zoo*Tycoon*Mac*.zip \
             "$HOME/Downloads"/*Zoo*Tycoon*Repack*.zip \
             "$HOME/Desktop"/*Zoo*Tycoon*Mac*.zip; do
    [ -f "$pat" ] && { ZIP="$pat"; break; }
  done
fi

if [ -z "$ZIP" ]; then
  warn "Not found. This one part is a manual download:"
  printf '\n'
  printf '    1. Open: %s\n' "$MAC_DL_URL"
  printf '    2. Choose the  Mac  version and download it\n'
  printf '    3. Keep it in Downloads, named:\n'
  printf '         %s\n' "$REPACK_NAME"
  printf '    4. Run this installer again.\n\n'
  printf '  Press ENTER to open that page now, or Ctrl-C to quit... '
  read -r
  open "$MAC_DL_URL"
  exit 0
fi
ok "found: $ZIP"
ZIP_SIZE=$(stat -f%z "$ZIP" 2>/dev/null || echo 0)
if [ "$ZIP_SIZE" -lt 100000000 ]; then
  warn "that file is only $((ZIP_SIZE/1048576)) MB - possibly incomplete or the wrong one"
  printf '  Continue anyway? (y/n): '
  read -r ans
  case "$ans" in y|Y) ;; *) exit 1;; esac
fi
ok "archive size: $((ZIP_SIZE/1048576)) MB"

# ---------------------------------------------------- 2. prepare work dir --
say "2. Preparing working folder"
[ -e "$WORK_DIR" ] && { warn "removing an old temp_install folder"; rm -rf "$WORK_DIR"; }
mkdir -p "$WORK_DIR"
cleanup() {
  [ -d "$WORK_DIR/vol" ] && hdiutil detach "$WORK_DIR/vol" >/dev/null 2>&1
  rm -rf "$WORK_DIR"
}
trap cleanup EXIT
ok "$WORK_DIR"

# -------------------------------------------------------- 3. get the dmg --
say "3. Extracting the disk image"
# Only pull the .dmg out - the archive is 1.2 GB and holds just this one file.
DMG_ENTRY=$(unzip -Z1 "$ZIP" 2>/dev/null | grep -i '\.dmg$' | head -1)
[ -n "$DMG_ENTRY" ] || { bad "No .dmg inside the archive - is this the Mac version?"; exit 1; }
unzip -o -q "$ZIP" "$DMG_ENTRY" -d "$WORK_DIR" 2>/dev/null
DMG=$(find "$WORK_DIR" -maxdepth 3 -iname "*.dmg" 2>/dev/null | head -1)
[ -n "$DMG" ] || { bad "Could not extract the disk image"; exit 1; }
ok "disk image: $(basename "$DMG") ($(( $(stat -f%z "$DMG") / 1048576 )) MB)"

# ------------------------------------------------------------ 4. mount -----
say "4. Mounting the disk image"
if ! hdiutil attach "$DMG" -nobrowse -readonly -mountpoint "$WORK_DIR/vol" >/dev/null 2>&1; then
  bad "Could not mount the disk image."
  printf '  If it is already mounted, eject it in Finder and retry.\n'
  exit 1
fi
ok "mounted read-only"

SRC_APP=$(find "$WORK_DIR/vol" -maxdepth 2 -name ".Zoo Tycoon.app" -type d 2>/dev/null | head -1)
if [ -z "$SRC_APP" ]; then
  bad "The hidden '.Zoo Tycoon.app' wrapper was not found."
  printf '  What the image contains:\n'
  find "$WORK_DIR/vol" -maxdepth 2 2>/dev/null | head -10 | sed 's/^/    /'
  exit 1
fi
SRC_FOLDER=$(dirname "$SRC_APP")
ok "wrapper found inside: $(basename "$SRC_FOLDER")"

# ------------------------------------------------------------ 5. install ---
say "5. Installing to /Applications"
if [ -e "$DEST" ]; then
  warn "an existing install was found - replacing it"
  rm -rf "$DEST"
fi
# ditto preserves the symlinks inside the wrapper (drive_c, Logs) and metadata.
if ! ditto "$SRC_FOLDER" "$DEST" 2>/dev/null; then
  bad "Copy failed - do you have permission to write to /Applications?"
  exit 1
fi
ok "copied to $DEST"
hdiutil detach "$WORK_DIR/vol" >/dev/null 2>&1
ok "disk image ejected"

# --------------------------------------------------- 6. clear quarantine ----
say "6. Clearing macOS quarantine (xattr -cr)"
# This is the step that cures "Zoo Tycoon is damaged and cannot be opened".
xattr -cr "$DEST" 2>/dev/null
find "$DEST" -name '._*' -delete 2>/dev/null
ok "quarantine cleared"

WRAPPER="$DEST/.Zoo Tycoon.app"
GAMEDIR="$WRAPPER/Contents/Resources/drive_c/Program Files/Microsoft Games/Zoo Tycoon"
[ -d "$GAMEDIR" ] || GAMEDIR="$WRAPPER/Contents/Resources/drive_c/Program Files (x86)/Microsoft Games/Zoo Tycoon"
if [ -d "$GAMEDIR" ]; then
  ok "game folder verified"
else
  warn "game folder not where expected"
  GAMEDIR=""
fi

# ------------------------------------------------- 6b. window size ---------
# Default: FULLSCREEN at the display's own logical size, so the game fills the
# screen on whatever Mac it runs on. macOS is asked for the desktop size; if
# that cannot be read we fall back to 1280x832 (a 13.6" M2 Air's default).
# Fullscreen must match a mode the display actually offers, which is why we
# read the real size instead of hard-coding one.
say "6b. Setting the game window"
WIN_FS=1
WIN_W=1280
WIN_H=832
BOUNDS=$(perl -e 'alarm 5; exec @ARGV' osascript \
  -e 'tell application "Finder" to get bounds of window of desktop' 2>/dev/null)
case "$BOUNDS" in
  *,*,*,*)
    BW=$(printf '%s' "$BOUNDS" | awk -F', *' '{print $3}')
    BH=$(printf '%s' "$BOUNDS" | awk -F', *' '{print $4}')
    if [ -n "$BW" ] && [ -n "$BH" ] && [ "$BW" -gt 0 ] 2>/dev/null && [ "$BH" -gt 0 ] 2>/dev/null; then
      WIN_W=$BW
      WIN_H=$BH
      did "your display reports ${WIN_W}x${WIN_H}"
    fi
    ;;
esac
if [ -n "$GAMEDIR" ] && [ -f "$GAMEDIR/zoo.ini" ]; then
  cp "$GAMEDIR/zoo.ini" "$GAMEDIR/zoo.ini.bak" 2>/dev/null
  if command -v perl >/dev/null 2>&1; then
    perl -e '
      my ($f,$w,$h,$fs)=@ARGV; local $/;
      open(my $fh,"<",$f) or exit 1; my $s=<$fh>; close $fh;
      $s =~ s/\r\n/\n/g;
      $s =~ s/^fullscreen=.*/fullscreen=$fs/mg;
      $s =~ s/^screenwidth=.*/screenwidth=$w/mg;
      $s =~ s/^screenheight=.*/screenheight=$h/mg;
      $s =~ s/\n/\r\n/g;
      open(my $o,">",$f) or exit 1; print $o $s; close $o;
    ' "$GAMEDIR/zoo.ini" "$WIN_W" "$WIN_H" "$WIN_FS"
  fi
  if grep -qi "^screenwidth=$WIN_W" "$GAMEDIR/zoo.ini" && \
     grep -qi "^screenheight=$WIN_H" "$GAMEDIR/zoo.ini" && \
     grep -qi "^fullscreen=$WIN_FS" "$GAMEDIR/zoo.ini"; then
    did "zoo.ini: ${WIN_W}x${WIN_H}, fullscreen"
    note "if fullscreen misbehaves, set fullscreen=0 in zoo.ini (a .bak is kept)"
  else
    warn "could not set the window size automatically"
    note "run \"Change Resolution.command\" in the game folder instead"
  fi
else
  warn "zoo.ini not found - leaving the game's own default (800x600)"
fi

# ------------------------------------------------------- 7. disc handling --
say "7. The disc check - choose one"
printf '  A) LuKeStorm Custom Patch    (BEST - one extra small download)\n'
printf '     Removes the CD check AND keeps staff upkeep working. It is the\n'
printf '     only option that gives both, and this game is exactly the version\n'
printf '     it supports (v12.4.0.9 / 12.04.00.0009). Needs the 140 KB patch\n'
printf '     from PCGamingWiki, saved as:\n'
printf '        ZooTycoonCC_CustomPatch.zip\n'
printf '     Not bundled here on purpose - it ships a copy of an original\n'
printf '     game file, so we generate that locally instead.\n\n'
printf '  B) No-CD patch\n'
printf '     Starts with no disc step, but the repack author and the\n'
printf '     MyAbandonware page warn it also disables staff upkeep: zookeepers\n'
printf '     stop cleaning exhibits, maintenance workers stop repairing fences.\n'
printf '     The original is kept as zoo.exe.original - fully reversible.\n\n'
printf '  C) Keep the original game files\n'
printf '     Gameplay intact, but the fake MARINE image shipped with the\n'
printf '     repack cannot satisfy\n'
printf '     the disc check on macOS 26/27, so the game keeps asking for the\n'
printf '     CD-ROM. Only useful on an older macOS.\n\n'

PATCH_ZIP=""
for cand in "$HOME/Desktop/Zoo Tycoon Kit/ZooTycoonCC_CustomPatch.zip" \
            "$HOME/Downloads/ZooTycoonCC_CustomPatch.zip"; do
  [ -f "$cand" ] && { PATCH_ZIP="$cand"; break; }
done

DEFAULT="C"
[ -f "$NOCD_ZIP" ]  && DEFAULT="B"
[ -n "$PATCH_ZIP" ] && DEFAULT="A"
printf '  Type A, B or C, then press Return [%s]: ' "$DEFAULT"
read -r choice
choice=$(printf '%s' "${choice:-$DEFAULT}" | tr '[:lower:]' '[:upper:]')

# ----------------------------------------------------- option A ------------
if [ "$choice" = "A" ] && [ -z "$PATCH_ZIP" ]; then
  warn "Custom Patch zip not found - falling back to the No-CD patch"
  choice="B"
fi
if [ "$choice" = "A" ] && [ -z "$GAMEDIR" ]; then
  warn "game folder not found - keeping the original files"
  choice="C"
fi
if [ "$choice" = "A" ]; then
  TMPP="$WORK_DIR/cp"; mkdir -p "$TMPP"
  unzip -o -q "$PATCH_ZIP" -d "$TMPP" 2>/dev/null
  PROXY=$(find "$TMPP" -iname "ijl15.dll" 2>/dev/null | head -1)
  INI=$(find "$TMPP" -iname "custompatch.ini" 2>/dev/null | head -1)
  if [ -n "$PROXY" ] && [ -n "$INI" ] && [ -f "$GAMEDIR/ijl15.dll" ]; then
    # The patch patches the ORIGINAL exe in memory - a pre-cracked exe conflicts.
    if [ -f "$GAMEDIR/zoo.exe.original" ]; then
      [ -f "$GAMEDIR/zoo.exe.nocd" ] || cp "$GAMEDIR/zoo.exe" "$GAMEDIR/zoo.exe.nocd" 2>/dev/null
      cp "$GAMEDIR/zoo.exe.original" "$GAMEDIR/zoo.exe"
      ok "restored the original zoo.exe (the patch requires it)"
    fi
    [ -f "$GAMEDIR/ijl15.dll.beforepatch" ] || cp "$GAMEDIR/ijl15.dll" "$GAMEDIR/ijl15.dll.beforepatch"
    cp "$PROXY" "$GAMEDIR/ijl15.dll"
    cp "$GAMEDIR/ijl15.dll.beforepatch" "$GAMEDIR/ijl15_org.dll"
    cp "$INI" "$GAMEDIR/custompatch.ini"
    did "Custom Patch installed - no CD check, staff upkeep preserved"
    ok "removable via: delete ijl15.dll + custompatch.ini, rename ijl15_org.dll to ijl15.dll"
  else
    warn "patch files not recognised in the zip - keeping the original files"
  fi
fi

# ----------------------------------------------------- option B ------------
if [ "$choice" = "B" ]; then
  if [ ! -f "$NOCD_ZIP" ]; then
    warn "No-CD zip not found at $NOCD_ZIP - keeping the original files"
  elif [ -z "$GAMEDIR" ]; then
    warn "game folder not found - keeping the original files"
  else
    TMPX="$WORK_DIR/nocd"; mkdir -p "$TMPX"
    unzip -o -q "$NOCD_ZIP" -d "$TMPX" 2>/dev/null
    PATCHED=$(find "$TMPX" -iname "zoo.exe" 2>/dev/null | head -1)
    if [ -n "$PATCHED" ] && [ -f "$GAMEDIR/zoo.exe" ]; then
      # Only snapshot the original once - never overwrite a real backup.
      if [ ! -f "$GAMEDIR/zoo.exe.original" ]; then
        cp "$GAMEDIR/zoo.exe" "$GAMEDIR/zoo.exe.original" 2>/dev/null
      fi
      cp "$PATCHED" "$GAMEDIR/zoo.exe"
      did "No-CD patch applied"
      warn "original kept as zoo.exe.original - restore it to get staff back"
    else
      bad "could not apply the patch - keeping the original files"
    fi
  fi
fi

# ----------------------------------------------------- option C ------------
if [ "$choice" = "C" ]; then
  ok "keeping the original game files - use this only on older macOS"
fi

# ------------------------------------------------ 8. Desktop shortcut -----
# No launcher script: it only ever existed to mount the repack's fake MARINE
# image, and that image cannot satisfy the disc check on macOS 26/27 (IOKit
# reports it as generic media, not a CD). With a patch the game needs no image
# at all, so a plain shortcut is both simpler and sufficient.
say "8. Creating the Desktop shortcut"
if [ "$choice" = "A" ] || [ "$choice" = "B" ]; then
  rm -f "$HOME/Desktop/Zoo Tycoon" "$HOME/Desktop/Play Zoo Tycoon.command" 2>/dev/null
  if ln -s "$WRAPPER" "$HOME/Desktop/Zoo Tycoon" 2>/dev/null; then
    ok "created: ~/Desktop/Zoo Tycoon - double-click it to play"
    note "no launcher script needed: with a patch there is no disc check"
  else
    warn "could not create the Desktop shortcut"
    note "start the game from: $DEST"
  fi
else
  note "no Desktop shortcut for option C"
  note "start the game from: $DEST"
  note "expect a CD-ROM prompt on macOS 26/27 - that is the unpatched game"
fi

# ------------------------------------------------------------- 9. done -----
hr
say "INSTALLATION COMPLETE"
hr
if [ "$choice" = "A" ] || [ "$choice" = "B" ]; then
  printf '  Play:       double-click "Zoo Tycoon" on your Desktop\n'
  printf '              (if macOS ever blocks it: right-click -> Open -> Open)\n'
else
  printf '  Play:       open "Zoo Tycoon - Complete Collection" in Applications\n'
fi
printf '  Installed:  %s\n' "$DEST"
printf '  Window:     %sx%s fullscreen, matching your display.\n' "$WIN_W" "$WIN_H"
printf '              If that misbehaves, set fullscreen=0 in zoo.ini\n'
printf '              (a backup is kept as zoo.ini.bak).\n'
hr
printf '\nPress any key to close this window... '
read -n 1 -s -r
printf '\n'