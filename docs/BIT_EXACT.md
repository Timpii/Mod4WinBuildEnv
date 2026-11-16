# Bit-exact rebuild

How closely the environment reproduces the shipped 2.40 files, what the
remaining differences are, and how to track down differences like them.

## Status

After `./setup.sh` from scratch, `./build.sh` (the original, unmodified
`SOURCE\MAKE.BAT` in the Windows XP guest, [WINXP.md](WINXP.md)) produces:

| File                                                                        | Result                                                                                                                                      |
| --------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------- |
| `PLAYER/PLAYER32.DLL`, `setup/m4w_full/PLAYER32.DL_`                        | identical                                                                                                                                   |
| `M4W_MCI/M4W_MCI.DLL`                                                       | identical                                                                                                                                   |
| `setup/mci_full/INST_MCI.EXE`, `M4W_MCI.TXT`                                | identical                                                                                                                                   |
| `setup/m4w_full/INSTALL.EXE`, `INST_USA.DLL`, `INST_GER.DLL`, `INSTALL.INF` | identical                                                                                                                                   |
| `setup/m4w_full/RES_*.DL_`, `M4W_*.HL_`, text files, modules, `TRLPLAY.*`   | identical                                                                                                                                   |
| `CUSTOM/Full/MOD4WIN.EXE`, `setup/m4w_full/MOD4WIN.EX_`                     | differ: source revision of `REGDLG.PAS` and `RLINK`'s default, see [below](#the-remaining-difference-regdlgpas); with `SHIPPED=1` identical |
| time stamps of everything in `setup\M4W_FULL` and `setup\MCI_FULL`          | identical                                                                                                                                   |
| the PKZIP archives                                                          | identical, except `MOD4WIN.EX_` inside (see [Packaging](#packaging)); with `SHIPPED=1` identical                                            |
| `setup/mci24ins.exe`                                                        | identical                                                                                                                                   |
| `setup/m4w24ins.exe`, `m4w24cin.exe`                                        | identical except `MOD4WIN.EX_` inside; with `SHIPPED=1` identical                                                                           |

So the whole chain, from sources to installers, is reproducible byte for
byte. From the repository as it is, everything but `MOD4WIN.EXE` is;
`SHIPPED=1` makes the [`REGDLG.PAS` revision and the `RLINK`
option](#the-remaining-difference-regdlgpas) of the shipped `MOD4WIN.EXE` in
the build's copy, and then it and all three installers are identical too.

`RES_*.DLL`/`.DL_`, `INSTALL\INST_*.DLL` and `HELP\M4W_*.HL_` are reused from
the repository, because `setup.pas` skips files that exist (as it would have in
the original developer's tree); `CLEAN=1 ./build.sh` deletes them first. A
strict run with every prebuilt output deleted first (`RES_*`, `INST_*.DLL`, `*.HL_`, `PLAYER32.*`, `M4W_MCI.DLL`,
`CUSTOM\Full\*`; only the `.hlp` files kept) gives the same result as the table
above: all staged files and their time stamps identical except `MOD4WIN.EX_`.
Rebuilt from source, they compare as follows.

| File                                                                                         | Rebuilt by                                           | Result                                                          |
| -------------------------------------------------------------------------------------------- | ---------------------------------------------------- | --------------------------------------------------------------- |
| `RES_USA.DLL`, `RES_GER.DLL` and their `.DL_`                                                | `setup.pas` (with `TransferCheckSum` and `COMPRESS`) | identical                                                       |
| `INSTALL/INST_USA.DLL`, `INST_GER.DLL`                                                       | `setup.pas`                                          | identical                                                       |
| `HELP/m4w_usa.hlp`, `m4w_fre.hlp`, `m4w_spa.hlp`, `m4w_grk.hlp`, `m4w_ita.hlp`, `m4w_nl.hlp` | `HELP\M4W_*.BAT` (`HCP.EXE`)                         | same content, not byte-identical (see below)                    |
| `HELP/m4w_ger.hlp`                                                                           | `HELP\M4W_GER.BAT`                                   | differs: the German help source was revised in 2000 (see below) |

Other build scripts:

| File                                           | Built by                                                                        | Result                                                                                              |
| ---------------------------------------------- | ------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------- |
| `IFACE32/PLAYTEST.EXE`, `IFACE32/DSTEST16.EXE` | `IFACE32\MAKE.BAT`                                                              | identical                                                                                           |
| `IFACE32/IFACE16.BIN`                          | `IFACE32\MAKE.BAT`                                                              | differs: the repository's file was linked with an older `W32Base` (see below)                       |
| `M4W_MCI/Delphi32/MCITest32.exe`               | Delphi 2 (`xp/jobs/IFACE32.CMD`; from the IDE originally)                       | identical except one unused padding byte ([BUILD_TOOLS.md](BUILD_TOOLS.md#delphi-2-compiler-dcc32)) |
| `CUSTOM/CHECKSUM.EXE`                          | `call bp checksum.pas` (`M4W_MCI\MAKE.BAT`), with the reconstructed `TURBO.TPL` | identical                                                                                           |

`MAKEDEMO.BAT`, `MAKERJ.BAT`, `MKEWSPLY.BAT`, `DEBUG.BAT` and the translation
kits' help scripts (`INTL\*\HELP\*.BAT`) build, but the repository has no
copies of their outputs to compare with. `DSTEST32` (Delphi)
has none either.

### Help files

- **The shipped help files are older than 2006.** They're all `HCP` 3.10
  output (`|SYSTEM` version 21): USA and German compiled 1998-11-17, the other
  five languages 1999-02-04. The 2006 package reuses them; its `M4W_*.HL_`
  files are exactly the repository's `.hlp` files compressed.
- **Six languages are reproduced in content.** For USA, French, Spanish, Greek,
  Italian and Dutch, the help text (`|TOPIC`), all bitmaps and the other
  internal files are identical. The differences are limited to these:
  - `|SYSTEM`: the compile time, plus a few bytes of the window definition.
  - `|FONT`: padding after the font names.
  - The three B-tree indexes (`|KWBTREE`, `|TTLBTREE`, `|CONTEXT`) and the
    help file's directory: unused space.

  `HCP` writes uninitialised memory into that padding and unused space, so it
  can't be reproduced byte for byte.

- **German isn't reproducible from the repository.** `HELP\GER\MODHELP.HPJ` was
  converted to Microsoft Help Workshop (HCW, WinHelp 4) in 2000.
  `HELP\GER\MODHELP.HLP` (`|SYSTEM` version 33, 2000-05-10) is that newer
  build, but the 2.40 package still ships the 1998 `HCP` one. `HCP` 3.10
  compiles the converted project into a smaller file with different text and
  fewer bitmaps.

### `IFACE16.BIN`

`IFACE16.PAS` and `PLAYPROC.PAS` compile to the shipped code. The file was
linked with an older revision of the shared `W32Base` unit, though:

- 808 bytes of code instead of 544.
- Its wrapper routines are exported, and its initialization also looks up
  `GetLastError`.
- It sits in the main code segment instead of next to `Strings`.

So the repository's `IFACE16.BIN` is left over from an earlier build (the
`IFACE32` sources date from 1996–97). Run with the 2006 units, as on the
original machine in 2006, `IFACE32\MAKE.BAT` produces the rebuilt version.

### Packaging

`MAKE.BAT` runs its packaging steps itself, and the results are exact:

- PKZIP uses its 32-bit protected-mode compressor (XP provides DPMI). Without
  DPMI, PKZIP 2.50 uses its 16-bit real-mode compressor, and seven of the 18
  entries compress a few bytes differently (see
  [BUILD_TOOLS.md](BUILD_TOOLS.md#pkzip)).
- WinZip SE 2.1 builds the installers. With `SHIPPED=1`, `m4w24ins.exe`,
  `m4w24cin.exe` and `mci24ins.exe` are all byte-identical to the shipped ones.
- That needs WinZip SE registered to the original licensee: each
  installer's stub stores the licensee's name from the registration
  (`winzipse.dat`), and the shipped ones say "Kay Bruns". With a
  registration to another name, the three installers differ in that name
  (and the settings block's length); their ZIP data is the same
  ([BUILD_TOOLS.md](BUILD_TOOLS.md#wzipse-winzip-self-extractor)).
- Two details of the original machine matter here
  ([WINXP.md](WINXP.md#what-the-original-machine-evidently-had)): F: on NTFS
  (the order of the ZIP entries) and `WZIPSE` in a short directory.

## What the environment reproduces

Beyond the rebuilt units ([MISSING_UNITS.md](MISSING_UNITS.md)), these details
of the original machine matter. This table says what the
environment sets and where; the evidence for each is in
[FINDINGS.md](FINDINGS.md#at-a-glance).

| Detail                                                                                | Effect                                                         | Where                                                                   |
| ------------------------------------------------------------------------------------- | -------------------------------------------------------------- | ----------------------------------------------------------------------- |
| `BPC.CFG` switches, including `/$K-`                                                  | code generation, callback prologues                            | `files/F/MOD4WIN/COMPILER/BPC.CFG`                                      |
| run-time library rebuilt from source                                                  | System without FPU-emulation padding, 286 code, fixed segments | `tools/patches.py`, `setup.sh`                                          |
| ObjectWindows rebuilt from source, with a `MoveWindow` added to `TWindow.SetupWindow` | OWindows/ODialogs code                                         | `tools/patches.py`, `setup.sh`                                          |
| `PLAYER/TASK.RES` with resource flags 0                                               | NE resource table                                              | `M4W230/TASK.RES` from the repository's `old_versions.zip` (`build.sh`) |
| older `Coroner` on the unit path                                                      | `M4W_MCI.DLL`                                                  | `files/F/MOD4WIN/M4W_MCI/CORONER.PAS`                                   |
| project at `F:\MOD4WIN`, drives C/E/F, `PATH`                                         | `setup.pas` and the batch files work unchanged                 | `setup.sh`                                                              |
| date 2006-12-10                                                                       | time stamps; forces full recompiles (below)                    | the guest's clock (`xp/lib.sh`)                                         |
| original time stamps of `DEFAULTS\*` and `WHATSNEW.TXT`                               | time stamps inside the packages                                | `build.sh` (`stage_project` in `xp/lib.sh`)                             |
| `Crt` with the Runtime Error 200 fix, DOS units with `$G+` (`TURBO.TPL`)              | `setup.exe` runs on fast CPUs; `CHECKSUM.EXE`                  | `tools/patches.py`, `setup.sh`                                          |
| F: on NTFS                                                                            | order of the ZIP entries                                       | XP guest                                                                |

### The build date

`setup.pas` and `CHECKSUM.EXE` stamp what they produce with today's date and
the time `VerMaj:VerMin`, so 02:40 for 2.40. Every built file in the shipped
packages says 2006-12-10 02:40:00. The original build machine's DOS date was
therefore 2006-12-10.

That date also affects what gets compiled. BPC's make mode (`/M`) recompiles a
unit when its source is newer than its `.TPW`. Under a clock set to 2006, the
build's `.TPW` files are always older than the source files, so every
compilation recompiles every unit from source. That is visible in the shipped
`INSTALL.EXE`:

- `setup.pas` compiles `MOD4WIN.PAS` first and `INSTALL.PAS` with `/DShare`
  later. Both use `modc`, whose typed constant `Registered` depends on `Share`.
- With a correct clock, the second compilation reuses `modc.tpw` from the first,
  and `Registered` comes out `True`.
- The shipped `INSTALL.EXE` has `False`, so `modc` was recompiled.

The guest's clock therefore starts at 2006-12-10 (QEMU's `-rtc base=…`,
running only while the guest runs). That is the guest's own clock; the host
clock is never touched.

## The remaining difference: `REGDLG.PAS`

`MOD4WIN.EXE` (both editions) was compiled from a slightly different
`REGDLG.PAS`. In `TRegWin.WMCommand` the repository has:

```pascal
        RegCloseKey (Key);
      END ELSE BEGIN
        { can't create key }
      END;
```

The shipped code has no `ELSE` branch: the empty branch compiles to a 2-byte
jump that isn't there. With the `ELSE BEGIN … END` removed:

- `setup/m4w_full/MOD4WIN.EX_` (standard edition) is identical;
- `CUSTOM/Full/MOD4WIN.EXE` is identical if `RLINK` also gets `-31`.

The original `RLINK` evidently marked programs as Windows 3.10 by default (see
[BUILD_TOOLS.md](BUILD_TOOLS.md#rlinkexe-borland-resource-linker)). The 2006
snapshot in `old_versions.zip` (`M4W240lb`, 2006-06-21) already has the empty
branch, so the shipped `MOD4WIN.EXE` was built from an edit in between, or the
branch was added after the build. By default the environment doesn't change
the sources, so it reproduces the repository as it is.

To reproduce the shipped file exactly, build with `SHIPPED=1 ./build.sh`,
which makes these edits in the build's copy (`tools/patches.py shipped`), or
make them by hand in a copy of the repository (`REPO=copy ./build.sh`):

1. Remove the three lines above from `SOURCE/REGDLG.PAS`, so it reads
   `RegCloseKey (Key);` and then `END;`.
2. In `CUSTOM/MAKE.BAT`, add `-31` to both `rlink` calls.

`MOD4WIN.EXE`, `MOD4WIN.EX_` and all three installers are then
byte-identical.

## What remains unknown

Of these, only the `REGDLG.PAS` revision and the `RLINK` default affect the
main build's output, and `SHIPPED=1` makes up for both; the older `W32Base`
and the byte at 0xFF affect the side build's `IFACE16.BIN` and
`MCITest32.exe`.

- **The 1999 hardware edition** (`M4W240HW.ZIP`): its sources aren't in the
  repository. Sources reconstructed from the binaries rebuild `INSTALL.EXE`,
  `MOD4WIN.EX_` and `PLAYER32.DL_` byte for byte
  ([INSTALLERS.md](INSTALLERS.md#can-it-be-built)); the original files, their
  unit names and routine names are partly unknown.
- **How `WZIPSE` was installed exactly:** a renamed `WZIPSE32.EXE` in a short
  `PATH` directory works and is what the evidence points to; the original
  directory, and whether the whole package was installed there, aren't known.
- **Missing original tools:**
  - the `RLINK` version that marks programs as Windows 3.10 by default (it
    affects `CUSTOM/Full/MOD4WIN.EXE`; `SHIPPED=1` passes `-31` instead);
  - the local `BPC.EXE` patch (it doesn't affect code generation);
  - the options the original `BPW32.BAT` passed to `DCC32` (at least `-CC`
    for `DSTEST32`).
- **`F:\DOSUNINT` and `F:\EXE`:** their original contents. Nothing in the
  repository needs `F:\DOSUNINT`: every DOS program and `MAKECODE`'s DOS
  branch compile without it, and no binaries exist to rebuild its units from.
  `F:\EXE` is only the Delphi projects' output directory.
- **The `REGDLG.PAS` revision** the shipped `MOD4WIN.EXE` was built from
  isn't in the repository (above), nor is the older `W32Base` in
  `IFACE16.BIN`, nor what put the byte at 0xFF in `MCITest32.exe`.

## Finding source revisions

This is how every difference above was found. Use the same method for the
1999 hardware edition (`M4W240HW.ZIP`) or any other revision question.

1. **Build with a map.** For example with a job (`./build.sh job FILE.CMD`)
   that runs, in `F:\MOD4WIN`:
   `COMPILER\BPC /Q /B /DCheck /GD /EF:\OUT mod4win.pas`.
   - Use the same defines as `setup.pas` or the `MAKE.BAT` in question.
   - `/GD` writes a detailed map: each unit's segment, offset and size, and
     the public symbols.
2. **Compare segment by segment:** `python3 research/cmpne.py ORIGINAL REBUILT`.
   This counts differing bytes per segment, ignoring relocated bytes.
   - Equal lengths with zero differences: done.
   - Different lengths: a unit's code differs, or units landed in different
     segments.
3. **Find the units:** `python3 research/locate.py REBUILT MAPFILE ORIGINAL`
   matches each unit of the map against the original's code. A unit found at
   another offset or in another segment is a layout difference. A weak match
   ("anchor" much smaller than the unit) is a code difference.
4. **Diff a unit:** `python3 research/cmpunit.py REBUILT SEG OFF LEN ORIGINAL SEG
OFF`. This lists instruction differences with addresses masked. Typical
   causes:
   - an extra or missing statement: a source revision, such as `RegDlg`;
   - near/far calls, prologues, 286 instructions: compiler switches;
   - shifted data offsets only: a layout difference elsewhere.

   For many units at once, `python3 research/diffunits.py REBUILT MAPFILE
ORIGINAL LOCFILE UNIT...` (LOCFILE is `locate.py`'s output) lists every
   differing place with its source file and line from the map, ignores
   address-only differences, and marks places that differ by one constant
   offset (`[shift +N]`, a moved field or variable). A unit given as
   `NAME@SEG:START..END=SEG:START..END` uses those ranges instead of
   `locate.py`'s.

5. **Disassemble:** `python3 research/nedis.py FILE SEG START STOP` to read the
   original code, with relocations, imported functions and strings
   annotated. Then change the source until `cmpunit.py` is clean.
6. **Layout differences.** To see the real unit link order, compile a copy of
   the main program with `{$S 16}` instead of `{$S 60000}`: every unit gets
   its own segment, numbered in link order. Then compare with the rules in
   [MISSING_UNITS.md](MISSING_UNITS.md#layout-details):
   - Data shifts usually mean a typed constant was added or removed, or sits in
     a different `CONST` section.
   - Variable shifts usually mean a different link order.

`python3 research/szdd.py FILE.EX_ FILE.EXE` expands compressed files
(`*.EX_`, `*.DL_`) for comparing.

The tools need Python 3 and `objdump` (binutils). Imported functions are shown
by ordinal unless `WINE_SPEC_DIR` points to Wine's `.spec` files.
