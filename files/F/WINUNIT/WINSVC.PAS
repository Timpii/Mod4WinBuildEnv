UNIT WinSvc;
{$C Fixed Preload Permanent}
{ Win32 service control manager (ADVAPI32) called from 16-bit code via
  generic thunks (CallProc32W).
  Reconstructed from PLAYER32.DLL - unit name is a guess. }
INTERFACE
USES WinTypes,W32Defs,W32Base;

CONST pOpenSCManagerA    :LongInt=0;
      pCloseServiceHandle:LongInt=0;
      pCreateServiceA    :LongInt=0;
      pOpenServiceA      :LongInt=0;
      pDeleteService     :LongInt=0;
      pStartServiceA     :LongInt=0;
      pControlService    :LongInt=0;

FUNCTION OpenSCManagerA(lpMachineName,lpDatabaseName:PChar;dwDesiredAccess:LongInt):LongInt;
FUNCTION CloseServiceHandle(hSCObject:LongInt):Bool;
FUNCTION CreateServiceA(hSCManager:LongInt;lpServiceName,lpDisplayName:PChar;
                        dwDesiredAccess,dwServiceType,dwStartType,dwErrorControl:LongInt;
                        lpBinaryPathName,lpLoadOrderGroup:PChar;lpdwTagId:Pointer;
                        lpDependencies,lpServiceStartName,lpPassword:PChar):LongInt;
FUNCTION OpenServiceA(hSCManager:LongInt;lpServiceName:PChar;dwDesiredAccess:LongInt):LongInt;
FUNCTION DeleteService(hService:LongInt):Bool;
FUNCTION StartServiceA(hService,dwNumServiceArgs:LongInt;lpServiceArgVectors:Pointer):Bool;
FUNCTION ControlService(hService,dwControl:LongInt;lpServiceStatus:Pointer):Bool;

IMPLEMENTATION

FUNCTION OpenSCManagerA(lpMachineName,lpDatabaseName:PChar;dwDesiredAccess:LongInt):LongInt; ASSEMBLER;
ASM
  DB 66h; cmp word ptr pOpenSCManagerA,0
  je @@1
  DB 66h; push word ptr lpMachineName
  DB 66h; push word ptr lpDatabaseName
  DB 66h; push word ptr dwDesiredAccess
  DB 66h; push word ptr pOpenSCManagerA
  push 0; push 6
  push 0; push 3
  call dword ptr CallProc32W
  jmp @@2
@@1:
  xor ax,ax
  xor dx,dx
@@2:
END;

FUNCTION CloseServiceHandle(hSCObject:LongInt):Bool; ASSEMBLER;
ASM
  DB 66h; cmp word ptr pCloseServiceHandle,0
  je @@1
  DB 66h; push word ptr hSCObject
  DB 66h; push word ptr pCloseServiceHandle
  push 0; push 0
  push 0; push 1
  call dword ptr CallProc32W
  jmp @@2
@@1:
  xor ax,ax
@@2:
END;

FUNCTION CreateServiceA(hSCManager:LongInt;lpServiceName,lpDisplayName:PChar;
                        dwDesiredAccess,dwServiceType,dwStartType,dwErrorControl:LongInt;
                        lpBinaryPathName,lpLoadOrderGroup:PChar;lpdwTagId:Pointer;
                        lpDependencies,lpServiceStartName,lpPassword:PChar):LongInt; ASSEMBLER;
ASM
  DB 66h; cmp word ptr pCreateServiceA,0
  je @@1
  DB 66h; push word ptr hSCManager
  DB 66h; push word ptr lpServiceName
  DB 66h; push word ptr lpDisplayName
  DB 66h; push word ptr dwDesiredAccess
  DB 66h; push word ptr dwServiceType
  DB 66h; push word ptr dwStartType
  DB 66h; push word ptr dwErrorControl
  DB 66h; push word ptr lpBinaryPathName
  DB 66h; push word ptr lpLoadOrderGroup
  DB 66h; push word ptr lpdwTagId
  DB 66h; push word ptr lpDependencies
  DB 66h; push word ptr lpServiceStartName
  DB 66h; push word ptr lpPassword
  DB 66h; push word ptr pCreateServiceA
  push 0; push 0C3Fh
  push 0; push 13
  call dword ptr CallProc32W
  jmp @@2
@@1:
  xor ax,ax
  xor dx,dx
@@2:
END;

FUNCTION OpenServiceA(hSCManager:LongInt;lpServiceName:PChar;dwDesiredAccess:LongInt):LongInt; ASSEMBLER;
ASM
  DB 66h; cmp word ptr pOpenServiceA,0
  je @@1
  DB 66h; push word ptr hSCManager
  DB 66h; push word ptr lpServiceName
  DB 66h; push word ptr dwDesiredAccess
  DB 66h; push word ptr pOpenServiceA
  push 0; push 2
  push 0; push 3
  call dword ptr CallProc32W
  jmp @@2
@@1:
  xor ax,ax
  xor dx,dx
@@2:
END;

FUNCTION DeleteService(hService:LongInt):Bool; ASSEMBLER;
ASM
  DB 66h; cmp word ptr pDeleteService,0
  je @@1
  DB 66h; push word ptr hService
  DB 66h; push word ptr pDeleteService
  push 0; push 0
  push 0; push 1
  call dword ptr CallProc32W
  jmp @@2
@@1:
  xor ax,ax
@@2:
END;

FUNCTION StartServiceA(hService,dwNumServiceArgs:LongInt;lpServiceArgVectors:Pointer):Bool; ASSEMBLER;
ASM
  DB 66h; cmp word ptr pStartServiceA,0
  je @@1
  DB 66h; push word ptr hService
  DB 66h; push word ptr dwNumServiceArgs
  DB 66h; push word ptr lpServiceArgVectors
  DB 66h; push word ptr pStartServiceA
  push 0; push 1
  push 0; push 3
  call dword ptr CallProc32W
  jmp @@2
@@1:
  xor ax,ax
@@2:
END;

FUNCTION ControlService(hService,dwControl:LongInt;lpServiceStatus:Pointer):Bool; ASSEMBLER;
ASM
  DB 66h; cmp word ptr pControlService,0
  je @@1
  DB 66h; push word ptr hService
  DB 66h; push word ptr dwControl
  DB 66h; push word ptr lpServiceStatus
  DB 66h; push word ptr pControlService
  push 0; push 1
  push 0; push 3
  call dword ptr CallProc32W
  jmp @@2
@@1:
  xor ax,ax
@@2:
END;

BEGIN
  IF Win32Available THEN
  BEGIN
    pOpenSCManagerA    :=GetProcAddress32W(hAdvApi32,'OpenSCManagerA');
    pCloseServiceHandle:=GetProcAddress32W(hAdvApi32,'CloseServiceHandle');
    pCreateServiceA    :=GetProcAddress32W(hAdvApi32,'CreateServiceA');
    pOpenServiceA      :=GetProcAddress32W(hAdvApi32,'OpenServiceA');
    pDeleteService     :=GetProcAddress32W(hAdvApi32,'DeleteService');
    pStartServiceA     :=GetProcAddress32W(hAdvApi32,'StartServiceA');
    pControlService    :=GetProcAddress32W(hAdvApi32,'ControlService');
  END;
END.
