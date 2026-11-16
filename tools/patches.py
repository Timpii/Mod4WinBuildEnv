"""Source changes. The original build machine's changes in Borland's library
sources (see docs/BUILD_TOOLS.md): setup.sh puts the patched files on the
tools disk, and the guest copies them over the installed ones before
rebuilding. And, optionally, the shipped revision of two project files.

usage: patches.py bp SRC OUT       Borland Pascal 7.01's run-time library:
                                   SRC holds MAKEFILE, STRINGS.PAS, WIN31.PAS,
                                   WINDOS.PAS, OMEMORY.PAS, OWINDOWS.PAS,
                                   CRT.ASM and CRT.PAS as on the RTL disk
       patches.py delphi SRC OUT   Delphi 2.01's System: SRC holds MAKEFILE,
                                   HALT.ASM and OPENFILE.ASM from SOURCE\\RTL;
                                   OUT also gets ASMRTL.BAT, which assembles
                                   the System modules with Turbo Assembler 3.2
       patches.py maths SRC OUT    the Maths unit (F:\\WINUNIT): SRC holds the
                                   2.31 MATHS.PAS from old_versions.zip,
                                   made into the revision the 2.40 binaries
                                   contain (docs/MISSING_UNITS.md; build.sh)
       patches.py getos SRC OUT    the GetOS unit (F:\\WINUNIT): SRC holds the
                                   repository's M4W_MCI\\GETOS.PAS, made into
                                   the revision the 2006 binaries contain
                                   (docs/MISSING_UNITS.md; build.sh)
       patches.py shipped SRC OUT  the staged project (F:\\MOD4WIN; OUT may
                                   be SRC) as the shipped MOD4WIN.EXE was
                                   built from it: REGDLG.PAS
                                   without the empty ELSE branch, RLINK with
                                   -31 (build.sh with SHIPPED=1;
                                   docs/BIT_EXACT.md)
"""
import os
import re
import sys

FIXED = '{$C Fixed Preload Permanent}\r\n'


def edit(src, out, name, edits):
    with open(os.path.join(src, name), 'rb') as f:
        s = f.read().decode('latin-1')
    for old, new in edits:
        if s.count(old) != 1:
            sys.exit('patches: unexpected source in %s (%r)' % (name, old[:40]))
        s = s.replace(old, new)
    with open(os.path.join(out, name), 'wb') as f:
        f.write(s.encode('latin-1'))


