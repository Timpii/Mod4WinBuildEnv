UNIT PrtLayer;
{$C Fixed Preload Permanent}
{ Port access layer for MOD4WIN's direct hardware support plus a simple
  timer service.  Direct port I/O under Windows 3.1/95 when no helper is
  available, TRLPLAY.VXD/.386 (Win 3.1/95) or TRLPLAY.SYS (NT) otherwise.
  All entry points are procedure variables that are redirected to the
  driver specific implementation during initialization.
  Reconstructed from PLAYER32.DLL. Only StartTimer/StopTimer are known by
  name (used by PLAY.INC); all other identifiers are guesses. }
{$F+}
INTERFACE
USES WinTypes,WinProcs,MMSystem,Task,GetOS,TrlVxD,TrlNT;

CONST pk_OutB=0;   {port queue item kinds}
      pk_OutW=1;
      pk_OutB2=2;
      pk_InB =3;
      pk_InW =4;
      pk_InD =5;
      MaxQueue=165;

TYPE tTimerFunc=FUNCTION:Word;           {returns next interval in ms, 0 = stop}
     tPortItem=RECORD
       Kind  :Word;
       Res1  :Word;
       Port  :Word;
       Res2  :Word;
       Value :LongInt;
     END;
     tPortQueue=RECORD
       Count:LongInt;
       Items:ARRAY[0..MaxQueue-1]OF tPortItem;
     END;

CONST PrtGetVersion :FUNCTION:Word=NIL;
      StartTimer    :FUNCTION(Proc:Pointer;Interval:Word):LongInt=NIL;
      StopTimer     :FUNCTION(ID:LongInt):Bool=NIL;
      GrantPort     :FUNCTION(Port:Word):Word=NIL;
      ReleasePort   :FUNCTION(Port:Word):Word=NIL;
      GrantPortList :FUNCTION(List:Pointer):Bool=NIL;
      SetPortWord   :FUNCTION(W:Word):Bool=NIL;
      {register based: DX=Port, AL/AX/EAX=Data}
      PortOutB_     :Pointer=NIL;
      PortOutW_     :Pointer=NIL;
      PortOutD_     :Pointer=NIL;
      PortInB_      :Pointer=NIL;
      PortInW_      :Pointer=NIL;
      PortInD_      :Pointer=NIL;
      {register based: DX=Port, ECX=Count, ES:ESI / ES:EDI=Buffer}
      PortOutSB_    :Pointer=NIL;
      PortOutSW_    :Pointer=NIL;
      PortOutSD_    :Pointer=NIL;
      PortInSB_     :Pointer=NIL;
      PortInSW_     :Pointer=NIL;
      PortInSD_     :Pointer=NIL;
      FlushQueue    :PROCEDURE=NIL;
      TimerCount    :Byte=0;
      NTLoaded      :Bool=False;
      VxDLoaded     :Bool=False;

VAR Queue:tPortQueue;

FUNCTION  PortInB(Port:Word):Byte;
FUNCTION  PortInW(Port:Word):Word;
FUNCTION  PortInD(Port:Word):LongInt;
PROCEDURE PortOutB(Port:Word;Value:Byte);
PROCEDURE PortOutW(Port:Word;Value:Word);

IMPLEMENTATION

TYPE tTimer=RECORD
       Proc:tTimerFunc;
       Next:LongInt;
     END;

VAR Timers  :ARRAY[1..32]OF tTimer;
    SaveExit:Pointer;

PROCEDURE ExecuteQueue;
VAR i:Word;
BEGIN
  IF Queue.Count>0 THEN
  BEGIN
    FOR i:=0 TO Queue.Count-1 DO WITH Queue.Items[i] DO
    CASE Kind OF
      pk_OutB :PortOutB(Port,LoWord(Value));
      pk_InB  :Value:=PortInB(Port);
      pk_OutW :PortOutW(Port,LoWord(Value));
      pk_InW  :Value:=PortInW(Port);
      pk_OutB2:PortOutB(Port,Byte(Value));
      pk_InD  :Value:=PortInD(Port);
    END;
  END;
  Queue.Count:=0;
END;

PROCEDURE FlushNT;
BEGIN
  IF Queue.Count>0 THEN NTFlush(@Queue);
  Queue.Count:=0;
