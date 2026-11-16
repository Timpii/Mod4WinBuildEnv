# Build tools and their status

This lists every tool, executable, configuration file and library that the
Mod4Win 2.40 build uses. For each one it gives the original location, its
status (in the Mod4Win repository, or how this environment provides it), a
likely source, how the build calls it, what it is used for, and what is blocked
if it is missing.

Sources checked: `SOURCE/MAKE.BAT`, `SOURCE/CLEANUP.BAT`, `SOURCE/MKEWSPLY.BAT`,
`SOURCE/setup.pas`, `CUSTOM/MAKE.BAT`, `IFACE32/MAKE.BAT`, `M4W_MCI/*.BAT`,
`HELP/*.BAT`, `COMPILER/dir.txt`, and the Borland Pascal 7.01 disk images.

The original machine's `PATH` (set at the top of every `MAKE.BAT`) was:

```
C:\tools;f:\exe;f:\compiler;e:\td;e:\bp;f:\winunit;f:\dosunint
```

Most of the missing pieces lived in these directories, not in the project tree.

## Overview with versions

The version given is what the original build used, as far as it can be
determined, and the evidence it comes from. "BP 7.01 disks" means the
Borland Pascal with Objects 7.01 images: files dated 1993-03-09 07:01, and the
07:01 time stamp is Borland's marker for 7.01.

| Tool                            | Version                                                                                                                                 | Evidence                                                                                                                                                                   | Status                                                                           |
| ------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------- |
| BPC.EXE                         | Borland Pascal 7.01 (banner says "7.0"), locally patched in an unknown way                                                              | Shipped binaries contain the 7.01 RTL's fixed longint shift helper byte for byte; `BPC.ORG` backup in `dir.txt`; the genuine 7.01 compiler reproduces the binaries exactly | replaceable (genuine 7.01)                                                       |
| TPW.TPL / TURBO.TPL / TPP.TPL   | BP 7.01; `TPW.TPL` and `TURBO.TPL` rebuilt locally from the RTL source (28 Jan 1997), `TURBO.TPL` with a Runtime Error 200 fix in `Crt` | code and segment attributes in the shipped binaries; `CUSTOM/CHECKSUM.EXE`; `dir.txt`                                                                                      | both rebuilt in the guest by `setup.sh`; `CHECKSUM.EXE` reproduced exactly       |
| ObjectWindows units             | BP 7.01 OWL, rebuilt locally from source with one change                                                                                | code in `MOD4WIN.EXE` and `INSTALL.EXE`                                                                                                                                    | rebuilt in the guest by `setup.sh`                                               |
| RTM.EXE / DPMI16BI.OVL          | 14 Apr 1993 build; newer than the 7.01 disks (09 Mar 1993)                                                                              | `dir.txt` dates                                                                                                                                                            | replaceable (7.01 disk copies)                                                   |
| BPC.CFG                         | n/a (written by the developers, last changed 21 Jun 2006)                                                                               | `dir.txt`                                                                                                                                                                  | recreated: `files/F/MOD4WIN/COMPILER/BPC.CFG`                                    |
| bp/bpw/bpw32/delbak.bat         | n/a (written by the developers)                                                                                                         | `MAKE.BAT` calls                                                                                                                                                           | recreated: `files/F/COMPILER/*.BAT`                                              |
| RLINK.EXE                       | a Borland Resource Linker that marks programs as Windows 3.10 by default                                                                | the custom `MOD4WIN.EXE` says 3.10; RLINK 1.00 from BP 7.01 writes 3.00 unless given `-31`                                                                                 | substitute: RLINK 1.00 (BP 7.01)                                                 |
| RC.EXE / RCPP.EXE               | Microsoft Windows Resource Compiler 3.1 (Copyright 1985-1992), the copy Borland shipped with BP 7.01                                    | the repo copies are byte-identical to `WINUTILS.ZIP` on the BP 7.01 disks                                                                                                  | present                                                                          |
| HCP.EXE                         | Microsoft Help Compiler 3.10.505 (extended), Copyright 1990-1992                                                                        | banner; same 236288-byte file in every version since 2.20 (1993-09-08)                                                                                                     | present                                                                          |
| COMPRESS.EXE                    | Microsoft File Compression Utility 2.00                                                                                                 | banner of the BP 7.01 disk copy; the original was dated 28 Jan 1997 in `dir.txt`                                                                                           | replaceable                                                                      |
| CHECKSUM.EXE                    | built from `M4W_MCI/CHECKSUM.PAS` with BP 7.x (DOS target)                                                                              | source present                                                                                                                                                             | present                                                                          |
| XDEL.EXE                        | DR DOS / Novell DOS `XDEL` (28 Jan 1997 copy)                                                                                           | switches `/S /N /D /R` match DR DOS `XDEL` exactly                                                                                                                         | provided: DR DOS 6.0 copy                                                        |
| PKZIP                           | PKZIP 2.50 for DOS (`-ex`), in its 32-bit DPMI mode                                                                                     | in the XP guest (which provides DPMI) it reproduces the shipped ZIPs byte for byte; without DPMI, 7 of 18 entries differ                                                   | provided: `pk250dos.exe`                                                         |
| WinZip Self-Extractor           | 2.1 (1997), registered to Kay Bruns; probably `WZIPSE32.EXE`                                                                            | `MAKE.BAT` reproduces all three installers byte for byte with it in the XP guest                                                                                           | provided: `wzipse21.exe` and your `winzipse.dat`                                 |
| FORMAT.COM / LABEL.EXE          | MS-DOS (version unknown; `FORMAT.COM` copied 28 Jan 1997)                                                                               | `dir.txt`, `setup.pas`                                                                                                                                                     | substitute: DR DOS 6.0 copies (floppy output only)                               |
| COMMAND.COM / XCOPY             | DOS prompt under 32-bit Windows, probably NT-based (XP)                                                                                 | `start /w` and `WZIPSE32.EXE` in `MAKE.BAT`; `setup.pas` runs `COMMAND.COM /C ren`, `xcopy`                                                                                | XP's own, in `C:\TOOLS`                                                          |
| Delphi                          | Delphi 2.0 compiler (`DCC32`), 2.01 units, `System` rebuilt with the memory-manager fix also found in C++Builder 1.0                    | `IFACE32/README.TXT`; `.DSK` paths; `MCITest32.exe` reproduced from these except one IDE padding byte                                                                      | installed in the guest in `C:\BORLAND\DELPHI32` (two test programs only)         |
| TASM                            | Turbo Assembler 3.2                                                                                                                     | `CPUID.OBJ` (old versions) says "Turbo Assembler Version 3.2"; the BP 7.01 disk copy is 3.2 too                                                                            | replaceable                                                                      |
| Impulse Tracker driver includes | unknown                                                                                                                                 | `IT/AWE32DRV.ASM` includes                                                                                                                                                 | missing (available from the Impulse Tracker source release; no build needs them) |
| TRLPLAY drivers                 | TRLPLAY.VXD file version 1.00 (product version 0.01), (c) 1996 Trinity Labs Germany                                                     | version resource of `DEFAULTS/TRLPLAY.VXD`                                                                                                                                 | binaries present                                                                 |
| W8LOSS.EXE, RTM.upx             | unknown / UPX (2008)                                                                                                                    | `dir.txt`                                                                                                                                                                  | not needed                                                                       |

