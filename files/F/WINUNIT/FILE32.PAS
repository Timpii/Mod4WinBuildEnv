UNIT File32;
{$C Fixed Preload Permanent}
{ File access through the Win32 API (long file names) when running under
  Windows 95/NT, falling back to the 16-bit API under Windows 3.x.
  Every handle carries an "Is32" flag telling which API it belongs to.
  Errors are reported in WinDos.DosError.
  Reconstructed from the compiled code in PLAYER32.DLL; _lCreat32, _lWrite32,
  GetCurrentDirectory and the l<Api> pointer names are guesses. }
INTERFACE
USES WinTypes,W32Defs;

TYPE pWordBool=^WordBool;

PROCEDURE SetFileApisToOEM;
PROCEDURE SetFileApisToANSI;
FUNCTION  CreateFile(lpFileName:pChar;dwDesiredAccess,dwShareMode:LongInt;lpSecurityAttributes:Pointer;
                     dwCreationDistribution,dwFlagsAndAttributes,hTemplateFile:LongInt):Handle32;
FUNCTION  SetFilePointer(hFile:Handle32;lDistanceToMove:LongInt;lpDistanceToMoveHigh:Pointer;
                         dwMoveMethod:LongInt):LongInt;
FUNCTION  CloseHandle(hObject:Handle32):Bool;
FUNCTION  DeviceIoControl(hDevice:Handle32;dwIoControlCode:LongInt;lpInBuffer:Pointer;nInBufferSize:LongInt;
                          lpOutBuffer:Pointer;nOutBufferSize:LongInt;lpBytesReturned:Pointer;
                          lpOverlapped:Pointer):Bool;
FUNCTION  GetCurrentDirectory(nBufferLength:LongInt;lpBuffer:pChar;Drive:Byte;NamesOEM:Bool):LongInt;

FUNCTION  _lCreat32(FileName:pChar;NamesOEM:Bool;Attribute,ShareMode:LongInt;Is32:pWordBool):Handle32;
FUNCTION  _lOpen32(FileName:pChar;NamesOEM:Bool;Access,ShareMode:LongInt;Is32:pWordBool):Handle32;
FUNCTION  _lClose32(H:Handle32;Is32:WordBool):Bool;
FUNCTION  _lSeek32(H:Handle32;Is32:WordBool;Distance:LongInt;Method:Word):LongInt;
FUNCTION  _lSeekAbs32(H:Handle32;Is32:WordBool;Pos:LongInt):LongInt;
FUNCTION  _lSize32(H:Handle32;Is32:WordBool):LongInt;
FUNCTION  _lPos32(H:Handle32;Is32:WordBool):LongInt;
FUNCTION  _lEOF32(H:Handle32;Is32:WordBool):Bool;
FUNCTION  _lRead32(H:Handle32;Is32:WordBool;Buffer:Pointer;Count:Word):Word;
FUNCTION  _lWrite32(H:Handle32;Is32:WordBool;Buffer:Pointer;Count:Word):Word;

IMPLEMENTATION
{ W32Base before WinDos: the unit link order of M4W_MCI.DLL depends on it }
USES WinProcs,W32Base,WinDos,Strings;

CONST lGetCurrentDirectoryA       :LongInt=0;
      lSetCurrentDirectoryA       :LongInt=0;
      lCreateDirectoryA           :LongInt=0;
      lRemoveDirectoryA           :LongInt=0;
      lGetFullPathNameA           :LongInt=0;
      lGetShortPathNameA          :LongInt=0;
      lFileTimeToSystemTime       :LongInt=0;
      lFileTimeToLocalFileTime    :LongInt=0;
      lFindFirstFileA             :LongInt=0;
      lFindNextFileA              :LongInt=0;
      lFindClose                  :LongInt=0;
      lSetFileApisToOEM           :LongInt=0;
      lSetFileApisToANSI          :LongInt=0;
      lAreFileApisANSI            :LongInt=0;
      lGetSystemDirectoryA        :LongInt=0;
      lCreateFileA                :LongInt=0;
      lReadFile                   :LongInt=0;
      lWriteFile                  :LongInt=0;
      lSetFilePointer             :LongInt=0;
      lCloseHandle                :LongInt=0;
      lFindFirstChangeNotificationA:LongInt=0;
      lFindNextChangeNotification :LongInt=0;
      lFindCloseChangeNotification:LongInt=0;
      lWaitForSingleObjectEx      :LongInt=0;
      lDeviceIoControl            :LongInt=0;

