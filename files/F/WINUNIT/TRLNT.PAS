UNIT TrlNT;
{$C Fixed Preload Permanent}
{ Interface to the TRLPLAY.SYS helper kernel driver (Windows NT).
  The driver is installed/started as service 'TrlPlay' and accessed via
  \\.\TrlPlay with DeviceIoControl. Register based port routines like in
  TrlVxD (DX=port, AL/AX/EAX=data, ES:(E)SI/(E)DI + ECX for strings).
  Reconstructed from PLAYER32.DLL - unit and routine names are guesses. }
INTERFACE
USES WinTypes,WinProcs,Win31,W32Defs,W32Base,File32,WinSvc,GetOS,WinDos,Strings;

TYPE PLongInt=^LongInt;

CONST hService:LongInt=0;
      hDevice :Handle32=-1; {INVALID_HANDLE_VALUE}
      Names:RECORD
              Service:ARRAY[0..8]OF Char;
              Display:ARRAY[0..29]OF Char;
              Device :ARRAY[0..12]OF Char;
            END=(Service:'TrlPlay';
                 Display:'Trinity Labs Helper Service0';
                 Device :'\\.\TrlPlay');

FUNCTION  NTGetVersion:Word;
FUNCTION  NTGrantPort(Port:Word):Word;
FUNCTION  NTReleasePort(Port:Word):Word;
FUNCTION  NTGrantPortList(List:Pointer):Bool;
FUNCTION  NTSetPortWord(W:Word):Bool;
PROCEDURE NTOutB;
PROCEDURE NTOutW;
PROCEDURE NTOutD;
PROCEDURE NTOutSB;
PROCEDURE NTOutSW;
PROCEDURE NTOutSD;
PROCEDURE NTInB;
PROCEDURE NTInW;
PROCEDURE NTInD;
PROCEDURE NTFlush(Queue:PLongInt);
PROCEDURE NTInSB;
PROCEDURE NTInSW;
PROCEDURE NTInSD;
FUNCTION  LoadNTDriver(DriverName:PChar):Bool;
FUNCTION  UnloadNTDriver(DriverName:PChar):Bool;

IMPLEMENTATION

{ A true constant here: the original code compares with an immediate -1,
  not with W32Defs typed constant. }
CONST INVALID_HANDLE_VALUE = -1;

VAR DriverPath:ARRAY[0..79]OF Char;

FUNCTION NTGetVersion:Word;
VAR Version:Word;
    BytesReturned:LongInt;
BEGIN
  IF DeviceIoControl(hDevice,$81576400,NIL,0,@Version,2,@BytesReturned,NIL)
  THEN NTGetVersion:=Version
  ELSE NTGetVersion:=0;
END;

FUNCTION NTGrantPort(Port:Word):Word;
BEGIN
END;

FUNCTION NTReleasePort(Port:Word):Word;
BEGIN
END;

FUNCTION NTGrantPortList(List:Pointer):Bool;
VAR BytesReturned:LongInt;
BEGIN
  IF List=NIL THEN NTGrantPortList:=False
  ELSE NTGrantPortList:=DeviceIoControl(hDevice,$81572428,List,Word(List^)*2+2,
                                       List,Word(List^)*2+2,@BytesReturned,NIL);
END;

FUNCTION NTSetPortWord(W:Word):Bool;
VAR BytesReturned:LongInt;
BEGIN
  NTSetPortWord:=DeviceIoControl(hDevice,$8157A42C,@W,2,NIL,0,@BytesReturned,NIL);
END;

PROCEDURE NTOutB;
VAR Buf:RECORD Port,Data:LongInt; END;
    BytesReturned:LongInt;
BEGIN
  ASM
    DB 66h; pusha
    push es
    DB 66h; mov word ptr Buf.Port,0; DW 0
    mov word ptr Buf.Port,dx
    DB 66h; mov word ptr Buf.Data,0; DW 0
    mov byte ptr Buf.Data,al
  END;
  DeviceIoControl(hDevice,$8157A440,@Buf,8,NIL,0,@BytesReturned,NIL);
  ASM
    pop es
    DB 66h; popa
  END;
END;

PROCEDURE NTOutW;
VAR Buf:RECORD Port,Data:LongInt; END;
    BytesReturned:LongInt;
