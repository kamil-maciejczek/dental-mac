# Dental software on macOS (Apple Silicon) via HighBall — setup log

Machine: MacBook Pro M1 Pro, 32 GB, macOS 26.5.1 Tahoe, Rosetta 2. HighBall 0.10.10 (free, `brew install --cask highball`).
Everything lives in `~/Library/Application Support/Highball/` (engines, bottles, logs). Installers + hashes: `~/Downloads/dental-installers/`.
Status date: 2026-10-11 (work in progress — see "Open items").

## Engines installed
| id | Wine | used for |
|---|---|---|
| `x64-sikarugir10.0_6-r21` (default) | 10.0 Sikarugir | Blue Sky Plan |
| `x64-crossover26.3-r19` | 11.0, CrossOver 26.3 tree (Wine Mono/Gecko, CrossOver patches) | DentiqGuide, CS 3D |

Apple D3DMetal is NOT used (license: games-only, non-commercial). Renderers in use: WineD3D (OpenGL apps), DXMT (DirectX 11).

## Bottles (one per app; all Windows 10, sync = none, `vcrun2022` applied)
| bottle | engine | renderer | extra |
|---|---|---|---|
| `BlueSkyPlan` | Wine 10 | wined3d | `dlloverrides = opengl32=n,b`; `avx 1`; env `GLSHIM_VERSION_STRING=4.3 (Core Profile) Mesa 26.2.4 (git-9a0169f2a7)`, `GLSHIM_LOG=C:\gltest\glshim.log`; `glshim/opengl32.dll` copied into `Program Files/BlueSkyPlan/Launcher/` and `.../BlueSkyPlan4/` (Mesa llvmpipe DLLs kept as fallback in the session scratch) |
| `DentiqGuide` | Wine 11 | dxmt | `dotnet48` tweak; env `WINE_DISABLE_NX_COMPAT=0`; WPF software rendering; engine ntdll.so patched (see below) |
| `CS3D` | Wine 11 | wined3d | (installer pending) |

Bottle settings were applied with the HighBall CLI built from source (`swift build -c release --product highball` in a clone of
`gauthierpiarrette/highball` at tag v0.10.10, with `highball-db` cloned beside it). Same bottle.json format as the GUI; nothing in HighBall was modified.

## Blue Sky Plan 5.0.29 — WORKS up to the login screen
- Installer: `BlueSkyPlan_5.0.29-setup64.exe` (1.74 GB, Inno Setup 6.4.3) → silent: `/VERYSILENT /SUPPRESSMSGBOXES /NORESTART /SP-`. sha256 `7ed10959…b26f`.
- Must be started via **`Launcher/BlueSkyLauncher.exe`** (the Start-Menu target). `BlueSkyPlan4/BlueSkyPlan.exe` alone says "can not be run as a standalone application".
- **Hard wall found:** the Launcher requires **OpenGL 4.3**; macOS exposes at most 4.1, so native GL through Wine fails ("Your hardware doesn't meet the minimum requirements. OpenGL 4.3 or higher is required").
  **Fix A (software, slow):** Mesa llvmpipe (software OpenGL 4.6) from `pal1000/mesa-dist-win` 26.2.4 (`mesa3d-26.2.4-release-msvc.7z`, sha256 `351fc8c8…6695`) next to both exes + native `opengl32` override; with bottle `avx 1` (Rosetta AVX2) llvmpipe runs 256-bit, still a slideshow for 3D. The app's own `opengl32sw.dll` is Mesa 11.2 (too old). Zink (GL-on-Vulkan via MoltenVK) is impossible: "Zink requires the nullDescriptor feature of KHR/EXT robustness2".
  **Fix B (hardware, current):** our own `glshim/opengl32.dll` (see `glshim/README.md`): forwards to Wine's real driver (Apple M1 Pro, GL 4.1 core), reports 4.3, clamps 4.3+ context requests to 4.1, redirects the Launcher's foreign-process probe window to a helper window (Wine's Mac driver cannot set a pixel format on another process's window), and hands out stubs for missing 4.2–4.5/debug entry points (the Launcher crashed calling `glDebugMessageCallback` = NULL). Result: Launcher log `LibGL Apple / Apple M1 Pro / 4.3 (Core Profile)…`, "Init finished", hardware-accelerated. **User-verified 2026-10-11: Easy CT DICOM Viewer renders and rotates smoothly on the GPU.**
