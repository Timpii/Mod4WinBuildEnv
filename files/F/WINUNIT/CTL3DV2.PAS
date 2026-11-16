UNIT Ctl3DV2;
{ Run-time binding to Microsoft's 3D controls library (CTL3DV2.DLL, falling
  back to CTL3D.DLL). Registers the module and enables automatic subclassing
  on load. Reconstructed from the compiled code in M4W_MCI.DLL; the procedure
  types follow the CTL3D API, identifier names are guesses. }
INTERFACE
USES WinTypes;

TYPE TCtl3dGetVer        = FUNCTION: Word;
     TCtl3dSubclassDlg   = FUNCTION(Wnd: HWnd; Flags: Word): Bool;
     TCtl3dSubclassCtl   = FUNCTION(Wnd: HWnd): Bool;
     TCtl3dCtlColor      = FUNCTION(DC: HDC; lParam: LongInt): HBrush;
     TCtl3dEnabled       = FUNCTION: Bool;
     TCtl3dColorChange   = FUNCTION: Bool;
     TCtl3dDlgFramePaint = FUNCTION(Wnd: HWnd; Msg, wParam: Word; lParam: LongInt): LongInt;
     TCtl3dRegister      = FUNCTION(Instance: THandle): Bool;
     TCtl3dUnregister    = FUNCTION(Instance: THandle): Bool;
     TCtl3dAutoSubclass  = FUNCTION(Instance: THandle): Bool;
     TCtl3dCtlColorEx    = FUNCTION(Msg, wParam: Word; lParam: LongInt): HBrush;

CONST Ctl3DAvailable    : Boolean             = True;
      Ctl3dGetVer       : TCtl3dGetVer        = NIL;
      Ctl3dSubclassDlg  : TCtl3dSubclassDlg   = NIL;
      Ctl3dSubclassCtl  : TCtl3dSubclassCtl   = NIL;
      Ctl3dCtlColor     : TCtl3dCtlColor      = NIL;
      Ctl3dEnabled      : TCtl3dEnabled       = NIL;
      Ctl3dColorChange  : TCtl3dColorChange   = NIL;
      Ctl3dDlgFramePaint: TCtl3dDlgFramePaint = NIL;
      Ctl3dRegister     : TCtl3dRegister      = NIL;
      Ctl3dUnregister   : TCtl3dUnregister    = NIL;
      Ctl3dAutoSubclass : TCtl3dAutoSubclass  = NIL;
      Ctl3dCtlColorEx   : TCtl3dCtlColorEx    = NIL;

IMPLEMENTATION
{ Objects and Win31 contribute no code. They are here because the unit link
  order of M4W_MCI.DLL requires Strings, OMemory and then Win31 to be
  compiled first; any ObjectWindows unit in place of Objects has the same
  effect. Which one the original used is unknown. }
USES WinProcs, Objects, Win31;

VAR hCtl3D  : THandle;
    OldMode : Word;
    SaveExit: Pointer;

PROCEDURE Ctl3DExit; FAR;
BEGIN
  ExitProc := SaveExit;
  IF Ctl3DAvailable THEN
  BEGIN
    Ctl3dUnregister(HInstance);
    FreeLibrary(hCtl3D);
  END;
END;

BEGIN
  SaveExit := ExitProc;
  ExitProc := @Ctl3DExit;
  OldMode := SetErrorMode($8001);
  hCtl3D := LoadLibrary('Ctl3dv2.dll');
  IF hCtl3D < 33 THEN hCtl3D := LoadLibrary('Ctl3d.dll');
  IF hCtl3D < 33 THEN Ctl3DAvailable := False
  ELSE
  BEGIN
    @Ctl3dGetVer        := GetProcAddress(hCtl3D, 'Ctl3DGetVer');
    @Ctl3dSubclassDlg   := GetProcAddress(hCtl3D, 'Ctl3DSubClassDlg');
    @Ctl3dSubclassCtl   := GetProcAddress(hCtl3D, 'Ctl3DSubClassCtl');
    @Ctl3dCtlColor      := GetProcAddress(hCtl3D, 'Ctl3DCtlColor');
    @Ctl3dDlgFramePaint := GetProcAddress(hCtl3D, 'Ctl3DDlgFramePaint');
    @Ctl3dEnabled       := GetProcAddress(hCtl3D, 'Ctl3DEnabled');
    @Ctl3dColorChange   := GetProcAddress(hCtl3D, 'Ctl3DColorChange');
    @Ctl3dRegister      := GetProcAddress(hCtl3D, 'Ctl3DRegister');
    @Ctl3dUnregister    := GetProcAddress(hCtl3D, 'Ctl3DUnregister');
    @Ctl3dAutoSubclass  := GetProcAddress(hCtl3D, 'Ctl3DAutoSubClass');
    @Ctl3dCtlColorEx    := GetProcAddress(hCtl3D, 'Ctl3DCtlColorEx');
  END;
  SetErrorMode(OldMode);
  IF Ctl3DAvailable THEN Ctl3dRegister(HInstance);
  IF Ctl3DAvailable THEN Ctl3dAutoSubclass(HInstance);
END.
