# glshim — OpenGL 4.3 compatibility shim for Blue Sky Plan on Wine/macOS

Blue Sky Plan 5's Launcher refuses to start unless OpenGL reports 4.3+, but Apple's driver (through Wine's Mac driver) tops out at 4.1 core. Mesa llvmpipe satisfies the check but renders in software (slideshow). This `opengl32.dll` sits in the app folder, forwards every call to Wine's real `system32\opengl32.dll` via jmp trampolines, and fixes the gaps:

- reports a 4.3 version string (`GLSHIM_VERSION_STRING`, default Mesa-shaped text the Launcher's parser accepts) and `GL_MAJOR/MINOR_VERSION` 4.3;
- clamps `wglCreateContextAttribsARB` requests above 4.1 (`GLSHIM_CLAMP_VERSION`) to 4.1 core;
- redirects DCs of windows Wine cannot attach a pixel format to (the Launcher's probe window lives in another process) to a hidden helper window for `wglSetPixelFormat`/`wglCreateContext*`/`wglMakeCurrent`/`wglSwapBuffers`;
- hands out no-op/emulated stubs for GL 4.2–4.5 and debug entry points the driver lacks (`glDebugMessageCallback`, `glBufferStorage`→`glBufferData`, base-instance draws, multisample storage, …) instead of NULL, which the Launcher called blindly and crashed on.

Deploy: copy `opengl32.dll` into `Program Files/BlueSkyPlan/Launcher/` and `.../BlueSkyPlan4/`, bottle `dlloverrides = opengl32=n,b`. Optional env `GLSHIM_LOG=C:\path\glshim.log` for a trace. Build: `./build.sh` (mingw-w64).
Known limits: anything that truly needs compute shaders / SSBOs / buffer storage semantics will silently misrender; verified only up to the Launcher init so far.
