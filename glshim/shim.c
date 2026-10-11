#include <windows.h>
#include <stdio.h>
#include <string.h>
#include <stdarg.h>
#define GL_VERSION 0x1F02
#define GL_SHADING_LANGUAGE_VERSION 0x8B8C
#define GL_MAJOR_VERSION 0x821B
#define GL_MINOR_VERSION 0x821C
#define WGL_CONTEXT_MAJOR_VERSION_ARB 0x2091
#define WGL_CONTEXT_MINOR_VERSION_ARB 0x2092
#define WGL_CONTEXT_FLAGS_ARB 0x2094
#define WGL_CONTEXT_PROFILE_MASK_ARB 0x9126
typedef const unsigned char* (WINAPI *PFN_glGetString)(unsigned int);
typedef const unsigned char* (WINAPI *PFN_glGetStringi)(unsigned int, unsigned int);
typedef void (WINAPI *PFN_glGetIntegerv)(unsigned int, int*);
typedef PROC (WINAPI *PFN_wglGetProcAddress)(LPCSTR);
typedef BOOL (WINAPI *PFN_wglSetPixelFormat)(HDC,int,const PIXELFORMATDESCRIPTOR*); typedef int (WINAPI *PFN_wglGetPixelFormat)(HDC); static PFN_wglSetPixelFormat p_wglSetPixelFormat; static PFN_wglGetPixelFormat p_wglGetPixelFormat; typedef HGLRC (WINAPI *PFN_wglCreateContext)(HDC); static PFN_wglCreateContext p_wglCreateContext;
typedef BOOL (WINAPI *PFN_wglMakeCurrent)(HDC,HGLRC); typedef BOOL (WINAPI *PFN_wglSwapBuffers)(HDC); static PFN_wglMakeCurrent p_wglMakeCurrent; static PFN_wglSwapBuffers p_wglSwapBuffers;
static struct { HDC dc; HDC helper; HWND hwnd; int fmt; } redir[32]; static int redir_n; static HDC mapdc(HDC dc){ for(int i=0;i<redir_n;i++) if(redir[i].dc==dc) return redir[i].helper; return dc; } static int mapfmt(HDC dc){ for(int i=0;i<redir_n;i++) if(redir[i].dc==dc) return redir[i].fmt; return 0; }
static struct { HDC dc; int fmt; } fmt_tab[64]; static int fmt_n; static void remember(HDC dc,int fmt){ for(int i=0;i<fmt_n;i++) if(fmt_tab[i].dc==dc){ fmt_tab[i].fmt=fmt; return; } if(fmt_n<64){ fmt_tab[fmt_n].dc=dc; fmt_tab[fmt_n].fmt=fmt; fmt_n++; } } static int recall(HDC dc){ for(int i=0;i<fmt_n;i++) if(fmt_tab[i].dc==dc) return fmt_tab[i].fmt; return 0; }
typedef HGLRC (WINAPI *PFN_wglCreateContextAttribsARB)(HDC, HGLRC, const int*);
struct fwd { const char* name; void** slot; }; extern struct fwd fwd_table[];
static HMODULE real; static PFN_glGetString p_glGetString; static PFN_glGetStringi p_glGetStringi; static PFN_glGetIntegerv p_glGetIntegerv; static PFN_wglGetProcAddress p_wglGetProcAddress; static PFN_wglCreateContextAttribsARB p_realCreateAttribs;
static int fake_major=4, fake_minor=3, clamp_major=4, clamp_minor=1; static FILE* logf; static const char* fake_string;
static void lg(const char* fmt, ...){ if(!logf) return; va_list a; va_start(a,fmt); vfprintf(logf,fmt,a); va_end(a); fputc('\n',logf); fflush(logf); }
static void init(void){ if(real) return; char path[MAX_PATH]; GetSystemDirectoryA(path,MAX_PATH); strcat(path,"\\opengl32.dll"); real=LoadLibraryA(path); for(struct fwd* e=fwd_table; e->name; e++) *e->slot=(void*)GetProcAddress(real,e->name);
  p_glGetString=(PFN_glGetString)GetProcAddress(real,"glGetString"); p_glGetIntegerv=(PFN_glGetIntegerv)GetProcAddress(real,"glGetIntegerv"); p_wglGetProcAddress=(PFN_wglGetProcAddress)GetProcAddress(real,"wglGetProcAddress"); p_wglSetPixelFormat=(PFN_wglSetPixelFormat)GetProcAddress(real,"wglSetPixelFormat"); p_wglGetPixelFormat=(PFN_wglGetPixelFormat)GetProcAddress(real,"wglGetPixelFormat"); p_wglCreateContext=(PFN_wglCreateContext)GetProcAddress(real,"wglCreateContext"); p_wglMakeCurrent=(PFN_wglMakeCurrent)GetProcAddress(real,"wglMakeCurrent"); p_wglSwapBuffers=(PFN_wglSwapBuffers)GetProcAddress(real,"wglSwapBuffers");
  const char* e=getenv("GLSHIM_FAKE_VERSION"); if(e) sscanf(e,"%d.%d",&fake_major,&fake_minor); e=getenv("GLSHIM_CLAMP_VERSION"); if(e) sscanf(e,"%d.%d",&clamp_major,&clamp_minor); e=getenv("GLSHIM_LOG"); if(e) logf=fopen(e,"a"); fake_string=getenv("GLSHIM_VERSION_STRING"); lg("init real=%p fake=%d.%d clamp=%d.%d", real, fake_major,fake_minor,clamp_major,clamp_minor); }
