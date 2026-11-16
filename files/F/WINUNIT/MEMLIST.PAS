UNIT MemList;
{$C Fixed Preload Permanent}
{ Sorted list of fixed-size records kept in one global memory block.
  Reconstructed from the compiled code in PLAYER32.DLL. }
INTERFACE
USES WinTypes, WinProcs, Win31, Crc;

TYPE TSortProc = FUNCTION(Items: Pointer; dwUser: LongInt): Integer;
     pMemList = ^tMemList;
     tMemList = OBJECT
       MemSel   : Word;
       MemSize  : LongInt;
       Count    : LongInt;
       SortStart: LongInt;
       ItemLen  : Word;
       CONSTRUCTOR Init(aItemLen: Word);
       DESTRUCTOR Done; VIRTUAL;
       FUNCTION  GetMemSel: Word;
       FUNCTION  ReSize(NewSize: LongInt): Boolean;
       PROCEDURE Clear; VIRTUAL;
       FUNCTION  GetCount: LongInt;
       PROCEDURE CopyItem(SrcSel: Word; SrcOfs: LongInt; DstSel: Word; DstOfs: LongInt; Len: LongInt);
       PROCEDURE InsertItem(VAR Index: LongInt; VAR Item);
       FUNCTION  AddListItem(Sort: TSortProc; VAR Item; dwUser: LongInt): LongInt;
       FUNCTION  ObjVersion: Word; VIRTUAL;
       FUNCTION  ObjName: pChar; VIRTUAL;
     END;

IMPLEMENTATION

CONSTRUCTOR tMemList.Init(aItemLen: Word);
BEGIN
  ItemLen := aItemLen;
  MemSel := GlobalAlloc($2020, 1024);
  IF MemSel = 0 THEN Fail;
  MemSel := SelectorOf(GlobalLock(MemSel));
  MemSize := GlobalSize(MemSel);
  Count := 0;
  SortStart := 0;
END;

DESTRUCTOR tMemList.Done;
BEGIN
  IF MemSel <> 0 THEN
  BEGIN
    GlobalUnlock(MemSel);
    GlobalFree(MemSel);
  END;
END;

FUNCTION tMemList.GetMemSel: Word;
BEGIN
  GetMemSel := MemSel;
END;

FUNCTION tMemList.ReSize(NewSize: LongInt): Boolean;
VAR h: THandle;
BEGIN
  ReSize := False;
  IF NewSize < 1024 THEN NewSize := 1024;
  WHILE GlobalUnlock(MemSel) DO;
  h := GlobalReAlloc(MemSel, GlobalSize(MemSel), $82);
  h := GlobalReAlloc(h, NewSize, 2);
  h := GlobalReAlloc(h, GlobalSize(h), $2020);
  IF h = 0 THEN MemSel := SelectorOf(GlobalLock(MemSel))
  ELSE
  BEGIN
    MemSel := SelectorOf(GlobalLock(h));
    MemSize := GlobalSize(MemSel);
    IF MemSize DIV ItemLen < Count THEN Count := MemSize DIV ItemLen;
    ReSize := True;
  END;
END;

PROCEDURE tMemList.Clear;
BEGIN
  Count := 0;
  ReSize(0);
END;

FUNCTION tMemList.GetCount: LongInt;
BEGIN
  GetCount := Count;
END;

PROCEDURE tMemList.CopyItem(SrcSel: Word; SrcOfs: LongInt; DstSel: Word; DstOfs: LongInt; Len: LongInt); ASSEMBLER;
ASM
  push ds
  mov ds,DstSel
  mov es,SrcSel
  DB 66h; mov di,word ptr DstOfs
  DB 66h; mov si,word ptr SrcOfs
  DB 66h; mov bx,word ptr Len
  mov ax,ds
  mov cx,es
  cmp ax,cx
  jne @Back
  DB 66h; cmp si,di
  jb @Back
  DB 66h; add si,bx
  DB 66h; add di,bx
  DB 66h; neg bx
