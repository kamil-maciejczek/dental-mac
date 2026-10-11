# Dental software on Apple Silicon Macs (free, Wine-based)

Runs three Windows dental programs on an Apple Silicon Mac through [HighBall](https://github.com/gauthierpiarrette/highball) (free, GPL) — no CrossOver, no Parallels, no developer tools on the target Mac:

| Program | Version | Status |
|---|---|---|
| Blue Sky Plan (Blue Sky Bio) | 5.0.29 | works, GPU-accelerated (needs our OpenGL 4.3 shim) |
| DentiqGuide (3D Industrial Imaging) | 1.4.00 | works for manual planning (AI automation needs a DirectX 12 GPU → not on macOS) |
| CS 3D Imaging (Carestream) | 3.10.48 | works incl. 3D volume rendering |

Verified on a MacBook Pro M1 Pro, macOS 26.5.1. Target: any Apple Silicon Mac, macOS 14 or newer, ~20 GB free, internet.
Full engineering record (every finding, dead end and workaround): [docs/SETUP-LOG.md](docs/SETUP-LOG.md). Original plan: [docs/PLAN.md](docs/PLAN.md).

## Install from scratch (clean Mac, no dev tools)

1. Get this repo onto the Mac. It is private, so either AirDrop/copy the folder, or on the Mac run (with a GitHub token that can read it):
   ```bash
   mkdir -p ~/dental-mac && curl -fsSL -H "Authorization: token GITHUB_TOKEN" -L https://api.github.com/repos/kamil-maciejczek/dental-mac/tarball/main | tar -xz --strip-components=1 -C ~/dental-mac
   ```
2. (Only for CS 3D Imaging) download `CS3DSuite.exe` from the dealer portal (lekarz.diagdent.pl → do pobrania) into `~/Downloads/dental-installers/cs3d/`.
3. Run everything (30–60 min, mostly downloads and the .NET install; asks for your password once for Rosetta):
   ```bash
   ~/dental-mac/scripts/install-all.sh
   ```
4. Start the programs from `~/Applications/Highball/` (drag them to the Dock). First start of each takes about a minute. Blue Sky Plan and DentiqGuide ask you to sign in with your own account.

Steps can be run individually and re-run safely (each skips what is already done): `scripts/00-bootstrap.sh`, `10-blueskyplan.sh`, `20-dentiqguide.sh`, `30-cs3d.sh`, `40-launchers.sh`.

## What the scripts do (short)
- **00**: Highball.app 0.10.10 (pinned DMG), Rosetta 2, the prebuilt HighBall CLI (`bin/highball`, built from the v0.10.10 source), both Wine engines (`engines/*.json` manifests, ~2.5 GB download).
- **10**: Blue Sky Plan silent install into bottle `BlueSkyPlan` (Wine 10 engine, WineD3D), VC++ runtimes, then `glshim/opengl32.dll` next to its exes. The Launcher demands OpenGL 4.3 and macOS stops at 4.1; the shim forwards to the real driver, reports 4.3, clamps context requests, and stubs the missing 4.3 entry points.
- **20**: DentiqGuide silent install into bottle `DentiqGuide` (Wine 11 / CrossOver-26.3-tree engine, DXMT) with every fix that was needed: the Sentinel dongle driver installer killed and its services disabled, Wine's auto-debugger off, .NET Framework 4.8 via winetricks run through an unprotected copy of bash (SIP strips library paths otherwise), the post-install registry step the stalled setup skipped, WPF software rendering, `WINE_DISABLE_NX_COMPAT=0`, and a 6-byte patch of the engine's `ntdll.so` (`NtFlushProcessWriteBuffers` → memory fence) that stops .NET's garbage collector from deadlocking the app under Rosetta.
- **30**: CS 3D Suite silent install into bottle `CS3D` (Wine 11 engine, WineD3D).
- **40**: Mac launcher apps (HighBall play links) in `~/Applications/Highball`.

## Repo layout
`scripts/` install steps · `bin/highball` prebuilt CLI (arm64) · `engines/` pinned engine manifests · `recipes/tweaks/` CC0 HighBall tweak recipes · `glshim/` OpenGL shim source + binary · `deploy/` alternative: clone a working setup as a 12 GB bundle · `docs/` setup log and plan · `ntdll-backup/` original engine library.

## Known limits
- Rosetta 2 is required; Apple keeps it through macOS 27 only. Don't upgrade past 27 until HighBall ships its native engine.
- A HighBall engine update that moves the DentiqGuide bottle to a newer engine drops the ntdll patch; rerun `scripts/20-dentiqguide.sh` (it re-checks the bytes; the offset is for engine r19).
- The programs are medical devices validated on Windows only; this is unsupported by their vendors.
