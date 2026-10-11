#!/bin/bash
# Step 4: Mac launchers in ~/Applications/Highball (same play-link stub Highball's "Make a Mac app" writes) and first Highball start.
. "$(dirname "$0")/lib.sh"; need_arm64
T="$HBHOME/launch-token"; [ -s "$T" ] || perl -e 'print join("", map { sprintf("%02x", int(rand(256))) } 1..16)' > "$T"; TOKEN=$(tr -d '\n' < "$T")
mkdir -p "$LAUNCHERS"
mk(){ # mk <app name> <bottle> <pin name>
  ID=$(perl -MJSON::PP -e '($f,$n)=@ARGV; $d=decode_json(do{local $/;open F,"<",$f or die;<F>}); for(@{$d->{pins}}){ print $_->{id} if $_->{name} eq $n }' "$(bottle_dir "$2")/bottle.json" "$3")
  [ -n "$ID" ] || { echo "   skip $1 (no pin '$3' in $2)"; return; }
  APP="$LAUNCHERS/$1.app"; rm -rf "$APP"; mkdir -p "$APP/Contents/MacOS"
  printf '<?xml version="1.0" encoding="UTF-8"?>\n<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">\n<plist version="1.0"><dict><key>CFBundleExecutable</key><string>launch</string><key>CFBundleIdentifier</key><string>app.highball.pin.%s</string><key>CFBundleName</key><string>%s</string><key>CFBundlePackageType</key><string>APPL</string><key>CFBundleShortVersionString</key><string>1.0</string><key>LSMinimumSystemVersion</key><string>14.0</string></dict></plist>\n' "$(echo "$ID" | tr -d - | tr A-Z a-z | cut -c1-12)" "$1" > "$APP/Contents/Info.plist"
  printf '#!/bin/sh\nexec /usr/bin/open -g "highball://play/pin/%s/%s?t=%s"\n' "$2" "$ID" "$TOKEN" > "$APP/Contents/MacOS/launch"; chmod +x "$APP/Contents/MacOS/launch"; codesign -s - -f "$APP" >/dev/null 2>&1 || true; echo "   $APP"; }
mk "Blue Sky Plan" BlueSkyPlan "Blue Sky Plan Launcher"; mk "DentiqGuide" DentiqGuide "DentiqGuide"; mk "CS 3D Imaging" CS3D "CS 3D Imaging"
if [ -z "${HIGHBALL_HOME:-}" ]; then log "starting Highball once so it registers the launchers' link scheme"; open -a Highball || true; sleep 5; open "$LAUNCHERS"; fi
log "Step 4 done — launchers in $LAUNCHERS"
