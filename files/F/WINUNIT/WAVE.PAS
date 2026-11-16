UNIT Wave;
{ Writes .WAV files for direct-to-disk recording. Reconstructed from the compiled
  code in PLAYER32.DLL (2.30's WAVE.PAS moved onto FILE32 handles). }
INTERFACE
{$I-}
USES WinTypes, WinProcs, MMSystem, WinDos, W32Defs, File32, ValConv;

TYPE tSign4=ARRAY[1..4]OF Char;
     tSign8=ARRAY[1..8]OF Char;
     pWaveFileHeader=^tWaveFileHeader;
     tWaveFileHeader=RECORD
                       RIFF_Sign    :tSign4;
                       RIFF_Len     :Longint;
                       WAVEfmt_Sign :tSign8;
                       WAVEfmt_Len  :Longint;
                       WaveFmt      :tPCMWaveFormat;
                       DATA_Sign    :tSign4;
                       DATA_Len     :Longint;
                     END;

FUNCTION CreateWaveFile(aFile:pChar; NamesOEM:Bool; MaxSize:Longint; VAR Is32:Bool):Handle32;
FUNCTION WriteWaveFile(hFile:Handle32; Is32:Bool; Sel:Word; FirstByte,LastByte:Longint):Bool;
{ SmplChunk: optional 60-byte 'smpl' chunk appended after the data, or NIL }
FUNCTION CloseWaveFile(hFile:Handle32; Is32:Bool; SampleRate,Bits,NumChannels:Longint; SmplChunk:Pointer):Bool;

IMPLEMENTATION

CONST sRIFF   :tSign4='RIFF';
      sWAVEfmt:tSign8='WAVEfmt ';
      sDATA   :tSign4='data';
      sSMPL   :tSign4='smpl';
      Unknown1:Word=0;        { unidentified; no linked code references it }

FUNCTION CreateWaveFile(aFile:pChar; NamesOEM:Bool; MaxSize:Longint; VAR Is32:Bool):Handle32;
VAR hFile:Handle32;
    Buf:ARRAY[1..SizeOf(tWaveFileHeader)]OF Char;
BEGIN
  CreateWaveFile:=INVALID_HANDLE_VALUE;
  IF (aFile=NIL)OR(aFile^=#0) THEN Exit;
  IF (aFile[1]=':')AND(DiskFree(Ord(UpCase(aFile^))-64)<MaxSize) THEN Exit;
  hFile:=_lCreat32(aFile,NamesOEM,$20,0,@Is32);
  IF hFile=INVALID_HANDLE_VALUE THEN Exit
  ELSE _lWrite32(hFile,Is32,@Buf,SizeOf(tWaveFileHeader));
  CreateWaveFile:=hFile;
END;

FUNCTION WriteWaveFile(hFile:Handle32; Is32:Bool; Sel:Word; FirstByte,LastByte:Longint):Bool;
VAR i:Word;
    StartTime:Longint;
    OldCursor:hCursor;
BEGIN
  WriteWaveFile:=False;
  IF (hFile=INVALID_HANDLE_VALUE)OR NOT IsValidSelector(Sel)OR(LastByte<=FirstByte) THEN Exit;
  StartTime:=TimeGetTime;
  OldCursor:=0;
  WHILE LastByte>FirstByte DO
  BEGIN
    IF (OldCursor=0)AND(TimeGetTime-StartTime>250) THEN OldCursor:=SetCursor(LoadCursor(0,IDC_Wait));
    IF LastByte-FirstByte>$2000 THEN i:=$2000 ELSE i:=LastByte-FirstByte;
    i:=_lWrite32(hFile,Is32,Long2Ptr(Sel,FirstByte),i);
    IF (i=$FFFF)OR(i=0) THEN Exit;
    Inc(FirstByte,i);
    Yield;
  END;
  IF OldCursor<>0 THEN SetCursor(OldCursor);
  WriteWaveFile:=True;
END;

FUNCTION CloseWaveFile(hFile:Handle32; Is32:Bool; SampleRate,Bits,NumChannels:Longint; SmplChunk:Pointer):Bool;
VAR pWaveHeader:pWaveFileHeader;
    FSize:Longint;
BEGIN
  CloseWaveFile:=False;
  IF hFile=INVALID_HANDLE_VALUE THEN Exit;
  FSize:=_lSize32(hFile,Is32);
  pWaveHeader:=New(pWaveFileHeader);
  WITH pWaveHeader^ DO
  BEGIN
    RIFF_Sign    :=sRIFF;
    RIFF_Len     :=FSize-8;
    WAVEfmt_Sign :=sWAVEfmt;
    WAVEfmt_Len  :=16;
    WITH Wavefmt,wf DO
    BEGIN
      wFormatTag       :=wave_Format_PCM;
      nChannels        :=NumChannels;
      nSamplesPerSec   :=SampleRate;
      nAvgBytesPerSec  :=SampleRate*NumChannels*(Bits SHR 3);
      nBlockAlign      :=(Bits SHR 3)*NumChannels;
      wBitsPerSample   :=Bits;
    END;
    DATA_Sign    :=sDATA;
    DATA_Len     :=FSize-SizeOf(tWaveFileHeader);
  END;
  IF SmplChunk<>NIL THEN pWaveHeader^.RIFF_Len:=pWaveHeader^.RIFF_Len+60+8;
  _lSeekAbs32(hFile,Is32,0);
  _lWrite32(hFile,Is32,pWaveHeader,SizeOf(tWaveFileHeader));
  IF SmplChunk<>NIL THEN
  BEGIN
    _lSeek32(hFile,Is32,pWaveHeader^.RIFF_Len-60,0);
    _lWrite32(hFile,Is32,@sSMPL,4);
    FSize:=60;
    _lWrite32(hFile,Is32,@FSize,4);
    _lWrite32(hFile,Is32,SmplChunk,60);
  END;
  _lClose32(hFile,Is32);
  Dispose(pWaveHeader);
  CloseWaveFile:=True;
END;

END.
