# Zoo Tycoon Complete Collection — Easy Installer for Apple Silicon

> **Two installation methods included:**
> - **Method A (Recommended):** Automated installer using the Mac version + No-CD patch — no Porting Kit needed, no ISO mounting required.
> - **Method B (Legacy):** Porting Kit 7.0.2 repair scripts — for when Method A doesn't work.
> 
> Tested on macOS 27 (Sequoia), M1/M2/M3/M4.

---

## What this fixes

### Method A (Mac Version + No-CD Patch)
The community-discovered Mac version on MyAbandonware is a Wineskin wrapper with a hidden `.app` file. It works out of the box **if**:
1. Apple's quarantine/extended attributes are cleared (`xattr -cr`)
2. The Windows No-CD `zoo.exe` patch is injected
3. `MARINE.ISO` is bundled for any secondary disc checks

Our installer script (`0 - Install from Mac Version.command`) automates all of this.

### Method B (Porting Kit 7.0.2 — 4 Independent Packaging Bugs)

| # | Bug | Symptom | Fix applied |
|---|-----|---------|-------------|
| 1 | **cnc-ddraw COM trap** | `err:ole:apartment_add_dll couldn't find function DllGetClassObject in L"ddraw.dll"` | Replace with Wine's builtin `ddraw.dll` + registry override `*ddraw=builtin` |
| 2 | **Missing LC_RPATH** | `Library not loaded: @rpath/libinotify.0.dylib` / `Failed to load libMoltenVK.dylib` | `install_name_tool -add_rpath @executable_path/../../../Frameworks/moltenvkcx` on engine binaries |
| 3 | **800×600 fullscreen demand** | `err:display:macdrv_ChangeDisplaySettingsEx No matching mode found 800x600x32 @0!` | Rewrite `zoo.ini` → windowed 1024×768, **preserving `[mgr]` and `[language]`** |
| 4 | **Stale `gdi` renderer** | Direct3D terrain/water never renders | Remove `renderer=gdi` from `user.reg` (file edit, no Wine session) |

**Also included:** auto-mounts the required `ZOO_TYCN.iso` disc image.

---

## Copyright & Ownership — Read Before Sharing

| Item | Owner | Status in this repo |
|------|-------|---------------------|
| **Zoo Tycoon Complete Collection** (game code, assets, ISOs) | **Microsoft / Xbox Game Studios** (originally Blue Fang Games) | **NOT included**. Still under copyright. Not abandonware legally. |
| **Porting Kit** (the wrapper app) | **Paul "PaulTheTall" van der Meer** | **NOT included**. Free download from <https://paulthetall.itch.io/porting-kit>. |
| **Wine / DXMT / MoltenVK** | Wine Project / Apple / Khronos | **NOT included**. LGPL/MPL/Apache-2.0 — used by Porting Kit. |
| **The fix scripts in this repo** (`0`, `1`, `2 - *.command`, `START HERE.txt`) | **You (arkarchanmyae)** | ✅ **Included — your original work**. Licensed **MIT** (see `LICENSE`). |
| **`ZOO_TYCN.iso` / `MARINE.iso` / NOCD cracks** | Various | **NOT included**. Copyrighted game data / derivative works. |

**What you MAY share:**  
The script/text files in this repository — they contain no game code, no ISOs, no cracks, no Porting Kit binaries.

**What you MUST NOT share:**  
Any game ISO, the Porting Kit `.dmg`, any `zoo.exe` binary (original or cracked), any `MARINE.iso` / `ZOO_TYCN.iso` file.

---

## Quick start (for end users)

### Method A — Recommended (15 minutes)

1. **Download this repo** (or the `Zoo Tycoon Kit/` folder) to your Mac.
2. Ensure `Zoo-Tycoon-Complete-Collection_NoCD_Win_EN.zip` is in the kit folder (included).
3. Double-click **`0 - Install from Mac Version.command`**.
   - First run: Right-click → **Open** → **Open** (Gatekeeper).
   - If auto-download fails, the script will guide you to manually download the Mac version from MyAbandonware.
4. After it finishes, double-click **`Play Zoo Tycoon.command`** on your Desktop to play!

### Method B — Porting Kit (30–45 minutes)

Use only if Method A fails.
1. Open `START HERE.txt` and follow the Method B steps (Porting Kit install, disc image, fix scripts).

> **First run for any `.command` file:** macOS will say "cannot be opened because the developer cannot be verified."  
> Right-click the `.command` file → **Open** → **Open**. You only do this once per file.

---

## Repository structure

```
.
├── LICENSE                                    # MIT — covers the script/text files only
├── README.md                                  # This file
├── Zoo Tycoon Kit/
│   ├── START HERE.txt                         # Plain-English user guide (Method A + B)
│   ├── 0 - Install from Mac Version.command   # NEW: Automated Mac version + No-CD installer
│   ├── 1 - Check My Mac.command               # Validates Mac readiness (Method B)
│   ├── 2 - Fix and Play.command               # Applies 4 fixes + launches (Method B)
│   └── Zoo-Tycoon-Complete-Collection_NoCD_Win_EN.zip  # No-CD patch (included)
```

---

## How the scripts work (technical)