PROCEDURE SetFileApisToOEM;ASSEMBLER;
ASM
  DB 66h; cmp word ptr lSetFileApisToOEM,0
  je @Exit
  DB 66h; push word ptr lSetFileApisToOEM
  push 0; push 0
  push 0; push 0
  call dword ptr CallProc32W
@Exit:
END;

PROCEDURE SetFileApisToANSI;ASSEMBLER;
ASM
  DB 66h; cmp word ptr lSetFileApisToANSI,0
  je @Exit
  DB 66h; push word ptr lSetFileApisToANSI
  push 0; push 0
  push 0; push 0
  call dword ptr CallProc32W
@Exit:
END;

FUNCTION CreateFile(lpFileName:pChar;dwDesiredAccess,dwShareMode:LongInt;lpSecurityAttributes:Pointer;
                    dwCreationDistribution,dwFlagsAndAttributes,hTemplateFile:LongInt):Handle32;ASSEMBLER;
ASM
  DB 66h; cmp word ptr lCreateFileA,0
  je @Fail
  call SetFileApisToOEM
  DB 66h; push word ptr lpFileName
  DB 66h; push word ptr dwDesiredAccess
  DB 66h; push word ptr dwShareMode
  DB 66h; push word ptr lpSecurityAttributes
  DB 66h; push word ptr dwCreationDistribution
  DB 66h; push word ptr dwFlagsAndAttributes
  DB 66h; push word ptr hTemplateFile
  DB 66h; push word ptr lCreateFileA
  push 0; push 1001000b
  push 0; push 7
  call dword ptr CallProc32W
  jmp @Exit
@Fail:
  mov ax,0FFFFh
  mov dx,0FFFFh
@Exit:
END;

FUNCTION SetFilePointer(hFile:Handle32;lDistanceToMove:LongInt;lpDistanceToMoveHigh:Pointer;
                        dwMoveMethod:LongInt):LongInt;ASSEMBLER;
ASM
  DB 66h; cmp word ptr lReadFile,0
  je @Fail
  DB 66h; push word ptr hFile
  DB 66h; push word ptr lDistanceToMove
  DB 66h; push word ptr lpDistanceToMoveHigh
  DB 66h; push word ptr dwMoveMethod
  DB 66h; push word ptr lSetFilePointer
  push 0; push 0010b
  push 0; push 4
  call dword ptr CallProc32W
  jmp @Exit
@Fail:
  mov ax,0FFFFh
  mov dx,0FFFFh
@Exit:
END;

FUNCTION CloseHandle(hObject:Handle32):Bool;ASSEMBLER;
ASM
  xor ax,ax
  DB 66h; cmp word ptr lCloseHandle,0
  je @Exit
  DB 66h; push word ptr hObject
  DB 66h; push word ptr lCloseHandle
  push 0; push 0
  push 0; push 1
  call dword ptr CallProc32W
@Exit:
END;

FUNCTION _lCreat32(FileName:pChar;NamesOEM:Bool;Attribute,ShareMode:LongInt;Is32:pWordBool):Handle32;ASSEMBLER;
ASM
  mov DosError,0
  DB 66h; cmp word ptr lCreateFileA,0
  je @Win16
  cmp NamesOEM,0
  je @Ansi
  call SetFileApisToOEM
  jmp @Create
@Ansi:
  call SetFileApisToANSI
