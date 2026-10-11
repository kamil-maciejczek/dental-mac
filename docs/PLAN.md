# Run CS 3D Imaging, DentiqGuide and Blue Sky Plan on macOS with HighBall (free)

## Context

Three Windows dental programs must run on this Mac for **daily clinical planning**, with no paid layer (no CrossOver, no Parallels). Preferred tool: **HighBall** (already installed, never launched). Writing recipes/patches is acceptable, but unmodified use is preferred — and research shows **no HighBall code changes are needed**: its UI accepts any `.exe`/`.msi` by drag-and-drop, with per-program renderer, env vars and a "Make a Mac app…" launcher.

**Machine (verified):** MacBook Pro M1 Pro, 32 GB, macOS 26.5.1 Tahoe, Rosetta 2 working, Homebrew arm64, no XQuartz/Wine/prefixes, no installers on disk. Highball 0.10.10 in `/Applications`, user data not yet created.

**Research outcome (2026-10-11), the facts that shape the plan:**
- **None of the three has a native Mac build.** Blue Sky Plan dropped its Intel-only 4.0.4.1 Mac build; vendor says "MacOS not supported". Carestream: Windows only, "VMs/emulated OS not supported". DentiqGuide: Windows 10/11 x64 only.
- **All three are OpenGL renderers** (Blue Sky Plan: Qt5 + OpenSceneGraph 3.6.5, QtWebEngine; CS 3D: OpenGL 3.2 required; DentiqGuide: says "DirectX 11" but credits OpenFlipper/Qt — unclear). Wine's Mac driver offers only a 2.1 legacy or a 3.2–4.1 **core/forward-compatible** context; a 3.1+ *compatibility* profile is impossible on macOS. HighBall forces `CX_FWD_COMPAT_GL_CTX=1` so core 3.2+ requests succeed.
- **.NET:** every free Wine is x86_64 under Rosetta; patch-free WineHQ 11.x builds regressed .NET apps; HighBall's optional **Wine 11 (CrossOver 26.3 tree) engine** ships Wine Mono/Gecko with CrossOver patches and is the most .NET-capable free Wine on macOS today. 64-bit .NET Framework apps can still crash (CLR 0x80131506) — untested on that engine.
- **Renderers:** DXMT (D3D10/11→Metal, MIT) and DXVK-macOS (zlib) are fine. **Apple D3DMetal is licensed for game evaluation only, non-commercial** → do **not** accept its license / use it for clinical software.
- **Homebrew Wine casks are disabled since 2026-09-01**; free alternatives are HighBall, Sikarugir (Wineskin successor, same Gcenx engines), frankea/Whisky fork, or curl-downloaded Gcenx tarballs.
- **Rosetta deadline:** available through macOS 27; macOS 28 keeps it only for old games. Stay ≤ macOS 27 until HighBall's planned non-Rosetta ARM64EC/FEX engine (needs macOS 26.5+, expected ~early 2027) exists.
- **DentiqGuide AI features** (auto nerve detection / scan alignment — user says required) are gated on a discrete NVIDIA/AMD GPU ≥ 2 GB. No layer or VM on this Mac provides one. Best effort: GPU-identity spoof; honest fallback: a Windows PC/cloud GPU VM for the AI steps.

**User-confirmed inputs:** CS Imaging Suite installer will be downloaded by the user from `lekarz.diagdent.pl/do-pobrania` (login-gated; 404 for anonymous fetch). DentiqGuide: trial/web license (no dongle). Downloads approved: HighBall engines (default one already installed; Wine 11 engine ~1–2 GB still to fetch), Blue Sky Plan 5.0.29 (1.74 GB), DentiqGuide (393 MB + 765 MB), Mesa llvmpipe (~100 MB).

