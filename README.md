# Zoo Tycoon Complete Collection — Porting Kit Fix for Apple Silicon

> **One-click repair + launch scripts for the Porting Kit 7.0.2 wrapper on macOS (M1/M2/M3/M4).**  
> Tested on macOS 27 (Sequoia), Porting Kit 7.0.2, Wine 11 engine with DXMT/MoltenVK.

---

## What this fixes

Porting Kit's Zoo Tycoon Complete Collection port has **four independent packaging bugs** that prevent it from running on Apple Silicon Macs. This kit applies all four automatically:

| # | Bug | Symptom | Fix applied |
|---|-----|---------|-------------|
| 1 | **cnc-ddraw COM trap** | `err:ole:apartment_add_dll couldn't find function DllGetClassObject in L"ddraw.dll"` — game dies at startup | Replace Porting Kit's `cnc-ddraw` with Wine's builtin `ddraw.dll` + registry override `*ddraw=builtin` |
| 2 | **Missing LC_RPATH on engine binaries** | `Library not loaded: @rpath/libinotify.0.dylib` / `wine_vk_init Failed to load libMoltenVK.dylib` — cold start crashes before game launches | `install_name_tool -add_rpath @executable_path/../../../Frameworks/moltenvkcx` on `wineserver`, `wine64`, `wine64-preloader`, and `winevulkan.so` |
| 3 | **800×600 fullscreen demand** | `err:display:macdrv_ChangeDisplaySettingsEx No matching mode found 800x600x32 @0!` — Retina displays don't offer this mode | Rewrite `zoo.ini` → windowed 1024×768, **preserving `[mgr]` and `[language]` sections** (dropping them makes the game loop rewriting the file forever) |
| 4 | **Stale `gdi` renderer override** | Direct3D terrain/water never renders; game appears broken | Remove `renderer=gdi` from `user.reg` (file edit, no Wine session needed) |

**Also included:** auto-mounts the required `ZOO_TYCN.iso` disc image (the game checks for this volume label).

---

## Copyright & Ownership — Read Before Sharing

| Item | Owner | Status in this repo |
|------|-------|---------------------|
| **Zoo Tycoon Complete Collection** (game code, assets, ISOs) | **Microsoft / Xbox Game Studios** (originally Blue Fang Games) | **NOT included**. Still under copyright. Not abandonware legally. |
| **Porting Kit** (the wrapper app) | **Paul "PaulTheTall" van der Meer** | **NOT included**. Free download from <https://paulthetall.itch.io/porting-kit>. |
| **Wine / DXMT / MoltenVK** | Wine Project / Apple / Khronos | **NOT included**. LGPL/MPL/Apache-2.0 — used by Porting Kit. |
| **The fix scripts in this repo** (`1 - Check My Mac.command`, `2 - Fix and Play.command`, `START HERE.txt`) | **You (arkarchanmyae)** | ✅ **Included — your original work**. Licensed **MIT** (see `LICENSE`). |
| **`ZOO_TYCN.iso` / `MARINE.iso` / NOCD cracks** | Various | **NOT included**. Copyrighted game data / derivative works. |

**What you MAY share:**  
The three script/text files in this repository — they contain no game code, no ISOs, no cracks, no Porting Kit binaries. They only *configure* a wrapper the user already installed.

**What you MUST NOT share:**  
Any game ISO, the Porting Kit `.dmg`, any `zoo.exe` binary (original or cracked), any `MARINE.iso` / `ZOO_TYCN.iso` file.

---

## Quick start (for end users)

1. **Download this repo** (or the `Zoo Tycoon Kit/` folder) to your Mac.
2. Open `START HERE.txt` and follow steps 1–6.  
   - Steps 2 & 3: Install Porting Kit + the Zoo Tycoon port (you do this manually).  
   - Step 4: Get `ZOO_TYCN.iso` from your own disc or a legal source.  
   - Steps 5 & 6: Double-click the two `.command` files — they do the rest.
3. Play.

> **First run:** macOS will say "cannot be opened because the developer cannot be verified."  
> Right-click the `.command` file → **Open** → **Open**. You only do this once per file.

---

## For contributors / developers