Status values used below:

- **missing**: not in the repo, and the environment doesn't provide it.
- **replaceable**: not in the repo; `setup.sh` installs it from the Borland
  media (the same version the original used, as far as known).
- **provided**: not in the repo; `setup.sh` installs it from a separate input
  (`pk250dos.exe`, `wzipse21.exe`, the DR DOS disks).
- **substitute**: provided, but not the version the original build used.
- **present**: in the repo.

Where things live in the build environment (drives `C:`, `E:` and `F:`) is
described in [../README.md](../README.md).

---

## 1. Compiler and its configuration

### BPC.EXE: Borland Pascal 7 command-line compiler

- **Original location:** `<ROOT>\compiler\bpc.exe`, with a backup `BPC.ORG`
  (`COMPILER/dir.txt`, dated 28 Jan 1997).
- **Status:** replaceable. The genuine BP 7.01 `BPC.EXE` is in `BPC.ZIP` on
  disk 10 of the BP 7.01 images. The modified copy that was used originally is
  lost; the `BPC.ORG` backup shows the compiler had been changed, but not how.
  - Whatever was changed doesn't affect code generation: the genuine compiler
    reproduces `PLAYER32.DLL`, `M4W_MCI.DLL` and `INST_MCI.EXE` byte for byte.
  - No known patch fits. Andreas Bauer's `TPPATCH` (the usual Runtime Error 200
    fix) patches the `Crt` delay loop, which isn't in `BPC.EXE`. A
    `Bpc79h.exe` found online is an unrelated 1994 beta ("BP 7.9h"). So the
    environment uses the genuine `BPC.EXE`.
- **Called by:** `setup.pas` (`CreateFile(..., ROOT+'compiler\bpc.exe', '/Q ...')`)
  for `mod4win.pas`, `player\player32.pas`, `res_*.pas`, `install\install.pas` and
  `install\inst_*.pas`. It is called indirectly from every `MAKE.BAT` through the
  `bp`/`bpw` wrappers (section 2).
- **Used for:** compiling all 16-bit Windows and DOS targets.
- **Blocks if missing:** everything.
- **Notes:** the shipped binaries match the genuine 7.01 runtime library: the
  longint shift helper in `TPW.TPL` is byte-identical. Running it needs
  `RTM.EXE` and `DPMI16BI.OVL` (`DPMISYS.ZIP`, disk 9). It works under XP's DOS
  subsystem.

### BPC.CFG: compiler options file

- **Original location:** `F:\MOD4WIN\COMPILER\BPC.CFG`, the project's
  `COMPILER` directory (dated 21 Jun 2006 in `dir.txt`).
- **Status:** recreated as `files/F/MOD4WIN/COMPILER/BPC.CFG`. The original is
  lost.
- **Likely source:** written by the developers.
- **Called by:** read automatically by `BPC.EXE` from its own directory.
  `setup.pas` calls `ROOT\compiler\bpc.exe`, so `setup.sh` puts `BPC.EXE`,
  `TPW.TPL`, `TURBO.TPL`, `RTM.EXE` and `DPMI16BI.OVL` next to it on the
  guest's F:, as `dir.txt` lists.
- **Used for:** the default target, the unit, include and resource
  directories, and the default compiler switches.
- **Blocks if missing:** nothing outright, but builds come out wrong. Without it
  `LIBRARY Player32` fails to compile (no `/CW`), `loaders.pas` fails with a
  type mismatch (no `$V-`), and the generated code differs from the shipped
  binaries.
