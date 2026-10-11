# Shared helpers. Source from the step scripts. Only tools that ship with macOS are used.
set -eu
REPO="$(cd "$(dirname "$0")/.." && pwd)"
HBHOME="${HIGHBALL_HOME:-$HOME/Library/Application Support/Highball}"
CLI="${HIGHBALL_CLI:-$REPO/bin/highball}"
DL="${DENTAL_DOWNLOADS:-$HOME/Downloads/dental-installers}"
LAUNCHERS="${LAUNCHER_DIR:-$HOME/Applications/Highball}"
ENGINE_BSP="x64-sikarugir10.0_6-r21"; ENGINE_NET="x64-crossover26.3-r19"
log(){ printf '\n==> %s\n' "$*"; }
die(){ printf 'ERROR: %s\n' "$*" >&2; exit 1; }
hb(){ (cd "$REPO" && HIGHBALL_HOME="$HBHOME" "$CLI" "$@"); }           # run from repo root so recipes/** resolves
hbq(){ hb "$@" 2>&1 | grep -vE 'fixme|HID device|mvk-info|^\s*$|GPU Family|Texture Tier|^\s*VK_|Vulkan extensions|supports the following|Read-Write|Metal|GPU memory|model:|type:|vendorID|deviceID|pipelineCache' || true; }
need_arm64(){ [ "$(uname -m)" = arm64 ] || die "Apple Silicon Mac required"; }
fetch(){ # fetch <url> <dest-file> [sha256]
  mkdir -p "$(dirname "$2")"; if [ ! -s "$2" ]; then log "downloading $(basename "$2")"; curl -fL --retry 3 -C - -o "$2" "$1"; fi
  if [ -n "${3:-}" ]; then printf '%s  %s\n' "$3" "$2" | shasum -a 256 -c - >/dev/null || die "checksum mismatch for $2"; fi; }
stop_bottle(){ hb bottle kill "$1" >/dev/null 2>&1 || true; sleep 2; }
bottle_dir(){ printf '%s/bottles/%s' "$HBHOME" "$1"; }
reg_edit(){ # reg_edit <bottle> <perl -0pe expression>   (bottle must be stopped)
  perl -0pi -e "$2" "$(bottle_dir "$1")/system.reg"; }