BEGIN
  ASM
    DB 66h; pusha
    push es
    DB 66h; mov word ptr Buf.Port,0; DW 0
    mov word ptr Buf.Port,dx
    DB 66h; mov word ptr Buf.Data,0; DW 0
    mov word ptr Buf.Data,ax
  END;
  DeviceIoControl(hDevice,$8157A444,@Buf,8,NIL,0,@BytesReturned,NIL);
  ASM
    pop es
    DB 66h; popa
  END;
END;

PROCEDURE NTOutD;
VAR Buf:RECORD Port,Data:LongInt; END;
    BytesReturned:LongInt;
BEGIN
  ASM
    DB 66h; pusha
    push es
    DB 66h; mov word ptr Buf.Port,0; DW 0
    mov word ptr Buf.Port,dx
    DB 66h; mov word ptr Buf.Data,ax
  END;
  DeviceIoControl(hDevice,$8157A448,@Buf,8,NIL,0,@BytesReturned,NIL);
  ASM
    pop es
    DB 66h; popa
  END;
END;

PROCEDURE NTOutSB;
VAR Buf:RECORD Addr,Count,Port:LongInt; END;
    BytesReturned:LongInt;
BEGIN
  ASM
    DB 66h; pusha
    push es
    DB 66h; mov word ptr Buf.Count,cx
    DB 66h,81h,0E2h,0FFh,0FFh,00h,00h  {and edx,0000FFFFh}
    DB 66h; mov word ptr Buf.Port,dx
    DB 66h; mov word ptr Buf.Addr,si
    push es
    call GetSelectorBase
    DB 66h; shl dx,16
    mov dx,ax
    DB 66h; add word ptr Buf.Addr,dx
  END;
  DeviceIoControl(hDevice,$8157A458,@Buf,12,NIL,0,@BytesReturned,NIL);
  ASM
    pop es
    DB 66h; popa
    DB 66h; add si,cx
    DB 66h; xor cx,cx
  END;
END;

PROCEDURE NTOutSW;
VAR Buf:RECORD Addr,Count,Port:LongInt; END;
    BytesReturned:LongInt;
BEGIN
  ASM
    DB 66h; pusha
    push es
    DB 66h; mov word ptr Buf.Count,cx
    DB 66h,81h,0E2h,0FFh,0FFh,00h,00h  {and edx,0000FFFFh}
    DB 66h; mov word ptr Buf.Port,dx
    DB 66h; mov word ptr Buf.Addr,si
    push es
    call GetSelectorBase
    DB 66h; shl dx,16
    mov dx,ax
    DB 66h; add word ptr Buf.Addr,dx
  END;
  DeviceIoControl(hDevice,$8157A45C,@Buf,12,NIL,0,@BytesReturned,NIL);
  ASM
    pop es
    DB 66h; popa
    DB 66h; add si,cx
    DB 66h; add si,cx
    DB 66h; xor cx,cx
  END;
END;

PROCEDURE NTOutSD;
VAR Buf:RECORD Addr,Count,Port:LongInt; END;
    BytesReturned:LongInt;
BEGIN
  ASM
    DB 66h; pusha
    push es
    DB 66h; mov word ptr Buf.Count,cx
    DB 66h,81h,0E2h,0FFh,0FFh,00h,00h  {and edx,0000FFFFh}
    DB 66h; mov word ptr Buf.Port,dx
    DB 66h; mov word ptr Buf.Addr,si
    push es
    call GetSelectorBase
    DB 66h; shl dx,16
    mov dx,ax
    DB 66h; add word ptr Buf.Addr,dx
  END;
  DeviceIoControl(hDevice,$8157A460,@Buf,12,NIL,0,@BytesReturned,NIL);
  ASM
    pop es
    DB 66h; popa
    DB 66h; add si,cx
    DB 66h; add si,cx
    DB 66h; add si,cx
    DB 66h; add si,cx
    DB 66h; xor cx,cx
  END;
END;

PROCEDURE NTInB;
VAR Port,BytesReturned:LongInt;
    Data:Byte;
BEGIN
  ASM
    DB 66h; pusha
    push es
    DB 66h; mov word ptr Port,0; DW 0
    mov word ptr Port,dx
  END;
  DeviceIoControl(hDevice,$8157644C,@Port,4,@Data,1,@BytesReturned,NIL);
  ASM
    pop es
    DB 66h; popa
    mov al,Data
  END;