END;

PROCEDURE FlushVxD;
BEGIN
  IF Queue.Count>0 THEN VxDFlush(Queue);
  Queue.Count:=0;
END;

PROCEDURE DirectOutB; ASSEMBLER;
ASM
  out dx,al
END;

PROCEDURE DirectOutW; ASSEMBLER;
ASM
  out dx,ax
END;

PROCEDURE DirectOutD; ASSEMBLER;
ASM
  DB 66h; out dx,ax
END;

PROCEDURE DirectInB; ASSEMBLER;
ASM
  in al,dx
END;

PROCEDURE DirectInW; ASSEMBLER;
ASM
  in ax,dx
END;

PROCEDURE DirectInD; ASSEMBLER;
ASM
  DB 66h; in ax,dx
END;

FUNCTION PortInB(Port:Word):Byte; ASSEMBLER;
ASM
  mov dx,Port
  call dword ptr PortInB_
END;

FUNCTION PortInW(Port:Word):Word; ASSEMBLER;
ASM
  mov dx,Port
  call dword ptr PortInW_
END;

FUNCTION PortInD(Port:Word):LongInt; ASSEMBLER;
ASM
  mov dx,Port
  call dword ptr PortInD_
  DB 66h; xor dx,dx
  DB 66h,0Fh,0A4h,0C2h,10h   {shld edx,eax,16}
END;

PROCEDURE PortOutB(Port:Word;Value:Byte); ASSEMBLER;
ASM
  mov dx,Port
  mov al,Value
  call dword ptr PortOutB_
END;

PROCEDURE PortOutW(Port:Word;Value:Word); ASSEMBLER;
ASM
  mov dx,Port
  mov ax,Value
  call dword ptr PortOutW_
END;

PROCEDURE DirectOutSB; ASSEMBLER;
ASM
  push ds
  push ax
  mov ax,es
  mov ds,ax
  pop ax
  DB 67h; rep outsb
  pop ds
END;

PROCEDURE DirectOutSW; ASSEMBLER;
ASM
  push ds
  push es
  pop ds
  DB 67h; rep outsw
  pop ds
END;

PROCEDURE DirectOutSD; ASSEMBLER;
ASM
  push ds
  push es
  pop ds
  DB 67h,66h; rep outsw
  pop ds
END;

PROCEDURE DirectInSB; ASSEMBLER;
ASM
  DB 67h; rep insb
END;

PROCEDURE DirectInSW; ASSEMBLER;
ASM
  DB 67h; rep insw
END;

PROCEDURE DirectInSD; ASSEMBLER;
ASM
  DB 67h,66h; rep insw
END;

FUNCTION DefGetVersion:Word;
BEGIN
  DefGetVersion:=$100;
END;

FUNCTION DefGrantPort(Port:Word):Word;
BEGIN
  DefGrantPort:=0;
END;

FUNCTION DefReleasePort(Port:Word):Word;
BEGIN
  DefReleasePort:=0;
END;

FUNCTION DefGrantPortList(List:Pointer):Bool;
BEGIN
  DefGrantPortList:=True;
END;

FUNCTION DefSetPortWord(W:Word):Bool;
BEGIN
  DefSetPortWord:=True;
END;

PROCEDURE TimerDispatch;
VAR i,R,Now:LongInt;
BEGIN
  IF TimerCount<>0 THEN
  BEGIN
    Now:=timeGetTime;
    FOR i:=1 TO 32 DO WITH Timers[i] DO
    IF (@Proc<>NIL)AND(Next<=Now) THEN
    BEGIN
      R:=Proc;
      IF R=0 THEN
      BEGIN
        @Proc:=NIL;
        Dec(TimerCount);
        IF TimerCount=0 THEN SetTaskProc(NIL);
      END ELSE Next:=timeGetTime+R;
    END;
  END;
END;

FUNCTION DefStartTimer(Proc:Pointer;Interval:Word):LongInt;
VAR i:LongInt;
BEGIN
  DefStartTimer:=0;
  IF Proc=NIL THEN Exit;
  IF Interval=0 THEN Exit;
  FOR i:=1 TO 32 DO
  IF @Timers[i].Proc=NIL THEN
  BEGIN
    IF TimerCount=0 THEN SetTaskProc(@TimerDispatch);
    Inc(TimerCount);
    @Timers[i].Proc:=Proc;
    Timers[i].Next:=timeGetTime+Interval;
    DefStartTimer:=i;
    Exit;
  END;