@Create:
  DB 66h; push word ptr FileName
  DB 66h,68h; DD 0C0000000h        {GENERIC_READ OR GENERIC_WRITE}
  DB 66h; push word ptr ShareMode
  DB 66h,68h; DD 0                 {lpSecurityAttributes}
  DB 66h,68h; DD 2                 {CREATE_ALWAYS}
  DB 66h; push word ptr Attribute
  DB 66h,68h; DD 0                 {hTemplateFile}
  DB 66h; push word ptr lCreateFileA
  push 0; push 1000000b
  push 0; push 7
  call dword ptr CallProc32W
  cmp ax,0FFFFh
  jne @Ok32
  cmp dx,-1
  jne @Ok32
  call GetLastError
  mov DosError,ax
  mov ax,0FFFFh
  mov dx,0FFFFh
@Ok32:
  DB 66h; cmp word ptr Is32,0
  je @Exit
  les di,Is32
  mov word ptr es:[di],1
  jmp @Exit
@Win16:
  cmp NamesOEM,0
  je @lCreat
  mov cx,word ptr Attribute
  push ds
  lds dx,FileName
  mov ax,3C00h
  int 21h
  jnc @DosOk
  pop ds
  mov DosError,ax
  mov ax,0FFFFh
  mov dx,0FFFFh
  jmp @Set16
@DosOk:
  pop ds
  jmp @Ok16
@lCreat:
  DB 66h; push word ptr FileName
  xor bx,bx
  mov ax,word ptr Attribute
  test ax,1
  je @a2
  mov bx,1
  jmp @a4
@a2:
  test ax,2
  je @a3
  mov bx,2
  jmp @a4
@a3:
  test ax,4
  je @a4
  mov bx,3
@a4:
  push bx
  call _lcreat
  cmp ax,0FFFFh
  jne @Ok16
  mov DosError,3
  mov dx,0FFFFh
  jmp @Set16
@Ok16:
  xor dx,dx
@Set16:
  DB 66h; cmp word ptr Is32,0
  je @Exit
  les di,Is32
  mov word ptr es:[di],0
@Exit:
END;

FUNCTION _lOpen32(FileName:pChar;NamesOEM:Bool;Access,ShareMode:LongInt;Is32:pWordBool):Handle32;ASSEMBLER;
ASM
  mov DosError,0
  DB 66h; cmp word ptr lCreateFileA,0
  je @Win16
  cmp NamesOEM,0
  je @Ansi
  call SetFileApisToOEM
  jmp @Open
@Ansi:
  call SetFileApisToANSI
@Open:
  DB 66h; push word ptr FileName
  DB 66h; push word ptr Access
  DB 66h; push word ptr ShareMode
  DB 66h,68h; DD 0                 {lpSecurityAttributes}
  DB 66h,68h; DD 3                 {OPEN_EXISTING}
  DB 66h,68h; DD 0                 {dwFlagsAndAttributes}
  DB 66h,68h; DD 0                 {hTemplateFile}
  DB 66h; push word ptr lCreateFileA
  push 0; push 1000000b
  push 0; push 7
  call dword ptr CallProc32W
  cmp ax,0FFFFh
  jne @Ok32
  cmp dx,-1
  jne @Ok32
  call GetLastError
  mov DosError,ax
  mov ax,0FFFFh
  mov dx,1
@Ok32:
  DB 66h; cmp word ptr Is32,0
  jne @Set32
  jmp @Exit
@Set32:
  les di,Is32
  mov word ptr es:[di],1
  jmp @Exit
@Win16:
  xor ax,ax
  DB 66h; mov bx,word ptr Access
  DB 66h; shr bx,30
  test bx,1
  je @m1
  mov ax,1
  test bx,2
  je @m1
  shl ax,1
@m1:
  mov bx,word ptr ShareMode
  or bx,3
  or bx,bx
  jne @s1
  or ax,10h
  jmp @s4
@s1:
  cmp bx,1
  jne @s2
  or ax,20h
  jmp @s4
@s2:
  cmp bx,2
  jne @s3
  or ax,30h
  jmp @s4
@s3:
  or ax,40h
@s4:
  cmp NamesOEM,0
  je @lOpen
  push ds
  lds dx,FileName
  mov ah,3Dh
  int 21h
  jnc @DosOk
  pop ds
  mov DosError,ax
  mov ax,0FFFFh
  mov dx,0FFFFh
  jmp @Set16
@DosOk:
  pop ds
  jmp @Ok16
