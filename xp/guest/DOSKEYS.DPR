{ DOSKEYS: drives an interactive DOS program from a script, inside the XP
  guest (see docs/WINXP.md). The program runs in DOSKEYS's own console;
  DOSKEYS reads that console's text (which XP's DOS subsystem keeps up to
  date) and writes keystrokes into its input, where the DOS program reads its
  keyboard from. Each step waits for the screen to show what's expected, so
  nothing depends on timing.

  Usage: DOSKEYS SCRIPT LOGFILE      (exit code 0: done; 1: failed, see log)

  Script lines (blank lines and lines starting with ; are skipped):
    cd DIR             working directory for run
    run COMMAND        starts the DOS program in this console
    wait TEXT          waits until a screen line contains TEXT (runs of
                       spaces count as one; a trailing $ anchors TEXT to the
                       end of the line); fails after the time limit
    limit SECONDS      the time limit for the following waits (default 300,
                       times the host's slowness factor in %SLOW%)
    key NAME ...       ENTER ESC TAB UP DOWN F9
    type TEXT          types TEXT
    answer TEXT|KEY    from now on, whenever a screen line contains TEXT,
                       presses KEY (for prompts that may or may not come)
    fail TEXT          from now on, fails as soon as a screen line, or the
                       end of the watched file, contains TEXT (for prompts
                       nobody should answer)
    watch FILE         the file whose end fail also looks at (the log a
                       redirected program writes its prompts to)
  A DOS program's error box ("16 bit MS-DOS Subsystem") fails at once too.
    done               waits until the program has ended (answering prompts
                       meanwhile)

  Compiled in the guest with Delphi 2.01: dcc32 -CC DOSKEYS.DPR }
program DOSKEYS;

{$APPTYPE CONSOLE}

uses Windows;

type
  { the Win32 INPUT_RECORD for a key event (Delphi 2's TKeyEventRecord puts
    dwControlKeyState one byte off) }
  TKeyInput = packed record
    EventType, Reserved: Word;
    KeyDown: BOOL;
    RepeatCount, VirtualKey, ScanCode, Character: Word;
    ControlKeyState: DWORD;
  end;
  TBufferInfo = packed record
    SizeX, SizeY, CursorX, CursorY, Attributes: SmallInt;
    Left, Top, Right, Bottom: SmallInt;
    MaxX, MaxY: SmallInt;
  end;

function WriteConsoleInputA(Input: THandle; const Buffer; Count: DWORD;
  var Written: DWORD): BOOL; stdcall; external 'kernel32.dll';
function ReadConsoleOutputCharacterA(Output: THandle; Buffer: PChar;
  Length: DWORD; Coord: DWORD; var Read: DWORD): BOOL; stdcall; external 'kernel32.dll';
function GetConsoleScreenBufferInfo(Output: THandle;
  var Info: TBufferInfo): BOOL; stdcall; external 'kernel32.dll';

const
  ShiftPressed = $10;
  EnhancedKey = $100;

var
  Log: Text;
  Serial: THandle;
  Process: TProcessInformation;
  Started: Boolean;
  Dir: string;
  WaitLimit: Integer;     { milliseconds }
  Answers: array[1..8] of record
    Pattern, Key: string;
    Showing: Boolean;
  end;
  AnswerCount: Integer;
  Fails: array[1..8] of string;
  FailCount: Integer;
  Watched: string;

{ the log, also on COM1 (the host sees that while the guest runs) }
procedure Say(const S: string);
var
  Written: DWORD;
  Line: string;
begin
  WriteLn(Log, S);
  Flush(Log);
  if Serial <> INVALID_HANDLE_VALUE then
  begin
    Line := 'DOSKEYS: ' + S + #13#10;
    WriteFile(Serial, Line[1], Length(Line), Written, nil);
  end;
end;

function OpenConsole(const Name: string): THandle;
begin
  Result := CreateFile(PChar(Name), GENERIC_READ or GENERIC_WRITE,
    FILE_SHARE_READ or FILE_SHARE_WRITE, nil, OPEN_EXISTING, 0, 0);
end;

{ the visible screen, one normalized line per entry }
function Screen: string;
var
  Out: THandle;
  Info: TBufferInfo;
  Line: array[0..255] of Char;
  Y, X, Width: Integer;
  Read: DWORD;
  S: string;
  Space: Boolean;
