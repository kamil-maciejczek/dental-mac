#!/bin/sh
# Build the "DentalApps-for-Mac" package from this Mac's working HighBall setup.
# Usage: ./pack.sh [destination-folder]   (default: ~/Desktop/DentalApps-for-Mac; ~11 GB; an external SSD is fine)
set -e
DEST="${1:-$HOME/Desktop/DentalApps-for-Mac}"; HB="$HOME/Library/Application Support/Highball"; HERE="$(cd "$(dirname "$0")" && pwd)"
mkdir -p "$DEST/highball-data/bottles" "$DEST/highball-data/engines" "$DEST/launchers"
echo "[1/5] Highball.dmg"; [ -s "$DEST/Highball.dmg" ] || curl -fL -o "$DEST/Highball.dmg" "https://github.com/gauthierpiarrette/highball/releases/latest/download/Highball.dmg"
echo "[2/5] engines (with the patched ntdll.so)"; rsync -a --delete "$HB/engines/x64-sikarugir10.0_6-r21" "$HB/engines/x64-crossover26.3-r19" "$DEST/highball-data/engines/"
echo "[3/5] bottles (BlueSkyPlan, DentiqGuide, CS3D)"; rsync -a --delete --exclude 'drive_c/users/km/AppData/Local/Temp' --exclude 'drive_c/highball/logs' --exclude 'drive_c/windows/Temp' "$HB/bottles/BlueSkyPlan" "$HB/bottles/DentiqGuide" "$HB/bottles/CS3D" "$DEST/highball-data/bottles/"
cp "$HB/launch-token" "$HB/mac-flags.json" "$DEST/highball-data/" 2>/dev/null || true
echo "[4/5] launchers"; rsync -a --delete "$HOME/Applications/Highball/" "$DEST/launchers/"; for a in "$DEST"/launchers/*.app; do codesign -s - -f "$a" >/dev/null 2>&1 || true; done
echo "[5/5] installer + docs"; cp "$HERE/INSTALL.command" "$HERE/README-for-Kasia.md" "$DEST/"; chmod +x "$DEST/INSTALL.command"
du -sh "$DEST"; echo "Done. Copy the whole '$DEST' folder to the other Mac (USB-C SSD, AirDrop, or a shared drive) and double-click INSTALL.command there."