@lOpen:
  DB 66h; push word ptr FileName
  push ax
  call _lopen
  cmp ax,0FFFFh
  jne @Ok16
  mov DosError,2
  mov dx,0FFFFh
  jmp @Set16
@Ok16:
  xor dx,dx
@Set16:
  DB 66h; cmp word ptr Is32,0
  je @Exit
  les di,Is32
  mov word ptr es:[di],0
@Exit:
END;

FUNCTION _lClose32(H:Handle32;Is32:WordBool):Bool;ASSEMBLER;
ASM
  cmp Is32,0
  je @Win16
  DB 66h; cmp word ptr lCloseHandle,0
  je @Win16
  DB 66h; push word ptr H
  DB 66h; push word ptr lCloseHandle
  push 0; push 0
  push 0; push 1
  call dword ptr CallProc32W
  jmp @Exit
@Win16:
  push word ptr H
  call _lclose
  not ax
@Exit:
END;

FUNCTION _lSeek32(H:Handle32;Is32:WordBool;Distance:LongInt;Method:Word):LongInt;ASSEMBLER;
ASM
  mov DosError,0
  cmp Is32,0
  je @Win16
  DB 66h; cmp word ptr SetFilePointer,0
  je @Win16
  DB 66h; push word ptr H
  DB 66h; push word ptr Distance
  DB 66h,68h; DD 0                 {lpDistanceToMoveHigh}
  push 0
  push Method
  DB 66h; push word ptr lSetFilePointer
  push 0; push 0
  push 0; push 4
  call dword ptr CallProc32W
  cmp ax,0FFFFh
  jne @Exit
  cmp dx,-1
  jne @Exit
  call GetLastError
  mov DosError,ax
  mov ax,0FFFFh
  mov dx,0FFFFh
  jmp @Exit
@Win16:
  push word ptr H
  DB 66h; push word ptr Distance
  push Method
  call _llseek
  cmp ax,0FFFFh
  jne @Exit
  cmp dx,-1
  jne @Exit
  mov DosError,1
@Exit:
END;

FUNCTION _lSeekAbs32(H:Handle32;Is32:WordBool;Pos:LongInt):LongInt;ASSEMBLER;
ASM
  DB 66h; push word ptr H
  push Is32
  DB 66h; push word ptr Pos
  push 0
  call _lSeek32
END;

FUNCTION _lSize32(H:Handle32;Is32:WordBool):LongInt;ASSEMBLER;
VAR OldPos:LongInt;
ASM
  cmp Is32,0
  jne @1
  jmp @Win16
@1:
  DB 66h; cmp word ptr SetFilePointer,0
  je @Win16
  DB 66h; push word ptr H
  DB 66h,68h; DD 0
  DB 66h,68h; DD 0
  push 0; push FILE_CURRENT
  DB 66h; push word ptr lSetFilePointer
  push 0; push 0
  push 0; push 4
  call dword ptr CallProc32W
  mov word ptr OldPos,ax
  mov word ptr OldPos+2,dx
  DB 66h; push word ptr H
  DB 66h,68h; DD 0
  DB 66h,68h; DD 0
  push 0; push FILE_END
  DB 66h; push word ptr lSetFilePointer
  push 0; push 0
  push 0; push 4
  call dword ptr CallProc32W
  push ax
  push dx
  DB 66h; push word ptr H
  DB 66h; push word ptr OldPos
  DB 66h,68h; DD 0
  push 0; push FILE_BEGIN
  DB 66h; push word ptr lSetFilePointer
  push 0; push 0
  push 0; push 4
  call dword ptr CallProc32W
  pop dx
  pop ax
  jmp @Exit
@Win16:
  push word ptr H
  DB 66h,68h; DD 0
  push FILE_CURRENT
  call _llseek
  mov word ptr OldPos,ax
  mov word ptr OldPos+2,dx
  push word ptr H
  DB 66h,68h; DD 0
  push FILE_END
  call _llseek
  push ax
  push dx
  push word ptr H
  DB 66h; push word ptr OldPos
  push FILE_BEGIN
  call _llseek
  pop dx
  pop ax
@Exit:
END;

