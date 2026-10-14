#!/bin/bash
# ============================================================================
#  Zoo Tycoon kit - step 1: check this Mac is suitable
#  Changes nothing. Just reports, and offers to open the pages you need.
# ============================================================================

say()  { printf '%s\n' "$*"; }
ok()   { printf '  [ok]    %s\n' "$*"; }
warn() { printf '  [warn]  %s\n' "$*"; }
bad()  { printf '  [FAIL]  %s\n' "$*"; }
hr()   { printf '%s\n' "------------------------------------------------------------------"; }

PROBLEMS=0

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
  warn "This Mac reports as '$ARCH' (Intel)."
  warn "The kit is tested on Apple Silicon only. It may still work,"
  warn "but the graphics fixes could differ."
  PROBLEMS=$((PROBLEMS+1))
fi

# --- macOS ------------------------------------------------------------------
say ""
say "macOS version"
OSV=$(/usr/bin/sw_vers -productVersion 2>/dev/null)
OSMAJ=${OSV%%.*}
ok "macOS $OSV"
if [ "${OSMAJ:-0}" -ge 26 ] 2>/dev/null; then
  ok "Porting Kit's engine needs the fixes included in this kit on this version - good, they are included"
else
  ok "older macOS - the kit still applies its fixes harmlessly"
fi

# --- rosetta ----------------------------------------------------------------
say ""
say "Rosetta 2 (required: the game engine is Intel code)"
if /usr/bin/pgrep -q oahd 2>/dev/null; then
  ok "Rosetta 2 is installed"
else
  warn "Rosetta 2 is not installed."
  warn "Open Terminal and run this, then come back:"
  say  "      softwareupdate --install-rosetta --agree-to-license"
  PROBLEMS=$((PROBLEMS+1))
fi

# --- disk space -------------------------------------------------------------
say ""
say "Free disk space"
FREE_GB=$(/bin/df -g /System/Volumes/Data 2>/dev/null | /usr/bin/awk 'NR==2{print $4}')
if [ -n "${FREE_GB:-}" ]; then
  if [ "$FREE_GB" -ge 12 ] 2>/dev/null; then
    ok "${FREE_GB} GB free"
  else
    warn "only ${FREE_GB} GB free - Porting Kit + the game need roughly 8-10 GB"
    PROBLEMS=$((PROBLEMS+1))
  fi
fi

# --- porting kit ------------------------------------------------------------
say ""
say "Porting Kit"
if [ -d "/Applications/Porting Kit.app" ]; then
  PKV=$(/usr/bin/defaults read "/Applications/Porting Kit.app/Contents/Info.plist" CFBundleShortVersionString 2>/dev/null)
  ok "installed (version ${PKV:-unknown})"
else
  warn "Porting Kit is not installed yet - see START HERE.txt step 2"
  PROBLEMS=$((PROBLEMS+1))
fi

# --- wrapper ----------------------------------------------------------------
say ""
say "Zoo Tycoon wrapper (installed by Porting Kit)"
APP=""
for cand in "$HOME/Applications/Zoo Tycoon.app" "/Applications/Zoo Tycoon.app"; do
  [ -d "$cand" ] && { APP="$cand"; break; }
done
if [ -z "$APP" ]; then
  APP=$(/usr/bin/find "$HOME/Applications" /Applications -maxdepth 2 -iname "Zoo*Tycoon*.app" 2>/dev/null | head -1)
fi
if [ -n "$APP" ]; then
  ok "found: $APP"
  SIZE=$(/usr/bin/du -sh "$APP" 2>/dev/null | /usr/bin/awk '{print $1}')
  ok "size on disk: ${SIZE:-unknown}"
else
  warn "not installed yet - see START HERE.txt step 3"
  PROBLEMS=$((PROBLEMS+1))
fi

# --- disc image -------------------------------------------------------------
say ""
say "Game disc image (ZOO_TYCN.iso)"
if [ -d /Volumes/ZOO_TYCN ]; then
  ok "a disc is already mounted at /Volumes/ZOO_TYCN"
else
  ISO=$(/usr/bin/find "$HOME/Downloads" "$HOME/Desktop" -maxdepth 3 -iname "*ZOO_TYCN*.iso" 2>/dev/null | head -1)
  if [ -n "$ISO" ]; then
    ok "found: $ISO"
  else
    warn "ZOO_TYCN.iso not found in Downloads or Desktop - see START HERE.txt step 4"
    PROBLEMS=$((PROBLEMS+1))
  fi
fi

# --- summary ----------------------------------------------------------------
hr
if [ "$PROBLEMS" = 0 ]; then
  say "Everything checks out. Next: run  \"2 - Fix and Play.command\""
else
  say "$PROBLEMS thing(s) still need doing - they are listed as [warn] above."
  say "Finish those, then run \"2 - Fix and Play.command\"."
fi
hr
say ""
read -n 1 -s -r -p "Press any key to close this window... "
say ""