begin
  Result := '';
  Out := OpenConsole('CONOUT$');     { the active buffer, which may change }
  if GetConsoleScreenBufferInfo(Out, Info) then
  begin
    Width := Info.SizeX;
    if Width > 256 then Width := 256;
    for Y := Info.Top to Info.Bottom do
    begin
      Read := 0;
      ReadConsoleOutputCharacterA(Out, Line, Width, DWORD(Y) shl 16, Read);
      S := '';
      Space := True;
      for X := 0 to Integer(Read) - 1 do
        if (Line[X] > ' ') and (Line[X] < #127) then
        begin
          S := S + Line[X];
          Space := False;
        end
        else if not Space then
        begin
          S := S + ' ';
          Space := True;
        end;
      if (S <> '') and (S[Length(S)] = ' ') then SetLength(S, Length(S) - 1);
      Result := Result + S + #13#10;
    end;
  end;
  CloseHandle(Out);
end;

function Normalize(const S: string): string;
var
  I: Integer;
begin
  Result := '';
  for I := 1 to Length(S) do
    if (S[I] <> ' ') or ((Result <> '') and (Result[Length(Result)] <> ' ')) then
      Result := Result + S[I];
end;

{ does a line of the screen contain Pattern ($ at its end: at the line's end)? }
function Shows(const Pattern: string): Boolean;
var
  Text, Line, P: string;
  AtEnd: Boolean;
  I: Integer;
begin
  P := Normalize(Pattern);
  AtEnd := (P <> '') and (P[Length(P)] = '$');
  if AtEnd then SetLength(P, Length(P) - 1);
  Text := Screen;
  Result := False;
  while Text <> '' do
  begin
    I := Pos(#13#10, Text);
    Line := Copy(Text, 1, I - 1);
    Delete(Text, 1, I + 1);
    I := Pos(P, Line);
    if (I > 0) and (not AtEnd or (I + Length(P) - 1 = Length(Line))) then
    begin
      Result := True;
      Exit;
    end;
  end;
end;

procedure Fail(const Why: string);
begin
  Say('FAILED: ' + Why);
  Say('--- screen ---');
  Say(Screen);
  if Started then TerminateProcess(Process.hProcess, 1);
  Close(Log);
  Halt(1);
end;

procedure SendKey(VirtualKey: Word; Character: Char; State: DWORD);
var
  Input: THandle;
  Rec: array[0..1] of TKeyInput;
  Written: DWORD;
begin
  FillChar(Rec, SizeOf(Rec), 0);
  Rec[0].EventType := KEY_EVENT;
  Rec[0].KeyDown := True;
  Rec[0].RepeatCount := 1;
  Rec[0].VirtualKey := VirtualKey;
  Rec[0].ScanCode := MapVirtualKey(VirtualKey, 0);
  Rec[0].Character := Ord(Character);
  Rec[0].ControlKeyState := State;
  Rec[1] := Rec[0];
  Rec[1].KeyDown := False;
  Input := OpenConsole('CONIN$');
  WriteConsoleInputA(Input, Rec, 2, Written);
  CloseHandle(Input);
  Sleep(50);
end;

procedure NamedKey(const Name: string);
begin
  if Name = 'ENTER' then SendKey(VK_RETURN, #13, 0)
  else if Name = 'ESC' then SendKey(VK_ESCAPE, #27, 0)
  else if Name = 'TAB' then SendKey(VK_TAB, #9, 0)
  else if Name = 'UP' then SendKey(VK_UP, #0, EnhancedKey)
  else if Name = 'DOWN' then SendKey(VK_DOWN, #0, EnhancedKey)
  else if Name = 'F9' then SendKey(VK_F9, #0, 0)
  else Fail('unknown key ' + Name);
end;

procedure TypeText(const S: string);
var
  I: Integer;
  Scan: SmallInt;
  State: DWORD;
begin
  for I := 1 to Length(S) do
  begin
    Scan := VkKeyScan(S[I]);
    State := 0;
    if Hi(Scan) and 1 <> 0 then State := ShiftPressed;
    SendKey(Lo(Scan), S[I], State);
  end;
end;

{ the last 2 KB of the watched file (shared: the program is writing it) }
function WatchedTail: string;
var
  H: THandle;
  Size, Got: DWORD;
begin
  Result := '';
  if Watched = '' then Exit;
  H := CreateFile(PChar(Watched), GENERIC_READ, FILE_SHARE_READ or FILE_SHARE_WRITE,
    nil, OPEN_EXISTING, 0, 0);
  if H = INVALID_HANDLE_VALUE then Exit;
  Size := GetFileSize(H, nil);
  if Size > 2048 then SetFilePointer(H, Size - 2048, nil, FILE_BEGIN);
  if Size > 2048 then Size := 2048;
  SetLength(Result, Size);
  if (Size > 0) and ReadFile(H, Result[1], Size, Got, nil) then SetLength(Result, Got)
  else Result := '';
  CloseHandle(H);
end;

{ fails if the screen or the watched file shows one of the fail patterns,
  or if NTVDM shows its error box (a crashed or stuck DOS program) }
procedure CheckFails;
var
  I: Integer;
  Tail: string;
begin
  if FindWindow(nil, '16 bit MS-DOS Subsystem') <> 0 then
    Fail('the DOS program stopped with an error box ("16 bit MS-DOS Subsystem")');
  if FailCount = 0 then Exit;
  Tail := WatchedTail;
  for I := 1 to FailCount do
    if Shows(Fails[I]) or (Pos(Fails[I], Tail) > 0) then
      Fail('the program asks "' + Fails[I] + '"');
end;

{ waits for Pattern, then until the screen has settled (the program may
  still be drawing, and programs often clear pending keys before a prompt) }
procedure Wait(const Pattern: string);
var
  Waited: Integer;
  Before: string;
begin
  Waited := 0;
  while not Shows(Pattern) do
  begin
    if WaitForSingleObject(Process.hProcess, 0) = WAIT_OBJECT_0 then
      Fail('the program ended while waiting for "' + Pattern + '"');
    CheckFails;
    if Waited >= WaitLimit then Fail('timed out waiting for "' + Pattern + '"');
    Sleep(200);
    Inc(Waited, 200);
  end;
  repeat
    Before := Screen;
    Sleep(500);
  until Screen = Before;
  Say('saw: ' + Pattern);
end;

procedure Run(const Command: string);
var
  Startup: TStartupInfo;
begin
  FillChar(Startup, SizeOf(Startup), 0);
  Startup.cb := SizeOf(Startup);
  if Dir = '' then GetDir(0, Dir);
  if not CreateProcess(nil, PChar(Command), nil, nil, False, 0, nil,
    PChar(Dir), Startup, Process) then
    Fail('could not start ' + Command);
  Started := True;
  Say('started: ' + Command);
end;

procedure Done;
var
  Waited, I: Integer;
begin
  Waited := 0;
  while WaitForSingleObject(Process.hProcess, 500) <> WAIT_OBJECT_0 do
  begin
    CheckFails;
    for I := 1 to AnswerCount do
      with Answers[I] do
        if Shows(Pattern) then
        begin
          if not Showing then
          begin
            Say('answering "' + Pattern + '" with ' + Key);
            NamedKey(Key);
          end;
          Showing := True;
        end
        else Showing := False;
    Inc(Waited, 500);
    if Waited >= WaitLimit then Fail('the program didn''t end');
  end;
  Started := False;
  Say('ended');
end;

var
  Script: Text;
  Line, Command, Arg, Name: string;
  I, Err: Integer;
begin
  { 5 minutes, times SLOW (1, or 10 on hosts without virtualisation) }
  WaitLimit := 300000;
  Line := '';
  SetLength(Line, 16);
  SetLength(Line, GetEnvironmentVariable('SLOW', PChar(Line), 16));
  Val(Line, I, Err);
  if (Err = 0) and (I > 0) then WaitLimit := WaitLimit * I;
  Serial := CreateFile('COM1', GENERIC_WRITE, 0, nil, OPEN_EXISTING, 0, 0);
  Assign(Log, ParamStr(2));
  Rewrite(Log);
  Assign(Script, ParamStr(1));
  Reset(Script);
  while not Eof(Script) do
  begin
    ReadLn(Script, Line);
    if (Line = '') or (Line[1] = ';') then Continue;
    I := Pos(' ', Line + ' ');
    Command := Copy(Line, 1, I - 1);
    Arg := Copy(Line, I + 1, Length(Line));
    if Command = 'cd' then Dir := Arg
    else if Command = 'run' then Run(Arg)
    else if Command = 'limit' then Val(Arg + '000', WaitLimit, I)
    else if Command = 'wait' then Wait(Arg)
    else if Command = 'type' then TypeText(Arg)
    else if Command = 'done' then Done
    else if (Command = 'answer') and (Pos('|', Arg) > 0) and (AnswerCount < 8) then
    begin
      Inc(AnswerCount);
      Answers[AnswerCount].Pattern := Copy(Arg, 1, Pos('|', Arg) - 1);
      Answers[AnswerCount].Key := Copy(Arg, Pos('|', Arg) + 1, Length(Arg));
      Answers[AnswerCount].Showing := False;
    end
    else if Command = 'watch' then Watched := Arg
    else if (Command = 'fail') and (Arg <> '') and (FailCount < 8) then
    begin
      Inc(FailCount);
      Fails[FailCount] := Arg;
    end
    else if Command = 'key' then
    begin
      Arg := Arg + ' ';
      while Arg <> '' do
      begin
        I := Pos(' ', Arg);
        Name := Copy(Arg, 1, I - 1);
        Delete(Arg, 1, I);
        if Name <> '' then NamedKey(Name);
      end;
    end
    else Fail('unknown script line: ' + Line);
  end;
  Close(Script);
  Say('OK');
  Close(Log);
end.
