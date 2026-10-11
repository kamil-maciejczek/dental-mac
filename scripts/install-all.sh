#!/bin/bash
# From-scratch install of Blue Sky Plan, DentiqGuide and CS 3D Imaging on a clean Apple Silicon Mac. Needs only macOS 14+ and internet.
# Usage: scripts/install-all.sh        (CS 3D step needs CS3DSuite.exe in ~/Downloads/dental-installers/cs3d/ — it is skipped otherwise)
cd "$(dirname "$0")"; set -e
./00-bootstrap.sh; ./10-blueskyplan.sh; ./20-dentiqguide.sh
if [ -s "${DENTAL_DOWNLOADS:-$HOME/Downloads/dental-installers}/cs3d/CS3DSuite.exe" ]; then ./30-cs3d.sh; else echo; echo "NOTE: CS 3D skipped — download CS3DSuite.exe from lekarz.diagdent.pl/do-pobrania into ~/Downloads/dental-installers/cs3d/ and run scripts/30-cs3d.sh, then scripts/40-launchers.sh again."; fi
./40-launchers.sh
echo; echo "All done. Launchers: ~/Applications/Highball. Blue Sky Plan and DentiqGuide ask for your own account on first start."