static char verbuf[128], glslbuf[64];
__declspec(dllexport) const unsigned char* WINAPI glGetString(unsigned int name){ init(); const unsigned char* s=p_glGetString?p_glGetString(name):0; if(!s) return s;
  if(name==GL_VERSION){ int maj=0,min=0; sscanf((const char*)s,"%d.%d",&maj,&min); if(maj*10+min<fake_major*10+fake_minor){ if(fake_string) snprintf(verbuf,sizeof verbuf,"%s",fake_string); else { const char* rest=strchr((const char*)s,' '); snprintf(verbuf,sizeof verbuf,"%d.%d.0%s",fake_major,fake_minor,rest?rest:""); } lg("glGetString(VERSION) '%s' -> '%s'", s, verbuf); return (const unsigned char*)verbuf; } }
  if(name==GL_SHADING_LANGUAGE_VERSION){ int maj=0,min=0; sscanf((const char*)s,"%d.%d",&maj,&min); if(maj*100+min<fake_major*100+fake_minor*10){ snprintf(glslbuf,sizeof glslbuf,"%d.%d0",fake_major,fake_minor); lg("glGetString(GLSL) '%s' -> '%s'", s, glslbuf); return (const unsigned char*)glslbuf; } }
  return s; }
__declspec(dllexport) const unsigned char* WINAPI glGetStringi(unsigned int name, unsigned int idx){ init(); return p_glGetStringi?p_glGetStringi(name,idx):0; }
__declspec(dllexport) void WINAPI glGetIntegerv(unsigned int pname, int* v){ init(); if(p_glGetIntegerv) p_glGetIntegerv(pname,v); if(!v) return;
  if(pname==GL_MAJOR_VERSION || pname==GL_MINOR_VERSION){ int maj=0,min=0; const unsigned char* s=p_glGetString?p_glGetString(GL_VERSION):0; if(s) sscanf((const char*)s,"%d.%d",&maj,&min); if(maj*10+min<fake_major*10+fake_minor){ int old=*v; *v = (pname==GL_MAJOR_VERSION)?fake_major:fake_minor; lg("glGetIntegerv(%s) %d -> %d", pname==GL_MAJOR_VERSION?"MAJOR":"MINOR", old, *v); } } }
static HGLRC WINAPI my_wglCreateContextAttribsARB(HDC dc, HGLRC share, const int* attribs){ dc=mapdc(dc); int buf[64]; int n=0; if(attribs){ for(; attribs[n] && n<60; n+=2){ buf[n]=attribs[n]; buf[n+1]=attribs[n+1]; } } buf[n]=0;
  int maj=-1,min=-1,prof=-1,flags=0; for(int i=0;i<n;i+=2){ if(buf[i]==WGL_CONTEXT_MAJOR_VERSION_ARB) maj=buf[i+1]; if(buf[i]==WGL_CONTEXT_MINOR_VERSION_ARB) min=buf[i+1]; if(buf[i]==WGL_CONTEXT_PROFILE_MASK_ARB) prof=buf[i+1]; if(buf[i]==WGL_CONTEXT_FLAGS_ARB) flags=buf[i+1]; }
  lg("CreateContextAttribs req %d.%d profile=%d flags=%d", maj,min,prof,flags);
  if(maj>=0 && (maj*10+min > clamp_major*10+clamp_minor)){ for(int i=0;i<n;i+=2){ if(buf[i]==WGL_CONTEXT_MAJOR_VERSION_ARB) buf[i+1]=clamp_major; if(buf[i]==WGL_CONTEXT_MINOR_VERSION_ARB) buf[i+1]=clamp_minor; } }
  HGLRC rc=p_realCreateAttribs(dc,share,buf); lg("  -> %p (err %lu)", rc, rc?0:GetLastError());
  if(!rc && maj>=0){ int b2[]={WGL_CONTEXT_MAJOR_VERSION_ARB,clamp_major,WGL_CONTEXT_MINOR_VERSION_ARB,clamp_minor,WGL_CONTEXT_PROFILE_MASK_ARB,1,0}; rc=p_realCreateAttribs(dc,share,b2); lg("  retry core %d.%d -> %p (err %lu)", clamp_major,clamp_minor, rc, rc?0:GetLastError()); }
  if(!rc){ rc=p_realCreateAttribs(dc,share,0); lg("  retry legacy -> %p", rc); } return rc; }