FUNCTION _lPos32(H:Handle32;Is32:WordBool):LongInt;ASSEMBLER;
ASM
  cmp Is32,0
  je @Win16
  DB 66h; cmp word ptr SetFilePointer,0
  je @Win16
  DB 66h; push word ptr H
  DB 66h,68h; DD 0
  DB 66h,68h; DD 0
  push 0; push FILE_CURRENT
  DB 66h; push word ptr lSetFilePointer
  push 0; push 0
  push 0; push 4
  call dword ptr CallProc32W
  jmp @Exit
@Win16:
  push word ptr H
  DB 66h,68h; DD 0
  push FILE_CURRENT
  call _llseek
@Exit:
END;

FUNCTION _lEOF32(H:Handle32;Is32:WordBool):Bool;ASSEMBLER;
ASM
  DB 66h; push word ptr H
  push Is32
  call _lPos32
  push dx
  push ax
  DB 66h; push word ptr H
  push Is32
  call _lSize32
  DB 66h; shl dx,16
  mov dx,ax
  DB 66h; pop bx
  DB 66h; cmp bx,dx
  jae @Eof
  xor ax,ax
  jmp @Exit
@Eof:
  mov ax,1
@Exit:
END;

FUNCTION _lRead32(H:Handle32;Is32:WordBool;Buffer:Pointer;Count:Word):Word;ASSEMBLER;
VAR BytesRead:LongInt;
ASM
  mov DosError,0
  cmp Is32,0
  je @Win16
  DB 66h; cmp word ptr lReadFile,0
  je @Win16
  DB 66h; push word ptr H
  DB 66h; push word ptr Buffer
  push 0
  push Count
  push ss
  lea di,BytesRead
  push di
  DB 66h,68h; DD 0                 {lpOverlapped}
  DB 66h; push word ptr lReadFile
  push 0; push 1010b
  push 0; push 5
  call dword ptr CallProc32W
  or ax,ax
  jne @Ok
  call GetLastError
  mov DosError,ax
  mov ax,0FFFFh
  jmp @Exit
@Ok:
  mov ax,word ptr BytesRead
  jmp @Exit
@Win16:
  push word ptr H
  DB 66h; push word ptr Buffer
  push Count
  call _lread
  cmp ax,0FFFFh
  jne @Exit
  mov DosError,5
@Exit:
END;

FUNCTION _lWrite32(H:Handle32;Is32:WordBool;Buffer:Pointer;Count:Word):Word;ASSEMBLER;
VAR BytesWritten:LongInt;
ASM
  mov DosError,0
  cmp Is32,0
  je @Win16
  DB 66h; cmp word ptr lWriteFile,0
  je @Win16
  DB 66h; push word ptr H
  DB 66h; push word ptr Buffer
  push 0
  push Count
  push ss
  lea di,BytesWritten
  push di
  DB 66h,68h; DD 0                 {lpOverlapped}
  DB 66h; push word ptr lWriteFile
  push 0; push 1010b
  push 0; push 5
  call dword ptr CallProc32W
  or ax,ax
  jne @Ok
  call GetLastError
  mov DosError,ax
  mov ax,0FFFFh
  jmp @Exit
@Ok:
  mov ax,word ptr BytesWritten
  jmp @Exit
@Win16:
  push word ptr H
  DB 66h; push word ptr Buffer
  push Count
  call _lwrite
  cmp ax,0FFFFh
  jne @Exit
  mov DosError,5
@Exit:
END;

FUNCTION DeviceIoControl(hDevice:Handle32;dwIoControlCode:LongInt;lpInBuffer:Pointer;nInBufferSize:LongInt;
                         lpOutBuffer:Pointer;nOutBufferSize:LongInt;lpBytesReturned:Pointer;
                         lpOverlapped:Pointer):Bool;ASSEMBLER;