END;

PROCEDURE NTInW;
VAR Port,BytesReturned:LongInt;
    Data:Word;
BEGIN
  ASM
    DB 66h; pusha
    push es
    DB 66h; mov word ptr Port,0; DW 0
    mov word ptr Port,dx
  END;
  DeviceIoControl(hDevice,$81576450,@Port,4,@Data,2,@BytesReturned,NIL);
  ASM
    pop es
    DB 66h; popa
    mov ax,Data
  END;
END;

PROCEDURE NTInD;
VAR Port,BytesReturned:LongInt;
    Data:LongInt;
BEGIN
  ASM
    DB 66h; pusha
    push es
    DB 66h; mov word ptr Port,0; DW 0
    mov word ptr Port,dx
  END;
  DeviceIoControl(hDevice,$81576454,@Port,4,@Data,4,@BytesReturned,NIL);
  ASM
    pop es
    DB 66h; popa
    DB 66h; mov ax,word ptr Data
  END;
END;

PROCEDURE NTFlush(Queue:PLongInt);
VAR BytesReturned:LongInt;
BEGIN
  DeviceIoControl(hDevice,$8157A470,Queue,Queue^*12+4,
                  Queue,Queue^*12+4,@BytesReturned,NIL);
END;

PROCEDURE NTInSB;
VAR Buf:RECORD Addr,Count,Port:LongInt; END;
    BytesReturned:LongInt;
BEGIN
  ASM
    DB 66h; pusha
    push es
    DB 66h; mov word ptr Buf.Count,cx
    DB 66h,81h,0E2h,0FFh,0FFh,00h,00h  {and edx,0000FFFFh}
    DB 66h; mov word ptr Buf.Port,dx
    DB 66h; mov word ptr Buf.Addr,di
    push es
    call GetSelectorBase
    DB 66h; shl dx,16
    mov dx,ax
    DB 66h; add word ptr Buf.Addr,dx
  END;
  DeviceIoControl(hDevice,$81576464,@Buf,12,NIL,0,@BytesReturned,NIL);
  ASM
    pop es
    DB 66h; popa
    DB 66h; add di,cx
    DB 66h; xor cx,cx
  END;
END;

PROCEDURE NTInSW;
VAR Buf:RECORD Addr,Count,Port:LongInt; END;
    BytesReturned:LongInt;
BEGIN
  ASM
    DB 66h; pusha
    push es
    DB 66h; mov word ptr Buf.Count,cx
    DB 66h,81h,0E2h,0FFh,0FFh,00h,00h  {and edx,0000FFFFh}
    DB 66h; mov word ptr Buf.Port,dx
    DB 66h; mov word ptr Buf.Addr,di
    push es
    call GetSelectorBase
    DB 66h; shl dx,16
    mov dx,ax
    DB 66h; add word ptr Buf.Addr,dx
  END;
  DeviceIoControl(hDevice,$81576468,@Buf,12,NIL,0,@BytesReturned,NIL);
  ASM
    pop es
    DB 66h; popa
    DB 66h; add di,cx
    DB 66h; add di,cx
    DB 66h; xor cx,cx
  END;
END;

PROCEDURE NTInSD;
BEGIN
END;