END;

FUNCTION DefStopTimer(ID:LongInt):Bool;
BEGIN
  DefStopTimer:=False;
  IF (TimerCount<>0)AND(ID>0)AND(ID<33)AND(@Timers[ID].Proc<>NIL) THEN
  BEGIN
    @Timers[ID].Proc:=NIL;
    Dec(TimerCount);
    IF TimerCount=0 THEN SetTaskProc(NIL);
    DefStopTimer:=True;
    Exit;
  END;
END;

PROCEDURE ExitPrtLayer;
BEGIN
  ExitProc:=SaveExit;
  IF NTLoaded THEN UnloadNTDriver('TRLPLAY');
  IF VxDLoaded THEN UnloadVxD('TRLPLAY');
END;

BEGIN
  FillChar(Timers,SizeOf(Timers),0);
  FillChar(Queue,SizeOf(Queue),0);
  @PrtGetVersion:=@DefGetVersion;
  @StartTimer   :=@DefStartTimer;
  @StopTimer    :=@DefStopTimer;
  @GrantPort    :=@DefGrantPort;
  @ReleasePort  :=@DefReleasePort;
  @GrantPortList:=@DefGrantPortList;
  @SetPortWord  :=@DefSetPortWord;
  PortOutB_     :=@DirectOutB;
  PortOutW_     :=@DirectOutW;
  PortOutD_     :=@DirectOutD;
  PortInB_      :=@DirectInB;
  PortInW_      :=@DirectInW;
  PortInD_      :=@DirectInD;
  PortOutSB_    :=@DirectOutSB;
  PortOutSW_    :=@DirectOutSW;
  PortOutSD_    :=@DirectOutSD;
  PortInSB_     :=@DirectInSB;
  PortInSW_     :=@DirectInSW;
  PortInSD_     :=@DirectInSD;
  @FlushQueue   :=@ExecuteQueue;
  IF OS=Windows_NT THEN
  BEGIN
    IF LoadNTDriver('TRLPLAY.SYS') THEN
    BEGIN
      NTLoaded:=True;
      @PrtGetVersion:=@NTGetVersion;
      @GrantPort    :=@NTGrantPort;
      @ReleasePort  :=@NTReleasePort;
      @GrantPortList:=@NTGrantPortList;
      @SetPortWord  :=@NTSetPortWord;
      PortOutB_     :=@NTOutB;
      PortOutW_     :=@NTOutW;
      PortOutD_     :=@NTOutD;
      PortInB_      :=@NTInB;
      PortInW_      :=@NTInW;
      PortInD_      :=@NTInD;
      PortOutSB_    :=@NTOutSB;
      PortOutSW_    :=@NTOutSW;
      PortOutSD_    :=@NTOutSD;
      PortInSB_     :=@NTInSB;
      PortInSW_     :=@NTInSW;
      PortInSD_     :=@NTInSD;
      @FlushQueue   :=@FlushNT;
    END;
  END ELSE
  IF (OS=Windows_95)OR(OS=Windows_31) THEN
  BEGIN
    IF LoadVxD('TRLPLAY.VXD') THEN
    BEGIN
      VxDLoaded:=True;
      @PrtGetVersion:=@VxDGetVersion;
      @GrantPort    :=@VxDGrantPort;
      @ReleasePort  :=@VxDReleasePort;
      PortOutB_     :=@VxDOutB;
      PortOutW_     :=@VxDOutW;
      PortOutD_     :=@VxDOutD;
      PortInB_      :=@VxDInB;
      PortInW_      :=@VxDInW;
      PortInD_      :=@VxDInD;
      PortOutSB_    :=@VxDOutSB;
      PortOutSW_    :=@VxDOutSW;
      PortOutSD_    :=@VxDOutSD;
      PortInSB_     :=@VxDInSB;
      PortInSW_     :=@VxDInSW;
      PortInSD_     :=@VxDInSD;
      @FlushQueue   :=@FlushVxD;
    END;
  END;
  SaveExit:=ExitProc;
  ExitProc:=@ExitPrtLayer;
END.
