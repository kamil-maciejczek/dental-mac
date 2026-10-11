#!/bin/bash
# Step 2: DentiqGuide 1.4 in bottle DentiqGuide (Wine 11/CrossOver-tree engine, DXMT) + all the Wine fixes found in the setup log.
. "$(dirname "$0")/lib.sh"; need_arm64
ZIP="$DL/dentiqguide/Setup_DentiqGuide_Newest.zip"; LIB="$DL/dentiqguide/Setup_ImplantLibrary_Newest.zip"
fetch "https://s3.ap-northeast-2.amazonaws.com/service.dentiqcloud.com/SetupFiles/NewestN/Setup_DentiqGuide_Newest.zip" "$ZIP"
fetch "https://s3.ap-northeast-2.amazonaws.com/service.dentiqcloud.com/SetupFiles/NewestN/Setup_ImplantLibrary_Newest.zip" "$LIB"
mkdir -p "$DL/dentiqguide/setup" "$DL/dentiqguide/library"; unzip -oq "$ZIP" -d "$DL/dentiqguide/setup"; unzip -oq "$LIB" -d "$DL/dentiqguide/library"
SETUP=$(ls "$DL/dentiqguide/setup"/*.exe | head -1); LIBSETUP=$(ls "$DL/dentiqguide/library"/*.exe | head -1)
B=DentiqGuide; C="$(bottle_dir $B)/drive_c"; E="$HBHOME/engines/$ENGINE_NET"

log "engine fix: NtFlushProcessWriteBuffers -> memory fence (deadlocks .NET's GC under Rosetta otherwise)"
N="$E/engine/lib/wine/x86_64-unix/ntdll.so"; OFF=$((0x6ab20)); cp -n "$N" "$N.orig" 2>/dev/null || true
case "$(xxd -s $OFF -l 4 -p "$N")" in
  554889e5) printf '\x0f\xae\xf0\x31\xc0\xc3' | dd of="$N" bs=1 seek=$OFF conv=notrunc status=none; codesign -s - -f "$N" 2>/dev/null; echo "   patched";;
  0faef031) echo "   already patched";;
  *) die "unexpected bytes in ntdll.so at 0x6ab20 (engine revision changed?)";;
esac

if [ ! -d "$(bottle_dir $B)" ]; then log "bottle $B"; hb bottle create $B --engine "$ENGINE_NET" --renderer dxmt; hb bottle set $B sync none; hb bottle set $B winver win10; hb recipe apply $B vcrun2022 >/dev/null; fi
stop_bottle $B; reg_edit $B 's/"Debugger"="winedbg --auto %ld %ld"/"Debugger"="false"/g'   # crashes must not spawn hung debuggers

if [ ! -f "$C/Program Files/DentiqGuideN/PlatformGuideN.exe" ]; then
  log "silent install (~7 min; the Sentinel dongle driver step is killed automatically)"
  ( hbq run $B "$SETUP" -- /S > "$DL/dentiqguide/install.log" 2>&1; echo "RUN EXIT $?" >> "$DL/dentiqguide/install.log" ) &
  for i in $(seq 1 240); do grep -q "RUN EXIT" "$DL/dentiqguide/install.log" && break; pkill -f "haspdinst.exe" 2>/dev/null && echo "   killed haspdinst.exe (dongle driver, not needed)"; sleep 5; done
  grep -q "RUN EXIT" "$DL/dentiqguide/install.log" || die "DentiqGuide installer did not finish"
fi
[ -f "$C/Program Files/DentiqGuideN/PlatformGuideN.exe" ] || die "DentiqGuide did not install"

log "disable Sentinel driver services (they crash-loop under Wine)"; stop_bottle $B
for f in aksfridge hardlock; do [ -f "$C/windows/system32/drivers/$f.sys" ] && mv "$C/windows/system32/drivers/$f.sys" "$C/windows/system32/drivers/$f.sys.disabled"; done
reg_edit $B 's/(\[System\\\\ControlSet001\\\\Services\\\\(aksfridge|hardlock)\][^\[]*?"Start"=dword:)0000000[0-9]/${1}00000004/sg'

log "implant library"; [ -d "$C/ProgramData/DentiqGuideN/Implant" ] && [ "$(find "$C/ProgramData/DentiqGuideN/Implant" -type f | wc -l)" -gt 100 ] || hbq run $B "$LIBSETUP" -- /S | tail -1

log ".NET Framework 4.8 via winetricks (10-30 min)"
if [ ! -f "$C/windows/Microsoft.NET/Framework64/v4.0.30319/clr.dll" ]; then
  stop_bottle $B; TB="$(mktemp -d)"; hb env $B > "$TB/env.sh"
  # /bin/bash is SIP-restricted: macOS strips DYLD_* from its environment, and this engine's Wine needs them to find its
  # frameworks. So WINE/WINESERVER are tiny wrappers that re-export the environment right before exec'ing the real binaries,
  # and WINE_BIN/WINESERVER_BIN/WINE_BINDIR tell winetricks where the real binaries are (its documented wrapper support).
  for t in wine wineserver; do { echo '#!/bin/sh'; cat "$TB/env.sh"; echo "exec \"$E/engine/bin/$t\" \"\$@\""; } > "$TB/$t"; chmod +x "$TB/$t"; done
  # winetricks asks lipo (an Xcode tool a clean Mac lacks) for the binary architecture; the engine is x86_64 by construction.
  printf '#!/bin/sh\necho x86_64\n' > "$TB/lipo"; chmod +x "$TB/lipo"
  ( set -a; . "$TB/env.sh"; set +a
    export PATH="$TB:$PATH" WINE="$TB/wine" WINESERVER="$TB/wineserver" WINE_BIN="$E/engine/bin/wine" WINESERVER_BIN="$E/engine/bin/wineserver" WINE_BINDIR="$E/engine/bin" WINETRICKS_LATEST_VERSION_CHECK=disabled
    /bin/bash "$E/tools/winetricks" --unattended dotnet48 > "$DL/dentiqguide/dotnet48.log" 2>&1 ) || true
  "$TB/wineserver" -w 2>/dev/null || true; hb bottle set $B winver win10
  [ -f "$C/windows/Microsoft.NET/Framework64/v4.0.30319/clr.dll" ] || die ".NET 4.8 install failed, see $DL/dentiqguide/dotnet48.log"
fi

mkdir -p "$C/users/Public/Documents/DentiqGuideN"   # the helper crashes (.NET exception) if its log folder does not exist yet
log "post-install registration the stalled setup never did + WPF software rendering"
hbq run $B "C:\\windows\\system32\\reg.exe" -- add "HKLM\\Software\\Microsoft\\Windows\\CurrentVersion\\App Paths\\DentiqGuideN.exe" /ve /d "C:\\Program Files\\DentiqGuideN\\PlatformGuideN.exe" /f >/dev/null
hbq run $B "C:\\windows\\system32\\reg.exe" -- add "HKLM\\Software\\Microsoft\\Windows\\CurrentVersion\\App Paths\\DentiqGuideN.exe" /v Path /d "C:\\Program Files\\DentiqGuideN" /f >/dev/null
hbq run $B "C:\\Program Files\\DentiqGuideN\\VxAdminExec.exe" -- WRITE_REG_AND_CHANGE_AUTHORITY "C:\\Program Files\\DentiqGuideN" "C:\\Program Files\\DentiqGuideN\\Database" "$USER" >/dev/null
hbq run $B "C:\\windows\\system32\\reg.exe" -- add "HKCU\\Software\\Microsoft\\Avalon.Graphics" /v DisableHWAcceleration /t REG_DWORD /d 1 /f >/dev/null
hb bottle set $B env "WINE_DISABLE_NX_COMPAT=0"      # engine's forced DEP killed worker threads
hb pin list $B | grep -q "^DentiqGuide" || hb pin add $B "DentiqGuide" "Program Files/DentiqGuideN/PlatformGuideN.exe"
stop_bottle $B
log "Step 2 done — DentiqGuide installed (sign in with your DentiqSolution account on first start; AI automation stays unavailable on macOS)"