ASM
  xor ax,ax
  cmp word ptr lDeviceIoControl,0
  je @Exit
  DB 66h; push word ptr hDevice
  DB 66h; push word ptr dwIoControlCode
  DB 66h; push word ptr lpInBuffer
  DB 66h; push word ptr nInBufferSize
  DB 66h; push word ptr lpOutBuffer
  DB 66h; push word ptr nOutBufferSize
  DB 66h; push word ptr lpBytesReturned
  DB 66h; push word ptr lpOverlapped
  DB 66h; push word ptr lDeviceIoControl
  push 0; push 101011b
  push 0; push 8
  call dword ptr CallProc32W
@Exit:
END;

FUNCTION GetCurrentDirectory(nBufferLength:LongInt;lpBuffer:pChar;Drive:Byte;NamesOEM:Bool):LongInt;ASSEMBLER;
ASM
  DB 66h; cmp word ptr lGetCurrentDirectoryA,0
  je @Win16
  cmp NamesOEM,0
  je @Ansi
  call SetFileApisToOEM
  jmp @Get
@Ansi:
  call SetFileApisToANSI
@Get:
  DB 66h; push word ptr nBufferLength
  DB 66h; push word ptr lpBuffer
  DB 66h; push word ptr lGetCurrentDirectoryA
  push 0; push 1
  push 0; push 2
  call dword ptr CallProc32W
  jmp @Exit
@Win16:
  DB 66h; push word ptr lpBuffer
  mov al,Drive
  xor ah,ah
  push ax
  call GetCurDir
  DB 66h; push word ptr lpBuffer
  call StrLen
  xor dx,dx
@Exit:
END;

BEGIN
  IF Win32Available THEN
  BEGIN
    lGetCurrentDirectoryA        :=GetProcAddress32W(hKernel32,'GetCurrentDirectoryA');
    lSetCurrentDirectoryA        :=GetProcAddress32W(hKernel32,'SetCurrentDirectoryA');
    lCreateDirectoryA            :=GetProcAddress32W(hKernel32,'CreateDirectoryA');
    lRemoveDirectoryA            :=GetProcAddress32W(hKernel32,'RemoveDirectoryA');
    lGetFullPathNameA            :=GetProcAddress32W(hKernel32,'GetFullPathNameA');
    lGetShortPathNameA           :=GetProcAddress32W(hKernel32,'GetShortPathNameA');
    lFileTimeToSystemTime        :=GetProcAddress32W(hKernel32,'FileTimeToSystemTime');
    lFileTimeToLocalFileTime     :=GetProcAddress32W(hKernel32,'FileTimeToLocalFileTime');
    lFindFirstFileA              :=GetProcAddress32W(hKernel32,'FindFirstFileA');
    lFindNextFileA               :=GetProcAddress32W(hKernel32,'FindNextFileA');
    lFindClose                   :=GetProcAddress32W(hKernel32,'FindClose');
    lSetFileApisToOEM            :=GetProcAddress32W(hKernel32,'SetFileApisToOEM');
    lSetFileApisToANSI           :=GetProcAddress32W(hKernel32,'SetFileApisToANSI');
    lAreFileApisANSI             :=GetProcAddress32W(hKernel32,'AreFileApisANSI');
    lGetSystemDirectoryA         :=GetProcAddress32W(hKernel32,'GetSystemDirectoryA');
    lCreateFileA                 :=GetProcAddress32W(hKernel32,'CreateFileA');
    lReadFile                    :=GetProcAddress32W(hKernel32,'ReadFile');
    lWriteFile                   :=GetProcAddress32W(hKernel32,'WriteFile');
    lSetFilePointer              :=GetProcAddress32W(hKernel32,'SetFilePointer');
    lCloseHandle                 :=GetProcAddress32W(hKernel32,'CloseHandle');
    lFindFirstChangeNotificationA:=GetProcAddress32W(hKernel32,'FindFirstChangeNotificationA');
    lFindNextChangeNotification  :=GetProcAddress32W(hKernel32,'FindNextChangeNotification');
    lFindCloseChangeNotification :=GetProcAddress32W(hKernel32,'FindCloseChangeNotification');
    lWaitForSingleObjectEx       :=GetProcAddress32W(hKernel32,'WaitForSingleObjectEx');
    lDeviceIoControl             :=GetProcAddress32W(hKernel32,'DeviceIoControl');
  END;
END.
