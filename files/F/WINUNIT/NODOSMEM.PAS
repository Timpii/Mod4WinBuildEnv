UNIT NoDOSMem;
{ GlobalAlloc that avoids conventional (DOS) memory: all free DOS memory is
  reserved with GlobalDOSAlloc for the duration of the allocation.
  Reconstructed from the compiled code in MOD4WIN.EXE; the unit name and all
  identifiers are guesses (no surviving source references this unit). }
INTERFACE
USES WinTypes, WinProcs;

PROCEDURE ReserveDOSMem;
PROCEDURE FreeDOSMem;
FUNCTION  GlobalAllocHigh(Flags: Word; Size: LongInt): THandle;

IMPLEMENTATION

VAR DOSBlocks: Word;   { selector of the first reserved block; chain via word at offset 0 }

PROCEDURE ReserveDOSMem; ASSEMBLER;
ASM
  cmp DOSBlocks,0
  jne @Exit
  push 0
  push 1000h
  call GlobalDOSAlloc
  or ax,ax
  je @Exit
  mov DOSBlocks,ax
@Loop:
  push ax
  push 0
  push 1000h
  call GlobalDOSAlloc
  pop es
  mov es:[0],ax
  or ax,ax
  jne @Loop
@Exit:
END;

PROCEDURE FreeDOSMem; ASSEMBLER;
ASM
  mov ax,DOSBlocks
  mov DOSBlocks,0
@Loop:
  or ax,ax
  je @Exit
  mov es,ax
  push word ptr es:[0]
  push ax
  call GlobalDOSFree
  pop ax
  jmp @Loop
@Exit:
END;

FUNCTION GlobalAllocHigh(Flags: Word; Size: LongInt): THandle; ASSEMBLER;
ASM
  cmp DOSBlocks,0
  jne @Plain
  call ReserveDOSMem
  push Flags
  DB 66h; mov ax,word ptr Size
  DB 66h; push ax
  call GlobalAlloc
  push ax
  call FreeDOSMem
  pop ax
  or ax,ax
  jne @Exit
@Plain:
  push Flags
  DB 66h; mov ax,word ptr Size
  DB 66h; push ax
  call GlobalAlloc
@Exit:
END;

BEGIN
  DOSBlocks := 0;
END.