def bp(src, out):
    # TASM without -e (no FPU-emulation padding in System); the project's
    # switches for the Windows units and ObjectWindows, $G+ for the DOS units
    edit(src, out, 'MAKEFILE', [
        ('BPCD = $(BPC) -t -cd -e$(TPU) -q\r\n', 'BPCD = $(BPC) -t -cd -e$(TPU) -q -$g+\r\n'),
        ('-q -$g-\r\n', '-q -$g+ -$s- -$w- -$v- -$i-\r\n'),
        (' $(TASM) -e -i$(INC) $*,$*.obj', ' $(TASM) -i$(INC) $*,$*.obj'),
        (' $(TASM) -e -i$(INC) -d_Windows_ ', ' $(TASM) -i$(INC) -d_Windows_ '),
        (' $(TASM) -e -i$(INC) -d_DPMI_ ', ' $(TASM) -i$(INC) -d_DPMI_ '),
        (' -$F+,S- buildowl', ' -$g+ -$s- -$w- -$v- -$i- -$k- -t$(BIN) buildowl'),
    ])
    # fixed code segments
    for name, unit in (('STRINGS.PAS', 'Strings'), ('WIN31.PAS', 'Win31'),
                       ('WINDOS.PAS', 'WinDos'), ('OMEMORY.PAS', 'OMemory')):
        edit(src, out, name, [('unit %s;\r\n' % unit, 'unit %s;\r\n' % unit + FIXED)])
    # TWindow.SetupWindow first moves the window to Attr.X/Y/W/H
    edit(src, out, 'OWINDOWS.PAS', [
        ('procedure TWindow.SetupWindow;\r\nbegin\r\n  TWindowsObject.SetupWindow;\r\n',
         'procedure TWindow.SetupWindow;\r\nbegin\r\n'
         '  MoveWindow(HWindow, Attr.X, Attr.Y, Attr.W, Attr.H, False);\r\n'
         '  TWindowsObject.SetupWindow;\r\n'),
    ])
    # the Runtime Error 200 fix, recovered from the shipped CHECKSUM.EXE: a
    # 32-bit DelayCnt (the first interface variable), calibrated by a multiply
    # instead of the 16-bit DIV that overflows on fast CPUs, with all
    # interrupts but the timer masked while it measures
    edit(src, out, 'CRT.PAS', [
        ('{ Interface variables }\r\n\r\n',
         '{ Interface variables }\r\n\r\n  DelayCnt: Longint;\r\n'),
    ])
    edit(src, out, 'CRT.ASM', [
        ('\tEXTRN\tSegB000:WORD,SegB800:WORD\r\n',
         '\tEXTRN\tSegB000:WORD,SegB800:WORD\r\n\tEXTRN\tDelayCnt:WORD\r\n'),
        ('DelayCnt\tDW\t?\r\n', ''),
        ('\tMOV\tDI,OFFSET Timer\r\n',
         '\tMOV\tDI,OFFSET Timer\r\n\tIN\tAL,21H\r\n\tPUSH\tAX\r\n'
         '\tMOV\tAL,0FEH\r\n\tOUT\t21H,AL\r\n'),
        ('\tMOV\tCX,55\r\n\tDIV\tCX\r\n\tMOV\tDelayCnt,AX\r\n',
         '\tXCHG\tDX,CX\r\n\tMOV\tBX,1193\r\n\tMUL\tBX\r\n\tXCHG\tCX,DX\r\n'
         '\tXCHG\tAX,DX\r\n\tMUL\tBX\r\n\tADD\tAX,CX\r\n\tADC\tDX,0\r\n'
         '\tMOV\tDelayCnt,AX\r\n\tMOV\tDelayCnt+2,DX\r\n\tPOP\tAX\r\n\tOUT\t21H,AL\r\n'),
        ('@@1:\tMOV\tAX,DelayCnt\r\n\tXOR\tDX,DX\r\n',
         '@@1:\tMOV\tAX,DelayCnt\r\n\tMOV\tDX,DelayCnt+2\r\n'),
    ])


def delphi(src, out):
    # Turbo Assembler 3.2 (the makefile wants TASM32 4.0+) writes 16-bit
    # fixups for external data declared outside a segment, which DCC32
    # rejects; a .DATA line before the first EXTRN avoids that, same code
    for name in ('HALT.ASM', 'OPENFILE.ASM'):
        with open(os.path.join(src, name), 'rb') as f:
            s = f.read().decode('latin-1')
        s, n = re.subn(r'(?m)^([ \t]*EXTRN)', '\t.DATA\r\n\\1', s, count=1)
        if n != 1:
            sys.exit('patches: unexpected source in ' + name)
        with open(os.path.join(out, name), 'wb') as f:
            f.write(s.encode('latin-1'))
    # the System modules (SYSTEMOBJ in the makefile), for TASM 3.2 in RTL\
    with open(os.path.join(src, 'MAKEFILE'), 'rb') as f:
        mk = f.read().decode('latin-1').replace('\r', '')
    block = re.search(r'^SYSTEMOBJ = (.*?)\n\n', mk, re.M | re.S)
    mods = re.findall(r'sys\\[a-z0-9]+', block.group(1), re.I) if block else []
    if not mods:
        sys.exit('patches: no SYSTEMOBJ list in the Delphi makefile')
    with open(os.path.join(out, 'ASMRTL.BAT'), 'wb') as f:
        for m in mods:
            f.write(('E:\\BP\\TASM -zn -m3 -t -w- -isys %s,%s.obj\r\n' % (m, m)).encode())