- A failed start leaves crash markers; the next start then shows a "previous run didn't finish correctly" report screen. To clear: stop the bottle and delete
  `drive_c/users/km/AppData/Local/BlueSkyBio/Blue Sky Plan Suite/logs/{crashinfo.log,Launcher.last}`.
- Launcher main window renders correctly (all modules shown). Login is browser-based SSO ("Open login page" → macOS default browser) — done. Easy CT DICOM Viewer imports the demo CBCT and renders the 3D surface under llvmpipe (verified 2026-10-11). Folder names with `#` break the CT folder picker (OK stays disabled) — use `demo-case/demo/CT`.
- Pins: `Blue Sky Plan Launcher` (use this), `Blue Sky Plan` (direct exe, do not use).
- Stack (for reference): Qt 6.8, OpenSceneGraph 3.7, QtWebEngine (software rendering), libtorch CPU, no .NET.

## DentiqGuide 1.4.00 (build 2026-08-20) — WORKS: login, license, device registration OK
- **Two Wine-specific fixes were required in this bottle:**
  1. The setup registers Sentinel HASP kernel drivers (`aksfridge`, `hardlock`) as auto-start services. Wine's driver host crashes loading them, services.exe restarts them, and every crash leaves a hung `winedbg` → thousands of processes, wineserver crash, system-wide resource exhaustion. Fix: stop the bottle, set `"Start"=dword:00000004` for both under `[System\\ControlSet001\\Services\\…]` in `system.reg`, and rename `drive_c/windows/system32/drivers/{aksfridge,hardlock}.sys` to `.disabled`. Also set `AeDebug "Debugger"="false"` so crashes don't spawn hung debuggers.
  2. `winetricks dotnet48` fails on the Wine 11 (CrossOver-tree) engine: HighBall runs winetricks through `/bin/bash`, which is SIP-protected, so macOS strips `DYLD_FALLBACK_LIBRARY_PATH`; the CrossOver-tree `wine` has no rpath and then cannot load FreeType/gnutls ("Wine cannot find the FreeType font library"), and the .NET installer's processes die with division-by-zero. The Wine 10 engine's loader carries an rpath and is not affected. Workaround used interactively: Homebrew bash. **Portable workaround (scripts/20-dentiqguide.sh, no extra tools):** keep `/bin/bash` but make `WINE`/`WINESERVER` wrapper scripts that re-export the env right before exec'ing the real binaries, and set winetricks' documented `WINE_BIN`/`WINESERVER_BIN`/`WINE_BINDIR`; also provide a stand-in `lipo` (winetricks calls it on macOS; absent without Xcode tools). Note: copying `/bin/bash` elsewhere does NOT work on Apple Silicon — the kernel kills platform binaries run outside the trust cache (`Killed: 9`). Worth reporting upstream to HighBall.
- Installer zip (393 MB, sha256 `32c1a7ee…6217`) contains `Setup_DentiqGuideN_V_1.4.00.20260820.exe` (NSIS) → silent `/S`.
  It runs prerequisites: VC++ 2015-2022, **Sentinel HASP driver (`haspdinst.exe`) — hangs under Wine with "Error when starting the aksfridge service"; kill `haspdinst.exe` and the setup continues** (dongle driver not needed with the web license), .NET Framework 4.8.1 (NDP481).