/* ---- emulation / no-op stubs for entry points the Mac driver lacks ---- */
typedef void (WINAPI *PFN_glBufferData)(unsigned, ptrdiff_t, const void*, unsigned);
typedef void (WINAPI *PFN_glDrawArraysInstanced)(unsigned,int,int,int);
typedef void (WINAPI *PFN_glDrawElementsInstancedBaseVertex)(unsigned,int,unsigned,const void*,int,int);
typedef void (WINAPI *PFN_glTexImage2DMultisample)(unsigned,int,unsigned,int,int,unsigned char);
typedef void (WINAPI *PFN_glTexImage3DMultisample)(unsigned,int,unsigned,int,int,int,unsigned char);
typedef void (WINAPI *PFN_glPolygonOffset)(float,float);
typedef void (WINAPI *PFN_glTexBuffer)(unsigned,unsigned,unsigned);
static PFN_glBufferData e_glBufferData; static PFN_glDrawArraysInstanced e_glDrawArraysInstanced; static PFN_glDrawElementsInstancedBaseVertex e_glDrawElementsInstancedBaseVertex; static PFN_glTexImage2DMultisample e_glTexImage2DMultisample; static PFN_glTexImage3DMultisample e_glTexImage3DMultisample; static PFN_glPolygonOffset e_glPolygonOffset; static PFN_glTexBuffer e_glTexBuffer;
static void WINAPI s_noop(void){ }
static int WINAPI s_zero(void){ return 0; }
static void WINAPI s_glBufferStorage(unsigned target, ptrdiff_t size, const void* data, unsigned flags){ if(!e_glBufferData) e_glBufferData=(PFN_glBufferData)p_wglGetProcAddress("glBufferData"); if(e_glBufferData) e_glBufferData(target,size,data,0x88E8 /*GL_DYNAMIC_DRAW*/); }
static void WINAPI s_glDrawArraysInstancedBaseInstance(unsigned mode,int first,int count,int prim,unsigned base){ if(!e_glDrawArraysInstanced) e_glDrawArraysInstanced=(PFN_glDrawArraysInstanced)p_wglGetProcAddress("glDrawArraysInstanced"); if(e_glDrawArraysInstanced) e_glDrawArraysInstanced(mode,first,count,prim); }
static void WINAPI s_glDrawElementsInstancedBaseVertexBaseInstance(unsigned mode,int count,unsigned type,const void* idx,int prim,int basev,unsigned basei){ if(!e_glDrawElementsInstancedBaseVertex) e_glDrawElementsInstancedBaseVertex=(PFN_glDrawElementsInstancedBaseVertex)p_wglGetProcAddress("glDrawElementsInstancedBaseVertex"); if(e_glDrawElementsInstancedBaseVertex) e_glDrawElementsInstancedBaseVertex(mode,count,type,idx,prim,basev); }
static void WINAPI s_glTexStorage2DMultisample(unsigned target,int samples,unsigned fmt,int w,int h,unsigned char fixed){ if(!e_glTexImage2DMultisample) e_glTexImage2DMultisample=(PFN_glTexImage2DMultisample)p_wglGetProcAddress("glTexImage2DMultisample"); if(e_glTexImage2DMultisample) e_glTexImage2DMultisample(target,samples,fmt,w,h,fixed); }
static void WINAPI s_glTexStorage3DMultisample(unsigned target,int samples,unsigned fmt,int w,int h,int d,unsigned char fixed){ if(!e_glTexImage3DMultisample) e_glTexImage3DMultisample=(PFN_glTexImage3DMultisample)p_wglGetProcAddress("glTexImage3DMultisample"); if(e_glTexImage3DMultisample) e_glTexImage3DMultisample(target,samples,fmt,w,h,d,fixed); }
static void WINAPI s_glPolygonOffsetClamp(float f,float u,float c){ if(!e_glPolygonOffset) e_glPolygonOffset=(PFN_glPolygonOffset)GetProcAddress(real,"glPolygonOffset"); if(e_glPolygonOffset) e_glPolygonOffset(f,u); }
static void WINAPI s_glTexBufferRange(unsigned target,unsigned fmt,unsigned buf,ptrdiff_t off,ptrdiff_t size){ if(!e_glTexBuffer) e_glTexBuffer=(PFN_glTexBuffer)p_wglGetProcAddress("glTexBuffer"); if(e_glTexBuffer) e_glTexBuffer(target,fmt,buf); }
static void WINAPI s_glGetInternalformati64v(unsigned t,unsigned f,unsigned p,int n,long long* out){ if(out && n>0) out[0]=0; }
static void WINAPI s_glGetInternalformativ(unsigned t,unsigned f,unsigned p,int n,int* out){ if(out && n>0) out[0]=0; }
static struct { const char* name; void* fn; } stubs[] = {
  {"glBufferStorage",(void*)s_glBufferStorage},{"glDrawArraysInstancedBaseInstance",(void*)s_glDrawArraysInstancedBaseInstance},{"glDrawElementsInstancedBaseVertexBaseInstance",(void*)s_glDrawElementsInstancedBaseVertexBaseInstance},
  {"glTexStorage2DMultisample",(void*)s_glTexStorage2DMultisample},{"glTexStorage3DMultisample",(void*)s_glTexStorage3DMultisample},{"glPolygonOffsetClamp",(void*)s_glPolygonOffsetClamp},{"glPolygonOffsetClampEXT",(void*)s_glPolygonOffsetClamp},{"glTexBufferRange",(void*)s_glTexBufferRange},
  {"glGetInternalformati64v",(void*)s_glGetInternalformati64v},{"glGetInternalformativ",(void*)s_glGetInternalformativ},
  {"glDebugMessageCallback",(void*)s_noop},{"glDebugMessageCallbackARB",(void*)s_noop},{"glDebugMessageControl",(void*)s_noop},{"glDebugMessageControlARB",(void*)s_noop},{"glDebugMessageInsert",(void*)s_noop},{"glDebugMessageInsertARB",(void*)s_noop},{"glGetDebugMessageLog",(void*)s_zero},{"glGetDebugMessageLogARB",(void*)s_zero},{"glObjectLabel",(void*)s_noop},{"glObjectPtrLabel",(void*)s_noop},{"glGetObjectLabel",(void*)s_noop},{"glPushDebugGroup",(void*)s_noop},{"glPopDebugGroup",(void*)s_noop},
  {"glDispatchCompute",(void*)s_noop},{"glDispatchComputeIndirect",(void*)s_noop},{"glMemoryBarrier",(void*)s_noop},{"glMemoryBarrierByRegion",(void*)s_noop},{"glBindImageTexture",(void*)s_noop},{"glShaderStorageBlockBinding",(void*)s_noop},{"glFramebufferParameteri",(void*)s_noop},{"glGetFramebufferParameteriv",(void*)s_noop},
  {"glClearBufferData",(void*)s_noop},{"glClearBufferSubData",(void*)s_noop},{"glClearTexImage",(void*)s_noop},{"glClearTexSubImage",(void*)s_noop},{"glCopyImageSubData",(void*)s_noop},{"glClipControl",(void*)s_noop},{"glTextureBarrier",(void*)s_noop},{"glTextureView",(void*)s_noop},
  {"glInvalidateBufferData",(void*)s_noop},{"glInvalidateBufferSubData",(void*)s_noop},{"glInvalidateFramebuffer",(void*)s_noop},{"glInvalidateSubFramebuffer",(void*)s_noop},{"glInvalidateTexImage",(void*)s_noop},{"glInvalidateTexSubImage",(void*)s_noop},
  {"glGetActiveAtomicCounterBufferiv",(void*)s_noop},{"glGetTextureLevelParameteriv",(void*)s_noop},{"glGetTextureParameteriv",(void*)s_noop},{"glBindVertexBuffer",(void*)s_noop},{"glVertexAttribFormat",(void*)s_noop},{"glVertexAttribIFormat",(void*)s_noop},{"glVertexAttribBinding",(void*)s_noop},{"glVertexBindingDivisor",(void*)s_noop},
  {0,0} };
