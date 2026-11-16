UNIT DragDet;
{ Initialization-only unit: looks up USER ordinal 465 (DragDetect) and sets a
  magic value. Reconstructed from the compiled code in PLAYER32.DLL (segment 2,
  between ValConv and NetDrv). No surviving source references it and nothing
  reads its results; the unit name and all identifiers are guesses. }
INTERFACE

IMPLEMENTATION
USES WinProcs;

CONST USER465: Pointer = NIL;
VAR   Magic: LongInt;

BEGIN
  USER465 := GetProcAddress(GetModuleHandle('USER'), PChar(465));
  Magic := $55921F30;
END.
