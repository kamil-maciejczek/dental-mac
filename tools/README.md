# tools
- `autonext.c` → `bin/autonext.exe`: clicks Next / Install / Finish / I Agree / OK on classic Win32 installer windows whose title contains "Setup"/"Installer". Used by `scripts/30-cs3d.sh` because the CS 3D Imaging inner setup stops on an "Application mode" page even with `/S`. Build: `x86_64-w64-mingw32-gcc -O1 -o autonext.exe autonext.c -luser32` (mingw-w64).
