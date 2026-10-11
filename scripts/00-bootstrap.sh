#!/bin/bash
# Step 0: Highball app (pinned DMG), Rosetta 2, the HighBall CLI, both Wine engines.
. "$(dirname "$0")/lib.sh"; need_arm64
log "Highball.app (pinned v0.10.10)"
if [ ! -d /Applications/Highball.app ]; then
  fetch "https://github.com/gauthierpiarrette/highball/releases/download/v0.10.10/Highball.dmg" "$DL/Highball.dmg"
  MP="$(mktemp -d)"; yes | hdiutil attach -nobrowse -quiet -mountpoint "$MP" "$DL/Highball.dmg" >/dev/null
  APP="$(ls -d "$MP"/*.app | head -1)"; [ -d "$APP" ] || die "no .app inside Highball.dmg"; cp -R "$APP" /Applications/; hdiutil detach "$MP" -quiet || true
  xattr -dr com.apple.quarantine /Applications/Highball.app 2>/dev/null || true
else echo "   already installed: $(/usr/libexec/PlistBuddy -c 'Print CFBundleShortVersionString' /Applications/Highball.app/Contents/Info.plist)"; fi
log "Rosetta 2"; if /usr/bin/pgrep -q oahd; then echo "   already installed"; else /usr/sbin/softwareupdate --install-rosetta --agree-to-license; fi
log "HighBall CLI (prebuilt, from this repo)"; xattr -d com.apple.quarantine "$CLI" 2>/dev/null || true; chmod +x "$CLI"; hb --help >/dev/null && echo "   ok: $CLI"
log "Wine engines (downloads ~2.5 GB once)"
mkdir -p "$HBHOME"
hb engine list | grep -q "^$ENGINE_BSP" || hb engine install "$REPO/engines/$ENGINE_BSP.json"
hb engine list | grep -q "^$ENGINE_NET" || hb engine install "$REPO/engines/$ENGINE_NET.json"
hb engine list
log "Step 0 done"
