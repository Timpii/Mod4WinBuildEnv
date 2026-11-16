UNIT ValConv;
{ Pointer/string helpers. Reconstructed from the compiled code in PLAYER32.DLL;
  names of routines not referenced by the surviving sources are guesses. }
INTERFACE
USES WinTypes;

{ Sel:L as a huge pointer (L may exceed 64K) }
FUNCTION Long2Ptr(Sel: Word; L: LongInt): Pointer;
{ True if Sel is a valid selector (LSL succeeds) }
FUNCTION IsValidSelector(Sel: Word): Bool;
{ Case-insensitive (ASCII) compare: 0 = equal, 1 = S1>S2, -1 = S1<S2 }
FUNCTION UpStrComp(S1, S2: PChar): Integer;
{ Pointer to the Count-th occurrence of C, counted from the end of S }
FUNCTION StrRScanCounted(S: PChar; C: Char; Count: Word): PChar;

IMPLEMENTATION
USES WinProcs, Strings, NetDrv, DragDet;


FUNCTION Long2Ptr(Sel: Word; L: LongInt): Pointer; ASSEMBLER;
ASM
  mov ax,word ptr L+2
  mul SelectorInc
  mov dx,Sel
  add dx,ax
  mov ax,word ptr L
END;

FUNCTION UpStrComp(S1, S2: PChar): Integer; ASSEMBLER;
ASM
  push ds
  lds si,S1
  les di,S2
  xor ax,ax
@Loop:
  mov bl,[si]
  mov bh,es:[di]
  or bx,bx
  je @Exit
  or bl,bl
  je @Less
  or bh,bh
  je @Greater
  cmp bl,'a'
  jb @1
  cmp bl,'z'
  ja @1
  sub bl,20h
@1:
  cmp bh,'a'
  jb @2
  cmp bh,'z'
  ja @2
  sub bh,20h
@2:
  cmp bl,bh
  ja @Greater
  jb @Less
  inc di
  inc si
  jmp @Loop
@Greater:
  mov ax,1
  jmp @Exit
@Less:
  mov ax,-1
@Exit:
  pop ds
END;

FUNCTION IsValidSelector(Sel: Word): Bool; ASSEMBLER;
ASM
  DB 66h; xor bx,bx
  mov bx,Sel
  DB 66h; lsl cx,bx
  jnz @Invalid
  mov ax,1
  jmp @Exit
@Invalid:
  xor ax,ax
@Exit:
END;

FUNCTION StrRScanCounted(S: PChar; C: Char; Count: Word): PChar; ASSEMBLER;
ASM
  DB 66h; cmp word ptr S,0
  jne @Search
@NotFound:
  mov ax,word ptr S
  mov dx,word ptr S+2
  jmp @Exit
@Search:
  DB 66h; push word ptr S
  call StrLen
  or ax,ax
  je @NotFound
  mov dx,Count
  or dx,dx
  je @NotFound
  mov cx,ax
  dec cx
  mov bl,C
  les si,S
  add si,cx
@Loop:
  cmp es:[si],bl
  jne @Next
  dec dx
  je @Found
@Next:
  or cx,cx
  je @Found
  dec si
  dec cx
  jmp @Loop
@Found:
  mov dx,es
  mov ax,si
@Exit:
END;

END.