static void* find_stub(const char* name){ for(int i=0; stubs[i].name; i++) if(!strcmp(stubs[i].name,name)) return stubs[i].fn; return 0; }
__declspec(dllexport) PROC WINAPI wglGetProcAddress(LPCSTR name){ init(); PROC p=p_wglGetProcAddress?p_wglGetProcAddress(name):0;
  if(p && !strcmp(name,"wglCreateContextAttribsARB")){ p_realCreateAttribs=(PFN_wglCreateContextAttribsARB)p; return (PROC)my_wglCreateContextAttribsARB; }
  if(p && !strcmp(name,"glGetStringi")){ p_glGetStringi=(PFN_glGetStringi)p; return (PROC)glGetStringi; }
  if(!p){ void* st=find_stub(name); if(st){ lg("wglGetProcAddress(%s) = stub", name); return (PROC)st; } lg("wglGetProcAddress(%s) = NULL", name); }
  return p; }
__declspec(dllexport) BOOL WINAPI wglSetPixelFormat(HDC dc, int fmt, const PIXELFORMATDESCRIPTOR* pfd){ init(); BOOL r=p_wglSetPixelFormat?p_wglSetPixelFormat(dc,fmt,pfd):FALSE; lg("wglSetPixelFormat(dc %p, fmt %d) -> %d", dc, fmt, r); if(r){ remember(dc,fmt); return r; }
  if(fmt<=0 || fmt>=256) return r;
  /* foreign-process or already-formatted window: redirect this DC to a hidden helper window of our own */
  static int cls=0; if(!cls){ WNDCLASSA wc={0}; wc.lpfnWndProc=DefWindowProcA; wc.hInstance=GetModuleHandleA(0); wc.lpszClassName="glshim_helper"; RegisterClassA(&wc); cls=1; }
  HWND hw=CreateWindowA("glshim_helper","glshim",WS_OVERLAPPEDWINDOW,0,0,64,64,0,0,GetModuleHandleA(0),0); if(!hw){ lg("  helper window creation failed"); return r; }
  HDC hd=GetDC(hw); PIXELFORMATDESCRIPTOR p2; if(!pfd){ DescribePixelFormat(hd,fmt,sizeof p2,&p2); pfd=&p2; }
  BOOL r2=p_wglSetPixelFormat(hd,fmt,pfd); lg("  redirect: helper hwnd %p dc %p set fmt %d -> %d", hw, hd, fmt, r2); if(!r2){ ReleaseDC(hw,hd); DestroyWindow(hw); return r; }
  int i; for(i=0;i<redir_n;i++) if(redir[i].dc==dc) break; if(i==redir_n && redir_n<32) redir_n++; redir[i].dc=dc; redir[i].helper=hd; redir[i].hwnd=hw; redir[i].fmt=fmt; SetLastError(0); return TRUE; }