### Repository structure
```
.
├── LICENSE                 # MIT — covers the three script/text files only
├── README.md               # This file
├── Zoo Tycoon Kit/
│   ├── START HERE.txt      # Plain-English user guide (steps 1–6)
│   ├── 1 - Check My Mac.command
│   └── 2 - Fix and Play.command
```

### How the fix script works (technical)
- **No Wine session required** — registry edits are done by editing `user.reg` directly (`wine64 reg` crashes with SIGFPE on Apple Silicon).
- **Idempotent** — safe to run repeatedly; check mode (`--check`) reports without changing anything.
- **Preserves game config** — the `zoo.ini` edit keeps `[mgr]` and `[language]` sections intact; only replaces the `[user]` block.
- **Detects both prefix layouts** — works whether Porting Kit uses `Contents/SharedSupport/prefix` or `Contents/Resources`.

### Testing checklist (before PR)
- [ ] `bash -n` passes on both `.command` files
- [ ] `./1 - Check My Mac.command` runs without error on a clean Mac
- [ ] `./2 - Fix and Play.command --check` reports `[todo]` for all four fixes on a fresh Porting Kit install
- [ ] `./2 - Fix and Play.command` applies fixes and launches game on a fresh install
- [ ] Game reaches main menu, terrain renders, no `:err:` lines in Wine log for 60+ seconds

---

## Forums where this fix is relevant

| Forum | Thread / Page | Notes |
|-------|---------------|-------|
| **Porting Kit Forum** (official) | <https://www.portingkit.com/forum/showthread.php?tid=485> | Thread "Zoo Tycoon - Complete Collection" — users report crashes, CD issues |
| **Reddit r/ZooTycoon** | <https://www.reddit.com/r/ZooTycoon/comments/14uwt7i/setting_up_zoo_tycoon_for_mac_using_porting_kit/> | "Setting Up Zoo Tycoon for Mac Using Porting Kit" — active, recent |
| **Reddit r/ZooTycoon** | <https://www.reddit.com/r/ZooTycoon/comments/1f6fqst/had_anyone_been_able_to_play_zoo_tycoon_1_on_the/> | M1/M2/M3 Apple Silicon specific |
| **Reddit r/ZooTycoon** | <https://www.reddit.com/r/ZooTycoon/comments/1ntqgjt/can_anyone_help_me_get_zoo_tycoon_1_to_work_on_my/> | Many confused users, incomplete guides |
| **Reddit r/ZooTycoon** | <https://www.reddit.com/r/ZooTycoon/comments/yzil5a/guide_how_to_play_zoo_tycoon_1_on_mac/> | "[Guide] How to play Zoo Tycoon 1 on Mac" — PlayOnMac based, outdated |
| **Reddit r/ZooTycoon** | <https://www.reddit.com/r/ZooTycoon/comments/vnm7ct/zoo_tycoon_on_new_mac/> | "Zoo Tycoon on new Mac" — disc drive gone, Sierra+ broke it |
| **Reddit r/ZooTycoon** | <https://www.reddit.com/r/ZooTycoon/comments/1rgmw4l/issues_running_on_my_new_imac/> | "Issues running on my new iMac" — M-series chip, CD prompt |
| **Reddit r/macgaming** | <https://www.reddit.com/r/macgaming/comments/e1l1qy/zoo_tycoon_for_mac/> | General Mac gaming, Porting Kit mentioned |
| **WineHQ Forums** | <https://forum.winehq.org/viewtopic.php?t=24933> | "Zoo Tycoon Complete Collection - Crashes While Loading" — Gold rating, old but relevant |
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

**Applies only to:** `1 - Check My Mac.command`, `2 - Fix and Play.command`, `START HERE.txt`.  
**Does NOT apply to:** any game files, ISOs, Porting Kit, Wine, or third-party binaries.

---

## Attribution

If you share this fix elsewhere, please credit:
- Fix author: **arkarchanmyae** (this repo)
- Porting Kit: **Paul "PaulTheTall" van der Meer** <https://paulthetall.itch.io/porting-kit>
- Wine/DXMT/MoltenVK teams for the underlying compatibility layer

---

## Disclaimer

This is an **unofficial community fix**. Not affiliated with Microsoft, Xbox Game Studios, Blue Fang Games, PaulTheTall, CodeWeavers, or the Wine Project. Use at your own risk. The game remains the property of its copyright holders.