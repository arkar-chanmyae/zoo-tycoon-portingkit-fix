#!/bin/bash
# ============================================================================
#  Zoo Tycoon Complete Collection - AUTOMATED INSTALLER (from Mac version)
#  Downloads the Mac version from MyAbandonware, extracts hidden .app, applies
#  No-CD patch, clears quarantine, bundles MARINE.ISO, creates launch shortcut.
#  Run this ONCE. After that, use "2 - Fix and Play.command" to launch.
# ============================================================================

set -euo pipefail

say()  { printf '\n%s\n' "$*"; }
ok()   { printf '  [ok]    %s\n' "$*"; }
did()  { printf '  [DONE]  %s\n' "$*"; }
warn() { printf '  [warn]  %s\n' "$*"; }
bad()  { printf '  [FAIL]  %s\n' "$*"; }
hr()   { printf '%s\n' "------------------------------------------------------------------"; }

# ------------ Config ------------
MAC_DL_URL="https://www.myabandonware.com/game/zoo-tycoon-complete-collection-dzx"
MAC_DL_HINT="Mac version ZIP (~1.3 GB) from MyAbandonware"
NOCd_ZIP="$HOME/Desktop/Zoo Tycoon Kit/Zoo-Tycoon-Complete-Collection_NoCD_Win_EN.zip"
DEST_ROOT="/Applications"
APP_NAME="Zoo Tycoon"
FINAL_APP="$DEST_ROOT/$APP_NAME.app"
# Use a simple, visible working folder on Desktop (easy to find/clean up)
WORK_DIR="$HOME/Desktop/Zoo Tycoon Kit/temp_install"
mkdir -p "$WORK_DIR"

trap 'rm -rf "$WORK_DIR"' EXIT

hr
say "Zoo Tycoon Complete Collection - Automated Installer (Mac version + No-CD)"
hr

# ------------ 0. Prereqs ------------
say "0. Checking prerequisites..."
command -v curl >/dev/null || { bad "curl not found"; exit 1; }
command -v unzip >/dev/null || { bad "unzip not found"; exit 1; }
command -v xattr >/dev/null || { bad "xattr not found"; exit 1; }
command -v hdiutil >/dev/null || { bad "hdiutil not found"; exit 1; }
ok "System tools present"

if [ ! -f "$NOCd_ZIP" ]; then
  bad "No-CD patch zip not found at: $NOCd_ZIP"
  say "Place the No-CD zip there, or edit this script to point to it."
  exit 1
fi
ok "No-CD patch zip found"

# ------------ 1. Download Mac version ------------
say "1. Downloading Mac version from MyAbandonware..."
MAC_ZIP="$WORK_DIR/ZooTycoon_Mac.zip"

# MyAbandonware requires a referrer and User-Agent to serve the actual file.
# We'll try a direct link pattern; if it fails, we fall back to manual instruction.
DL_LINK="https://www.myabandonware.com/redirect.php?url=https%3A%2F%2Farchive.org%2Fdownload%2Fzoo-tycoon-complete-collection%2FZoo%2520Tycoon%2520Complete%2520Collection.zip"
# The above is a best-effort guess; archive.org often hosts these.
# If auto-download fails, we will instruct manual download.

say "   Trying direct download..."
if curl -L -A "Mozilla/5.0" -H "Referer: $MAC_DL_URL" -o "$MAC_ZIP" "$DL_LINK" 2>/dev/null; then
  if [ -f "$MAC_ZIP" ] && [ $(stat -f%z "$MAC_ZIP" 2>/dev/null || stat -c%s "$MAC_ZIP") -gt 100000000 ]; then
    ok "Download succeeded ($(du -h "$MAC_ZIP" | awk '{print $1}'))"
  else
    warn "Download too small or failed - will need manual download"
    rm -f "$MAC_ZIP"
  fi
else
  warn "Auto-download failed (site blocks bots) - will need manual download"
fi

if [ ! -f "$MAC_ZIP" ]; then
  say ""
  say "*** MANUAL STEP REQUIRED ***"
  say "Auto-download was blocked by MyAbandonware. Please:"
  say "  1. Open this URL in Safari: $MAC_DL_URL"
  say "  2. Click 'Download' -> Choose 'Mac' version -> Save to Downloads"
  say "  3. The file is usually named 'Zoo Tycoon Complete Collection.zip' (~1.3 GB)"
  say "  4. When done, move it to: $WORK_DIR/ZooTycoon_Mac.zip"
  say "     (or just leave it in Downloads - the script will find it there)"
  say "  5. Then press ENTER here to continue..."
  read -r
  # Try common download locations
  for cand in "$HOME/Downloads/Zoo Tycoon Complete Collection.zip" \
              "$HOME/Downloads/Zoo Tycoon Complete Collection (Mac).zip" \
              "$HOME/Downloads/zoo-tycoon-complete-collection.zip"; do
    if [ -f "$cand" ]; then
      cp "$cand" "$MAC_ZIP"
      ok "Found manual download: $cand"
      break
    fi
  done
  [ -f "$MAC_ZIP" ] || { bad "Still no Mac zip found at $MAC_ZIP"; exit 1; }
fi

