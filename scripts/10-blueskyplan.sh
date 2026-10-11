#!/bin/bash
# Step 1: Blue Sky Plan 5.0.29 in bottle BlueSkyPlan (Wine 10 engine, WineD3D) + the OpenGL 4.3 shim for GPU rendering.
. "$(dirname "$0")/lib.sh"; need_arm64
EXE="$DL/blueskyplan/BlueSkyPlan_5.0.29-setup64.exe"
fetch "https://manual.blueskyplan.com/catalogs/BSP/BlueSkyPlan_5.0.29-setup64.exe" "$EXE" 7ed10959a49f933a642e5039b467ef459e6cfc990516ba98e30a199be9b8b26f
B=BlueSkyPlan; P="$(bottle_dir $B)/drive_c/Program Files/BlueSkyPlan"
if [ ! -d "$(bottle_dir $B)" ]; then log "bottle $B"; hb bottle create $B --engine "$ENGINE_BSP" --renderer wined3d; hb bottle set $B sync none; hb bottle set $B winver win10; hb recipe apply $B vcrun2022 >/dev/null; fi
if [ ! -x "$P/Launcher/BlueSkyLauncher.exe" ]; then log "silent install (~2 min)"; hbq run $B "$EXE" -- /VERYSILENT /SUPPRESSMSGBOXES /NORESTART /SP- | tail -2; fi
[ -f "$P/Launcher/BlueSkyLauncher.exe" ] || die "Blue Sky Plan did not install"
log "OpenGL 4.3 shim (hardware rendering)"; stop_bottle $B
for d in Launcher BlueSkyPlan4; do cp "$REPO/glshim/opengl32.dll" "$P/$d/opengl32.dll"; done
hb bottle set $B dlloverrides "opengl32=n,b"; hb bottle set $B env "GLSHIM_VERSION_STRING=4.3 (Core Profile) Mesa 26.2.4 (git-9a0169f2a7)"
hb pin list $B | grep -q "Blue Sky Plan Launcher" || hb pin add $B "Blue Sky Plan Launcher" "Program Files/BlueSkyPlan/Launcher/BlueSkyLauncher.exe"
log "Step 1 done — Blue Sky Plan installed (sign in with your Blue Sky Bio account on first start)"
