UNIT Crc;
{$C Fixed Preload Permanent}
{ CRC-16/CRC-32 table routines. Reconstructed from the compiled code in PLAYER32.DLL. }
INTERFACE

CONST CCT_PolyCRC16 = $8408;

{ CRC-16 (reflected polynomial $A001) over Len bytes at Sel:Ofs, starting with CRC value Start }
FUNCTION CalcBuf_CRC16(Start, Sel: Word; Ofs, Len: LongInt): Word;

IMPLEMENTATION

VAR CRC32Table: ARRAY[0..255] OF LongInt;
    CRC16Table: ARRAY[0..255] OF Word;

FUNCTION CalcBuf_CRC16(Start, Sel: Word; Ofs, Len: LongInt): Word; ASSEMBLER;
ASM
  push ds
  push es
  DB 66h; mov cx,word ptr Len
  DB 66h; or cx,cx
  jz @Exit
  mov ax,ds
  mov es,ax
  mov ax,Sel
  mov ds,ax
  DB 66h; mov si,word ptr Ofs
  mov ax,Start
  cld
@Loop:
  xor bh,bh
  mov bl,al
  DB 66h; lodsb
  xor bl,al
  shl bx,1
  mov bx,word ptr es:CRC16Table[bx]
  xor bl,ah
  mov ax,bx
  DB 66h; loop @Loop
@Exit:
  pop es
  pop ds
END;

PROCEDURE MakeCRC32Table;
VAR i, j: Integer;
    c: LongInt;
BEGIN
  FOR i := 0 TO 255 DO
  BEGIN
    c := i;
    FOR j := 8 DOWNTO 1 DO
      IF Boolean(c AND 1)
      THEN c := (c SHR 1) XOR $EDB88320
      ELSE c := c SHR 1;
    CRC32Table[i] := c;
  END;
END;

PROCEDURE MakeCRC16Table;
VAR i, j: Integer;
    c: Word;
BEGIN
  FOR i := 0 TO 255 DO
  BEGIN
    c := i;
    FOR j := 0 TO 7 DO
      IF Boolean(c AND 1)
      THEN c := (c SHR 1) XOR $A001
      ELSE c := c SHR 1;
    CRC16Table[i] := c;
  END;
END;

BEGIN
  MakeCRC32Table;
  MakeCRC16Table;
END.