# ------------ 2. Extract and find hidden .app ------------
say "2. Extracting Mac version..."
unzip -q "$MAC_ZIP" -d "$WORK_DIR/mac_extract" 2>/dev/null || { bad "unzip failed"; exit 1; }

# Find the hidden .Zoo Tycoon.app (the actual Wineskin wrapper)
HIDDEN_APP=$(find "$WORK_DIR/mac_extract" -name ".Zoo Tycoon.app" -o -name "Zoo Tycoon.app" 2>/dev/null | head -1)
[ -n "$HIDDEN_APP" ] || { bad "Could not find .Zoo Tycoon.app in extracted files"; exit 1; }
ok "Found wrapper: $(basename "$HIDDEN_APP")"

# ------------ 3. Move to Applications, rename, clear quarantine ------------
say "3. Installing to Applications..."

# Remove any existing install
[ -d "$FINAL_APP" ] && { say "   Removing old install..."; rm -rf "$FINAL_APP"; }

# Move the hidden app to Applications as "Zoo Tycoon.app"
mv "$HIDDEN_APP" "$FINAL_APP"
ok "Moved to $FINAL_APP"

# Clear quarantine / extended attributes (the critical step)
say "   Clearing quarantine attributes (xattr -cr)..."
xattr -cr "$FINAL_APP" 2>/dev/null || warn "xattr had warnings (usually harmless)"
ok "Quarantine cleared"

# ------------ 4. Inject No-CD zoo.exe ------------
say "4. Applying No-CD patch..."

NOCd_EXE="$WORK_DIR/patched_zoo.exe"
unzip -q -o "$NOCd_ZIP" -d "$WORK_DIR/nocd" 2>/dev/null
PATCHED_EXE=$(find "$WORK_DIR/nocd" -name "zoo.exe" -o -name "Zoo.exe" 2>/dev/null | head -1)
[ -f "$PATCHED_EXE" ] || { bad "No zoo.exe found in No-CD zip"; exit 1; }

# Target game directory inside the wrapper
GAME_DIR="$FINAL_APP/Contents/Resources/drive_c/Program Files/Microsoft Games/Zoo Tycoon"
[ -d "$GAME_DIR" ] || GAME_DIR="$FINAL_APP/Contents/Resources/drive_c/Program Files (x86)/Microsoft Games/Zoo Tycoon"
[ -d "$GAME_DIR" ] || { bad "Game directory not found in wrapper at expected paths"; exit 1; }

# Backup original
[ -f "$GAME_DIR/zoo.exe" ] && mv "$GAME_DIR/zoo.exe" "$GAME_DIR/zoo.exe.bak" && ok "Backed up original zoo.exe"
cp "$PATCHED_EXE" "$GAME_DIR/zoo.exe"
ok "No-CD zoo.exe installed"

# ------------ 5. Bundle MARINE.ISO ------------
say "5. Bundling MARINE.ISO..."

# Find MARINE.ISO inside the extracted Mac version (it's usually in the wrapper's Resources)
MARINE_ISO=$(find "$WORK_DIR/mac_extract" -iname "MARINE.ISO" -o -iname "marine.iso" 2>/dev/null | head -1)
if [ -f "$MARINE_ISO" ]; then
  TARGET_ISO="$FINAL_APP/Contents/Resources/MARINE.ISO"
  cp "$MARINE_ISO" "$TARGET_ISO"
  ok "MARINE.ISO bundled at $TARGET_ISO"
else
  warn "MARINE.ISO not found in Mac download - you may need to mount it manually later"
  say "   (The No-CD patch should make this optional, but some versions still check for it)"
fi

# ------------ 6. Create Launch Script (double-click to play) ------------
say "6. Creating launch shortcut on Desktop..."

LAUNCHER="$HOME/Desktop/Play Zoo Tycoon.command"
cat > "$LAUNCHER" <<'LAUNCHEOF'
#!/bin/bash
# Auto-generated launcher - double-click to play
APP="/Applications/Zoo Tycoon.app"
ISO="/Applications/Zoo Tycoon.app/Contents/Resources/MARINE.ISO"

# Mount MARINE.ISO if present and not already mounted
if [ -f "$ISO" ] && [ ! -d "/Volumes/MARINE" ]; then
  echo "Mounting MARINE.ISO..."
  hdiutil attach "$ISO" -nobrowse -quiet 2>/dev/null
  sleep 2
fi

echo "Launching Zoo Tycoon..."
open "$APP"

# Keep terminal open for a moment to show any errors
sleep 3
LAUNCHEOF

chmod +x "$LAUNCHER"
ok "Launcher created: ~/Desktop/Play Zoo Tycoon.command"

# ------------ 7. Done ------------
hr
say "INSTALLATION COMPLETE!"
hr
say ""
say "Next steps:"
say "  1. Double-click: ~/Desktop/Play Zoo Tycoon.command"
say "     (First run: right-click -> Open -> Open to bypass Gatekeeper)"
say "  2. The game should launch without asking for a CD."
say ""
say "If you ever need to re-apply fixes (display mode, etc.), run:"
say "  ~/Desktop/Zoo Tycoon Kit/2 - Fix and Play.command"
say ""
hr
read -n 1 -s -r -p "Press any key to close..."
say ""