UNIT oFarProc;
{ Callback thunks that call an object method with Self bound, usable as plain
  FAR callbacks (SetTimer, timeSetEvent, ...). Each thunk runs on a small private
  return stack, so it can be entered at interrupt time.
  Reconstructed from the compiled code in MOD4WIN.EXE; identifiers not used by
  the surviving sources are guesses. }
INTERFACE

{ Returns a FAR procedure address that calls Method with Obj pushed as Self }
FUNCTION  MakeObjProcInstance(Method, Obj: Pointer): Pointer;
{ Releases all thunks created for Obj }
PROCEDURE FreeObjProcInstances(Obj: Pointer);

IMPLEMENTATION
USES WinTypes, WinProcs, NoDOSMem;

CONST
  ThunkSize  = $87;
  ThunksPerBlock = 100;
  BlockSize  = 6 + ThunksPerBlock * ThunkSize;

  { Thunk code; offsets $05,$0A,$12,$26,$2B,$30,$35,$3D,$45,$55 are patched }
  Template: ARRAY[0..ThunkSize-1] OF Byte = (
    $8C,$DA,$8C,$D9,$B8,$00,$00,$8E,$D8,$B8,$00,$00,$8E,$C0,$FA,$26,
    $8B,$1E,$00,$00,$26,$89,$17,$83,$C3,$02,$66,$5A,$26,$66,$89,$17,
    $83,$C3,$04,$26,$89,$1E,$00,$00,$FB,$66,$68,$00,$00,$00,$00,$9A,
    $00,$00,$00,$00,$BB,$00,$00,$8E,$C3,$FA,$26,$8B,$1E,$00,$00,$83,
    $EB,$06,$26,$89,$1E,$00,$00,$26,$8B,$0F,$26,$66,$8B,$5F,$02,$FB,
    $8E,$D9,$66,$53,$CB,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
    $00,$00,$00,$00,$00,$00,$00);

  FirstBlock: Word = 0;

TYPE pBlock = ^tBlock;
     tBlock = RECORD
       Handle, CodeSel, Next: Word;
     END;

VAR SaveExit: Pointer;

FUNCTION MakeObjProcInstance(Method, Obj: Pointer): Pointer; ASSEMBLER;
VAR LastBlock: Word;
ASM
  mov ax,FirstBlock
@NextBlock:
  or ax,ax
  jne @Search
  mov LastBlock,es
  mov dx,BlockSize
  push 60h
  push 0
  push dx
  call GlobalAllocHigh
  xor dx,dx
  or ax,ax
  jne @Allocated
  jmp @Exit
@Allocated:
  push ax
  call GlobalLock
  cmp FirstBlock,0
  je @First
  mov es,LastBlock
  mov es:[4],dx
  jmp @Link
@First:
  mov FirstBlock,dx
@Link:
  mov LastBlock,dx
  mov es,dx
  mov es:[0],dx
  push dx
  call AllocDStoCSAlias
  mov es,LastBlock
  mov es:[2],ax
  mov ax,es
@Search:
  mov es,ax
  mov di,6
  mov cx,ThunksPerBlock
@Find:
  cmp word ptr es:[di+5],0
  je @Free
  add di,ThunkSize
  loop @Find
  mov ax,es:[4]
  jmp @NextBlock
@Free:
  mov bx,ThunkSize
@Copy:
  or bx,bx
  je @Copied
  dec bx
  mov al,byte ptr Template[bx]
  mov es:[bx+di],al
  jmp @Copy
@Copied:
  mov es:[di+5],ds
  mov es:[di+0Ah],es
  mov es:[di+35h],es
  mov ax,di
  add ax,55h
  mov es:[di+12h],ax
  mov es:[di+26h],ax
  mov es:[di+3Dh],ax
  mov es:[di+45h],ax
  add ax,2
  mov es:[di+55h],ax
  DB 66h; mov ax,word ptr Obj
  DB 66h; mov es:[di+2Bh],ax
  DB 66h; mov ax,word ptr Method
  DB 66h; mov es:[di+30h],ax
  mov dx,es:[2]
  mov ax,di
@Exit:
END;

PROCEDURE FreeObjProcInstances(Obj: Pointer); ASSEMBLER;
ASM
  mov dx,word ptr Obj
  mov bx,word ptr Obj+2
  mov ax,FirstBlock
@NextBlock:
  cmp ax,0
  je @Exit
  mov es,ax
  mov di,6
  mov cx,ThunksPerBlock
@Loop:
  cmp es:[di+2Bh],dx
  jne @Skip
  cmp es:[di+2Dh],bx
  jne @Skip
  mov word ptr es:[di+5],0
@Skip:
  add di,ThunkSize
  loop @Loop
  mov ax,es:[4]
  jmp @NextBlock
@Exit:
END;

PROCEDURE ObjProcExit; FAR;
VAR Sel: Word;
BEGIN
  ExitProc := SaveExit;
  Sel := FirstBlock;
  WHILE Sel <> 0 DO
    WITH pBlock(Ptr(Sel, 0))^ DO
    BEGIN
      Sel := Next;
      FreeSelector(CodeSel);
      GlobalUnlock(Handle);
      GlobalFree(Handle);
    END;
  FirstBlock := 0;
END;

BEGIN
  SaveExit := ExitProc;
  ExitProc := @ObjProcExit;
END.
