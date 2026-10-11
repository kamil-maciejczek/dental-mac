#!/bin/sh
# Build the OpenGL 4.3 compatibility shim for Blue Sky Plan under Wine/macOS.
# Needs: brew install mingw-w64. exports.txt = export names of Wine's builtin opengl32.dll
#   (x86_64-w64-mingw32-objdump -p <engine>/lib/wine/x86_64-windows/opengl32.dll | grep '+base\[' | awk '{print $NF}' | grep -E '^(gl|wgl)' | sort -u)
set -e; cd "$(dirname "$0")"
python3 gen_forwarders.py
x86_64-w64-mingw32-gcc -shared -O1 -o opengl32.dll shim.c fwd.S fwd_tab.c opengl32.def -lgdi32 -luser32
ls -la opengl32.dll