- Implant library zip (765 MB, sha256 `57a01b75…c393`) → `Setup_New_ImplantLibrary_FULL_20260729.exe` (NSIS) `/S`.
- Installed to `Program Files/DentiqGuideN/` (`PlatformGuideN.exe`). Stack: .NET/WPF + C++/CLI (`Clr*.dll`, `VxEngineCliWrapper.dll`), DirectX 11 volume renderer (`VS-GPUDX11VxRenderer.dll`) with CPU fallback (`VS-CPUVxRenderer.dll`), AI via **ONNX Runtime + DirectML (DirectX 12)**, WebView2 (`Microsoft.Web.WebView2.Wpf.dll`), Sentinel HASP + Reprise RLM license libs.
- `dotnet48` installed (NDP Release 528049, 64-bit clr.dll present, Wine Mono removed). Pin: `DentiqGuide` → `PlatformGuideN.exe` (a .NET 4.8.1-targeted exe; runs on 4.8).
- **Post-install registration must be done by hand** (the NSIS setup stalled on the dongle driver and never ran it): the app needs `HKLM\Software\Microsoft\Windows\CurrentVersion\App Paths\DentiqGuideN.exe` with `GUIDEDB` set, otherwise it shows "The program is not installed properly" / "has not been properly installed" and exits. Fix (one-time, bottle stopped afterwards):
  `highball run DentiqGuide "C:\Program Files\DentiqGuideN\VxAdminExec.exe" -- WRITE_REG_AND_CHANGE_AUTHORITY "C:\Program Files\DentiqGuideN" "C:\Program Files\DentiqGuideN\Database" km`
  (the helper's `icacls` calls succeed on Wine's stub; it logs "Change Authority : result = OK"). The app's own first-run "Permission settings… configure now?" ✓ registers the `dentiqguide://` URL scheme (works). The App Paths key itself was created by hand first (`@` = exe path, `Path` = install dir).
- WPF software rendering is on (`HKCU\Software\Microsoft\Avalon.Graphics\DisableHWAcceleration=1`). "Automation status" shows red (AI gated on a discrete GPU; expected).
- **Random full-UI freezes** (dialogs ignoring clicks, hang when zooming the 3D arch) — two causes, both fixed (user-verified 2026-10-11):
  1. Engine patch 0013 forces DEP on under Rosetta; a worker thread died with `nested exception on signal stack`. Fix: bottle env `WINE_DISABLE_NX_COMPAT=0` (documented knob of the HighBall engine).
  2. .NET's GC calls `FlushProcessWriteBuffers` on every thread suspension; Wine's macOS implementation (`NtFlushProcessWriteBuffers` → `thread_get_register_pointer_values` per thread) deadlocks with ~70 threads under Rosetta (process sample: 15 threads stuck inside it). Fix: 6-byte patch of `engines/x64-crossover26.3-r19/engine/lib/wine/x86_64-unix/ntdll.so` at `_NtFlushProcessWriteBuffers` (0x6ab20): `mfence; xor eax,eax; ret`, ad-hoc re-signed. Backup: `ntdll-backup/ntdll.so.orig`. **A HighBall engine update (new rNN) replaces ntdll.so — re-apply the patch** (command in the chat log / below).
  Patch command: `python3 -c "import sys;p=sys.argv[1];off=0x6ab20;b=bytearray(open(p,'rb').read());assert b[off:off+4]==bytes.fromhex('554889e5');b[off:off+6]=bytes.fromhex('0faef031c0c3');open(p,'wb').write(b)" "$N" && codesign -s - -f "$N"` (offset valid for engine r19 only — re-locate with `nm -n ntdll.so | grep NtFlushProcessWriteBuffers`).
- Not causes (tested and excluded): renderer choice (DXMT/WineD3D/DXVK all froze; DXMT kept, it is the only one without shader errors), CLI stdout pipe, accessibility clients (Grammarly, Codex Computer Use), `oleacc` typelib (registered anyway).
- Renderer: DXMT. Launch via `~/Applications/Highball/DentiqGuide.app`.
- Trial/web license: account login succeeded, licenses loaded, this Mac registered as a device (2 credits). Never recreate this bottle (device slot).
- App log: `drive_c/users/Public/Documents/DentiqGuideN/logfile_YYYYMM.txt`. Config: `Program Files/DentiqGuideN/Config/Settings/DentiqGuide_config.cvx` (XML).
- Demo data: `~/Downloads/dental-installers/demo-case/extracted/3DII_DentiqGuide_Demo_Case/` (512 DICOM slices + upper/lower jaw STL).

