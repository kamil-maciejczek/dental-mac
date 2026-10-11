#!/usr/bin/env python3
"""Generate x86-64 jmp trampolines + export list for every opengl32 export except the hooked ones."""
hooks={'glGetString','wglGetProcAddress','glGetStringi','glGetIntegerv','wglSetPixelFormat','wglGetPixelFormat','wglCreateContext','wglMakeCurrent','wglSwapBuffers'}
names=[l.strip() for l in open('exports.txt') if l.strip() and l.strip() not in hooks]
open('fwd.S','w').write('.text\n'+''.join(f'.globl {n}\n{n}:\n\tjmp *p_{n}(%rip)\n' for n in names))
with open('fwd_tab.c','w') as f:
    f.write('#include <windows.h>\n'+''.join(f'void* p_{n};\n' for n in names)+'struct fwd { const char* name; void** slot; } fwd_table[] = {\n'+''.join(f'  {{"{n}", &p_{n}}},\n' for n in names)+'  {0,0} };\n')
open('opengl32.def','w').write('LIBRARY opengl32.dll\nEXPORTS\n'+'\n'.join(names+sorted(hooks))+'\n')
print('forwarders:', len(names))