**bottle.json fields seen in the live `Games` bottle** (useful for the README and any manual tweak): `engineID`, `renderer` + `rendererExplicit`, `sync` (`none|esync|msync`), `windowsVersion`, `dllOverrides` (string), `environment` / `gameEnvironment`, `pins[]`, `recipes[]`, `dxvkAppConfig{}`, `dpiScale`, `retinaAt100`, `advertiseAVX`.

**Boundaries:** Claude will not create vendor accounts, fill registration forms, or accept Apple's GPTK license; those steps are handed to the user at the right moment. Vendors do not support Wine/VM use for these regulated medical devices — the user accepts this for clinical use.

## Decisions

| Topic | Choice | Why |
|---|---|---|
| Layer | **HighBall 0.10.x** (stable channel, beta builds off) | installed, free, GUI handles arbitrary installers, best free .NET engine, per-program renderer/env, Mac app launchers |
| Bottles | one per app: `BlueSkyPlan`, `DentiqGuide`, `CS3D` (not the default "Games" bottle) | isolation; licenses/device registrations live in the bottle |
| Engine | Blue Sky Plan: default Wine 10 (Sikarugir) first; DentiqGuide + CS 3D: **Wine 11 (CrossOver 26.3 tree)** | no .NET in BSP; unknown/.NET-likely stacks get the CrossOver-patched tree |
| Renderer | BSP & CS 3D: **WineD3D** (OpenGL apps, D3D unused); DentiqGuide: **DXMT** (D3D11), DXVK as alt | MIT/zlib licenses; D3DMetal excluded |
| Windows ver / sync | Windows 10, sync = **none** | business apps; msync/esync hang Chromium-based UIs (BSP's QtWebEngine) |
| Installers | `~/Downloads/dental-installers/<app>/` (one empty dir per download, sha256 recorded) | persistent for reinstalls; untrusted-download hygiene |
| Recipes / code | **none initially**; README with exact steps instead | Ponytail: GUI path needs no code. Upstream recipes (highball-db `recipes/launchers/*.json`, CC0) only if steps prove reproducible and user wants it |

## Phase 0 — HighBall bootstrap (mostly done already)

**Already in place (verified 2026-10-11 12:25):** Highball 0.10.10 launched; default engine `x64-sikarugir10.0_6-r21` installed (1.2 GB) at `~/Library/Application Support/Highball/engines/`; one bottle `Games` (DXMT, msync, win10, no pins) created; `acceptedLicenses: []` (D3DMetal never accepted — keep it that way). 319 GB free.

1. Leave the `Games` bottle alone. Create bottles `BlueSkyPlan`, `DentiqGuide`, `CS3D`. For `DentiqGuide` and `CS3D`: Advanced → move to the Wine 11 (CrossOver 26.3) engine (one extra ~1–2 GB engine download; its DXMT/runtime components are shared). **Decline / skip any Apple GPTK (D3DMetal) license prompt.** Settings: keep "Get beta builds" off.
3. Per bottle: Windows version = Windows 10, sync = none, renderer per table above.
4. Tweaks (HighBall "add-ons"): `vcrun2022` in all three. `corefonts` (may need Xcode licence accepted or HighBall ≥ 0.10.11; skip if it fails — fonts are cosmetic). `dotnet48` only in bottles whose installer turns out to need .NET (20–40 min).
5. Note engine ids actually installed (`~/Library/Application Support/Highball/engines/`) — HighBall never auto-moves a bottle to another engine, which is what we want for daily use.

## Phase 1 — Blue Sky Plan 5.0.29 (highest success chance, do first)

1. Download `https://manual.blueskyplan.com/catalogs/BSP/BlueSkyPlan_5.0.29-setup64.exe` (~1.74 GB) → `~/Downloads/dental-installers/blueskyplan/`; record sha256.
2. Drop the exe on the `BlueSkyPlan` bottle → "Run and add to Programs" → complete the installer. If it complains about VC++ 2013/2015-2019 runtimes, run Microsoft's `vcredist_x64` 2013 exe in the bottle the same way (2015-2022 already via `vcrun2022`; WineHQ bug 50019's `vcomp140` crash is fixed since Wine 6.21).
3. Launch → **user** fills the in-app registration form; activation code arrives by e-mail (≤ 48 h); user enters it.
4. Test rendering with a real CBCT DICOM folder: 3D view, MPR slices, implant placement, guide design, STL export.
   - Black viewports → try in order: renderer WineD3D OpenGL vs Vulkan backend; `QT_OPENGL=desktop` program env var; Wine 11 engine; then Phase 5 Mesa fallback.
   - Black/blank web panes (QtWebEngine) → program env `QTWEBENGINE_CHROMIUM_FLAGS=--disable-gpu`; on Wine 11 engine `DXMT_ALLOW_CROSS_PROCESS_SWAPCHAIN=1` is already in the base env.