## CS 3D Imaging 3.10.48 (CS 3D Suite) — WORKS, renders 3D on native OpenGL
- Installer `CS3DSuite.exe` (654 MB, from lekarz.diagdent.pl, sha256 `4e5f17d2…319c`): NSIS 2.46 wrapper → silent `/S` (239 s). Contains `setup3DViewer.exe` (NSIS, 479 MB: `3DImagingSoftware.exe`, Lite viewer `ViewData.exe`, CPU TensorFlow models, vcredist2022) plus crown library, Film Composer, Quick Burn, Report Editor. **No SQL Server, no .NET** — C++/wxWidgets + OpenGL.
- Installed to `Program Files/Carestream Dental/3D Visualization Application/`. Pins: `CS 3D Imaging` (3DImagingSoftware.exe), `CS 3D Lite Viewer` (ViewData.exe). Start-menu also has "CS Activation" (licensing).
- Verified: opens the demo CBCT (pass a `.dcm` path as the program argument: `highball run CS3D "CS 3D Imaging" -- "Z:\...\Demo_0001.dcm"`), shows axial/panoramic/cross-section MPR and a **3D volume rendering** through Wine's Mac OpenGL driver (WineD3D bottle, `CX_FWD_COMPAT_GL_CTX=1` from HighBall). No Mesa needed.
- Cosmetic: non-Latin patient names show as mojibake in the title (code-page/font issue).

## Mac app launchers (daily use)
`~/Applications/Highball/{Blue Sky Plan, CS 3D Imaging, DentiqGuide}.app` — same stub HighBall's "Make a Mac app…" writes: a shell script opening `highball://play/pin/<bottle>/<pin-uuid>?t=<token>` (token in `~/Library/Application Support/Highball/launch-token`). HighBall must be installed; it starts the bottle and program. No icons yet — HighBall's own "Make a Mac app…" (Library → program) overwrites them with iconned versions.

## Deployment to another Apple Silicon Mac (`deploy/`)
The working setup is cloned, not re-installed: `deploy/pack.sh [dest]` builds `DentalApps-for-Mac/` (~11 GB: Highball.dmg, both engines incl. the patched ntdll.so, the three bottles minus temp/logs, the launchers, `INSTALL.command`, `README-for-users.md`). Copy the folder to the other Mac (USB-C SSD / AirDrop / shared drive) and double-click `INSTALL.command` there: it installs Highball.app from the DMG, Rosetta, copies the data into `~/Library/Application Support/Highball`, the launchers into `~/Applications/Highball`, strips quarantine and opens Highball once. The bottles' `users/km` profile is simply left unused on the other account (Wine creates the new user's profile); apps keep their Program Files/ProgramData state. Accounts (Blue Sky Bio, DentiqSolution) are signed in afresh there; DentiqGuide registers the new Mac as a device.

## Useful commands (CLI at `<scratch>/src/highball/.build/release/highball`, run from that repo dir)
```
highball bottle list
highball run BlueSkyPlan "Blue Sky Plan Launcher"
highball bottle kill BlueSkyPlan
highball recipe apply DentiqGuide dotnet48
highball pin list DentiqGuide
```
Logs: `~/Library/Application Support/Highball/logs/`, app logs inside each bottle's `drive_c/users/km/AppData/Local/`.

## Open items
- Blue Sky Plan: hardware rendering verified in the CT viewer; still to check other modules (implant planning, guide design) for artifacts from the stubbed GL 4.3 functions.
- DentiqGuide: manual planning works (user-verified); AI automation stays red (DirectML/DirectX 12 — no free path on macOS). Re-apply the ntdll patch after engine updates.
- CS 3D: licensing/activation (CS Activation) if the practice has a license; test with real patient exports; measurements/implant module.
- Time Machine backup of `bottles/` (licenses/device registrations live there).
- Do not upgrade past macOS 27 (Rosetta removal in macOS 28) until HighBall ships its ARM64 engine.
