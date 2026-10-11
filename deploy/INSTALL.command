#!/bin/sh
# DentalApps-for-Mac installer. Double-click on the target Mac (Apple Silicon, macOS 14 or newer).
set -e; cd "$(dirname "$0")"
echo "== Dental apps installer (Blue Sky Plan, DentiqGuide, CS 3D Imaging via HighBall) =="
if [ "$(uname -m)" != "arm64" ]; then echo "This package is for Apple Silicon Macs only."; exit 1; fi
HB="$HOME/Library/Application Support/Highball"
echo "[1/5] Installing the Highball app..."
if [ ! -d /Applications/Highball.app ]; then if [ -d /Volumes/Highball/Highball.app ]; then MP=/Volumes/Highball; else MP="$(mktemp -d)"; yes | hdiutil attach -nobrowse -quiet -mountpoint "$MP" Highball.dmg || { echo "could not mount Highball.dmg"; exit 1; }; fi; cp -R "$MP"/*.app /Applications/; hdiutil detach "$MP" -quiet 2>/dev/null || true; else echo "   already installed"; fi
echo "[2/5] Installing Rosetta 2 (needed to run Windows programs; may ask for your password)..."
if ! /usr/bin/pgrep -q oahd; then softwareupdate --install-rosetta --agree-to-license || echo "   (Rosetta will be offered by Highball on first start)"; else echo "   already installed"; fi
echo "[3/5] Copying the prepared Windows environments (~11 GB, a few minutes)..."
mkdir -p "$HB/bottles" "$HB/engines" "$HB/logs" "$HB/manifests" "$HB/downloads"
rsync -a highball-data/engines/ "$HB/engines/"; rsync -a highball-data/bottles/ "$HB/bottles/"; cp -n highball-data/launch-token "$HB/" 2>/dev/null || true; cp -n highball-data/mac-flags.json "$HB/" 2>/dev/null || true
echo "[4/5] Installing the launchers into ~/Applications/Highball..."
mkdir -p "$HOME/Applications/Highball"; rsync -a launchers/ "$HOME/Applications/Highball/"; xattr -dr com.apple.quarantine "$HOME/Applications/Highball" /Applications/Highball.app 2>/dev/null || true
echo "[5/5] Opening Highball once so it registers itself (close it afterwards if you like)..."
open -a Highball; sleep 5; open "$HOME/Applications/Highball"
echo; echo "Done. Start the programs from the Finder window that just opened (Blue Sky Plan / DentiqGuide / CS 3D Imaging)."
echo "First start of each program takes about a minute. Blue Sky Plan and DentiqGuide will ask you to sign in with your own account."