5. "Make a Mac app…" → `~/Applications/Highball/Blue Sky Plan.app`.

## Phase 2 — DentiqGuide 1.4.x

1. Download `https://s3.ap-northeast-2.amazonaws.com/service.dentiqcloud.com/SetupFiles/NewestN/Setup_DentiqGuide_Newest.zip` (~393 MB) and the implant-library zip (~765 MB, URL from `https://www.dentiqsolution.com/support/download`) → `~/Downloads/dental-installers/dentiqguide/`; unzip into their own empty dirs; record sha256.
2. Run the InstallShield setup in the `DentiqGuide` bottle (Wine 11 engine, DXMT). InstallShield may unpack an MSI; HighBall runs `.msi` through `msiexec /i … /qn`. If the installer's .NET bootstrapper fails with `0x8007000E`, install `dotnet48` first and retry.
3. Install the implant library the same way.
4. Launch → **user** signs in / starts the 90-day trial (web license registers this bottle as a device; trial allows 3 devices — never delete/recreate this bottle casually).
5. Test manual workflow (CBCT import, implant placement, guide export with trial credits/watermark).
6. **AI features test.** If greyed out / "GPU not supported":
   a. per-program GPU-identity override — NVIDIA vendor/device id and ≥4 GB VRAM via the renderer config (DXVK: `DXVK_CONFIG="dxgi.customVendorId = 10de; dxgi.customDeviceId = 2684; dxgi.customDeviceDesc = NVIDIA GeForce RTX 4090; dxgi.maxDeviceMemory = 8192"`; DXMT equivalent if it exposes one; HighBall's own `csgo-legacy` recipe uses a scoped NVIDIA identity + `nvapi-stub`, same mechanism);
   b. if the AI backend needs CUDA or DirectX 12 compute (DirectML) it cannot run under free Wine on this Mac; document and hand to the user the realistic option: run the AI steps on a Windows machine with a discrete GPU (or a cloud GPU VM), keep manual planning on the Mac.
7. "Make a Mac app…".

## Phase 3 — CS 3D Imaging (CS Imaging Suite from diagdent)

1. **User** downloads the suite installer from `lekarz.diagdent.pl/do-pobrania` into `~/Downloads/dental-installers/cs3d/` (and, if available there, any standalone "CS 3D Imaging" package and a sample patient export — the exported-disc "CS 3D Imaging Lite" `ViewData.exe` viewer is the license-free fallback).
2. Inspect before running: `7z l` / `innoextract -l` / `cabextract -l` on the installer to learn components (SQL Server? .NET? separate CS 3D MSI?). **Install only the CS 3D Imaging / workstation component**; avoid CS Imaging Server + SQL Server (does not install under Wine). If the suite setup cannot deselect it, extract the CS 3D MSI with `msiexec /a` and install just that.
3. Bottle `CS3D` (Wine 11 engine, WineD3D): add `dotnet48` first if the inspection shows .NET; then run the installer. If the app is WPF: registry `HKCU\Software\Microsoft\Avalon.Graphics\DisableHWAcceleration = 1` (software WPF) — HighBall per-program step or `regedit` in the bottle.
4. Licensing: workstation installs need no activation; if the practice has a CS Imaging Server, mount its share in macOS and expose it to the bottle via a drive letter symlink in `bottles/CS3D/dosdevices/`. Premium features need the user's Carestream sign-in (every 7 days).
5. Test with a CBCT volume: 2D/MPR first, then 3D volume rendering. If 3D is blank/garbled with "OpenGL 3.2 required" symptoms → Phase 5 Mesa fallback for this program only.
6. "Make a Mac app…".

## Phase 4 — Daily-use polish

- Launchers for all three in `~/Applications/Highball/`; verify they open the right bottle/program after a reboot and that licenses persist.
- Back up `~/Library/Application Support/Highball/bottles/` (holds licenses/device registrations) — point Time Machine at it, exclude nothing.
- Write `/Users/km/Desktop/code/dental soft/README.md`: versions (HighBall, engine ids, app builds, sha256s), exact per-bottle settings and env vars, what worked/failed per app, the fallback ladder, and the "don't upgrade past macOS 27 / reinstall Rosetta after upgrading to 27" note.
- Optional, only if the user wants to share: HighBall recipe JSONs (`kind: launcher`, `installer`/`winetricks`/`registry`/`pin` steps as in the bundled `vcrun2022.json`/`steam.json`) for a PR to `gauthierpiarrette/highball-db` `recipes/launchers/`. Not required for the setup to work.

## Phase 5 — Fallback ladder (apply per program, stop at the first that works)

1. Other HighBall engine (Wine 10 ↔ Wine 11) and other renderer (WineD3D ↔ DXMT ↔ DXVK).
2. **Mesa llvmpipe** software OpenGL 4.5 (all profiles): download `pal1000/mesa-dist-win` release (~100 MB) → `~/Downloads/dental-installers/mesa/`; copy the x64 `opengl32.dll` (+ dependencies) next to the program's exe with a per-program DLL override `opengl32=native`; env `LP_NUM_THREADS=8`. Expect slow but correct 3D (MPR slices fine; volume rendering sluggish).
3. **Sikarugir** wrapper (`brew trust Sikarugir-App/sikarugir && brew install --cask Sikarugir-App/sikarugir/sikarugir`): different winemac build (Wine 11.0_1 or CX24 engine), per-app .app. Same bottle tricks apply.
4. Windows 11 ARM VM in **VMware Fusion** (free since Nov 2024) — needs a Windows licence; virtual DirectX 11 GPU; OpenGL for Windows guests unverified; still no NVIDIA/AMD GPU (DentiqGuide AI likely still blocked).
5. Windows PC / cloud GPU VM for GPU-gated AI only.

## Verification (end-to-end, per app)

- Installer exits 0, program pinned in HighBall, launches from the Mac app launcher.
- User completes registration/sign-in; license survives quit, reboot and a HighBall app update.
- Real CBCT DICOM dataset opens; 3D view renders and rotates interactively (target ≥ 15 fps on hardware GL; record llvmpipe fps if used); MPR slices, measurements, implant placement, guide/STL export all work.
- DentiqGuide: AI features status recorded explicitly (works / spoof works / impossible → fallback handed over).
- On any failure, collect `~/Library/Application Support/Highball/logs/` and `bottles/<name>/drive_c/highball/logs` before changing settings; one variable at a time.

## Risks / honest expectations

- **CS 3D Imaging** is the least likely to run on hardware GL (OpenGL 3.2 + NVIDIA-only history; 2010 CrossOver report rendered no 3D). Worst case: 2D works, 3D via llvmpipe only, or Lite viewer only.
- **DentiqGuide AI** may be impossible on this hardware regardless of layer; manual workflow is the realistic Mac deliverable.
- **Blue Sky Plan** had black-viewport bugs even in Parallels; 5.x on Wine is untested anywhere.
- **Rosetta** removal in macOS 28; HighBall's ARM64 engine is not shipped yet.
- Single-maintainer tool in beta; pin and back up what works.
