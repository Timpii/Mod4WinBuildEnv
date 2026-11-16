UNIT User32;
{ USER32.DLL functions without a Win16 equivalent, called from 16-bit code
  through the generic thunks. Reconstructed from the compiled code in MOD4WIN.EXE.
  Only SetWindowRgn and DrawCaption were linked into the binary; the init code
  also resolves the other USER32 functions listed below (their wrappers were not
  linked, so their declarations are not recoverable). }
INTERFACE
USES WinTypes, W32Defs;

CONST DC_ACTIVE   = $01;
      DC_SMALLCAP = $02;
      DC_ICON     = $04;
      DC_TEXT     = $08;
      DC_INBUTTON = $10;
      DC_GRADIENT = $20;

{ Handles are 32-bit (see WOW32.WOWHandle32) }
FUNCTION SetWindowRgn(hWnd32, hRgn32: LongInt; Redraw: Bool): Bool;
FUNCTION DrawCaption(hWnd32, hDC32: LongInt; R: pRect32; Flags: LongInt): Bool;

IMPLEMENTATION
USES W32Base;

CONST lSystemParametersInfoA: Pointer = NIL;
      lLoadStringA          : Pointer = NIL;
      lLoadIconA            : Pointer = NIL;
      lDrawIcon             : Pointer = NIL;
      lCopyIcon             : Pointer = NIL;
      lDestroyIcon          : Pointer = NIL;
      lGetIconInfo          : Pointer = NIL;
      lSetWindowRgn         : Pointer = NIL;
      lGetClassLongA        : Pointer = NIL;
      lGetWindowLongA       : Pointer = NIL;
      lDrawCaption          : Pointer = NIL;

FUNCTION SetWindowRgn(hWnd32, hRgn32: LongInt; Redraw: Bool): Bool; ASSEMBLER;
ASM
  DB 66h; cmp word ptr lSetWindowRgn,0
  je @NoThunk
  DB 66h; push word ptr hWnd32
  DB 66h; push word ptr hRgn32
  push 0
  push Redraw
  DB 66h; push word ptr lSetWindowRgn
  push 0
  push 0
  push 0
  push 3
  call dword ptr CallProc32W
  jmp @Exit
@NoThunk:
  xor ax,ax
@Exit:
END;

FUNCTION DrawCaption(hWnd32, hDC32: LongInt; R: pRect32; Flags: LongInt): Bool; ASSEMBLER;
ASM
  xor ax,ax
  DB 66h; cmp word ptr lDrawCaption,0
  je @Exit
  DB 66h; push word ptr hWnd32
  DB 66h; push word ptr hDC32
  DB 66h; push word ptr R
  DB 66h; push word ptr Flags
  DB 66h; push word ptr lDrawCaption
  push 0
  push 2          { translate the 16:16 rect pointer }
  push 0
  push 4
  call dword ptr CallProc32W
@Exit:
END;

BEGIN
  IF Win32Available THEN
  BEGIN
    lSystemParametersInfoA:= Pointer(GetProcAddress32W(hUser32, 'SystemParametersInfoA'));
    lLoadStringA          := Pointer(GetProcAddress32W(hUser32, 'LoadStringA'));
    lSetWindowRgn         := Pointer(GetProcAddress32W(hUser32, 'SetWindowRgn'));
    lLoadIconA            := Pointer(GetProcAddress32W(hUser32, 'LoadIconA'));
    lDrawIcon             := Pointer(GetProcAddress32W(hUser32, 'DrawIcon'));
    lCopyIcon             := Pointer(GetProcAddress32W(hUser32, 'CopyIcon'));
    lDestroyIcon          := Pointer(GetProcAddress32W(hUser32, 'DestroyIcon'));
    lGetIconInfo          := Pointer(GetProcAddress32W(hUser32, 'GetIconInfo'));
    lGetClassLongA        := Pointer(GetProcAddress32W(hUser32, 'GetClassLongA'));
    lGetWindowLongA       := Pointer(GetProcAddress32W(hUser32, 'GetWindowLongA'));
    lDrawCaption          := Pointer(GetProcAddress32W(hUser32, 'DrawCaption'));
  END;
END.
