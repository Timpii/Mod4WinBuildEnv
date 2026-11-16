UNIT WOW32;
{ WOW32.DLL functions (16<->32-bit handle translation) called from 16-bit code
  through the generic thunks. Reconstructed from the compiled code in MOD4WIN.EXE.
  Only WOWHandle32 was linked into the binary; WOWHandle16 and WOWDirectedYield16
  are resolved by the init code, and their wrappers below follow the same pattern
  (not verifiable against the binary). Handle type values as in wownt32.h. }
INTERFACE

CONST WOW_TYPE_HWND      = 0;
      WOW_TYPE_HMENU     = 1;
      WOW_TYPE_HDWP      = 2;
      WOW_TYPE_HDROP     = 3;
      WOW_TYPE_HDC       = 4;
      WOW_TYPE_HFONT     = 5;
      WOW_TYPE_HMETAFILE = 6;
      WOW_TYPE_HRGN      = 7;
      WOW_TYPE_HBITMAP   = 8;
      WOW_TYPE_HBRUSH    = 9;
      WOW_TYPE_HPALETTE  = 10;
      WOW_TYPE_HPEN      = 11;
      WOW_TYPE_HACCEL    = 12;
      WOW_TYPE_HTASK     = 13;
      WOW_TYPE_FULLHWND  = 14;

{ 32-bit handle for a 16-bit one; returns Handle16 unchanged without Win32 }
FUNCTION  WOWHandle32(Handle16: Word; HandleType: Word): LongInt;
FUNCTION  WOWHandle16(Handle32: LongInt; HandleType: Word): Word;
PROCEDURE WOWDirectedYield16(hTask16: Word);

IMPLEMENTATION
USES W32Defs, W32Base;

CONST lWOWDirectedYield16: Pointer = NIL;
      lWOWHandle16       : Pointer = NIL;
      lWOWHandle32       : Pointer = NIL;

FUNCTION WOWHandle32(Handle16: Word; HandleType: Word): LongInt; ASSEMBLER;
ASM
  mov ax,Handle16
  DB 66h; cmp word ptr lWOWHandle32,0
  je @NoThunk
  push 0
  push Handle16
  push 0
  push HandleType
  DB 66h; push word ptr lWOWHandle32
  push 0
  push 0
  push 0
  push 2
  call dword ptr CallProc32W
  jmp @Exit
@NoThunk:
  xor dx,dx
@Exit:
END;

FUNCTION WOWHandle16(Handle32: LongInt; HandleType: Word): Word; ASSEMBLER;
ASM
  mov ax,word ptr Handle32
  DB 66h; cmp word ptr lWOWHandle16,0
  je @Exit
  DB 66h; push word ptr Handle32
  push 0
  push HandleType
  DB 66h; push word ptr lWOWHandle16
  push 0
  push 0
  push 0
  push 2
  call dword ptr CallProc32W
@Exit:
END;

PROCEDURE WOWDirectedYield16(hTask16: Word); ASSEMBLER;
ASM
  DB 66h; cmp word ptr lWOWDirectedYield16,0
  je @Exit
  push 0
  push hTask16
  DB 66h; push word ptr lWOWDirectedYield16
  push 0
  push 0
  push 0
  push 1
  call dword ptr CallProc32W
@Exit:
END;

BEGIN
  IF Win32Available THEN
  BEGIN
    lWOWHandle16       := Pointer(GetProcAddress32W(hWOW32, 'WOWHandle16'));
    lWOWHandle32       := Pointer(GetProcAddress32W(hWOW32, 'WOWHandle32'));
    lWOWDirectedYield16:= Pointer(GetProcAddress32W(hWOW32, 'WOWDirectedYield16'));
  END;
END.
