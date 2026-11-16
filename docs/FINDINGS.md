# The original build machine

What is known about the machine that built Mod4Win 2.40, and how the tools
whose versions the repository doesn't record were identified. What the
environment uses is in [BUILD_TOOLS.md](BUILD_TOOLS.md).

## At a glance

| Aspect | Finding | Evidence |
|---|---|---|
| Operating system | a DOS prompt under 32-bit Windows, not plain DOS; probably NT-based (2000/XP) | `start /w` in `MAKE.BAT`; `WZIPSE32.EXE` is a Win32 program; `MAKE.BAT`'s `PATH` has no Windows directory, so `start` was most likely `cmd.exe`'s built-in; 2006 `GetOS` forces NT |
| Drives and directories | `C:\TOOLS`, `E:\BP`, `E:\TD`, `F:\COMPILER`, `F:\WINUNIT`, `F:\DOSUNINT`, `F:\EXE`, project at `F:\MOD4WIN` with `_BURGER_`; `W:\M4W_HTML\MOD4WIN.COM\FILES` (the web site); `X:\SOUND\MOD4WIN\MCI_DEMO` | `PATH` in every `MAKE.BAT`; `CLEANUP.BAT`; `setup.pas`; old Delphi `.DSK`/`.DOF` files; `MAKERJ.BAT`, `MAKEDEMO.BAT`, `MKEWSPLY.BAT` |
| Delphi | Delphi 2.0 compiler with 2.01 units and a `System` rebuilt with a memory-manager fix (the one in C++Builder 1.0); built from the IDE in `C:\Borland\Delphi32`; for two test programs only | `IFACE32/README.TXT`; `.DSK` files; `MCITest32.exe` reproduced except one padding byte |
| Compiler | Borland Pascal 7.01 `BPC.EXE`, with an unidentified local patch (`BPC.ORG` backup) that doesn't affect code generation | the 7.01 run-time library in the binaries; the genuine compiler reproduces them |
| `BPC.CFG` | `/CW /M /$V- /$S- /$W- /$G+ /$I- /$K-`, unit path `E:\BP\UNITS;F:\WINUNIT;F:\MOD4WIN\M4W_MCI;F:\MOD4WIN\PLAYER;F:\MOD4WIN\INSTALL;F:\MOD4WIN`, `/I` and `/R` paths | compared code; `setup.pas` calls |
| `TPW.TPL` | rebuilt from Borland's RTL source: TASM without `-e`, project switches, Strings/Win31/WinDos/OMemory with fixed segments | code in the binaries; `dir.txt` (28 Jan 1997) |
| ObjectWindows | rebuilt from source with the project switches (not `$F+`), and `TWindow.SetupWindow` starting with `MoveWindow(...)` | OWindows/ODialogs code in `MOD4WIN.EXE` and `INSTALL.EXE` |
| `F:\WINUNIT` | shared units, rebuilt from the binaries: W32Defs, W32Base, File32, Wave, ValConv, Maths, Crc, MemList, PrtLayer, User32, WOW32, oFarProc, Ctl3DV2, VK_KEYS, TrlNT, TrlVxD, WinSvc, VxDLdr, NoDOSMem, NetDrv, DragDet, plus the 2006 `GetOS` | [MISSING_UNITS.md](MISSING_UNITS.md) |
| An older `Coroner` | on the unit path ahead of the project root (`M4W_MCI\` or `F:\WINUNIT`), used only by the MCI build | `M4W_MCI.DLL`; [MISSING_UNITS.md](MISSING_UNITS.md#coroner-the-revision-in-m4w_mcidll) |
| Build date | the PC's clock was set to 2006-12-10, which also made every `/M` compile recompile all units | `setup.pas`/`CHECKSUM.EXE` stamps (02:40 = version 2.40); `INSTALL.EXE`'s `Registered` byte |
| `RLINK` | a version that marks programs as Windows 3.10 by default | NE header of `CUSTOM/Full/MOD4WIN.EXE` |
| PKZIP | PKZIP 2.50 for DOS with `-ex`, running its 32-bit DPMI compressor (Windows provides DPMI) | reproduces the shipped ZIPs byte for byte in the XP guest |
| F: | an NTFS drive | PKZIP adds files in directory order; the shipped ZIPs are alphabetical, as on NTFS (FAT gives creation order) |
| WinZip Self-Extractor | 2.1, registered to Kay Bruns: `WZIPSE32.EXE` renamed to `WZIPSE.EXE` in a short directory on the `PATH`, with `WINZIPSE.HLP`, its `.ini` and `winzipse.dat` beside it | reproduces all three installers byte for byte in the XP guest; from `C:\Program Files` it refuses the command line as too long, and elsewhere it wants its help file beside it |
| `COMMAND.COM` | on `MAKE.BAT`'s `PATH`, so a copy was in `C:\TOOLS` or a similar directory | `setup.pas` uses `FSearch('Command.com', PATH)` |
| `Crt` (DOS programs) | `TURBO.TPL` rebuilt with a Runtime Error 200 fix: 32-bit `DelayCnt`, multiply instead of `DIV`, timer-only interrupts while calibrating, `$G+` | `CUSTOM/CHECKSUM.EXE` reproduced byte for byte (`tools/patches.py`) |
| Sources | the repository, except `REGDLG.PAS`: the shipped `MOD4WIN.EXE` was built without the empty `ELSE` branch in `TRegWin.WMCommand` | [BIT_EXACT.md](BIT_EXACT.md#the-remaining-difference-regdlgpas) |
| `PLAYER/TASK.RES` | missing from the repository's `PLAYER/`; the 2.30 copy in `old_versions.zip` is byte-identical to the resource in `PLAYER32.DLL` | `PLAYER32.DLL`, `old_versions.zip` |

## PKZIP 2.50 for DOS

- **The shipped archives** (the ZIPs inside `setup/*.exe`) have "version made
  by" 2.5, host "MS-DOS/FAT", no extra fields, maximum deflation, and their
  text files flagged as text (`t`). Their entries are in alphabetical order,
  which is the directory order of an NTFS drive (on FAT it would be creation
  order), so the project was on NTFS.
- **PKZIP 2.50 for DOS** with `MAKE.BAT`'s exact command (`-a -ex -p -r`)
  matches all header fields of all 18 entries: version, host, text flags,
  time stamps and names. `-exx`, `-en` and `-es` don't match; nor does
  anything depend on the memory available.
- **Its compressor depends on DPMI.** PKZIP 2.50 for DOS has two
  compressors: without a DPMI host it uses "16-Bit Real Mode Maximum
  Compression", with a 32-bit DPMI host "32-Bit Protected Mode Maximum
  Compression" (`-)` turns that off). Only the protected-mode compressor
  reproduces the shipped ZIPs byte for byte; with the real-mode one, 7 of the
  18 entries (the larger files) come out a few bytes different. So PKZIP ran
  where DPMI was available, as in a Windows DOS prompt.
- **Not PKZIP 2.50 for Windows 95/NT:** it rejects `MAKE.BAT`'s command line
  ("Ambiguous option … - a"), also with its `-204` 2.04g-compatibility
  switch. With its own syntax (`-add -max -path -recurse`), 9 of 18 entries
  come out a different size (it stores `CRYSTALS.66_` uncompressed), and it
  flags the text files as binary (`b`).
- **Not PKZIP 2.04g:** it writes "made by 2.0", so it can't have made the 2006
  packages. The 1999 `M4W240HW.ZIP` does say 2.0 and was probably made with
  2.04g.

## WinZip Self-Extractor 2.1

- **The 32-bit builder of version 2.1, registered:** `WZIPSE32.EXE` from
  `wzipse21.exe` (files dated 1997-07-16) turns the original ZIPs into
  `m4w24ins.exe`, `m4w24cin.exe` and `mci24ins.exe` byte for byte, with
  `MAKE.BAT`'s options. The 16-bit `WINZIPSE.EXE` of the same package
  reproduces `m4w24ins.exe` but makes `mci24ins.exe` 12 bytes longer.
- **The registration** is in the installers: the stub stores the licensee's
  name in its settings block, and the shipped installers say "Kay Bruns". An
  unregistered copy leaves the name out (the settings block is 8 bytes
  shorter; the ZIP data is the same) and shows an evaluation notice on every
  run.
- **How it was run:** `MAKE.BAT` calls it as `start /w WZIPSE`, so a program
  named `WZIPSE` was on the `PATH` or registered with Windows. A renamed
  `WZIPSE32.EXE` in a short `PATH` directory works, with `WINZIPSE.HLP`, its
  `.ini` and `winzipse.dat` beside it. Started from `C:\Program Files\...`
  (for example through an App Paths entry), it refuses `MAKE.BAT`'s options as
  too long: its own path counts toward the command line's limit. Without the
  help file beside it, it stops with "Help file not in same folder as
  executable".
- **Other versions don't fit:**
  - The shipped stub is a 16-bit Windows program (21312 bytes; 21314 in
    `mci24ins.exe`) saying "Copyright (c) 1995,96 Nico Mak Computing". 2.1
    still writes that string, so it doesn't identify the version.
  - Version 2.2 can't make 16-bit stubs: its `WINZIPSE.EXE` says "The creation
    of 16-bit and MS-DOS self-extracting files is no longer supported".
  - Version 2.0 (`WZIPSE20.EXE`, 1996-09-18) has no `-auto` and no `-st`: it
    reads `-auto` as `-a uto` (About-box text file `uto`). Its stub code also
    differs.
- `-3` in `MAKE.BAT`'s options means "use CTL3D.DLL for 3D effects", not
  Windows 3.1.

## Delphi 2

`MCITest32.exe` was built with Delphi 2.0's compiler, the 2.01 units and a
`System` with C++Builder 1.0's memory-manager fix (details in
[BUILD_TOOLS.md](BUILD_TOOLS.md#delphi-2-compiler-dcc32)). The evidence:

- `IFACE32/README.TXT` says "Delphi 2.0 demo App"; the `.DSK` files point to
  `C:\Borland\Delphi32`, Delphi 2's default directory.
- The shipped file (14848 bytes) has PE linker version 2.25, Borland's fixed
  1992 time stamp, `CODE`/`DATA`/`BSS` sections and the console subsystem.
- Stock 2.0 and stock 2.01 both give the right size but differ in `System`'s
  memory manager; no compiler switch explains it. The fixed `System` does,
  and with 2.01's own `GETMEM.INC` the rebuilt `System` gives exactly the
  stock 2.01 result.
- 2.01's `DCC32` allocates registers differently in `KeyPressed`, so the
  compiler is 2.0's.
- Delphi 3 adds resources the shipped file doesn't have; C++Builder 1.0's own
  `DCC32` (9.3) gives different output and rejects 2.0 units.
- No published Delphi 2.01 memory-manager patch is known. The fix came either
  from Borland outside the 2.01 media or from the developers themselves; the
  original machine also had a locally rebuilt Borland Pascal run-time library.