__declspec(dllexport) BOOL WINAPI wglMakeCurrent(HDC dc, HGLRC rc){ init(); HDC d=mapdc(dc); BOOL r=p_wglMakeCurrent?p_wglMakeCurrent(d,rc):FALSE; if(d!=dc) lg("wglMakeCurrent(dc %p -> helper %p, rc %p) -> %d", dc, d, rc, r); return r; }
__declspec(dllexport) BOOL WINAPI wglSwapBuffers(HDC dc){ init(); return p_wglSwapBuffers?p_wglSwapBuffers(mapdc(dc)):FALSE; }
__declspec(dllexport) int WINAPI wglGetPixelFormat(HDC dc){ init(); int mf=mapfmt(dc); if(mf) return mf; int r=p_wglGetPixelFormat?p_wglGetPixelFormat(dc):0; if(!r){ int m=recall(dc); if(m){ lg("wglGetPixelFormat(dc %p) real 0 -> remembered %d", dc, m); return m; } } return r; }
__declspec(dllexport) HGLRC WINAPI wglCreateContext(HDC dc){ init(); HDC d=mapdc(dc); HGLRC rc=p_wglCreateContext?p_wglCreateContext(d):0; lg("wglCreateContext(dc %p%s) -> %p (err %lu)", dc, d!=dc?" [helper]":"", rc, rc?0:GetLastError()); return rc; }
BOOL WINAPI DllMain(HINSTANCE h, DWORD r, LPVOID x){ if(r==DLL_PROCESS_ATTACH) init(); return TRUE; }
