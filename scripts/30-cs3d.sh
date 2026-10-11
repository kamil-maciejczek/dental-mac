#!/bin/bash
# Step 3: Carestream CS 3D Imaging (CS 3D Suite) in bottle CS3D. The installer is not public:
# download CS3DSuite.exe from the dealer portal (lekarz.diagdent.pl/do-pobrania) into $DL/cs3d/ first.
. "$(dirname "$0")/lib.sh"; need_arm64
EXE="$DL/cs3d/CS3DSuite.exe"; [ -s "$EXE" ] || die "put CS3DSuite.exe into $DL/cs3d/ first (dealer download), then rerun"
B=CS3D; A="$(bottle_dir $B)/drive_c/Program Files/Carestream Dental/3D Visualization Application"
if [ ! -d "$(bottle_dir $B)" ]; then log "bottle $B"; hb bottle create $B --engine "$ENGINE_NET" --renderer wined3d; hb bottle set $B sync none; hb bottle set $B winver win10; hb recipe apply $B vcrun2022 >/dev/null; fi
if [ ! -f "$A/3DImagingSoftware.exe" ]; then log "silent install (~4 min)"; hbq run $B "$EXE" -- /S | tail -1; fi
[ -f "$A/3DImagingSoftware.exe" ] || die "CS 3D Imaging did not install"
hb pin list $B | grep -q "CS 3D Imaging" || hb pin add $B "CS 3D Imaging" "Program Files/Carestream Dental/3D Visualization Application/3DImagingSoftware.exe"
hb pin list $B | grep -q "CS 3D Lite Viewer" || hb pin add $B "CS 3D Lite Viewer" "Program Files/Carestream Dental/3D Visualization Application/ViewData.exe"
stop_bottle $B; log "Step 3 done — CS 3D Imaging installed"
