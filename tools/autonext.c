/* autonext: clicks Next/Install/Finish/I Agree/OK on visible windows whose title contains "Setup" (classic Win32 installers).
   Usage: autonext.exe [seconds]  (default 1800). Exits when the time is up. */
#include <windows.h>
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
static int clicks=0;
static BOOL CALLBACK btn(HWND h, LPARAM lp){ char cls[64]="",t[128]=""; GetClassNameA(h,cls,sizeof cls); GetWindowTextA(h,t,sizeof t);
  if(_stricmp(cls,"Button")!=0 || !IsWindowVisible(h) || !IsWindowEnabled(h)) return TRUE;
  char n[128]; int j=0; for(int i=0;t[i]&&j<127;i++) if(t[i]!='&') n[j++]=t[i]; n[j]=0;
  if(!strcmp(n,"Next >")||!strcmp(n,"Next")||!strcmp(n,"Install")||!strcmp(n,"Finish")||!strcmp(n,"I Agree")||!strcmp(n,"OK")||!strcmp(n,"Close")){ printf("click \"%s\" in %p\n",n,(HWND)lp); fflush(stdout); SendMessageA(h,BM_CLICK,0,0); clicks++; return FALSE; }
  return TRUE; }
static BOOL CALLBACK top(HWND h, LPARAM lp){ char t[256]=""; if(!IsWindowVisible(h)) return TRUE; GetWindowTextA(h,t,sizeof t); if(strstr(t,"Setup")||strstr(t,"Installer")) EnumChildWindows(h,btn,(LPARAM)h); return TRUE; }
int main(int argc,char**argv){ int secs=argc>1?atoi(argv[1]):1800; for(int i=0;i<secs/2;i++){ EnumWindows(top,0); Sleep(2000); } printf("autonext done, %d clicks\n",clicks); return 0; }
