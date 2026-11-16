# Setting up the Windows XP build by hand

This guide recreates the Windows XP build environment step by step, without
running any of this project's scripts. It produces the same environment as
`setup.sh` and `build.sh` ([WINXP.md](WINXP.md)), which follow exactly these
steps. With it, the original `MAKE.BAT` reproduces the shipped 2.40 files.

Any PC or virtual machine that runs Windows XP will do. Use one you can reset:
the build sets the clock to 2006, and some steps are easiest to undo by
starting over.

Paths like `files/F/WINUNIT` are relative to this project; `Mod4Win/` is the
repository (its submodule).

## 1. What you need

| Item | Used for |
|---|---|
| Windows XP Professional install CD, 32-bit (64-bit XP can't run DOS programs), and its product key (tested: SP3, English, volume licence) | the system |
| Borland Pascal 7.01: the ten 3.5" install disks and the run-time library source disk, as disk images | Borland Pascal 7.01 and its library source |
| Delphi Developer 2.01 CD | Delphi 2.01 |
| Delphi Desktop 2.0 (its InstallShield setup with `DATA.Z`) | Delphi 2.0's compiler (`DCC32.EXE`, `RLINK32.DLL`) |
| C++Builder 1.0 Client/Server Suite (its `Setup\DATA.Z`) | one source file, `GETMEM.INC` |
| DR DOS 6.0 install disks | `XDEL.EXE`, `FORMAT.COM`, `LABEL.COM` |
| PKZIP 2.50 for DOS (the shareware self-extractor) | PKZIP 2.50 for DOS |
| WinZip Self-Extractor 2.1 (its setup program, `wzipse21.exe`) and its registration, `winzipse.dat` | WinZip Self-Extractor 2.1 |
| the `Mod4Win` repository | the sources |
| this project's `files/` | the reconstructed files (units, `BPC.CFG`, batch files, one older unit revision) |
| a way to read disk images on another computer, such as 7-Zip | unpacking the archives above |

(The scripts expect all of these except the repository and `files/` in
`inputs/`.)

Everything has to get into the XP machine somehow, and its results out again.
Any way works (a CD image, a second disk, a USB stick), as long as file dates
survive the trip where noted. The scripted setup gives the machine no network
at all and passes files on disk images.

## 2. Install Windows XP

1. Install XP normally onto C:. A minimal installation is enough: in
   *Add/Remove Windows Components* nothing optional is needed. The scripted
   setup leaves out accessories, games, MSN, Windows Messenger, Media Player
   extras and Outlook Express links, and disables System Restore and Automatic
   Updates.
2. Give it no network connection (or disconnect it), so that it can't set its
   clock from the internet later.
3. Choose a time zone without daylight saving time, such as *Greenwich
   Standard Time* (any fixed zone works; what matters is that it doesn't
   change while you build).

## 3. Prepare the drives

The original machine had the tools on C: and E:, the project on F:, and two
side-script targets on W: and X:.

| Drive | File system | Contents |
|---|---|---|
| C: | NTFS (the system) | `C:\TOOLS`, Delphi, WinZip SE |
| E: | FAT (FAT16, 256 MB is plenty) | Borland Pascal (`E:\BP`, `E:\TD`) |
| F: | **NTFS** | the project tree |
| W:, X: | any | targets of `MAKERJ.BAT` and `MAKEDEMO.BAT` only |

1. Create E: and F: as partitions or extra disks with *Disk Management*
   (`diskmgmt.msc`), and give them those letters. If the CD drive has one of
   them, give it another letter first.
2. Format F: as **NTFS**. This matters: PKZIP adds files in directory order,
   which is alphabetical on NTFS, as in the shipped ZIPs. On FAT the ZIPs come
   out in a different order and don't match.
3. W: and X: can be any drives, or folders mapped with `SUBST`, for example
   `subst W: F:\_W` and `subst X: F:\_X`. Only the side scripts use them.
   `SUBST` lasts until you log off.

## 4. Borland Pascal 7.01 (E:)

1. Unpack the ten install disk images **into one folder** on a drive the XP
   machine can read, for example `D:\BP`. Each disk has its own
   `DISKn.DSK` marker, and no other file names collide, so the installer
   then finds all disks without asking for them.
2. Unpack the run-time library source disk (the one with `RTL.ZIP` on it)
   into its own folder, for example `D:\BPRTL`.
3. In a command prompt, run `D:\BP\INSTALL.EXE`:
   1. Enter on the welcome screen; source drive `D`; source path `\BP`.
   2. **Borland Pascal directory:** `E:\BP`.
   3. **Directory Options…**
      - *IDE/Command Line/Help:* `E:\BP` (not `E:\BP\BIN`: `MAKE.BAT`'s
        `PATH` has `e:\bp`, and the build expects `BPC.EXE`, `TASM.EXE`,
        `MAKE.EXE` and the rest directly there).
      - *BWCC.DLL:* leave `C:\WINDOWS\SYSTEM`. *Online Documentation:* leave
        `E:\BP\DOC`.
      - *Application Frameworks/Libraries…:* leave the defaults (all units in
        `E:\BP\UNITS`).
      - *Turbo Debugger…:* both entries `E:\TD`.
      - *Windows Tools…:* Resource Workshop, WinSight, WinSpector and Turbo
        Profiler for Windows `E:\BP`; **Windows Utilities `E:\TD`** (this puts
        `RC.EXE` where `MAKEDEMO.BAT` calls it, `e:\td\rc`).
      - *DOS Tools…:* all three `E:\BP`.
      - *Examples Programs…:* leave the defaults.
   4. Leave *Product Component Options* and *Example Options* at their
      defaults (everything), and choose **Start Installation**.
   5. Confirm the notes at the end; Esc leaves the README viewer.
4. Run `D:\BPRTL\INSTALL.EXE`: Enter, source drive `D`, source path
   `\BPRTL`, **run-time library directory `E:\BP\RTL`**, F9 to install.

## 5. Rebuild the run-time libraries (E:\BP\RTL)

The original machine used locally rebuilt libraries (see
[BUILD_TOOLS.md](BUILD_TOOLS.md#tpwtpl-turbotpl-tpptpl-runtime-libraries)).
These are the changes `tools/patches.py` makes. Keep a copy of every file
before you change it (the scripts name the copies
`*.ORG`: `MAKEFILE.ORG`, `STRINGS.ORG`, and `CRTASM.ORG` for `CRT.ASM`).
All files have DOS line ends; any text editor that keeps them will do
(Notepad works).

1. **`E:\BP\RTL\MAKEFILE`:**
   - `BPCD = $(BPC) -t -cd -e$(TPU) -q` → add ` -$g+` at the end.
   - `BPCW = $(BPC) -t -cw -e$(TPW) -q -$g-` → replace `-$g-` with
     `-$g+ -$s- -$w- -$v- -$i-`.
   - In the three rules under `.asm.obj:`, `.asm.obw:` and `.asm.obp:`,
     remove `-e ` from `$(TASM) -e -i$(INC) …`.
   - `$(BPC) -cw -m -e$(OWLBIN) -u$(COMMON) -$F+,S- buildowl` → replace
     `-$F+,S-` with `-$g+ -$s- -$w- -$v- -$i- -$k- -t$(BIN)`.
2. **`str\STRINGS.PAS`, `win\WIN31.PAS`, `win\WINDOS.PAS`, `owl\OMEMORY.PAS`:**
   after the line `unit Strings;` (`unit Win31;`, `unit WinDos;`,
   `unit OMemory;`), add the line `{$C Fixed Preload Permanent}`.
3. **`owl\OWINDOWS.PAS`:** in `procedure TWindow.SetupWindow;`, insert as the
   first line after `begin`:
   ```pascal
     MoveWindow(HWindow, Attr.X, Attr.Y, Attr.W, Attr.H, False);
   ```
   so that it comes before `TWindowsObject.SetupWindow;`.
4. **`crt\CRT.PAS`:** in the `var` section under `{ Interface variables }`,
   add as the first variable, before `CheckBreak`:
   ```pascal
     DelayCnt: Longint;
   ```
5. **`crt\CRT.ASM`** (the Runtime Error 200 fix; tabs between the columns, as
   in the rest of the file):
   - After the line `EXTRN SegB000:WORD,SegB800:WORD`, add
     `EXTRN DelayCnt:WORD`.
   - Delete the line `DelayCnt DW ?` (under `; Local workspace`).
   - After `MOV DI,OFFSET Timer` (in the initialisation), add:
     ```
     	IN	AL,21H
     	PUSH	AX
     	MOV	AL,0FEH
     	OUT	21H,AL
     ```
   - A few lines further, replace
     ```
     	MOV	CX,55
     	DIV	CX
     	MOV	DelayCnt,AX
     ```
     with
     ```
     	XCHG	DX,CX
     	MOV	BX,1193
     	MUL	BX
     	XCHG	CX,DX
     	XCHG	AX,DX
     	MUL	BX
     	ADD	AX,CX
     	ADC	DX,0
     	MOV	DelayCnt,AX
     	MOV	DelayCnt+2,DX
     	POP	AX
     	OUT	21H,AL
     ```
   - In `Delay:`, replace the `XOR DX,DX` after `@@1: MOV AX,DelayCnt` with
     `MOV DX,DelayCnt+2`.
6. Build, in a command prompt:
   ```
   E:
   cd \BP\RTL
   set PATH=E:\BP;%PATH%
   MAKE rtlwin
   MAKE owl
   MAKE rtldos
   ```
   "TPW.TPL not found" and "TURBO.TPL not found" warnings are normal here.
   The results are `E:\BP\RTL\BIN\TPW.TPL`, `TURBO.TPL` and the ObjectWindows
   units in `E:\BP\RTL\BIN\OWL`.
7. Copy every `.TPW` from `E:\BP\RTL\BIN\OWL` over the one of the same name in
   `E:\BP\UNITS` (keep the originals).

## 6. C:\TOOLS

1. Create `C:\TOOLS`.
2. Copy `C:\WINDOWS\system32\command.com` and `xcopy.exe` into it.
   `MAKE.BAT` sets a `PATH` without the Windows directory, and `setup.pas`
   runs `COMMAND.COM /C xcopy …` from that `PATH`.
3. From the DR DOS disk images, copy `LABEL.COM` into it.
4. Copy the PKZIP 2.50 self-extractor into it and run it there: it unpacks
   `PKZIP.EXE`, `PKUNZIP.EXE` and documentation, and reports "Authentic files
   Verified!".

## 7. WinZip Self-Extractor 2.1

1. Run WinZip Self-Extractor's setup program and choose *Setup*; keep the
   default folder (`C:\Program Files\WinZip Self-Extractor`).
2. It starts the program once: accept the license (*Yes*), then close it.
   This writes `winzipse.ini`, which records the acceptance.
3. Copy into `C:\TOOLS`:
   - `WZIPSE32.EXE`, **renamed to `WZIPSE.EXE`** (`MAKE.BAT` calls `WZIPSE`);
   - `WINZIPSE.HLP` and `winzipse.ini` from the program folder;
   - your `winzipse.dat` (the registration). Put a copy in the program folder
     too.

   Don't use the installed program through its long path instead (for
   example with an App Paths entry): it then rejects `MAKE.BAT`'s options with
   "The command line is too long". Without the help file beside it, it stops
   with "Help file not in same folder as executable".

## 8. Delphi 2

1. From the Delphi Developer 2.01 CD, run `INSTALL\SETUP.EXE`:
   - *Setup Type:* Full.
   - *Select Directories:* **Delphi 2.0 Directory `C:\BORLAND\DELPHI32`** (the
     path in the project's `.DSK` files); the other parts can stay at their
     defaults.
   - Accept the remaining pages; cancel the online registration wizard.

   The installer writes `C:\BORLAND\DELPHI32\BIN\DCC32.CFG` with the unit path
   and aliases; nothing to add.
2. Rebuild `SYSTEM.DCU` with the memory-manager fix:
   1. Get `GETMEM.INC` from C++Builder 1.0: it's
      `EBONY\OPTIONS\SOURCE\VCL\GETMEM.INC` in its installer's
      `Setup\DATA.Z` (see [the note below](#getting-files-out-of-dataz)). Copy
      it over `C:\BORLAND\DELPHI32\SOURCE\RTL\SYS\GETMEM.INC` (keep the
      original).
   2. In `SYS\HALT.ASM` and `SYS\OPENFILE.ASM`, add a line `.DATA` right after
      `.MODEL FLAT` (before the first `EXTRN`). Turbo Assembler 3.2 otherwise
      writes fixups that `DCC32` rejects.
   3. Assemble the System modules with Borland Pascal's Turbo Assembler 3.2.
      In `C:\BORLAND\DELPHI32\SOURCE\RTL`, for each module in the
      `SYSTEMOBJ = …` list of `MAKEFILE` (33 modules in `SYS\`):
      ```
      E:\BP\TASM -zn -m3 -t -w- -isys sys\NAME,sys\NAME.obj
      ```
   4. Compile, in the same folder, with the installed (2.01) compiler:
      ```
      mkdir OUT
      ..\..\BIN\DCC32 -q SYS\SYSTEM -y -z -$D- -NOUT
      ```
   5. Copy `OUT\SYSTEM.DCU` over `C:\BORLAND\DELPHI32\LIB\SYSTEM.DCU` (keep the
      original).
3. Replace the 2.01 compiler with Delphi 2.0's: copy `DCC32.EXE` and
   `RLINK32.DLL` from Delphi Desktop 2.0 (`DELPHI32\MINIMAL\BIN\` in its
   installer's `DATA.Z`; see the note below) over the ones in
   `C:\BORLAND\DELPHI32\BIN` (keep the originals).

Delphi is only needed for `IFACE32\MAKE.BAT` and `MCITest32`, not for the main
build.

### Getting files out of DATA.Z

Delphi Desktop 2.0 and C++Builder 1.0 are InstallShield 3 installers: their
files are in `DATA.Z`, compressed with PKWARE's DCL "implode", which 7-Zip and
unzip can't read. `tools/is3x.py` (a short Python 3 script) extracts named
files from it, on any computer:

```
python3 tools/is3x.py DATA.Z OUTDIR 'DELPHI32\MINIMAL\BIN\DCC32.EXE' 'DELPHI32\MINIMAL\BIN\RLINK32.DLL'
python3 tools/is3x.py DATA.Z OUTDIR 'EBONY\OPTIONS\SOURCE\VCL\GETMEM.INC'
```

Don't install these two products instead, on the same machine as Delphi 2.01:
Delphi Desktop 2.0 puts its Database Desktop and BDE into 2.01's folders and
uses the same Start menu folder, and C++Builder 1.0 brings its own BDE.

## 9. The project on F:

Put together this tree on F: (F: must be NTFS, see step 3):

| Path | From |
|---|---|
| `F:\MOD4WIN\` | the repository's `SOURCE\` contents |
| `F:\MOD4WIN\<folder>\` | each other folder of the repository (`COMPILER`, `CUSTOM`, `DEFAULTS`, `HELP`, `IFACE32`, `INSTALL`, `INTL`, `IT`, `M4W_MCI`, `MAKECODE`, `PLAYER`, `setup`) |
| `F:\MOD4WIN\_BURGER_\` | empty folder (`MKEWSPLY.BAT` copies into it) |
| `F:\MOD4WIN\PLAYER\TASK.RES` | `M4W230/TASK.RES` from the repository's `old_versions.zip` (missing from `PLAYER/`) |
| `F:\MOD4WIN\M4W_MCI\CORONER.PAS` | `files/F/MOD4WIN/M4W_MCI/CORONER.PAS` (the older revision in `M4W_MCI.DLL`) |
| `F:\MOD4WIN\COMPILER\BPC.CFG` | `files/F/MOD4WIN/COMPILER/BPC.CFG` |
| `F:\MOD4WIN\COMPILER\BPC.EXE`, `RTM.EXE`, `DPMI16BI.OVL`, `COMPRESS.EXE` | `E:\BP` |
| `F:\MOD4WIN\COMPILER\TPW.TPL`, `TURBO.TPL` | **the rebuilt ones** from `E:\BP\RTL\BIN` (step 5) |
| `F:\MOD4WIN\COMPILER\XDEL.EXE`, `FORMAT.COM` | the DR DOS disk images |
| `F:\COMPILER\` | `files/F/COMPILER/*.BAT`, plus `XDEL.EXE` and `FORMAT.COM` again |
| `F:\WINUNIT\` | `files/F/WINUNIT/*.PAS`; `MATHS.PAS`: `m4w231/PLAYER/FILTER/MATHS.PAS` from the repository's `old_versions.zip`, and `GETOS.PAS`: the repository's `M4W_MCI/GETOS.PAS`, each with changes (below) |
| `F:\DOSUNINT\`, `F:\EXE\` | empty folders (on `MAKE.BAT`'s `PATH`; `F:\EXE` is the Delphi projects' output folder) |
| `W:\M4W_HTML\MOD4WIN.COM\FILES\`, `X:\SOUND\MOD4WIN\MCI_DEMO\` | empty folders, for the side scripts |

The two changes in `F:\WINUNIT\MATHS.PAS` (2.40's revision of the 2.31 unit):

1. Near the top, `lg` and `_lg` swap names: the assembler function
   (`FUNCTION _lg(x:Double):Double;ASSEMBLER;` … `END;`) becomes `lg`, and
   the one-line Pascal function `lg` becomes `_lg`, placed after it.
2. At the end, in the unit's initialization, add as the first lines after
   `BEGIN`:

   ```pascal
   {$IFNDEF DEBUG}
     ASM finit END;
   {$ENDIF}
   ```

The changes in `F:\WINUNIT\GETOS.PAS` (the revision in the 2006 binaries):

1. After `UNIT GetOS;`, add the line `{$C Fixed Preload Permanent}`.
2. Delete the three lines with `lFreeLibrary32W`: its declaration, its
   `GetProcAddress`, and its call.
3. At the very end, before the final `END.`, add:

   ```pascal
     OS:=Windows_NT;
     ExOS:=Ex_NewWin;
   ```

Then fix six file dates. They go into the installers unchanged, and git
doesn't keep them. The simplest way is to take these files from the shipped
`Mod4Win/setup/m4w24ins.exe` (a ZIP archive) with a tool that keeps the
stored dates, and copy them over the ones in the tree; or set the dates
(local time) by hand:

| File | Date |
|---|---|
| `F:\MOD4WIN\DEFAULTS\CRYSTALS.66_`, `FREEDANC.MO_` | 1998-07-10 18:59:38 |
| `F:\MOD4WIN\DEFAULTS\TRLPLAY.386`, `TRLPLAY.SYS`, `TRLPLAY.VXD` | 1998-07-10 18:59:40 |
| `F:\MOD4WIN\WHATSNEW.TXT` | 2006-12-10 11:06:10 |

(`build.sh` also dates `PLAYER\TASK.RES` 1997-01-28 09:28:00, the DOS time
stamp in `old_versions.zip`; that date doesn't reach any output.)

`MAKE.BAT` changes its own tree (it deletes the shipped installers in
`setup\` and renames files during the build), so work on a copy, never on the
repository.

## 10. Build

1. Set the date to the 2.40 build date, in a command prompt:
   `date 12-10-2006` (US date format). `setup.pas` and `CHECKSUM.EXE` stamp
   files with the current date, and the 2006 date also makes every compile a
   full recompile, as on the original ([BIT_EXACT.md](BIT_EXACT.md#the-build-date)).
2. If W: and X: are `SUBST` drives, map them in this session.
3. Build:
   ```
   F:
   cd \MOD4WIN
   MAKE.BAT
   ```
   It takes about a minute. The installers end up in `F:\MOD4WIN\setup\`
   (`m4w24ins.exe`, `m4w24cin.exe`, `mci24ins.exe`), the staged files in
   `setup\m4w_full` and `setup\mci_full`. If a step fails, `setup.exe`
   stops with "ERROR! press a key to abort"; the compiler's message is above
   it.
   - `setup.pas` reuses outputs that already exist, and the repository has
     some: `RES_*.DLL` and `.DL_` in `F:\MOD4WIN`, `INST_*.DLL` in `INSTALL\`,
     `*.HL_` in `HELP\`. Delete them first to rebuild them from source (this
     is what `CLEAN=1` does for `build.sh`).
   - Build again from a fresh copy of the tree: `MAKE.BAT` changes its own.
4. For the Delphi test programs: in a prompt where `MAKE.BAT`'s `PATH` and
   `C:\BORLAND\DELPHI32\BIN` are set, run `IFACE32\MAKE.BAT`; compile
   `M4W_MCI\Delphi32\MCITest32.dpr` with
   `dcc32 -CC -B -$A-,B-,D-,I-,L-,O+,R-,S-,V+,X+,Y-,H+,J+,P+,Q-,T-,U-,W-,Z+ MCITest32.dpr`
   (the switches from its `.DOF`).

## 11. Check the result

Compare with the repository's files (the build overwrote its copies):

- Everything in `setup\m4w_full` and `setup\mci_full`, with dates, and
  `mci24ins.exe` are identical to the shipped ones.
- `MOD4WIN.EXE` (and so `m4w24ins.exe`, `m4w24cin.exe`) differs, because the
  repository's `REGDLG.PAS` isn't quite the revision that was shipped. To
  check that everything else is exact, make the two edits from
  [BIT_EXACT.md](BIT_EXACT.md#the-remaining-difference-regdlgpas) on F: and
  build again: then all three installers are byte-identical.
- The installers carry the WinZip SE licensee's name from `winzipse.dat`, so
  they're byte-identical only with a registration to the original licensee
  ("Kay Bruns"); with another, they differ in that name.

For a player that loads modules over 16 MB, make the edits of
`tools/patches.py bigmem` before building (`playdefs.pas` and both copies of
`HUGEMEM.PAS`; [BIGMEM.md](BIGMEM.md)), for example by running
`python3 tools/patches.py bigmem DIR DIR` on a copy of the project tree
(`DIR` as `F:\MOD4WIN`); its `PLAYER32.DLL` is then no longer identical.