def maths(src, out):
    # 2.40's lg is the FPU version (2.31 had it as _lg, its Pascal version as
    # lg), and the unit's initialization runs finit
    fpu = ('ASM\r\n  fld1\r\n  fld x\r\n  fyl2x\r\n  fldl2t\r\n'
           '  fdivp st(1),st\r\nEND;\r\n')
    edit(src, out, 'MATHS.PAS', [
        ('FUNCTION lg(x:Double):Double; BEGIN lg:=ln(x)/ln(10); END;\r\n'
         'FUNCTION _lg(x:Double):Double;ASSEMBLER;\r\n' + fpu,
         'FUNCTION lg(x:Double):Double;ASSEMBLER;\r\n' + fpu +
         'FUNCTION _lg(x:Double):Double; BEGIN _lg:=ln(x)/ln(10); END;\r\n'),
        ('{$ENDIF}\r\nBEGIN\r\n{$IFDEF DEBUG}\r\n',
         '{$ENDIF}\r\nBEGIN\r\n{$IFNDEF DEBUG}\r\n  ASM finit END;\r\n{$ENDIF}\r\n'
         '{$IFDEF DEBUG}\r\n'),
    ])


GETOS_NOTE = (
    '{ The GetOS revision compiled into the shipped 2006 binaries (PLAYER32.DLL,\r\n'
    '  MOD4WIN.EXE, M4W_MCI.DLL, INSTALL.EXE), reconstructed from their code.\r\n'
    '  It differs from M4W_MCI\\GETOS.PAS in two places:\r\n'
    '  - FreeLibrary32W is neither resolved nor called (KERNEL32 stays loaded);\r\n'
    '  - the initialization ends by forcing OS:=Windows_NT and ExOS:=Ex_NewWin,\r\n'
    '    overriding the detected values on every Windows version.\r\n'
    '  The 1999 binaries (M4W240HW.ZIP) do not have the forced ending.\r\n'
    '  See MISSING_UNITS.md. }\r\n')


def getos(src, out):
    # the 2006 revision: fixed segment, no FreeLibrary32W (KERNEL32 stays
    # loaded), and the initialization forces NT on every Windows version
    edit(src, out, 'GETOS.PAS', [
        ('UNIT GetOS;\r\n',
         'UNIT GetOS;\r\n{$C Fixed Preload Permanent}\r\n' + GETOS_NOTE),
        ('    lFreeLibrary32W    :TFreeLibrary32W;\r\n', ''),
        ("  @lFreeLibrary32W   :=GetProcAddress(hKrnl16,'FreeLibrary32W');\r\n", ''),
        ('    lFreeLibrary32W(hKrnl32);\r\n', ''),
        ('    END;\r\n  END;\r\nEND.',
         '    END;\r\n  END;\r\n  OS:=Windows_NT;\r\n  ExOS:=Ex_NewWin;\r\nEND.'),
    ])


def shipped(src, out):
    # the shipped MOD4WIN.EXE has no empty ELSE branch in TRegWin.WMCommand,
    # and the original RLINK marked programs as Windows 3.10 by default
    edit(src, out, 'REGDLG.PAS', [
        ('        RegCloseKey (Key);\r\n      END ELSE BEGIN\r\n'
         '        { can\'t create key }\r\n      END;\r\n',
         '        RegCloseKey (Key);\r\n      END;\r\n'),
    ])
    edit(src, out, os.path.join('CUSTOM', 'MAKE.BAT'), [
        ('rlink MOD4WIN.FXE\r\n', 'rlink -31 MOD4WIN.FXE\r\n'),
        ('rlink -feFULL', 'rlink -31 -feFULL'),
    ])