FUNCTION GetFileName(S:STRING):STRING;
VAR i:Byte;
BEGIN
  i:=Length(S);
  WHILE (i>0)AND(S[i]<>'\') DO Dec(i);
  GetFileName:=Copy(S,i+1,Length(S)-i);
END;

FUNCTION FindDriver(VAR Name:STRING):Boolean;
VAR Env :PChar;
    SR  :TSearchRec;
    Rest:STRING;
    Path:STRING[80];
    F   :FILE;
    Attr:Word;

  PROCEDURE CheckFile;
  BEGIN
    DosError:=0;
    FindFirst(@Path[1],$27,SR);
    IF DosError=0 THEN
    BEGIN
      Assign(F,Path);
      GetFAttr(F,Attr);
    END;
  END;

BEGIN
  Rest:=GetFileName(Name);
  IF Pos('.',Rest)=0 THEN Name:=Name+'.exe';
  IF Pos('\',Name)=0 THEN
  BEGIN
    Path:=ParamStr(0);
    WHILE (Path[0]>#0)AND(Path[Length(Path)]<>'\') DO Dec(Path[0]);
    Path:=Path+Name+#0;
    CheckFile;
    IF DosError<>0 THEN
    BEGIN
      Env:=GetDOSEnvironment;
      Rest[0]:=#0;
      WHILE (Env^<>#0)AND(Rest[0]=#0) DO
      BEGIN
        Rest:=StrPas(Env);
        IF Pos('PATH',Rest)<>1 THEN
        BEGIN
          Inc(Env,StrLen(Env)+1);
          Rest[0]:=#0;
        END;
      END;
      Rest:=Rest+#0;
      Delete(Rest,1,5);
      WHILE Rest[0]>#0 DO
      BEGIN
        Path:=Copy(Rest,1,Pos(';',Rest)-1);
        IF Path[0]=#0 THEN Path:=Rest;
        IF Path[Length(Path)]<>'\' THEN Path:=Path+'\';
        Path:=Path+Name+#0;
        CheckFile;
        IF (DosError=0)OR(Pos(';',Rest)=0)
        THEN Rest[0]:=#0
        ELSE Delete(Rest,1,Pos(';',Rest));
      END;
    END;
    Dec(Path[0]);
    Name:=Path;
  END ELSE
  BEGIN
    Path:=Name+#0;
    CheckFile;
  END;
  FindDriver:=DosError=0;
END;

FUNCTION LoadNTDriver(DriverName:PChar):Bool;
VAR hSCManager:LongInt;
    Ok        :Bool;
    Status    :ARRAY[0..6]OF LongInt;
    Path      :STRING;
    Started   :Bool;
BEGIN
  IF (hDevice<>INVALID_HANDLE_VALUE)AND(hService<>0) THEN
  BEGIN
    LoadNTDriver:=True;
    Exit;
  END;
  Ok:=False;
  IF OS=Windows_NT THEN
  BEGIN
    hSCManager:=OpenSCManagerA(NIL,NIL,$000F003F);
    IF hSCManager=0 THEN Exit;
    Path:=StrPas(DriverName)+#0;
    IF FindDriver(Path) THEN
    BEGIN
      Path:=Path+#0;
      hService:=CreateServiceA(hSCManager,Names.Service,Names.Display,$000F01FF,1,3,1,
                               @Path[1],NIL,NIL,NIL,NIL,NIL);
    END ELSE
      hService:=CreateServiceA(hSCManager,Names.Service,Names.Display,$000F01FF,1,3,1,
                               DriverName,NIL,NIL,NIL,NIL,NIL);
    IF hService=0 THEN hService:=OpenServiceA(hSCManager,Names.Service,$000F01FF);
    IF hService<>0 THEN
    BEGIN
      Started:=StartServiceA(hService,0,NIL);
      IF NOT Started THEN Started:=GetLastError=1056; {ERROR_SERVICE_ALREADY_RUNNING}
      IF Started THEN
      BEGIN
        hDevice:=CreateFile(Names.Device,$C0000000,0,NIL,3,0,0);
        IF hDevice<>INVALID_HANDLE_VALUE
        THEN Ok:=True
        ELSE ControlService(hService,1,@Status);
      END;
      IF NOT Ok THEN
      BEGIN
        DeleteService(hService);
        CloseServiceHandle(hService);
        hService:=0;
      END;
    END;
    CloseServiceHandle(hSCManager);
  END;
  LoadNTDriver:=Ok;
END;

FUNCTION UnloadNTDriver(DriverName:PChar):Bool;
VAR Status:ARRAY[0..6]OF LongInt;
BEGIN
  UnloadNTDriver:=(hDevice<>INVALID_HANDLE_VALUE)AND(hService<>0);
  IF hDevice<>INVALID_HANDLE_VALUE THEN
  BEGIN
    CloseHandle(hDevice);
    hDevice:=INVALID_HANDLE_VALUE;
  END;
  IF hService<>0 THEN
  BEGIN
    ControlService(hService,1,@Status);
    DeleteService(hService);
    CloseServiceHandle(hService);
  END;
END;

BEGIN
  FillChar(DriverPath,SizeOf(DriverPath),0);
END.
