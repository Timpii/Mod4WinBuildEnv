UNIT TrlVxD;
{$C Fixed Preload Permanent}
{ Interface to the TRLPLAY.VXD / TRLPLAY.386 helper VxD (Win 3.1 / Win 95).
  All calls go through the VxD's protected mode API entry point,
  function number in AX. Register based port routines (DX=port,
  AL/AX/EAX=data, ES:(E)SI/(E)DI + ECX for the string versions).
  Reconstructed from PLAYER32.DLL - unit and routine names are guesses. }
INTERFACE
USES WinTypes,GetOS,VxDLdr;

CONST VxDEntry:Pointer=NIL;
      VxDLoadedByLdr:Bool=False;

FUNCTION  VxDGetVersion:Word;
FUNCTION  VxDGrantPort(Port:Word):Word;
FUNCTION  VxDReleasePort(Port:Word):Word;
PROCEDURE VxDOutB;
PROCEDURE VxDOutW;
PROCEDURE VxDOutD;
PROCEDURE VxDInB;
PROCEDURE VxDInW;
PROCEDURE VxDInD;
PROCEDURE VxDOutSB;
PROCEDURE VxDOutSW;
PROCEDURE VxDOutSD;
PROCEDURE VxDInSB;
PROCEDURE VxDInSW;
PROCEDURE VxDInSD;
PROCEDURE VxDFlush(VAR Queue);
FUNCTION  LoadVxD(Name:PChar):Bool;
FUNCTION  UnloadVxD(Name:PChar):Bool;

IMPLEMENTATION

FUNCTION VxDGetVersion:Word; ASSEMBLER;
ASM
  mov ah,0
  mov al,0
  call dword ptr VxDEntry
END;

FUNCTION VxDGrantPort(Port:Word):Word; ASSEMBLER;
ASM
  mov ah,2
  mov al,0
  mov dx,Port
  call dword ptr VxDEntry
END;

FUNCTION VxDReleasePort(Port:Word):Word; ASSEMBLER;
ASM
  mov ah,2
  mov al,1
  mov dx,Port
  call dword ptr VxDEntry
END;

PROCEDURE VxDOutB; ASSEMBLER;
ASM
  DB 66h; push cx
  DB 66h; mov cx,ax
  mov ax,0300h
  call dword ptr VxDEntry
  DB 66h; pop cx
END;

PROCEDURE VxDOutW; ASSEMBLER;
ASM
  DB 66h; push cx
  DB 66h; mov cx,ax
  mov ax,0400h
  call dword ptr VxDEntry
  DB 66h; pop cx
END;

PROCEDURE VxDOutD; ASSEMBLER;
ASM
  DB 66h; push cx
  DB 66h; mov cx,ax
  mov ax,0500h
  call dword ptr VxDEntry
  DB 66h; pop cx
END;

PROCEDURE VxDInB; ASSEMBLER;
ASM
  mov ax,0600h
  call dword ptr VxDEntry
END;

PROCEDURE VxDInW; ASSEMBLER;
ASM
  mov ax,0700h
  call dword ptr VxDEntry
END;

PROCEDURE VxDInD; ASSEMBLER;
ASM
  mov ax,0800h
  call dword ptr VxDEntry
END;

PROCEDURE VxDOutSB; ASSEMBLER;
ASM
  mov ax,0900h
  call dword ptr VxDEntry
END;

PROCEDURE VxDOutSW; ASSEMBLER;
ASM
  mov ax,0A00h
  call dword ptr VxDEntry
END;

PROCEDURE VxDOutSD; ASSEMBLER;
ASM
  mov ax,0B00h
  call dword ptr VxDEntry
END;

PROCEDURE VxDInSB; ASSEMBLER;
ASM
  mov ax,0C00h
  call dword ptr VxDEntry
END;

PROCEDURE VxDInSW; ASSEMBLER;
ASM
  mov ax,0D00h
  call dword ptr VxDEntry
END;

PROCEDURE VxDInSD; ASSEMBLER;
ASM
  mov ax,0E00h
  call dword ptr VxDEntry
END;

PROCEDURE VxDFlush(VAR Queue); ASSEMBLER;
ASM
  DB 66h; xor di,di
  les di,Queue
  mov ax,0F00h
  call dword ptr VxDEntry
END;

FUNCTION LoadVxD(Name:PChar):Bool;
BEGIN
  LoadVxD:=False;
  IF OS=Windows_NT THEN Exit;
  IF OS=Windows_95 THEN VxDLoadedByLdr:=VxDLdrLoadDevice(Name);
  VxDEntry:=GetVxDEntryByName('TRLPLAY ');
  IF VxDEntry<>NIL THEN LoadVxD:=True;
END;

FUNCTION UnloadVxD(Name:PChar):Bool;
BEGIN
  IF VxDLoadedByLdr
  THEN UnloadVxD:=VxDLdrUnloadDevice(Name)
  ELSE UnloadVxD:=True;
END;

BEGIN
END.
