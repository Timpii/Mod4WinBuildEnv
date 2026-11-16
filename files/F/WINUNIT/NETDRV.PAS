UNIT NetDrv;
{ Network-driver probe. Reconstructed from the compiled code in PLAYER32.DLL
  (segment 2, between ValConv and the end of the segment). No surviving source
  references this unit and nothing in PLAYER32.DLL reads its results, so the
  unit name and all identifiers are guesses. }
INTERFACE
USES WinTypes;

VAR FirstDrive: PChar;     { 'A:' under Windows 3.1, otherwise DefaultFirstDrive }
    NetPresent: Boolean;   { a network driver answered WNetGetCaps(WNNC_DRIVER_VERSION) }

{ USER.WNetGetCaps (ordinal 513), 0 if not available }
FUNCTION WNetGetCaps(Index: Word): Word;

IMPLEMENTATION
USES WinProcs, GetOS;

{ Unidentified: 88 zero bytes of typed constants precede sDriveA in the data
  segment of PLAYER32.DLL (possibly 22 pointers). No linked code references them. }
CONST Unknown2         : ARRAY[0..87] OF Byte = (
        0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
        0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0);
      sDriveA          : ARRAY[0..3] OF Char = 'A:'#0#0;
      DefaultFirstDrive: PChar = NIL;
      lWNetGetCaps     : Pointer = NIL;

FUNCTION WNetGetCaps(Index: Word): Word; ASSEMBLER;
ASM
  xor ax,ax
  DB 66h; cmp word ptr lWNetGetCaps,0
  je @Exit
  push Index
  call dword ptr lWNetGetCaps
@Exit:
END;

BEGIN
  lWNetGetCaps := GetProcAddress(GetModuleHandle('USER'), PChar(513));
  NetPresent := WNetGetCaps(2) <> 0;
  IF OS = Windows_31
  THEN FirstDrive := @sDriveA
  ELSE FirstDrive := DefaultFirstDrive;
END.
