UNIT Coroner;
{ Coroner revision linked into the shipped M4W_MCI.DLL (2006). Rebuilt from
  that binary: it lies between the 2.30 and 2.31 sources in old_versions.zip
  (exception-major message table, four message languages, PChar error title,
  AddCriticalSeg as a function, exception 0 ignored). The original file is lost;
  it must have been on the unit path ahead of the project root, because
  M4W_MCI\MAKE.BAT compiles from PLAYER\, while PLAYER32.DLL and MOD4WIN.EXE,
  compiled from the root, use the root's coroner.pas.
  Guessed: the result type of AddCriticalSeg and the enumeration's length. }
{$C Fixed Preload Permanent}
{ $DEFINE Debug}
INTERFACE
USES ToolHelp,WinProcs,WinTypes;

CONST CriticalExit:PROCEDURE=NIL; {Works like ExitProc...just for Critical Sections that
                                   have to be cleaned up before terminating...}
      CatchBuf:pCatchBuf=NIL;
      {String to display if an Error occurs}
      CriticalErrorName:PChar='The program has been closed.'+#0;

{Adds Owner of the given Selector to our App Exception Handler}
FUNCTION AddCriticalSeg(NewSeg:Word):WordBool;

TYPE  tCoronerLang=(c_ger,c_usa,c_fre,c_spa,c_grk,c_ita);
CONST CoronerLanguage:tCoronerLang=c_USA;

IMPLEMENTATION
CONST Coroning:Boolean=False; {For ReEntrance}
      CriticalDataSegs:ARRAY[0..15]OF Word=(0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0); {up to 16 Owners (DLL's,EXE's)
                                                               to check on Faults}
VAR GE:tGlobalEntry;
    ME:tModuleEntry;
    MainTask:Word;
    i:Longint;
    Proc:PROCEDURE;
    ErrorName:pChar;

FUNCTION AddCriticalSeg(NewSeg:Word):WordBool;
BEGIN
  AddCriticalSeg:=False;
  IF NewSeg=0 THEN Exit;
  FOR i:=0 TO 15 DO IF CriticalDataSegs[i]=0 THEN
  BEGIN
    ge.dwSize:=SizeOf(ge);
    GlobalEntryHandle(@ge,NewSeg);
    CriticalDataSegs[i]:=ge.hOwner;
    AddCriticalSeg:=True;
    Exit;
  END;
END;

VAR ERRORString,FaultName:ARRAY[0..512]OF Char;
    ERRARR:RECORD
      ExptModule:pChar;
      ExptLogSeg:Word;
      ExptLogOfs:Word;
    END;
PROCEDURE DoExit(FaultSeg,FaultOfs,Exception:Word);
BEGIN
  IF (Exception=0)OR(Exception=3)OR(Exception>14)THEN Exit;
  ge.dwSize:=SizeOf(ge);
  IF (NOT GlobalEntryHandle(@ge,FaultSeg))OR(ge.wType<>GT_Code) THEN Exit;
  me.dwSize:=SizeOf(me);
  IF ModuleFindHandle(@me,ge.hOwner)=0 THEN Exit;
  lstrcpy(FaultName,me.szModule);
  FOR i:=0 TO 15 DO IF CriticalDataSegs[i]=ge.hOwner THEN
  BEGIN
    ErrorName:='An error has occured...'+#0;
    CASE Exception OF
     0:CASE CoronerLanguage OF
         c_USA,c_ITA,c_SPA:ErrorName:='We tried to divide something by zero in module %s at address [%04X:%04X]!'+#0;
         c_GRK:ErrorName:='Προσπαθήσαμε να διαιρέσουμε κάτι με μηδέν στο module %s και διεύθυνση [%04X:%04X]!'+#0;
         c_FRE:ErrorName:='Division par zero dans le module %s a l''adresse [%04X:%04X]!'+#0;
         c_GER:ErrorName:='Wir haben in %s bei [%04X:%04X] versucht, etwas durch NULL zu teilen!'+#0;
        END;
     6:CASE CoronerLanguage OF
         c_USA,c_ITA,c_SPA:ErrorName:='We tried to execute an invalid opcode in module %s at address [%04X:%04X]!'+#0;
         c_GRK:ErrorName:='Προσπαθήσαμε να εκτελέσουμε άκυρο opcode στο module %s και διεύθυνση [%04X:%04X]!'+#0;
         c_FRE:ErrorName:='Execution d''un opcode invalide dans le module %s a l''adresse [%04X:%04X]!'+#0;
         c_GER:ErrorName:='Wir wollten in %s bei [%04X:%04X] einen ungόltigen Opcode ausfόhren!'+#0;
        END;
    12:CASE CoronerLanguage OF
         c_USA,c_ITA,c_SPA:ErrorName:='We caused a memory stack overflow in module %s at address [%04X:%04X]!'+#0;
         c_GRK:ErrorName:='Προκαλέσαμε υπερχείλιση στοίβας στη μνήμη στο module %s και διεύθυνση [%04X:%04X]!'+#0;
         c_FRE:ErrorName:='Depassement de pile memoire dans le module %s a l''adresse [%04X:%04X]!'+#0;
         c_GER:ErrorName:='Wir verursachten in %s bei [%04X:%04X] einen Stapelspeicherόberlauf!'+#0;
        END;
    13:CASE CoronerLanguage OF
         c_USA,c_ITA,c_SPA:ErrorName:='We accessed memory we didn''t actually own in module %s at address [%04X:%04X]!'+#0;
         c_GRK:ErrorName:='Προσπελάσαμε μνήμη που δε μας ανήκε στο module %s και διεύθυνση [%04X:%04X]!'+#0;
         c_FRE:ErrorName:='Acces a de la memoire deja reservee dans le module %s a l''adresse [%04X:%04X]!'+#0;
         c_GER:ErrorName:='Wir griffen in %s bei [%04X:%04X] auf Speicher zu, der nicht uns gehφrt!'+#0;
        END;
    14:CASE CoronerLanguage OF
         c_USA,c_ITA,c_SPA:ErrorName:='We caused a memory page fault in module %s at address [%04X:%04X]!'+#0;
         c_GRK:ErrorName:='Προκαλέσαμε memory page fault στο module %s και διεύθυνση [%04X:%04X]!'+#0;
         c_FRE:ErrorName:='Erreur de page memoire dans le module %s a l''adresse [%04X:%04X]!'+#0;
         c_GER:ErrorName:='Wir verursachten einen Seitenfehler in %s bei [%04X:%04X]!'+#0;
        END;
      ELSE Exit;
    END;
    ERRARR.ExptModule:=@FaultName;
    ERRARR.ExptLogSeg:=ge.wData;
    ERRARR.ExptLogOfs:=FaultOfs;
    wvsprintf(@ERRORString,ErrorName,ErrArr);
    WHILE @CriticalExit<>NIL DO
    BEGIN
      @Proc:=@CriticalExit;
      @CriticalExit:=NIL;
      Proc;
      IF CatchBuf<>NIL THEN Break;
    END;
    MessageBox(0,CriticalErrorName,@ERRORString,mb_systemModal OR mb_IconStop);
    IF CatchBuf=NIL THEN
    BEGIN
      IF GetCurrentTask<>MainTask THEN TerminateApp(MainTask,NO_UAE_BOX);
      TerminateApp(0,NO_UAE_BOX);
    END ELSE
    BEGIN
      PostAppMessage(MainTask,WM_Quit,0,0);
      Throw(CatchBuf^,1);
    END;
  END;
END;

PROCEDURE DoCoroner; EXPORT; ASSEMBLER;
ASM
  pusha
  push es
  cmp coroning,0
  jne @Out
  mov coroning,1
  push word Ptr ss:[bp+$0E] {Fault-CS}
  push word Ptr ss:[bp+$0C] {Fault-IP}
  push word Ptr ss:[bp+$08] {Fault-ERROR}
  Call DoExit
  mov coroning,0
@Out:
  pop es
  popa
END;

VAR OrgExitProc:Pointer;
    CoronerProc:tIntCallBack;
PROCEDURE ExitDll; FAR;
BEGIN
  ExitProc:=OrgExitProc;
  IF NOT Coroning THEN
  BEGIN
    InterruptUnregister(0);
    FreeProcInstance(@CoronerProc);
  END;
END;

{$IFNDEF Debug}

BEGIN
  OrgExitProc:=ExitProc;
  ExitProc:=@ExitDLL;
  @CoronerProc:=MakeProcInstance(@DoCoroner,hInstance);
  InterruptRegister(0,CoronerProc);
  AddCriticalSeg(hInstance);
  MainTask:=GetCurrentTask;
{$ENDIF}

END.
