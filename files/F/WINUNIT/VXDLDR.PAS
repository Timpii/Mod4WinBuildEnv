UNIT VxDLdr;
{ Access to VxD API entry points (INT 2Fh/1684h) and to the VXDLDR
  device (ID 27h) for dynamic loading/unloading of VxDs.
  Reconstructed from PLAYER32.DLL - unit and routine names are guesses. }
INTERFACE
USES WinTypes;

CONST VxDLdrEntry:Pointer=NIL;

FUNCTION GetVxDEntryByName(Name:PChar):Pointer;
FUNCTION GetVxDEntryByID(ID:Word):Pointer;
FUNCTION VxDLdrLoadDevice(Name:PChar):Bool;
{Name with Seg(Name^)=0 means: Ofs(Name^) is the device ID}
FUNCTION VxDLdrUnloadDevice(Name:PChar):Bool;

IMPLEMENTATION

FUNCTION GetVxDEntryByName(Name:PChar):Pointer; ASSEMBLER;
ASM
  DB 66h; xor di,di
  les di,Name
  xor bx,bx
  mov ax,1684h
  int 2Fh
  mov ax,es
  or ax,di
  jnz @@1
  xor ax,ax
  xor dx,dx
  jmp @@2
@@1:
  mov ax,di
  mov dx,es
@@2:
END;

FUNCTION GetVxDEntryByID(ID:Word):Pointer; ASSEMBLER;
ASM
  xor di,di
  mov es,di
  mov bx,ID
  mov ax,1684h
  int 2Fh
  mov ax,es
  or ax,di
  jnz @@1
  xor ax,ax
  xor dx,dx
  jmp @@2
@@1:
  mov ax,di
  mov dx,es
@@2:
END;

FUNCTION VxDLdrLoadDevice(Name:PChar):Bool; ASSEMBLER;
VAR P:Pointer;
ASM
  DB 66h; cmp word ptr VxDLdrEntry,0
  je @@0
  DB 66h; cmp word ptr Name,0
  jne @@1
@@0:
  xor ax,ax
  jmp @@2
@@1:
  DB 66h; mov ax,word ptr VxDLdrEntry
  DB 66h; mov word ptr P,ax
  push ds
  lds dx,Name
  mov ax,1
  call dword ptr P
  pop ds
  jc @@0
  mov ax,1
@@2:
END;

FUNCTION VxDLdrUnloadDevice(Name:PChar):Bool; ASSEMBLER;
VAR P:Pointer;
ASM
  DB 66h; cmp word ptr VxDLdrEntry,0
  je @@0
  DB 66h; cmp word ptr Name,0
  jne @@1
@@0:
  xor ax,ax
  jmp @@3
@@1:
  DB 66h; mov ax,word ptr VxDLdrEntry
  DB 66h; mov word ptr P,ax
  push ds
  cmp word ptr Name+2,0
  je @@ID
  lds dx,Name
  mov bx,0FFFFh
  jmp @@2
@@ID:
  mov bx,word ptr Name
@@2:
  mov ax,2
  call dword ptr P
  pop ds
  jc @@0
  mov ax,1
@@3:
END;

BEGIN
  VxDLdrEntry:=GetVxDEntryByID($27);
END.