### Method A Installer (`0 - Install from Mac Version.command`)
- Downloads/extracts the Mac version from MyAbandomware (or guides manual download)
- Finds the hidden `.Zoo Tycoon.app` (the actual Wineskin wrapper)
- Moves to `/Applications/Zoo Tycoon.app`
- Runs `xattr -cr` to clear quarantine (critical for Wine on macOS)
- Extracts `zoo.exe` from the included No-CD zip and injects it into the game folder
- Copies `MARINE.ISO` into the wrapper's `Contents/Resources/`
- Creates `~/Desktop/Play Zoo Tycoon.command` launcher that auto-mounts ISO and launches

### Method B Fix Script (`2 - Fix and Play.command`)
- **No Wine session required** — registry edits by editing `user.reg` directly (`wine64 reg` crashes with SIGFPE on Apple Silicon)
- **Idempotent** — safe to run repeatedly; `--check` mode reports without changes
- **Preserves game config** — `zoo.ini` edit keeps `[mgr]` and `[language]` intact
- **Detects both prefix layouts** — works with `SharedSupport/prefix` or `Contents/Resources`

---

## Testing checklist

- [ ] `bash -n` passes on all `.command` files
- [ ] `0 - Install from Mac Version.command` runs on a clean Mac (auto or manual download path)
- [ ] `1 - Check My Mac.command` runs without error
- [ ] `2 - Fix and Play.command --check` reports `[todo]` for all four fixes on fresh Porting Kit install
- [ ] `2 - Fix and Play.command` applies fixes and launches game
- [ ] Game reaches main menu, terrain renders, no `:err:` lines in Wine log for 60+ seconds

---

## Forums where this fix is relevant

| Forum | Thread / Page | Notes |
|-------|---------------|-------|
| **Porting Kit Forum** (official) | <https://www.portingkit.com/forum/showthread.php?tid=485> | Thread "Zoo Tycoon - Complete Collection" — users report crashes, CD issues |
| **Reddit r/ZooTycoon** | <https://www.reddit.com/r/ZooTycoon/comments/14uwt7i/setting_up_zoo_tycoon_for_mac_using_porting_kit/> | "Setting Up Zoo Tycoon for Mac Using Porting Kit" — active, recent |
| **Reddit r/ZooTycoon** | <https://www.reddit.com/r/ZooTycoon/comments/1f6fqst/had_anyone_been_able_to_play_zoo_tycoon_1_on_the/> | M1/M2/M3 Apple Silicon specific |
| **Reddit r/ZooTycoon** | <https://www.reddit.com/r/ZooTycoon/comments/1ntqgjt/can_anyone_help_me_get_zoo_tycoon_1_to_work_on_my/> | Many confused users, incomplete guides |
| **Reddit r/ZooTycoon** | <https://www.reddit.com/r/ZooTycoon/comments/yzil5a/guide_how_to_play_zoo_tycoon_1_on_mac/> | "[Guide] How to play..." — PlayOnMac based, outdated |
| **Reddit r/ZooTycoon** | <https://www.reddit.com/r/ZooTycoon/comments/vnm7ct/zoo_tycoon_on_new_mac/> | "Zoo Tycoon on new Mac" — disc drive gone, Sierra+ broke it |
| **Reddit r/ZooTycoon** | <https://www.reddit.com/r/ZooTycoon/comments/1rgmw4l/issues_running_on_my_new_imac/> | "Issues running on my new iMac" — M-series chip, CD prompt |
| **Reddit r/macgaming** | <https://www.reddit.com/r/macgaming/comments/e1l1qy/zoo_tycoon_for_mac/> | General Mac gaming, Porting Kit mentioned |
| **WineHQ Forums** | <https://forum.winehq.org/viewtopic.php?t=24933> | "Crashes While Loading" — Gold rating, old but relevant |
| **PaulTheTall Blog** | <https://www.paulthetall.com/zoo-tycoon-for-mac/> | Creator's page, comments section open |
| **MyAbandonware** | <https://www.myabandonware.com/game/zoo-tycoon-complete-collection-dzx> | Game page, comments full of Mac users asking for help |
| **MacRumors** | <https://forums.macrumors.com/threads/zoo-tycoon-pc-game-on-mac.1422308/> | Old thread (2012) but still linked; Wineskin-focused |
| **Apple Discussions** | <https://discussions.apple.com/thread/7031602> | "How do I install Zoo Tycoon on my Mac Air?" |

---

## License

```
MIT License

Copyright (c) 2026 arkarchanmyae

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

**Applies only to:** `0 - Install from Mac Version.command`, `1 - Check My Mac.command`, `2 - Fix and Play.command`, `START HERE.txt`.  
**Does NOT apply to:** any game files, ISOs, Porting Kit, Wine, or third-party binaries.

---

## Attribution

If you share this fix elsewhere, please credit:
- Fix author: **arkarchanmyae** (this repo)
- Porting Kit: **Paul "PaulTheTall" van der Meer** <https://paulthetall.itch.io/porting-kit>
- Wine/DXMT/MoltenVK teams for the underlying compatibility layer
- Community members on Reddit/MyAbandonware who documented the Mac version + No-CD method

---

## Disclaimer

This is an **unofficial community fix**. Not affiliated with Microsoft, Xbox Game Studios, Blue Fang Games, PaulTheTall, CodeWeavers, or the Wine Project. Use at your own risk. The game remains the property of its copyright holders.