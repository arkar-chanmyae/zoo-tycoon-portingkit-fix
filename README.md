# Zoo Tycoon Complete Collection — Easy Installer for Apple Silicon

> **Two installation methods included:**
> - **Method A (Recommended):** Automated installer using the Mac version + No-CD patch — no Porting Kit needed, no ISO mounting required.
> - **Method B (Legacy):** Porting Kit 7.0.2 repair scripts — for when Method A doesn't work.
> 
> Tested on macOS 27 (Sequoia), M1/M2/M3/M4.

---

## What this fixes

### Method A (Mac Version repack — verified working)
The Mac version on MyAbandonware is a ZIP containing a single `ZT-CE.dmg`. Inside that image sit **two** app bundles:

| Bundle | Role | Size |
|--------|------|------|
| `.Zoo Tycoon.app` (hidden) | The real Wineskin wrapper — engine `WS11WineCX21.1.0`, contains the whole game + a fake `MARINE.iso` | 1.6 GB |
| `Zoo Tycoon.app` | The author's launcher: mounts the fake MARINE image, opens the wrapper, ejects the image after 20 s | tiny |

It runs on Apple Silicon **if**:
1. Apple's quarantine attributes are cleared (`xattr -cr`) — otherwise macOS reports *"Zoo Tycoon is damaged and cannot be opened"*
2. The disc check is satisfied

Point 2 is the catch. The repack's fake `MARINE.iso` **does not work on macOS 26/27**: Wine on macOS types removable media by IOKit class, and a `hdiutil`-mounted image reports as generic media, not a CD — so the game still demands the CD-ROM. Verified on a real machine, not inferred.

Therefore the installer defaults to the **No-CD patch**, with a documented trade-off (below).

Our installer (`0 - Install from Mac Version.command`) automates the whole chain.

#### The No-CD trade-off — read before choosing

The repack author and the MyAbandonware page both state it plainly:

> *"Attention. If you use a No-CD crack the Zookeepers won't tidy up the park nor repairing anything! You must Play the Game with CD2 inserted and the original exe."*

So the No-CD patch buys a working launch at the cost of **staff upkeep**: zookeepers stop cleaning exhibits, maintenance workers stop repairing fences. The installer therefore:

- keeps the original as `zoo.exe.original`, so it is one `cp` to undo
- offers choice **B** (original files) for older macOS where the fake image still satisfies the check

#### The disc check — three options, and the one that works

Since the fake `MARINE` image cannot satisfy the check on macOS 26/27, a patch is required. The installer offers three paths:

| Option | No CD prompt | Staff upkeep intact |
|--------|:---:|:---:|
| **A — LuKeStorm Custom Patch** | ✅ | ✅ |
| B — No-CD crack | ✅ | ❌ |
| C — original files | ❌ | ✅ |

**Option A is verified working in this wrapper.** The patch (proxy `ijl15.dll` + `custompatch.ini`, ~140 KB) targets Complete Collection v12.4.0.9 — exactly what this repack's `zoo.exe` reports (`12.04.00.0009`) — and the `ijl15_org.dll` it ships md5-matches this game's stock `ijl15.dll` (`4fc074c3…`), confirming a clean base. Its ini enables `NoCD=1` and `EnableCCFixStaffWithoutRegValue=1`.

It works by patching the **original exe in memory**, so the installer restores the original `zoo.exe` before applying it — a pre-cracked exe must not be left in place. Confirmed on a real machine: patch installed, **no disk image mounted at all**, game starts and runs.

We do **not** redistribute the patch: the `ijl15_org.dll` inside it is a copy of one of the game's own files. The installer takes the proxy DLL and ini from a user-supplied zip and rebuilds `ijl15_org.dll` from the local stock file. Manual download (free account may be required): <https://community.pcgamingwiki.com/files/file/3251-zoo-tycoon-complete-collection-custom-patch/>

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

### Method A — Recommended and verified (15 minutes)

1. **Download this repo** (or the `Zoo Tycoon Kit/` folder) to your Mac.
2. Download the Mac version from MyAbandonware and leave it in `Downloads`:
   `Zoo-Tycoon-Complete-Collection_Mac_EN_Repack.zip` (1.2 GB) — the installer cannot fetch this itself, the site blocks scripted downloads.
3. **Recommended:** download the 140 KB LuKeStorm Custom Patch and save it as `ZooTycoonCC_CustomPatch.zip` (Downloads or the kit folder). This is what gives you *both* no CD prompt *and* working staff. Without it the installer falls back to the No-CD crack, which breaks zookeeper/maintenance behaviour.
4. Ensure `Zoo-Tycoon-Complete-Collection_NoCD_Win_EN.zip` is in the kit folder (included, used only as the fallback).
5. Double-click **`0 - Install from Mac Version.command`**. *Only if macOS blocks it* with the "developer cannot be verified" box: right-click the file → **Open** → **Open**. That approval is one-time per file; if it opens normally there is nothing to right-click.
6. Answer the one question about the disc check — press Return for the default.
7. Play: double-click **`Zoo Tycoon`** on your Desktop (created by the installer when you pick option A or B).

> **You do not re-run anything to play again.** With option A or B the game needs no disc — just open **`Zoo Tycoon`** on the Desktop, or the game in `Applications`. `Play Zoo Tycoon.command` only matters for option C (original files), where it mounts the fake image the unpatched game expects.

Requires ~3 GB free disk space (the game is 1.6 GB).

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
- Locates `Zoo-Tycoon-Complete-Collection_Mac_EN_Repack.zip` in the kit folder, `Downloads`, or `Desktop`
- Extracts only `ZT-CE.dmg` from inside it (the ZIP holds that single file), mounts it read-only at a private mountpoint
- Finds the hidden `.Zoo Tycoon.app` on the volume and `ditto`s its **parent folder** to `/Applications/Zoo Tycoon - Complete Collection` — `ditto` because the wrapper contains symlinks (`drive_c`, `Logs`) and resource forks a plain `cp` would mangle
- Runs `xattr -cr` plus `find -name '._*' -delete` to clear quarantine
- Prompts for the disc-check method (A Custom Patch / B No-CD / C original), defaulting to A when the patch zip is present, else B, else C
- **Option A**: takes `ijl15.dll` + `custompatch.ini` from the user's patch zip, restores the original `zoo.exe` first (the patch patches it in memory), backs up the stock DLL to `ijl15.dll.beforepatch`, and rebuilds `ijl15_org.dll` from that local copy rather than shipping the game's own file
- **Option B**: snapshots to `zoo.exe.original` **only if that backup does not already exist**, so re-running can never overwrite a genuine original with a cracked exe
- Writes `~/Desktop/Play Zoo Tycoon.command`, which prefers the repack's own helper (mounting the fake image, then ejecting it after 20 s) and falls back to mounting `MARINE.iso` directly if the helper was removed
- Cleans its temp folder on exit via a `trap`, and detaches the image even on failure

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