@Fwd:
  DB 67h,8Ah,04h,1Eh      { mov al,[esi+ebx] }
  DB 67h,88h,04h,1Fh      { mov [edi+ebx],al }
  DB 66h; inc bx
  jnz @Fwd
  jmp @Exit
@Back:
  DB 66h; dec bx
  DB 26h,67h,8Ah,04h,1Eh  { mov al,es:[esi+ebx] }
  DB 67h,88h,04h,1Fh      { mov [edi+ebx],al }
  jnz @Back
@Exit:
  pop ds
END;

PROCEDURE tMemList.InsertItem(VAR Index: LongInt; VAR Item);
BEGIN
  IF Index <= Count THEN
  BEGIN
    Inc(Count);
    IF MemSize DIV ItemLen < Count THEN
      IF NOT ReSize(MemSize + $4000) THEN
      BEGIN
        Index := -2;
        Exit;
      END;
    IF (Count > 1) AND (Count - 1 > Index) THEN
      CopyItem(MemSel, ItemLen * Index, MemSel, (Index + 1) * ItemLen, (Count - Index - 1) * ItemLen);
    CopyItem(Seg(Item), Ofs(Item), MemSel, ItemLen * Index, ItemLen);
  END;
END;

FUNCTION tMemList.AddListItem(Sort: TSortProc; VAR Item; dwUser: LongInt): LongInt;
VAR P: Pointer;
    Pos, Step, Hi, Lo: LongInt;
BEGIN
  IF @Sort <> NIL THEN
  BEGIN
    IF Count > SortStart THEN
    BEGIN
      GetMem(P, ItemLen * 2);
      IF P = NIL THEN
      BEGIN
        AddListItem := -1;
        Exit;
      END;
      CopyItem(Seg(Item), Ofs(Item), Seg(P^), Ofs(P^), ItemLen);
      Pos := Count - 1;
      Step := Count - SortStart;
      Hi := Count;
      Lo := SortStart;
      REPEAT
        CopyItem(MemSel, ItemLen * Pos, Seg(P^), Ofs(P^) + ItemLen, ItemLen);
        CASE Sort(P, dwUser) OF
          1: IF Count - 1 > Pos THEN
             BEGIN
               IF Pos > Lo THEN Lo := Pos;
               Inc(Pos, Step);
               IF Pos >= Hi THEN
               BEGIN
                 Pos := Hi;
                 Step := Step SHR 1;
               END;
             END
             ELSE
             BEGIN
               Step := 0;
               Pos := Count;
             END;
          -1: IF Pos > SortStart THEN
             BEGIN
               IF Pos < Hi THEN Hi := Pos;
               Dec(Pos, Step);
               IF Pos < Lo THEN
               BEGIN
                 Pos := Lo;
                 Step := Step SHR 1;
               END;
             END
             ELSE
             BEGIN
               Step := 0;
               Pos := SortStart;
             END;
          ELSE Step := 0;
        END;
      UNTIL Step = 0;
      FreeMem(P, ItemLen * 2);
    END
    ELSE Pos := Count;
    InsertItem(Pos, Item);
    AddListItem := Pos;
  END
  ELSE
  BEGIN
    Inc(Count);
    IF MemSize DIV ItemLen < Count THEN
      IF NOT ReSize(MemSize + $4000) THEN
      BEGIN
        AddListItem := -2;
        Exit;
      END;
    CopyItem(Seg(Item), Ofs(Item), MemSel, (Count - 1) * ItemLen, ItemLen);
    AddListItem := Count - 1;
  END;
END;

FUNCTION tMemList.ObjVersion: Word;
BEGIN
  ObjVersion := $100;
END;

FUNCTION tMemList.ObjName: pChar;
BEGIN
  ObjName := 'TSC_LLIST';
END;

END.