def bigmem(src, out):
    # the player's memory blocks (samples, patterns) from unit HugeMem on
    # every Windows version, as on Windows 3.1/95, instead of one 16-bit
    # global block, which can't grow past 16 MB - 64 KB
    edit(src, out, os.path.join('PLAYER', 'playdefs.pas'), [
        ('  {$IFDEF HUGEMEM}\r\n  IF OS<>WINDOWS_NT THEN\r\n  BEGIN\r\n    FitGlobalMem:=False;\r\n',
         '  {$IFDEF HUGEMEM}\r\n  IF True THEN\r\n  BEGIN\r\n    FitGlobalMem:=False;\r\n'),
    ])
    # Windows NT's DPMI server for 16-bit programs has only about 15 MB, so
    # on NT (and Wine) HugeMem takes its memory from VirtualAlloc instead and
    # puts the same tiled selectors over it; Windows 3.1/95 keep DPMI
    names = ['GetFreeHugeMem:Longint;ASSEMBLER;',
             'DPMIAlloc(Size:Longint;VAR Mem:tDPMIMem): Word;  ASSEMBLER;',
             'DPMIFree(VAR Mem:tDPMiMem): Word;  ASSEMBLER;',
             'DPMIReAlloc(NewSize:Longint;VAR Mem:tDPMIMem): Word;  ASSEMBLER;',
             'DPMILock(Mem:tDPMIMem):Word;ASSEMBLER;',
             'DPMIUnLock(Mem:tDPMIMem):Word;ASSEMBLER;']
    # (the same in both copies of the unit: SOURCE\HUGEMEM.PAS, which
    # PLAYER32.DLL gets, and PLAYER\HUGEMEM.PAS, which M4W_MCI.DLL gets)
    for hm in ('HUGEMEM.PAS', os.path.join('PLAYER', 'HUGEMEM.PAS')):
        edit(src, out, hm,
             [('\r\nIMPLEMENTATION\r\n', '\r\nIMPLEMENTATION\r\n{$IFDEF WINDOWS}\r\nUSES WinProcs, W32Base;\r\n{$ENDIF}\r\n')] +
             [('\r\nFUNCTION ' + n, '\r\nFUNCTION ' + n.replace('(', '0(', 1).replace(':Longint;ASSEMBLER', '0:Longint;ASSEMBLER'))
              for n in names] +
             [('\r\nfunction MakeLong(A, B: Word): LongInt;', '\r\n' + HUGEMEM_WIN32.replace('\n', '\r\n') +
               'function MakeLong(A, B: Word): LongInt;')])