- **How the contents were recovered:**
  - `/CW /$V- /$S- /$W- /$G+ /$I-`: found by comparing compiled code with the
    shipped `PLAYER32.DLL` and `MOD4WIN.EXE`.
  - `/$K-` (no smart callbacks): the exported callbacks in `MOD4WIN.EXE` and
    `INSTALL.EXE` start with `mov ax,ds`. With `$K+` the linker writes
    `mov ax,ss`. No source sets `$K`, and DLLs are unaffected.
  - `/M`: `setup.pas` calls `bpc.exe /Q <file>` without `/M` or `/B`, and BPC
    only compiles unit sources when one of them is given.
  - Unit path: `E:\BP\UNITS;F:\WINUNIT;F:\MOD4WIN\M4W_MCI;F:\MOD4WIN\PLAYER;F:\MOD4WIN\INSTALL;F:\MOD4WIN`.
    `setup.pas` compiles everything from the project root, so
    `install\install.pas` needs `INSTALL` on the unit path. The order is a
    reconstruction too: `F:\WINUNIT` and `M4W_MCI` come before the project
    root so that the MCI driver build (compiled in `PLAYER\`) picks up the
    older `CORONER.PAS`, while builds started from the root still use the
    root's `coroner.pas` (see
    [MISSING_UNITS.md](MISSING_UNITS.md#coroner-the-revision-in-m4w_mcidll)).
  - The project must be at `F:\MOD4WIN`, not at the drive root. `setup.pas`
    strips a trailing backslash before `ChDir`, so with the root at `F:\` its
    `ChDir(ROOT)` would only select the drive. The old Delphi `.DSK` files also
    refer to `F:\MOD4WIN\...`.
- With it, the original `SOURCE/MAKE.BAT` (including `CUSTOM` and `M4W_MCI`)
  runs unchanged and builds every binary.

### TPW.TPL, TURBO.TPL, TPP.TPL: runtime libraries

- **Original location:** `<ROOT>\compiler\TPW.TPL` (modified 28 Jan 1997).
- **What the modification was:** the Windows run-time library rebuilt from
  Borland's RTL source (`RTL*.ZIP` on the BP disks). The shipped binaries show
  three differences from the genuine 7.01 `TPW.TPL`:
  - System was assembled without TASM's `-e`, so it lacks the NOP padding for
    floating-point emulation.
  - The Pascal units were compiled with the project's switches
    (`$G+ $S- $W- $V- $I-`), so they contain 286 code.
  - Strings, Win31, WinDos and OMemory have `{$C Fixed Preload Permanent}`
    code segments.
- **`TURBO.TPL` (DOS) was rebuilt too, with a fixed `Crt`.** `dir.txt` dates
  it 28 Jan 1997 like `TPW.TPL`, and the shipped `CUSTOM/CHECKSUM.EXE` (a DOS
  program using `Crt`) shows the change. Compared with a build against the
  genuine 7.01 `TURBO.TPL`, only `Crt` differs:
  - `DelayCnt` is a `Longint`, declared as the first interface variable in
    `CRT.PAS` instead of a word in `CRT.ASM`'s data.
  - The delay calibration multiplies the 32-bit tick count by 1193 and keeps
    the upper 32 bits (about ÷55) instead of the 16-bit `DIV` that overflows on
    fast CPUs (Runtime Error 200). While it measures, all interrupts but the
    timer are masked (port 21h).
  - `Delay` uses the whole 32-bit count.
  - The Pascal part was compiled with `$G+` (the makefile's DOS line got
    `-$g+`).

  `tools/patches.py` applies exactly this to Borland's source. With it,
  `CHECKSUM.PAS` compiles to the shipped `CHECKSUM.EXE` byte for byte. Without
  it, `setup.exe` crashes with Runtime Error 200 on a fast CPU.

- **Status:** rebuilt in the guest by `setup.sh`: `tools/patches.py`'s
  changes over Borland's sources, then Borland's own `MAKE rtlwin`,
  `MAKE owl` and `MAKE rtldos`. The originals are kept as `MAKEFILE.ORG` and
  `*.ORG` next to each changed source (`CRTASM.ORG` for `CRT.ASM`); the
  rebuilt `TPW.TPL` and `TURBO.TPL` go into `F:\MOD4WIN\COMPILER`.
  `TPP.TPL` is the genuine 7.01 file. The result is not BPL 1.6's `TPW.TPL`
  (in the Borland Pascal archive's `Addons/BPL 1.6`).
- **Used for:** the System, WinTypes, WinProcs, Strings and WinDos code linked
  into every binary.
- **Blocks if missing:** everything.

### Standard BP7 unit files (`*.TPW`)

- **Status:** replaceable: `OWL.ZIP`, `WIN31.ZIP`, `UNITS.ZIP` and `COMMDLGS.ZIP`
  on the BP disks. This covers OWindows, ODialogs, OMemory, Objects, Validate,
  MMSystem, ShellAPI, CommDlg, ToolHelp, LZExpand, Ver, Win31, BWCC and so on.
- **ObjectWindows was rebuilt locally too.** `MOD4WIN.EXE` and `INSTALL.EXE`
  contain OWindows and ODialogs compiled from source:
  - with the project switches instead of Borland's `$F+` (near private
    routines, 286 code);
  - with one change: `TWindow.SetupWindow` starts with
    `MoveWindow(HWindow, Attr.X, Attr.Y, Attr.W, Attr.H, False)`.

  `setup.sh` rebuilds the OWL units the same way (`MAKE owl`) and installs
  them in `E:\BP\UNITS`, keeping Borland's as `*.ORG`.

- **Blocks if missing:** all Windows targets.

---

## 2. Compiler wrapper batch files

### bp.bat, bpw.bat, bpw32.bat, delbak.bat

- **Original location:** one of the `PATH` directories, most likely
  `f:\compiler`.
- **Status:** recreated as `files/F/COMPILER/BP.BAT`, `BPW.BAT`, `BPW32.BAT` and
  `DELBAK.BAT` (`F:\COMPILER`, on the `PATH`). The originals are lost; the
  recreated versions do what the calls require:
  - `BP` runs `F:\MOD4WIN\COMPILER\BPC /CD`. `/CD` overrides the `/CW`
    default from `BPC.CFG`.
  - `BPW` runs `F:\MOD4WIN\COMPILER\BPC /CW`.
  - `BPW32` runs `dcc32`, which is on the `PATH` only if
    `C:\BORLAND\DELPHI32\BIN` is (as in `xp/jobs/IFACE32.CMD`).
  - `DELBAK` deletes `*.bak` and `*.~*` in the current directory.
  - All of them pass their arguments on.
- **Likely source:** written by the developers.
- **Called by:**
  - `call bp checksum.pas` (`M4W_MCI/*.BAT`), `call bp setup` (`SOURCE/MAKE.BAT`).
  - `call bpw iface16`, `call bpw m4w_mci.pas /DMCI /R..\intl`,
    `call bpw inst_mci.pas /DCHECK` and `call bpw MPLAY32.pas /DEWSPLAYER /DEWS /R..\intl`,
    among others.
  - `call bpw32 dstest32` (`IFACE32/MAKE.BAT`).
  - `call delbak` (end of most `MAKE.BAT` files).
- **Blocks if missing:** every `MAKE.BAT` as written.

---

## 3. Shared unit libraries

### f:\winunit and f:\dosunint

- **Status:** the Windows units have been rebuilt from the shipped binaries
  into `files/F/WINUNIT/` (`F:\WINUNIT`); see `MISSING_UNITS.md`. `f:\dosunint`
  is an empty directory and can't be reconstructed. Nothing in the repository
  needs it, and there are no binaries to rebuild its units from:
  - It appears only on the `PATH` lines of the batch files.
  - Every DOS program in the repository compiles without it, using Borland's
    units and the repository's own: `setup.pas` (with `HYPERAPI.PAS`),
    `CHECKSUM.PAS`, and `MAKECODE\M4WMAIL`, `AKM_IMP` and `CIS_IMP`.
  - `makecode.pas`'s DOS branch also compiles, with the repository's `HugeMem`
    and the empty `VK_KEYS`; it uses nothing from `VK_KEYS`.
  - `REGISTER`, `TEST` and `CIS-REG` are Windows programs.
- **Contents:**
  - Windows units used by the project: GetOS, W32DEFS, W32BASE, FILE32, User32,
    WOW32, oFarProc, Wave, PrtLayer, MemList, VALCONV, Maths, Crc, VK_KEYS and
    Ctl3DV2.
  - Units that only those units use: TrlNT, TrlVxD, WinSvc, VxDLdr, NoDOSMem,
    NetDrv and DragDet.
  - GetOS: the copy in `M4W_MCI/GETOS.PAS` is not the revision the 2006
    binaries were built with. The shipped revision is in `F:\WINUNIT\GETOS.PAS`
    (see `MISSING_UNITS.md`).
  - `f:\dosunint`: presumably DOS versions of shared units for DOS tools that
    aren't in the repository.
- **Blocks if missing:** `f:\winunit` blocks `PLAYER32.DLL`, `M4W_MCI.DLL`,
  `MOD4WIN.EXE`, `INSTALL.EXE` and `IFACE16.BIN`. `f:\dosunint` blocks
  nothing.

---

## 4. Resource tools

### RLINK.EXE: Borland resource linker

- **Original location:** on `PATH`, probably `e:\bp` or `e:\td`.
- **Status:** substitute: RLINK 1.00 from `RWUTILS.ZIP` (disk 9), together
  with `BRC.EXE` and `BRCC.EXE`; see the version difference below.
- **Called by:** `CUSTOM/MAKE.BAT`:

  ```
  rlink MOD4WIN.FXE
  rlink -feFULL\MOD4WIN.EXE MOD4WIN.RES MOD4WIN.FXE
  ```

- **Used for:** binding the customised resources (`CUSTOM/MOD4WIN.RES`) into
  the compiled `MOD4WIN.FXE`, producing the final `CUSTOM\FULL\MOD4WIN.EXE`.
- **Version difference:** the shipped `CUSTOM/Full/MOD4WIN.EXE` is marked as
  a Windows 3.10 program (NE header). RLINK 1.00 writes 3.00 unless given
  `-31`, and `CUSTOM/MAKE.BAT` doesn't pass it. So the original was a later
  RLINK with 3.10 as its default. With `-31` added (`SHIPPED=1` does that in
  the build's copy), the rebuilt file is byte-identical (see
  [BIT_EXACT.md](BIT_EXACT.md)).
- **Blocks if missing:** the shipped `MOD4WIN.EXE`. An `.FXE` without the
  custom resources can still be built.

### RC.EXE and RCPP.EXE: Microsoft resource compiler

- **Location:** `M4W_MCI/RC.EXE`, `M4W_MCI/RCPP.EXE`. `MAKERJ.BAT` and
  `MAKEDEMO.BAT` call `e:\td\rc` instead.
- **Status:** present. Version: Microsoft Windows Resource Compiler 3.1. The
  repo copies are byte-identical to `RC.EXE`/`RCPP.EXE` in `WINUTILS.ZIP` on
  the BP 7.01 disks, so they came with Borland Pascal.
- **Called by:** `rc -r inst_exe.rc` in the `M4W_MCI/*.BAT` files.
- **Used for:** compiling `INST_EXE.RC` into `INST_EXE.RES`. That embeds
  `M4W_MCI.DLL` into the MCI installer `INST_MCI.EXE` (and into `rjmod4wn.exe`).
- **Blocks if missing:** the MCI driver installer.

### TASK.RES (contains `taskres.EXE`)

- **Location:** `{$R TASK.RES}` in `PLAYER/task.pas`.
- **Status:** missing from the repository's `PLAYER/`, but
  `old_versions.zip` has `M4W230/TASK.RES` (1997-01-28), byte-identical to the
  resource in the shipped `PLAYER32.DLL` (`TASKEXE`/`TASKEXE`, 1536 bytes).
  `build.sh` extracts it from there. No source for `taskres.EXE` exists.
- **Used for:** a tiny 16-bit Windows task that `task.pas` writes out and
  starts, so that the player gets its own task context (the MMTASK technique).
- **Blocks if missing:** `PLAYER32.DLL` and `M4W_MCI.DLL` do not compile
  ("File not found (TASK.RES)").

---

## 5. Cleanup and file utilities

### XDEL.EXE: delete files across subdirectories

- **Original location:** `F:\MOD4WIN\COMPILER\xdel.exe` (dated 28 Jan 1997 in
  `dir.txt`), and `F:\COMPILER\XDEL` for `CLEANUP.BAT`'s rooted
  `\compiler\xdel`.
- **What it is:** the DR DOS / Novell DOS "extended delete" utility. Its
  switches match the calls exactly:
  - `/S`: include subdirectories.
  - `/N`: no confirmation.
  - `/D`: remove emptied directories.
  - `/R`: include read-only files.
- **Status:** provided from DR DOS 6.0 (`XDEL.EXE` on disk 1), in both
  locations. The original copy may have come from a later DR DOS or Novell DOS
  release.
- **Behaviour:**
  - `xdel *.bak /sn` deletes recursively and leaves other files alone.
  - `xdel setup\*.* /sndr` removes the directory itself as well. That's why
    `MAKE.BAT` follows it with `md setup`.
- **Called by:**
  - `CLEANUP.BAT`: `\compiler\xdel *.bak /sn`, plus the same for `*.~??`,
    `*.tpu`, `*.tpw`, `*.fxe` and `*.sxe`.
  - `SOURCE/MAKE.BAT`: `xdel setup\*.* /sndr`.
  - `setup.pas`: `xdel <ROOT>*.dcu /sn`, `xdel <ROOT>*.tpw /sn`, and
    `xdel <target>:\*.* /sndr` to clear a floppy.
- **Blocks if missing:** the cleanup steps.
  - Stale `.TPW` files get reused.
  - `setup\` isn't cleared, and `setup.pas` copies into the old contents.

### COMMAND.COM and XCOPY.EXE: DOS shell

- **Original:** a DOS prompt under 32-bit Windows, not plain DOS.
  - `MAKE.BAT` runs `start /w WZIPSE …`. `start` exists only under Windows,
    and the builder that reproduces the installers, `WZIPSE32.EXE`, is a
    32-bit Windows program.
  - The ZIPs feed straight into the installers, so the whole of `MAKE.BAT`
    ran in that one Windows session.
- **Which Windows:** not recorded. An NT-based one (Windows 2000 or XP) is
  more likely than Windows 95:
  - `MAKE.BAT` replaces `PATH` with `C:\tools;f:\exe;…`, without any Windows
    directory.
  - In NT's `cmd.exe`, `start` is built in, so it works with that `PATH`. In
    Windows 95 it is `C:\WINDOWS\COMMAND\START.EXE`, which would only be found
    if copied to one of those directories.
  - The 2006 `GetOS` revision forces the NT code path
    ([MISSING_UNITS.md](MISSING_UNITS.md#getos-two-revisions)), so the authors
    ran NT-based Windows.
  - In 2006 an XP machine is the likely setup.
- **Consequences:**
  - `setup.pas` looks up `COMMAND.COM` on that `PATH`, so a copy must have
    been in `C:\TOOLS` or another of those directories. XP's 16-bit
    `COMMAND.COM` runs under NTVDM.
  - Setting the date to 2006-12-10 in that prompt changed the PC's real clock,
    so the build date was set on purpose (see
    [BIT_EXACT.md](BIT_EXACT.md#the-build-date)).
  - On a 2006 CPU, the `Crt` unit in `setup.exe` and `CHECKSUM.EXE` fails with
    Runtime Error 200 unless patched. The original `Crt` was patched; the fix
    has been recovered (see [TURBO.TPL](#tpwtpl-turbotpl-tpptpl-runtime-libraries)).
- **Status:** XP's own `COMMAND.COM` and `XCOPY.EXE`, copied into `C:\TOOLS`
  in the guest.
- **Called by:** `setup.pas` looks up `COMMAND.COM` on the `PATH` and runs
  `COMMAND.COM /C ren <file>.exe *.fxe`, `/C copy`, `/C del` and `/C xcopy …`.

### CHECKSUM.EXE

- **Location:** `CUSTOM/CHECKSUM.EXE`. `M4W_MCI/*.BAT` rebuild it from
  `M4W_MCI/CHECKSUM.PAS` each time (`call bp checksum.pas`).
- **Status:** present, with source. Rebuilt with the reconstructed
  `TURBO.TPL`, it is identical to the shipped one.
- **Called by:** `CheckSum FULL\MOD4WIN.EXE`, `CheckSum inst_mci.exe`,
  `CheckSum m4w_mci.dll` and `checksum ..\setup\MCI_full\m4w_mci.txt`.
- **Used for:** writing a size and checksum into a signature block inside the
  binary. The program's `Check` unit verifies it at runtime and detects
  tampering.
- **Blocks if missing:** the self-check in released builds. If the checksums
  are left out, builds compiled with `/DCHECK` refuse to run or warn.
- **Also:** like `setup.pas`, it sets the file's time stamp to today's date at
  `VerMaj:VerMin` (02:40 for 2.40).
- **Note:** it `uses crt`, and its `Crt` carries the original machine's
  Runtime Error 200 fix (see [TURBO.TPL](#tpwtpl-turbotpl-tpptpl-runtime-libraries)).

### setup.pas / setup.exe: build driver ("ValidateMod4WinCopy")

- **Location:** `SOURCE/setup.pas`. A newer variant is `SOURCE/newsetup.pas`.
- **Status:** present.
- **Called by:** `SOURCE/MAKE.BAT`:
  `call bp setup`, then `setup -p.\setup\M4W_FULL\ -u"2.40 Last Beta" -lUSA -lGER`.
- **Used for:** compiling `MOD4WIN` (as `.fxe` for the full version or `.sxe`
  for shareware), `PLAYER32.DLL`, the `RES_*` and `INST_*` DLLs, and
  `INSTALL.EXE`. It also writes the user name and checksums into the
  binaries, compresses the files, builds the help files, and copies
  everything to the target directory or floppy.
- **Blocks if missing:** the release packaging. It has the same `Crt` and
  error-200 problem as `CHECKSUM.EXE`, and it uses `HyperApi`.

---

## 6. Compression and packaging

What the finished packages contain, and how each one is produced, is described
in [INSTALLERS.md](INSTALLERS.md).

### COMPRESS.EXE: Microsoft-compatible file compressor (`*.EX_`, `*.DL_`, `*.HL_`)

- **Original location:** `<ROOT>\compiler\compress.exe` (28 Jan 1997).
- **Status:** replaceable: `UTILS.ZIP` on the BP disks.
- **Called by:**
  - `setup.pas`: `compress mod4win.exe mod4win.ex_`, the same for
    `player32.dll`, `res_*.dll` and the help files.
  - `SOURCE/MAKE.BAT`: `compress CUSTOM\FULL\MOD4WIN.EXE CUSTOM\FULL\MOD4WIN.EX_`.
- **Used for:** producing the compressed files that `INSTALL.EXE` expands
  (with `LZExpand`).
- **Blocks if missing:** the installer packages. The program itself still
  builds.

### PKZIP

- **Original location:** on `PATH`.
- **Status:** **PKZIP 2.50 for DOS** (03-01-1999, shareware), the version the
  original build used. Running it with a 32-bit DPMI host, as under XP,
  reproduces the shipped ZIPs byte for byte.
  `setup.sh` runs `pk250dos.exe` in the guest (and only there), in
  `C:\TOOLS`; it reports "Authentic files Verified!". PKZIP accepts
  `MAKE.BAT`'s command line unchanged, and under XP uses its 32-bit
  protected-mode compressor. The PKZIP 2.50 CLI for Windows 95/NT doesn't
  fit.
- **Called by:**
  - `SOURCE/MAKE.BAT`: `pkzip M4WDISK.ZIP .\setup\M4W_FULL\*.* -a -ex -p -r`
    and two similar calls.
  - `MAKERJ.BAT`: `pkzip W:\M4W_HTML\MOD4WIN.COM\files\rjmod4wn rjmod4wn.exe`.
- **How it was identified:** from the shipped archives' headers, and by
  testing the DOS and Windows editions and the compressor modes; see
  [FINDINGS.md](FINDINGS.md#pkzip-250-for-dos).
- **Blocks if missing:** the distribution archives only. Any ZIP tool that
  produces compatible archives works.

### WZIPSE: WinZip Self-Extractor

- **Original location:** on `PATH`, a Windows program.
- **Status:** in the XP guest, installed with its own setup and run by
  `MAKE.BAT` itself; all three installers come out identical
  ([WINXP.md](WINXP.md)). The original build ran it from its Windows DOS
  prompt (`start /w`; see [COMMAND.COM](#commandcom-and-xcopyexe-dos-shell)).
- **How the original found `WZIPSE`:** as a renamed `WZIPSE32.EXE` in a short
  directory on the `PATH` (in the guest `C:\TOOLS\WZIPSE.EXE`), with its help
  file, `.ini` and `winzipse.dat` next to it. Evidence from XP:
  - Started from `C:\Program Files\WinZip Self-Extractor` (through an App
    Paths entry for `WZIPSE.EXE`), it refuses `MAKE.BAT`'s options with "The
    command line is too long": the program's path counts toward its limit.
  - A copy elsewhere stops with "Help file not in same folder as executable"
    unless `WINZIPSE.HLP` is beside it, and asks to accept the license again
    unless its `winzipse.ini` is too.
- **The original was WinZip Self-Extractor 2.1, registered,** most likely its
  32-bit builder `WZIPSE32.EXE` (`wzipse21.exe`, files dated 1997-07-16): it
  reproduces all three installers byte for byte. How the version is
  identified: [FINDINGS.md](FINDINGS.md#winzip-self-extractor-21).
- **Registration matters.** The stub stores the licensee's name in its
  settings block, and the shipped installers say "Kay Bruns". An evaluation
  copy leaves the name empty, so its output differs.
  - The registration is a file `winzipse.dat`, which must be in the same
    directory as the executable: the program reads `<exe dir>\winzipse.dat`,
    not the current directory's.
  - The registration file is yours and never stored here; `setup.sh` takes
    it from `inputs/` and requires it.
  - Unregistered, WinZip SE shows an evaluation notice on every run, which
    would stop a headless `MAKE.BAT` at each of its three calls. Its
    installers have the same ZIP data, but their settings block lacks the
    name (8 bytes shorter).
- **Called by:** `SOURCE/MAKE.BAT`:

  ```
  start /w WZIPSE M4WDISK.ZIP -setup -3 -i intl\m4w.ico -t intl\M4W_WZSE.TXT -auto -st"MOD4WIN Install" -C INSTALL.EXE
  ```

  It is also used for `-C INST_MCI.EXE`. Its inputs `INTL/M4W.ICO` and
  `INTL/M4W_WZSE.TXT` are present.

- **Used for:** turning the ZIPs into `m4w24ins.exe`, `m4w24cin.exe` and
  `mci24ins.exe`: self-extracting archives that run the installer after
  unpacking.
- **Blocks if missing:** the single-file installers only.

### FORMAT.COM and LABEL.EXE: DOS disk utilities

- **Original location:** `F:\MOD4WIN\COMPILER\format.com`. `label.exe` was on
  `PATH`.
- **Status:** substitute: the DR DOS 6.0 `FORMAT.COM` and `LABEL.COM`.
  `setup.pas` passes MS-DOS switches (`/autotest /F:1.44`), which the DR DOS
  `FORMAT` may not accept.
- **Called by:** `setup.pas`: `format <drive>: /autotest /F:1.44` and
  `label <drive>: MOD4WIN <n>`.
- **Used for:** preparing labelled distribution floppies.
- **Blocks if missing:** floppy output only. Building to a directory works.

---

## 7. Help compiler

### HCP.EXE: Microsoft Windows Help Compiler (protected-mode)

- **Location:** `HELP/HELPCOMP/HCP.EXE`, and per language under
  `INTL/M4W_*/HELP/HELPCOMP/`.
- **Status:** present, with `.HPJ`, `.RTF`, `.SHG` and `.BMP` sources per language.
- **Called by:** `HELP/M4W_*.BAT` (`..\helpcomp\hcp.exe modushlp.hpj`), which
  `setup.pas` runs for each selected language.
- **Used for:** building `m4w_usa.hlp`, `m4w_ger.hlp` and the other help files.
- **Behaviour:** runs under XP's DOS subsystem.
  - The shipped help files are its output (version 21, from 1998–99).
  - Rebuilds of six languages have the same content; only the compile time
    and memory left in padding differ.
  - The German project has since been converted to Microsoft Help Workshop
    (2000), so it no longer reproduces the shipped German help. See
    [BIT_EXACT.md](BIT_EXACT.md#help-files).
- **Blocks if missing:** the help files.

---

## 8. Other components

### Delphi 2 compiler (`dcc32`)

- **Called by:** `call bpw32 dstest32` (`IFACE32/MAKE.BAT`, through the
  recreated `BPW32.BAT`). `M4W_MCI/Delphi32/MCITest32.dpr` isn't in any
  script; its `.DSK` file shows it was built from the IDE.
- **Used for:** two 32-bit console test programs, neither part of the product:
  `DSTEST32` plays `NO-SN.XM` through `PLAYER32.DLL` via `IFACE16.BIN`, and
  `MCITest32` plays it through the MCI driver. Only `MCITest32.exe` is in the
  repository to compare with.
- **Result:** the shipped `MCITest32.exe` was built with
  - the **Delphi 2.0** compiler (`DCC32.EXE` 9.0 and `RLINK32.DLL`, from
    Delphi Desktop 2.0);
  - the **Delphi 2.01** units (`LIB\` from Delphi Developer 2.01);
  - a `SYSTEM.DCU` rebuilt from the 2.01 RTL source with a fixed memory
    manager: in 2.01's `GETMEM.INC`, `DeleteBlock` never returns block
    descriptors to `blockDescFreeList`. **C++Builder 1.0**'s `GETMEM.INC` is
    2.01's plus exactly that fix.

  Compiled with `DCC32 -CC -B -$A-,B-,D-,I-,L-,O+,R-,S-,V+,X+,Y-,H+,J+,P+,Q-,T-,U-,W-,Z+`
  (the switches from the `.DOF`), this gives the shipped file except one byte.
  The evidence: [FINDINGS.md](FINDINGS.md#delphi-2).

- **The one differing byte** is file offset 0xFF: 0x83 in the shipped file,
  0x00 in every rebuild. It is the last padding byte before the PE header
  (at 0x100), and **unused**:
  - Windows finds the PE header through the pointer at 0x3C and ignores the
    stub area; the PE checksum is 0, so no checksum covers it.
  - Under DOS the stub prints "This program must be run under Win32" (the
    text ends before 0xFF), and no instruction reads that address.
  - No Borland tool on the three media writes a non-zero byte there: all 112
    Borland-built PE files on them have 0x00, and so does the output of the
    Delphi 2.0 and 2.01 IDEs. The likeliest source is uninitialised memory in
    the original IDE run, which can't be reproduced.
- **Status:** installed in the guest by `setup.sh` in `C:\BORLAND\DELPHI32`:
  - the Delphi Developer 2.01 CD's setup (Full), which also writes
    `BIN\DCC32.CFG` with the unit path and aliases;
  - `SYSTEM.DCU` rebuilt from the installed 2.01 RTL source with C++Builder
    1.0's `SYS\GETMEM.INC` (2.01's kept as `GETMEM.ORG`; the file comes from
    C++Builder's InstallShield 3 `DATA.Z`, unpacked with `tools/is3x.py`):
    the 33 `.ASM` modules assembled with Turbo Assembler 3.2 from `E:\BP`
    (Borland's makefile wants `TASM32` 4.0+, which isn't available), then
    `SYS\SYSTEM.PAS` compiled with 2.01's `DCC32 -y -z -$D-`. TASM 3.2 writes
    16-bit fixups for external data declared outside a segment, which `DCC32`
    rejects in `HALT.ASM` and `OPENFILE.ASM`; a `.DATA` line before their
    `EXTRN`s fixes that without changing the code (`tools/patches.py`;
    originals kept as `*.ORG`);
  - Delphi Desktop 2.0's `DCC32.EXE` and `RLINK32.DLL` (from its `DATA.Z`)
    over 2.01's, which are kept as `*.ORG`.
- **How it runs:** `DCC32.EXE` is a 32-bit Windows console program (its 32RTM
  stub needs `32RTM.EXE`, which came with Borland C++, not Delphi), so it
  can't run in plain DOS. It runs from a Windows DOS prompt. It
  doesn't read `.DOF` files: building `DSTEST32` as a console program takes
  `-CC` or a `DSTEST32.CFG`, neither of which is in the repository, so the
  original `BPW32.BAT` probably passed such options. The recreated one passes
  only its arguments.
- **What's needed from Delphi** (no IDE): `DCC32.EXE`, `RLINK32.DLL` and the
  whole `LIB\` (`MCITest32` needs only `System`, `Windows` and `MMSystem`, but
  `DSTEST32` pulls in most of the VCL through `Dialogs`). The VCL source isn't
  needed.
- **Blocks if missing:** these two test programs only.

### TASM / TLINK: Turbo Assembler

- **Status:** replaceable: `TASM.ZIP` on the BP disks. TASM 3.2 built
  `m4w231/PLAYER/FILTER/CPUID.OBJ`.
- **Called by:** no current Mod4Win build script. The environment uses it to
  rebuild Borland Pascal's run-time library and Delphi's `System` unit.
- **Used for:** `IT/AWE32DRV.ASM`, `IT/M12BIT.ASM`, `IT/M32BITI.ASM` (and the
  old `CPUID.ASM`).
- **Blocks if missing:** the `IT/` experiments only.

### Impulse Tracker driver includes (`drhead.inc`, `vtable.inc`, `reqproc.inc`)

- **Status:** replaceable. Jeffrey Lim released the Impulse Tracker source
  under the BSD-3-Clause license: <https://github.com/jthlim/impulse-tracker>.
  All three files are in its `SoundDrivers/` directory, and `MAWE.BAT` there
  shows how the AWE32 driver is built.
- **How the `IT/` files relate to it:** `IT/M12BIT.ASM` and `IT/M32BITI.ASM`
  are identical to that repo's `SoundDrivers/M12BIT.MIX` and
  `SoundDrivers/M32BITI.MIX`. `IT/AWE32DRV.ASM` (1998) is an earlier, modified
  version of `SoundDrivers/AWE32DRV.ASM`. It differs in, for example, the
  status-line format (it shows "k RAM" instead of a DMA channel), in some
  initialisation tables, and it lacks `DMABuffer`.
- **Assembles:** with the three `.INC` files from that repo (commit `58c44e4`)
  next to it, `IT/AWE32DRV.ASM` assembles with TASM 3.2 from
  `TASM.ZIP` (`tasm /m /ut310 awe32drv`, as in `MAWE.BAT`) with no errors and
  no warnings. The newer `REQPROC.INC` table is a superset of what the 1998
  driver uses. Linking (`tlink /3`, which needs `DPMI16BI.OVL`/`RTM.EXE`) and
  `EXECOM.COM` (in the same `SoundDrivers/` directory) were not run.
- **Used for:** `IT/AWE32DRV.ASM`, which uses `include` for all three.
- **Blocks if missing:** the `IT/` AWE32 driver experiment only.
- **Note:** `old_versions.zip` has one more file from this directory that is
  not in `IT/`: `M4W240lb/IT/AWESTUFF/AWE32.ASM`.

### TRLPLAY.386, TRLPLAY.VXD, TRLPLAY.SYS: Trinity Labs helper drivers

- **Location:** `DEFAULTS/`.
- **Status:** binaries present; sources missing.
- **Likely source:** Trinity Labs Germany (1996). Rebuilding them needs the
  Windows 3.1, 95 and NT DDKs. A web search found no public trace of TRLPLAY
  or of Trinity Labs Germany. The drivers were probably written for Mod4Win
  by people close to the (German) authors, so the original authors are the
  only realistic source. Failing that, the drivers would have to be
  disassembled; they are small (6.7, 7.2 and 7.4 KB).
- **Searched (Oct 2026):** web searches for "Trinity Labs Germany", TRLPLAY
  and the authors' names find nothing relevant. The Discmaster index of
  shareware CDs (125 hits for "trlplay") lists `TRLPLAY.*` only inside
  Mod4Win archives, never with source files and never in another product.
  It does have several older builds of the binaries (dated 1996-07-17/26, 1997-01-16,
  1997-01-27/28, 1997-02-05, 1997-03-10 and 1997-09-18), which match the
  `WHATSNEW.TXT` entries about new TRLPLAY versions and could help with
  disassembly. "Trinity Labs Germany" appears to be a name used by the Mod4Win
  authors themselves; the NT driver's exports (`TrlPlayMapPorts`,
  `TrlPlayMULTIO`, `TrlPlayIOControl`) and the service name
  "Trinity Labs Helper Service" in `PLAYER32.DLL` fit that.
- **Used by:** the `PrtLayer` unit at runtime: high-resolution timer callbacks
  and port or memory-mapped I/O. `setup.pas` copies them to the distribution.
- **Blocks if missing:** nothing in the build. Without the drivers the player
  falls back to its normal timer at runtime.

### W8LOSS.EXE, RTM.upx

- **Original location:** `<ROOT>\compiler\` (`dir.txt`).
- **Status:** missing; no script references them.
- **Likely source:** `W8LOSS` was a third-party Borland EXE size reducer.
  `RTM.upx` is an UPX-packed `RTM.EXE`, added in 2008.
- **Blocks if missing:** nothing.
