UNIT W32Base;
{$C Fixed Preload Permanent}
{ Generic thunk base: gives 16-bit code access to Win32 DLLs under
  Windows 95/NT (LoadLibraryEx32W, GetProcAddress32W, CallProc32W).
  The 32-bit module handles and Win32Available live in W32Defs.
  Reconstructed from the compiled code in PLAYER32.DLL; names not used by the
  surviving sources are guesses. }
INTERFACE

VAR CallProc32W:Pointer;

FUNCTION LoadLibraryEx32W(LibName:pChar;hFile,dwFlags:LongInt):LongInt;
FUNCTION FreeLibrary32W(hLib32:LongInt):LongInt;
FUNCTION GetProcAddress32W(hLib32:LongInt;ProcName:pChar):LongInt;
FUNCTION GetVDMPointer32W(P:Pointer;fMode:Word):LongInt;
FUNCTION GetLastError:LongInt;

IMPLEMENTATION
USES WinTypes,WinProcs,W32Defs;

CONST lLoadLibraryEx32W :Pointer=NIL;
      lFreeLibrary32W   :Pointer=NIL;
      lGetProcAddress32W:Pointer=NIL;
      lGetVDMPointer32W :Pointer=NIL;
      lGetLastError     :LongInt=0;

FUNCTION LoadLibraryEx32W(LibName:pChar;hFile,dwFlags:LongInt):LongInt;ASSEMBLER;
ASM
  DB 66h; cmp word ptr lLoadLibraryEx32W,0
  je @Fail
  DB 66h; push word ptr LibName
  DB 66h; push word ptr hFile
  DB 66h; push word ptr dwFlags
  call dword ptr lLoadLibraryEx32W
  jmp @Exit
@Fail:
  xor ax,ax
  xor dx,dx
@Exit:
END;

FUNCTION FreeLibrary32W(hLib32:LongInt):LongInt;ASSEMBLER;
ASM
  DB 66h; cmp word ptr lFreeLibrary32W,0
  je @Fail
  DB 66h; push word ptr hLib32
  call dword ptr lFreeLibrary32W
  jmp @Exit
@Fail:
  xor ax,ax
  xor dx,dx
@Exit:
END;

FUNCTION GetProcAddress32W(hLib32:LongInt;ProcName:pChar):LongInt;ASSEMBLER;
ASM
  DB 66h; cmp word ptr lGetProcAddress32W,0
  je @Fail
  DB 66h; push word ptr hLib32
  DB 66h; push word ptr ProcName
  call dword ptr lGetProcAddress32W
  jmp @Exit
@Fail:
  xor ax,ax
  xor dx,dx
@Exit:
END;

FUNCTION GetVDMPointer32W(P:Pointer;fMode:Word):LongInt;ASSEMBLER;
ASM
  DB 66h; cmp word ptr lGetVDMPointer32W,0
  je @Fail
  DB 66h; push word ptr P
  push fMode
  call dword ptr lGetVDMPointer32W
  jmp @Exit
@Fail:
  xor ax,ax
  xor dx,dx
@Exit:
END;

FUNCTION GetLastError:LongInt;ASSEMBLER;
ASM
  DB 66h; cmp word ptr lGetLastError,0
  je @Fail
  DB 66h; push word ptr lGetLastError
  push 0; push 0
  push 0; push 0
  call dword ptr CallProc32W
  jmp @Exit
@Fail:
  xor ax,ax
  xor dx,dx
@Exit:
END;

FUNCTION InitThunks:Boolean;
VAR hKernel,OldMode:Word;
BEGIN
  OldMode:=SetErrorMode($8001);
  hKernel:=GetModuleHandle('KERNEL');
  lLoadLibraryEx32W :=GetProcAddress(hKernel,'LoadLibraryEx32W');
  lFreeLibrary32W   :=GetProcAddress(hKernel,'FreeLibrary32W');
  lGetProcAddress32W:=GetProcAddress(hKernel,'GetProcAddress32W');
  lGetVDMPointer32W :=GetProcAddress(hKernel,'GetVDMpointer32W');
  CallProc32W       :=GetProcAddress(hKernel,'CallProc32W');
  InitThunks:=(lLoadLibraryEx32W<>NIL)AND(CallProc32W<>NIL)AND(lGetProcAddress32W<>NIL)AND
              (lFreeLibrary32W<>NIL)AND(lGetVDMPointer32W<>NIL);
  SetErrorMode(OldMode);
END;

BEGIN
  Win32Available:=InitThunks;
  IF Win32Available THEN
  BEGIN
    hKernel32:=LoadLibraryEx32W('KERNEL32',0,0);
    hUser32  :=LoadLibraryEx32W('USER32',0,0);
    hGDI32   :=LoadLibraryEx32W('GDI32',0,0);
    hShell32 :=LoadLibraryEx32W('SHELL32',0,0);
    hAdvapi32:=LoadLibraryEx32W('ADVAPI32',0,0);
    hMPR     :=LoadLibraryEx32W('MPR',0,0);
    hWOW32   :=LoadLibraryEx32W('WOW32',0,0);
    hVersion :=LoadLibraryEx32W('VERSION',0,0);
    lGetLastError:=GetProcAddress32W(hKernel32,'GetLastError');
  END;
END.