HUGEMEM_WIN32 = """{ BIGMEM=1: on Windows NT and Wine the memory comes from Win32 }
{$IFDEF WINDOWS}
CONST pVirtualAlloc:LongInt=0;
      pVirtualFree :LongInt=0;
      pMoveMemory  :LongInt=0;
      pMemStatus   :LongInt=0;
      Win32Tried   :Boolean=False;

{ CallProc32W with up to four dword arguments; Mask: 16:16 pointers to
  translate (bit 0 = the last argument) }
FUNCTION Call32(Proc,A,B,C,D:LongInt;N,Mask:Word):LongInt;ASSEMBLER;
ASM
  DB 66h; push word ptr A
  cmp N,1
  je @call
  DB 66h; push word ptr B
  DB 66h; push word ptr C
  cmp N,3
  je @call
  DB 66h; push word ptr D
@call:
  DB 66h; push word ptr Proc
  push 0; push Mask
  push 0; push N
  call dword ptr CallProc32W
END;

FUNCTION Win32Mem:Boolean;
VAR hK:LongInt;
BEGIN
  IF NOT Win32Tried THEN
  BEGIN
    Win32Tried:=True;
    IF (GetWinFlags AND $4000<>0)AND(CallProc32W<>NIL) THEN
    BEGIN
      hK:=LoadLibraryEx32W('KERNEL32.DLL',0,0);
      IF hK<>0 THEN
      BEGIN
        pVirtualAlloc:=GetProcAddress32W(hK,'VirtualAlloc');
        pVirtualFree :=GetProcAddress32W(hK,'VirtualFree');
        pMoveMemory  :=GetProcAddress32W(hK,'RtlMoveMemory');
        pMemStatus   :=GetProcAddress32W(hK,'GlobalMemoryStatus');
      END;
    END;
  END;
  Win32Mem:=(pVirtualAlloc<>0)AND(pVirtualFree<>0)AND(pMoveMemory<>0)AND(pMemStatus<>0);
END;
{$ELSE}
CONST pVirtualAlloc=0; pVirtualFree=0; pMoveMemory=0; pMemStatus=0;
FUNCTION Call32(Proc,A,B,C,D:LongInt;N,Mask:Word):LongInt; BEGIN Call32:=0; END;
FUNCTION Win32Mem:Boolean; BEGIN Win32Mem:=False; END;
{$ENDIF}

FUNCTION GetFreeHugeMem:Longint;
VAR MS:ARRAY[0..7]OF LongInt;
BEGIN
  IF NOT Win32Mem THEN BEGIN GetFreeHugeMem:=GetFreeHugeMem0; Exit; END;
  MS[0]:=SizeOf(MS);
  Call32(pMemStatus,LongInt(@MS),0,0,0,1,1);
  GetFreeHugeMem:=MS[7]; { dwAvailVirtual }
END;

FUNCTION DPMIAlloc(Size:Longint;VAR Mem:tDPMIMem):Word;
BEGIN
  IF NOT Win32Mem THEN BEGIN DPMIAlloc:=DPMIAlloc0(Size,Mem); Exit; END;
  DPMIAlloc:=8;
  Mem.LinAddr:=Call32(pVirtualAlloc,0,Size,$3000,4,4,0);
  IF Mem.LinAddr=0 THEN Exit;
  Mem.hMem:=Mem.LinAddr;
  Mem.Size:=Size;
  DPMIAlloc:=0;
END;

FUNCTION DPMIFree(VAR Mem:tDPMIMem):Word;
BEGIN
  IF NOT Win32Mem THEN BEGIN DPMIFree:=DPMIFree0(Mem); Exit; END;
  IF Mem.LinAddr<>0 THEN Call32(pVirtualFree,Mem.LinAddr,0,$8000,0,3,0);
  Mem.LinAddr:=0;
  Mem.hMem:=0;
  DPMIFree:=0;
END;

FUNCTION DPMIReAlloc(NewSize:Longint;VAR Mem:tDPMIMem):Word;
VAR NewLin,N:LongInt;
BEGIN
  IF NOT Win32Mem THEN BEGIN DPMIReAlloc:=DPMIReAlloc0(NewSize,Mem); Exit; END;
  DPMIReAlloc:=8;
  NewLin:=Call32(pVirtualAlloc,0,NewSize,$3000,4,4,0);
  IF NewLin=0 THEN Exit;
  N:=Mem.Size;
  IF N>NewSize THEN N:=NewSize;
  Call32(pMoveMemory,NewLin,Mem.LinAddr,N,0,3,0);
  Call32(pVirtualFree,Mem.LinAddr,0,$8000,0,3,0);
  Mem.LinAddr:=NewLin;
  Mem.hMem:=NewLin;
  Mem.Size:=NewSize;
  DPMIReAlloc:=0;
END;

FUNCTION DPMILock(Mem:tDPMIMem):Word;
BEGIN
  IF Win32Mem THEN DPMILock:=0 ELSE DPMILock:=DPMILock0(Mem);
END;

FUNCTION DPMIUnLock(Mem:tDPMIMem):Word;
BEGIN
  IF Win32Mem THEN DPMIUnLock:=0 ELSE DPMIUnLock:=DPMIUnLock0(Mem);
END;

"""


{'bp': bp, 'delphi': delphi, 'getos': getos, 'maths': maths,
 'shipped': shipped, 'bigmem': bigmem}[sys.argv[1]](sys.argv[2], sys.argv[3])
