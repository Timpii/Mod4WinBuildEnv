# Installer packages

There are four Mod4Win 2.40 distribution packages: the three in `setup/`, and
`M4W240HW.ZIP`, which isn't in the repository (an optional input in
`inputs/`). This file says what each contains, which repository files they
match, and how each was built or could be rebuilt.

`.??_` files are compressed with Microsoft `COMPRESS` (SZDD format). They expand
with `EXPAND.EXE` or, on Linux, `msexpand`.

## Overview

| Package                                | Built                                     | Languages       | Matches the repository                                |
| -------------------------------------- | ----------------------------------------- | --------------- | ----------------------------------------------------- |
| `setup/m4w24ins.exe`                   | 2006-12-10                                | English, German | yes, contents are `setup/m4w_full/`                   |
| `setup/m4w24cin.exe`                   | 2006-12-10                                | English, German | yes, as `m4w24ins.exe`, with the custom `MOD4WIN.EXE` |
| `setup/mci24ins.exe`                   | 2006                                      | English         | yes, contents are `setup/mci_full/INST_MCI.EXE`       |
| `M4W240HW.ZIP` (not in the repository) | 1999-05-03 binaries, packed December 2000 | English, French | no, it's an earlier build with hardware support       |

A separately distributed copy of `m4w24ins.exe` is byte-identical to
`setup/m4w24ins.exe`.

## The 2006 packages (`setup/`)

### Contents

`m4w24ins.exe` and `m4w24cin.exe` are WinZip Self-Extractor 2.1 installers that unpack
to a temporary directory and run `INSTALL.EXE`. Both contain the same 18 files
as `setup/m4w_full/`, except for `MOD4WIN.EX_`:

| File                                                      | Same as                                                   |
| --------------------------------------------------------- | --------------------------------------------------------- |
| `PLAYER32.DL_`                                            | `PLAYER/PLAYER32.DLL`                                     |
| `RES_USA.DL_`, `RES_GER.DL_`                              | `SOURCE/RES_USA.DLL`, `SOURCE/RES_GER.DLL`                |
| `INST_USA.DLL`, `INST_GER.DLL`                            | `INSTALL/INST_USA.DLL`, `INSTALL/INST_GER.DLL`            |
| `INSTALL.EXE`                                             | `setup/m4w_full/INSTALL.exe`                              |
| `MOD4WIN.EX_` in `m4w24ins.exe`                           | the standard `MOD4WIN.EXE` (not in the repo uncompressed) |
| `MOD4WIN.EX_` in `m4w24cin.exe`                           | `CUSTOM/Full/MOD4WIN.EXE`                                 |
| `TRLPLAY.*`, `*.MO_`, `*.66_`                             | `DEFAULTS/`                                               |
| `M4W_*.HL_`, `README.TXT`, `LIESMICH.TXT`, `WHATSNEW.TXT` | help and text files                                       |

The two `MOD4WIN.EXE` files have identical code. They differ only in:

- **Resources:** the custom edition (`cin`) has larger bitmaps, from
  `CUSTOM/MOD4WIN.RES`.
- **Data segment:** `CHECKSUM.EXE` writes a checksum into it.

`mci24ins.exe` contains only `INST_MCI.EXE`, which is
`setup/mci_full/INST_MCI.EXE`. That installer carries `M4W_MCI.DLL` inside it
as a resource (`M4W_MCI/INST_EXE.RC`).

### How they are built

`SOURCE/MAKE.BAT` drives everything. With the recreated `COMPILER/` files and
the rebuilt units (see [MISSING_UNITS.md](MISSING_UNITS.md) and
[BUILD_TOOLS.md](BUILD_TOOLS.md)), the steps are as follows. The build ran with
the DOS date set to 2006-12-10. `setup.pas` and `CHECKSUM.EXE` stamp their
output with that date and the time 02:40 (version 2.40).

1. **`call cleanup`, then `call bp setup`.** This builds `setup.exe`, a DOS
   program.
2. **`setup -p.\setup\M4W_FULL\ -u"2.40 Last Beta" -lUSA -lGER`**, which:
   - compiles `mod4win.pas` (`/Q /DCheck`; `/DDEMO` for shareware),
     `player\player32.pas`, `res_usa/res_ger.pas`, `install\install.pas` and
     `install\inst_usa/inst_ger.pas` with `compiler\bpc.exe`;
   - renames `mod4win.exe` to `MOD4WIN.FXE`;
   - compresses the binaries and help files with `compiler\compress.exe`;
   - copies everything, including `DEFAULTS/` modules, drivers and text files,
     to `setup\M4W_FULL`;
   - writes `INSTALL.INF`.
3. **`CUSTOM\MAKE.BAT`:** two `rlink` steps produce `CUSTOM\FULL\MOD4WIN.EXE`,
   with the custom `MOD4WIN.RES` bound into `MOD4WIN.FXE`. Then `CheckSum` is
   run on it.
4. **`M4W_MCI\MAKE.BAT`:** builds `M4W_MCI.DLL` (`player32.pas` with `/DMCI`)
   and `INST_MCI.EXE` (with `rc -r inst_exe.rc` and `CheckSum`), and copies the
   result to `setup\MCI_FULL`.
5. **Package 1:** `pkzip M4WDISK.ZIP setup\M4W_FULL\*.*`, then `WZIPSE` makes
   `setup\m4w24ins.exe`.
6. **Package 2:** `compress CUSTOM\FULL\MOD4WIN.EXE`, then `pkzip` it into the
   same `M4WDISK.ZIP`, replacing `MOD4WIN.EX_`. `WZIPSE` makes
   `setup\m4w24cin.exe`.
7. **Package 3:** `pkzip` `INST_MCI.EXE`, then `WZIPSE` makes
   `setup\mci24ins.exe`.

**How exact the rebuild is** ([BIT_EXACT.md](BIT_EXACT.md)):

- **Steps 1–4:** everything they produce is byte-identical, with the original
  time stamps, except `MOD4WIN.EXE`/`MOD4WIN.EX_`. Those come from a slightly
  different `REGDLG.PAS`, and for the custom edition an `RLINK` that marks
  Windows 3.10 (`SHIPPED=1` makes up for both).
- **ZIPs:** byte-identical with PKZIP 2.50 for DOS running its 32-bit DPMI
  compressor, as under XP. Without DPMI, 7 of the 18 entries compress a few
  bytes differently.
- **Self-extractors:** a registered WinZip Self-Extractor 2.1 reproduces all
  three; in the XP guest `MAKE.BAT` builds them itself (see
  [BUILD_TOOLS.md](BUILD_TOOLS.md#wzipse-winzip-self-extractor)).

## `M4W240HW.ZIP`: the 1999 hardware edition

The unit-level details are in [HW1999.md](HW1999.md).

### What it is

This is a plain ZIP: no self-extractor, PKZIP 2.0-compatible, made on MS-DOS.
It holds 17 files. The binaries are dated **1999-05-03**, and `INSTALL.INF` and
`LISEZMOI.TXT` are dated 2000-12-12.

"HW" stands for **hardware support**. Its `PLAYER32.DLL` is a different, much
larger build: 143 KB of code in 5 segments, compared with 109 KB in the 2006
DLL. It contains drivers for:

- Gravis Ultrasound and AMD InterWave (GUS PnP), via `ULTRASND`;
- SAM9407 cards (TerraTec EWS64, Hoontech SoundTrack 97/128), via
  `EWSAudio.Drv`, `Dream94.Drv`, `Dream95.Drv`, `ST97.Drv` and `ST128.Drv`.

The 2006 `WHATSNEW.TXT` records the removal (2006/06/21): _"Removed Hardware
support for EWS64, GUS and OPL4"_. OPL4 support was already gone from the
code in 1999: the 1999 binaries test the device IDs `dev_GF1` (−4) and
`dev_EWS` (−5) dozens of times but never `dev_OPL4` (−3), and no OPL4 code
is in the DLL. Only the help file (the same file in 1999 and 2006) still
describes it.

### Compared with the 2006 package

| File                                                       | Relationship                                                                                                                                                                                                                                                                                      |
| ---------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `PLAYER32.DL_`                                             | different build (hardware support)                                                                                                                                                                                                                                                                |
| `MOD4WIN.EX_`                                              | different build (1999 sources)                                                                                                                                                                                                                                                                    |
| `INSTALL.EXE`                                              | different build                                                                                                                                                                                                                                                                                   |
| `RES_USA.DL_`, `INST_USA.DLL`, `M4W_USA.HL_`, `README.TXT` | identical                                                                                                                                                                                                                                                                                         |
| `RES_FRE.DL_`, `M4W_FRE.HL_`, `LISEZMOI.TXT`               | French files from version 2.31 (the resource DLL and help file are dated 1996-05-14). `RES_FRE.DL_` rebuilds byte for byte from the 2.31 sources; the help file's text and bitmaps do too. `LISEZMOI.TXT` is the repository's without the order form. See [HW1999.md](HW1999.md#the-french-files) |
| `WHATSNEW.TXT`                                             | ends before the 2006 entries, and lists `PeakSearch=0`/`ExactPeakSearch=0` as defaults (2006: `1`)                                                                                                                                                                                                |
| `TRLPLAY.*`, sample modules                                | identical                                                                                                                                                                                                                                                                                         |
| `INSTALL.INF`                                              | lists French instead of German, plus `*.zip` among the sample files                                                                                                                                                                                                                               |

None of its binaries has the forced-NT ending in `GetOS` (see
`MISSING_UNITS.md`).

### What is missing

The repository has only the 2006 sources, which replaced the 1999 ones. These
pieces of the HW build are missing:

- **The 1999 player sources.** `player32.pas`, `play.inc` and `playdefs.pas`
  with the hardware-device dispatch, plus the 1999 `dsetup.pas` (device
  selection in the setup dialog) and other 1999 revisions. The current files
  have no trace of the hardware code.
- **The hardware device units.** Only their **1996** versions survive, in
  `old_versions.zip` under `m4w231/PLAYER/DEVICES/`: `OPL4.PAS`, `GF1.PAS`,
  `GUSPATCH.PAS`, `EWS.PAS`, `DREAM.PAS` and `AWE32.PAS`. They already cover
  InterWave (`GF1`) and the `Dream94.Drv`/`Dream95.Drv` drivers (`DREAM`).
  `ST97.Drv`, `ST128.Drv` and `EWSAudio.Drv` aren't in any surviving source.
  (`m4w231/M4W300/` is an older player rewrite from the 2.2x era, not a
  later version.)
- **Units no source mentions:** `Sam9407` (which `DREAM.PAS` uses) and the
  Plug-and-Play, delay and registry units described under
  [The hardware code](#the-hardware-code).
- **Nothing for the French files:** the 2.31 sources in `old_versions.zip`
  build them ([HW1999.md](HW1999.md#the-french-files)).

### Which sources changed after the 1999 build

The 2006 snapshot in `old_versions.zip` (`M4W240lb`) keeps each file's date.
Files dated before 1999-05-03 are most likely as they were for the HW build
(among them `PLAYER/dacmix.pas`, `PLAYER/effects.inc`, `PLAYER/TASK.PAS`,
`ana.pas`, `coroner.pas`, `newsetup.pas` and most dialog units). These are
dated later and are the ones to recover:

| Date       | Files                                                                                                                                                                                                                                                                         |
| ---------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 2002-08-29 | `HUGEMEM.PAS`                                                                                                                                                                                                                                                                 |
| 2004-12-03 | `PLAYER/loaders.pas`, `PLAYER/playdefs.pas`, `playproc.pas`, batch files                                                                                                                                                                                                      |
| 2006-06-21 | `PLAYER/player32.pas`, `PLAYER/play.inc`, `PLAYER/WAITBOX.PAS`, `mod4win.pas`, `winunit.pas`, `newopen.pas`, `dsetup.pas`, `modc.pas`, `SHARE.PAS`, `REGDLG.PAS`, `setup.pas`, `INSTALL/install.pas`, `INSTALL/instlang.pas`, `INSTALL/REGISTER.PAS`, `MAKECODE/REGISTER.PAS` |

`M4W240lb/WHATSNEW.TXT` (2000-03-22) is the 1999 file; the 2006 entries
added to it list most of what changed in between.

### How the 2006 sources differ, place by place

The 2006 sources, compiled with a detailed map (`/GD`, which includes line
numbers), were compared with the HW binaries unit by unit, instruction by
instruction. Differences that are only addresses (code, data, jump targets)
were ignored. Each remaining place was traced to a source line
(`research/diffunits.py`). The method is the one in
[BIT_EXACT.md](BIT_EXACT.md#finding-source-revisions).
"1996 code" means the same code is in the 2.31 sources in `old_versions.zip`
(`m4w231/`), minus its OPL4 parts.

**`INSTALL.EXE`** is built by `setup.pas` with **`/DShare`** in both
editions: `InstallShare` is on unless `setup` gets `-ufull`, and `MAKE.BAT`
passes `-u"2.40 Last Beta"`. So the `Register` unit, the registration dialog,
`runcheck` and everything else inside `{$ifndef share}` is in neither. Against
that build, 1999 differs only in:

- `winunit`: the December 2006 font changes (below);
- `GetOS`: the forced-NT ending;
- `W32Base` linked into segment 1 instead of 2 (layout).

**`MOD4WIN.EXE`:**

| Unit              | Places | What they are                                                                                                                                                                                                                                                                                                               |
| ----------------- | ------ | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `MOD4WIN`         | 23     | `dev_GF1`/`dev_EWS` branches: default settings per device (including a `Surround` key), display mode, stop handling (1996 code). 2006 changes: _Open → Cancel_ (`getloadings` gets a `bCancel` parameter), _About → Normal view_, hotkeys X/C/D (`wmkeydown`, `wmendsession`), no clamping of the mini window to the screen |
| `Dsetup`          | 96     | 81 are one layout change: the dialog object has three more `Integer` fields, set to 200 (1996 declares `DACID, GF1ID, EWSID, OPLID`; 2006 only `DACID`). 14 are `dev_GF1`/`dev_EWS` branches with 44,100 Hz for GF1 and 37,500 Hz for EWS (1996 code)                                                                       |
| `winunit`         | 6      | December 2006 font changes: no umlaut replacement in bitmap fonts (`Replace`, `CharsInFont`), a temporary font file from `GetTempFileName(…, 'm4w', 1, …)` without the `.FON` rename, and the "could not remove font" warning still shown. `KeepWindowsAlive` isn't linked: its only caller is the 2006 _D_ key             |
| `newopen`         | 1      | the _Open → Cancel_ fix (`PostMessage(…, wm_getloadings, 1, 0)`)                                                                                                                                                                                                                                                            |
| `modc`            | 1      | `setcorrectwinpos` still keeps the window on the desktop (`GetSystemMetrics`)                                                                                                                                                                                                                                               |
| `Playproc`        | 1      | `InstallPlayer` also fetches player ordinal 500, `WINEWS_SETACTIVECARD` (stored, never called)                                                                                                                                                                                                                              |
| `RegDlg`, `GetOS` | 1 each | the known revisions ([BIT_EXACT.md](BIT_EXACT.md))                                                                                                                                                                                                                                                                          |

**`PLAYER32.DLL`:**

| Unit                             | Places | What they are                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  |
| -------------------------------- | ------ | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `Player32` (with `play.inc`)     | 38     | about 30 `dev_GF1`/`dev_EWS` dispatch places (play, stop, pause, timer, settings, `canplay`, `CriticalExit`) and the hardware detection with `UseHardware` ([Settings](#settings)). The rest is 2006 changes: `ActivateSound` rounds `BufferSize` and `PlayMemOfs` up to multiples of 32 (1996 and 1999 don't); `TimerOn` calls `StopTimer(VxDTID)` once more, unconditionally, before the existing conditional call; the DirectSound/interface device is 255 (1999 uses 256, `dev_DS` in the 1996 `MODC.PAS`) |
| `Loaders`                        | 19     | 16 are data addresses; 1 is the sample upload to GF1/EWS memory (1996 code); 2 are disassembly artifacts. The module name is shortened with region J's `GetFileName`, where 2006 calls `modc`'s `prevdir` (the same code)                                                                                                                                                                                                                                                                                      |
| `PlayDefs`                       | 6      | `GetSongMem` without the 2004 `PatternSize` local (same calculation); the rest are artifacts                                                                                                                                                                                                                                                                                                                                                                                                                   |
| `PrtLayer`                       | 35     | 33 data addresses; 3 extra routines that put a port operation in the queue (`InB` with mask 0xFF, `OutB`, `OutW`). Only the hardware code calls them, so the 2006 link dropped them and the rebuilt unit doesn't have them                                                                                                                                                                                                                                                                                     |
| `TrlNT`                          | 2      | `GetFileName`/`FindDriver` aren't in `TrlNT` in 1999: `LoadNTDriver` calls the same lookup in a separate unit (region J below)                                                                                                                                                                                                                                                                                                                                                                                 |
| `modc`                           | 1      | no `prevdir`: nothing in the 1999 DLL calls it (see `Loaders`); the rest is identical                                                                                                                                                                                                                                                                                                                                                                                                                          |
| `GetOS`                          | 1      | the forced-NT ending                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           |
| `DACMix`, `Maths` and all others | 0      | identical apart from addresses                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 |

`DACMix` (`dacmix.pas`, dated 1998-12-02) shows the layout effects most
clearly. Its bytes differ only in 216 offsets into its own code (its jump
tables and code addresses, shifted by the unit's position) and in 26
data-segment offsets. The data offsets map one to one, and most of them are
0x2EE8 (12,008) bytes higher in 1999 (and 0x2EF2 for one of them). The 1999
data segment holds that much more, mostly the hardware code's variables,
ahead of `DACMix`'s.

### The hardware code

About 31 KB of code in the 1999 `PLAYER32.DLL` has no 2006 counterpart. (The
rest of what no 2006 unit covers is Borland's: segment 5 is `System`, and
there are more `WinDos`, `Strings` and `WinAPI`/`Win31` routines.)

The DLL's main block calls every unit's initialization in link order, and each
initialization ends its unit. That splits the unknown code into units. The
order also gives the dependencies:
H, I, G, F, `GF1`, E2, B, D, A (E1 and J have no initialization part).

| Region            | Size    | Unit      | What it does                                                                                                                                                                                                                                                                                                                                                         | Surviving source                                                              |
| ----------------- | ------- | --------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------- |
| A seg1:BD6E–C35B  | 1.5 KB  | `EWS`     | device layer over `Dream`, through a table of procedure pointers; called by `Player32` and `Loaders`                                                                                                                                                                                                                                                                 | 1996 `EWS.PAS` (64 % of the region)                                           |
| B seg1:C35B–CB52  | 2.0 KB  | ?         | interface to TerraTec's `EWSAudio.Drv`: `OpenDriver`/`SendDriverMessage`, entry points `MODDEVOPEN`, `MODDEVCLOSE`, `MODDEVCHANGEPARAM`, `MODVOICESTART`, `MODVOICECHANGEPARAM`, `MODVOICECLOSE`, `MODVOICEADDOFS`, `GetMemMapAddress`                                                                                                                               | none                                                                          |
| C seg1:CB52–E57A  | 6.7 KB  | `GF1`     | Gravis Ultrasound / InterWave. The 1996 code spans the whole region; the volume, pan, fade and key-off routines now go through `PrtLayer` (94 calls), so they work on NT                                                                                                                                                                                             | 1996 `GF1.PAS` (56 % of the region; 69 % of the 1996 unit survives)           |
| D seg2:A052–C59A  | 9.5 KB  | `Dream`   | SAM9407 drivers `Dream95.Drv`, `Dream94.Drv`, `ST97.Drv`, `ST128.Drv`, `EWSAudio.Drv`, called by name (`modOpen`, `modClose`, `modCommand`, `modOpenVoice`, `modDefineVoiceMemory`, `memRead`, `memWrite`, …); exports `WINEWS_SETACTIVECARD`                                                                                                                        | 1996 `DREAM.PAS`, but only 19 % of the region: the unit was largely rewritten |
| E1 seg2:C59A–D3B8 | 3.6 KB  | `Sam9407` | direct access to the SAM9407's host port: the `EWS_*` routines `DREAM.PAS` imports (`EWS_Write_Mem`, `EWS_MOD_Vol` = firmware command 0x56, …, with the parameter sizes `DREAM.PAS` implies), and finding the cards through the Windows 95 Plug-and-Play registry (`Config Manager\Enum`, `HardWareKey`, `Allocation`) and ISA PnP through F; no initialization part | none                                                                          |
| E2 seg2:D3B8–D5B5 | 0.5 KB  | ?         | the `SETUPX.DLL` device installer through seven procedure pointers (`DiGetClassDevs`, `DiRemoveDevice`, `DiCallClassInstaller`, `DiChangeState`, `DiBuildClassDrvList`, `DiDestroyDeviceInfoList`, …)                                                                                                                                                                | none                                                                          |
| F seg2:D5B5–E60C  | 4.2 KB  | ?         | ISA Plug and Play with direct port I/O: sends the 34-byte initiation key, wakes cards, sets card select numbers and the read-data port; used by `GF1` and E                                                                                                                                                                                                          | none                                                                          |
| G seg2:E60C–E6AF  | 0.2 KB  | ?         | busy-wait delay calibrated against the PC timer (ports 61h/43h/42h), used by F                                                                                                                                                                                                                                                                                       | none                                                                          |
| H seg2:E6AF–E7FF  | 0.3 KB  | ?         | ADVAPI32 registry functions (`RegOpenKeyA` … `RegDeleteKeyA`) through `W32Base`, like `WinSvc`                                                                                                                                                                                                                                                                       | none                                                                          |
| I seg3:0000–0589  | 1.4 KB  | ?         | Plug-and-Play registry scan (its own copy of the `Config Manager\Enum` code) for the Gravis/InterWave side; called by `Player32` and `GF1`                                                                                                                                                                                                                           | none                                                                          |
| J seg4:14B9–180E  | 0.85 KB | ?         | driver-file lookup (`GetFileName`, `FindDriver` through the DOS environment's `PATH`), used by `TrlNT` and `Loaders`                                                                                                                                                                                                                                                 | 2006 `TrlNT.PAS` has the same routines                                        |

A unit without an initialization part doesn't show up in that call list, so
the regions were also checked for hidden boundaries. In Borland Pascal only
implementation-local routines are called near, so no boundary can lie inside
a near call's span. A unit also only calls the units it uses, which are linked
after it, so no far call crosses a boundary backwards. These two rules hold
at every real boundary in the 2006 DLL but also at many points inside units,
so they can only rule a split out:

- C (`GF1`), D (`Dream`), G, H, I and J are single units.
- E splits at D3B8: the two parts use separate blocks of variables (0x02B2…,
  0x3784… against 0x0494–0x04B0, 0x22CC), so E2 is a unit of its own.
- F has possible split points, but uses one block of variables
  (0x0566–0x0580) throughout: one unit.
- A and B have possible split points, because nearly all their routines are
  called far, but each uses one block of variables throughout (A: 0x0178–0x01B0,
  including its table of procedure pointers; B: 0x0320–0x0356): one unit
  each. (0x22CC/0x22CE, used everywhere, is `System`'s `ExitProc`.)

Of the 1996 units, `GUSPATCH` and `AWE32` weren't found as such, and `OPL4`
isn't there (2 % of the hardware code matches it, which is noise).

### Exports and data

- **Exports:** the 1999 DLL has the 2006 DLL's 20 named exports plus
  `WINEWS_SETACTIVECARD` (ordinal 500). Its entry table has 308 entries
  (2006: 95); the extra ones are unnamed internal entry points.
- **`PLAYER32.DLL` data segment:** 8,962 bytes initialised, 60,824 in all
  (2006: 5,584 and 50,344). The extra strings are the driver names and entry
  points, the registry and `SETUPX` names above, `ULTRASND`, `SAM9407` and
  `UseHardware`.
- **`MOD4WIN.EXE` data segment:** 162 bytes more. The extra strings are the
  default device names `GF1 (e.g. Gravis Ultrasound)` and `Dream SAM9407
(e.g. EWS64)`, and a `44100` where 2006 has `48000`. `BLOEDIE` and
  `DOOOVIEOFFLINE` (from `USERNAME.PAS`) are only in 2006. The DLL carries
  `AMD Interwave (e.g. GUS PnP)` in its code segment.
- **Resources and help:** `RES_USA.DLL` and `M4W_USA.HL_` are the same files
  in 1999 and 2006. The resource DLL holds only string tables and bitmaps,
  without hardware texts or dialog templates: the setup screen is drawn by
  `Dsetup` itself. The help file still describes the hardware support
  (OPL4 mode, Gravis Ultrasound, wavetable explanations).

### Settings

The settings-file calls in 1999 and 2006 differ only in these:

| Call                      | Section / key                            | Where                                   |
| ------------------------- | ---------------------------------------- | --------------------------------------- |
| `GetPrivateProfileInt`    | `[Sampling] Surround`                    | `MOD4WIN.EXE`, the EWS default settings |
| `GetPrivateProfileString` | `[Sampling] SampleRate`, default `44100` | 2006: default `48000`                   |
| `GetProfileInt`           | `[Player32] UseHardware` (WIN.INI)       | `PLAYER32.DLL`                          |
| `WriteProfileString`      | `[Player32] UseHardware` (WIN.INI)       | `PLAYER32.DLL`                          |

The 1996 player only reads `UseHardware` (default 1) and skips hardware
detection when it is 0 or the system is Windows NT. The 1999 player also
writes it: `0` before it probes the hardware and `1` after each probe
returns, so a crash during detection turns detection off for the next
start.

### How much of the 1999 code the 2.31 sources cover

The 2.31 sources were compiled ([below](#compiling-the-231-sources)) and
compared with the 1999 binaries: for each unit, the 1999 instructions that
don't match the 2006 build, and how many of those match the 2.31 build.

| 1999 unit                    | Instructions not in 2006 | Of those, as in 2.31                            |
| ---------------------------- | ------------------------ | ----------------------------------------------- |
| `MOD4WIN`                    | 161                      | 96 %                                            |
| `Dsetup`                     | 236                      | 94 %                                            |
| `Player32` (with `play.inc`) | 848                      | 72 %                                            |
| `Loaders`                    | 208                      | 72 %                                            |
| `PlayDefs`                   | 54                       | 12 % (the `GetSongMem` form, not hardware code) |

For the hardware units, the share of the 1999 code that matches 2.31 is 64 %
for `EWS`, 56 % for `GF1` and 19 % for `Dream`. `Loaders` as a whole is 93 %
the same in 2.31 and 1999.

### Compiling the 2.31 sources

The 2.31 tree in `old_versions.zip` (`m4w231/`) compiles in the recreated
environment, with these additions, for comparing only:

- **`Sam9407`** doesn't survive. A unit with the declarations `DREAM.PAS`
  calls (`EWS_Present`, `EWS_Get_MemMapAddress`, `EWS_Write_Mem`,
  `EWS_Read_Mem`, `EWS_MOD_Vol`/`Main`/`Pitch`/`Aux`/`Filter`/`Mem`,
  `EWS_MOD_Get_Offset`/`Set_Offset`, `EWS_MOD_Start`/`Stop`/`Close`,
  `EWS_Get_Voices_Avail`, `EWS_MOD_Open_Voice`) and empty bodies is enough.
  The parameter types follow `DREAM.PAS`'s procedure types (`tmodOpenVoice`
  and so on).
- **`Task`** doesn't survive in 2.31. The 2006 `TASK.PAS` (with `TASK.RES`)
  works if its `Idle` procedure variable is moved to the interface.
- **`Wave`** doesn't survive either. The rebuilt `WAVE.PAS` from
  `files/F/WINUNIT` works with a five-parameter `CloseWaveFile` (without the
  2006 `SmplChunk`) in front of the six-parameter one.
- **`PLAYER32.PAS` line 1238** passes `FileName_IS_ANSI`, which nothing
  defines. `MOD4WIN.PAS` passes `False` at the same place, with
  `{FileName_IS_ANSI}` as a comment.
- **`File32`, `W32Defs`, `ValConv`, `GetOS`** and the other shared units come
  from `F:\WINUNIT`.
- **The unit path** must be short (Borland Pascal cuts long `/U` values).
  From the 2.31 root:
  `/U.;PLAYER;PLAYER\DEVICES;PLAYER\FILTER;PLAYER\MISC;E:\BP\UNITS;F:\WINUNIT`,
  `/IPLAYER;.`, `/OPLAYER\FILTER` (for `CPUID.OBJ`), `/RINTL;PLAYER`, with
  the switches of the 2.40 `BPC.CFG`.

Then `BPC /B PLAYER\PLAYER32.PAS` and `BPC /B /DCheck MOD4WIN.PAS` build
both binaries. The 2.31 `MAKE.BAT` only calls the 2.31 `setup.exe`, which
isn't rebuilt this way. `m4w231/M4W300/` is an older player rewrite, not part
of this build.

### Developer documentation

Published documentation covers most of what the hardware code talks to.
These are outside sources, not part of this project:

| Covers                                                                                                                                                                                                                                                                                                              | Document                                                                                                                                            | Where                                                                                                                          |
| ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------ |
| `Dream`: the Dream driver functions (`modOpen`, `modGetVoiceNumber`, `modOpenVoice`, `modChangeParam`, `modDefineVoiceMemory`, `modGetPos`, `modSetNewPos`, `modCommand`, `modClose`, `memRead`, `memWrite`, `memGetMapAddress`) with signatures, the firmware API and the memory-mapping table                     | _SAM9407 Programmer's Reference_, rev. 11, Dream, December 1996 (`SAM9407_driver_api.pdf`, also as `PRGREF02.DOC`)                                  | `ftp://retronn.de/driver/Guillemot/MaxiSound64HomeStudio/dokumentation/`                                                       |
| `Dream`, `Sam9407` (E1): the firmware command codes, among them `0x01`/`0x02` memory write/read, `0x03`/`0x04` get/set memory-mapping table, `0x52`–`0x5A` voice open/close/start/stop/volume/main/pitch/aux/filter (the same values as `MOD_CLOSE`…`VOI_FILT` in the 1996 `DREAM.PAS`), and the host-port protocol | Linux `sam9407` driver 1.0.3 by Gerd Rausch (GPL), `kernel/firmware.h` and the driver source                                                        | `https://www.ibiblio.org/pub/linux/kernel/sound/sam9407-1.0.3.tar.gz`                                                          |
| SAM9407 chip, host interface timing                                                                                                                                                                                                                                                                                 | SAM9407 datasheet                                                                                                                                   | `https://dosdays.co.uk/media/dream/SAM9407.PDF`; other Dream chips under `ftp://retronn.de/docs/pc_hardware/wavetables/dream/` |
| `GF1`, I: InterWave registers, memory, PnP resources                                                                                                                                                                                                                                                                | AMD _InterWave IC Am78C201/202 Programmer's Guide_, rev. 2, 1996 (`IWPG.PDF`), with the Am78C201 datasheet, a Windows DDK manual and sample sources | InterWave SDK 2.0, `https://archive.org/details/iwsdk-20`                                                                      |
| `GF1`: the original Gravis Ultrasound (GF1 chip)                                                                                                                                                                                                                                                                    | Gravis Ultrasound SDK 2.10 (`ULTRADOC.TXT`, `GUSSDK.pdf`)                                                                                           | `discmaster.textfiles.com`, _Experimental BBS Explossion III_, `gus/gusdk210.zip` and `gus/sdkdoxps.zip`                       |
| F, G: ISA Plug and Play (initiation key, isolation, card select numbers, configuration registers)                                                                                                                                                                                                                   | _Plug and Play ISA Specification_ 1.0a (MSDN copy)                                                                                                  | `https://techshelps.github.io/MSDN/SPECS/PLATFRM1/D4/S1CEBA.HTM`                                                               |
| E1, F: ISA Plug-and-Play setup of SAM9407 cards. The Linux driver's `kernel/cards.c` writes two `0x00` bytes and then the 32-byte initiation key to the address port, the same 34 bytes F sends from its table                                                                                                      | Linux `sam9407` driver (above)                                                                                                                      | as above                                                                                                                       |
| E2: the `SETUPX.DLL` device installer (`DiGetClassDevs` and so on)                                                                                                                                                                                                                                                  | Wine's re-implementation, as a stand-in for the Windows 95 DDK                                                                                      | `https://source.winehq.org/WineAPI/setupx.html`, Wine `dlls/setupx.dll16/devinst16.c`                                          |

No documentation was found for TerraTec's `EWSAUDIO.DRV`, which region B
drives, or for the `ST97.Drv`/`ST128.Drv` drivers. The driver
itself gives the interface. The TerraTec _AudioSystem EWS64 L/XL_ driver CD
of January 1999 (on `vogonsdrivers.com`, file 2234; `EWSAUDIO.DRV` is stored
uncompressed in `DRIVER/WINDOWS/UNPACKED/`) has `EWSAUDIO.DRV` dated 1998,
_"EWS64 audio driver (c)1998 TerraTec Electronic GmbH, (P)(C) Sonic Labs"_.
Its exports:

| Ordinal | Name                  | Parameter bytes |
| ------- | --------------------- | --------------- |
| 10      | `MODDEVOPEN`          | 8               |
| 11      | `MODDEVCLOSE`         | 4               |
| 12      | `MODVOICESTART`       | 8               |
| 13      | `MODVOICECLOSE`       | 8               |
| 14      | `MODVOICECHANGEPARAM` | 8               |
| 15      | `MODVOICEADDOFS`      | 12              |
| 16      | `MODDEVCHANGEPARAM`   | 8               |
| 17      | `MODVOICESETLOOPSE`   | 14              |

(1–7 and 18 are the standard `DRIVERPROC`, `WIDMESSAGE`, `WODMESSAGE`,
`MIDMESSAGE`, `MODMESSAGE`, `AUXMESSAGE`, `MXDMESSAGE` and `WEP`.)
Region B also sends 13 private driver messages through `SendDriverMessage`:
0x42BC, 0x42BE, 0x42BF, 0x42C3, 0x42C7, 0x42CA (with the result of 0x42C7 as
its parameter), 0x42D0, 0x42D1, 0x42D3, 0x42EE, 0x42EF, 0x42F1 and 0x42F2.
This driver handles all of them, so it is the interface the HW edition was
written against. Which VxD function each one reaches is in
[HW1999.md](HW1999.md#the-ewsaudiodrv-interface).

### Its build environment

The HW binaries were made with the same tools as the 2006 ones:

- **Compiler, switches and RTL.** Units whose source didn't change compile
  to the same instructions (addresses aside), for example `copywnd`
  (6,177 instructions), `mulbox`, `Task`, `W32Base`, `File32` and `DACMix`.
  Borland's units (`OWindows`, `ODialogs`, `Objects`, `Strings`, `WinDos`,
  `Win31`, `OMemory`, `Validate`) are identical. Another compiler version or
  other `$G`/`$S`/near-far settings would show in every unit.
- **Linker.** The NE headers match: linker 6.1, alignment, flags, heap and
  stack sizes. `MOD4WIN.EXE` is marked Windows 3.00, like the standard 2006
  `MOD4WIN.EXE`; only the custom edition gets 3.10, and the HW package has
  no custom edition.
- **`setup.pas`.** Every file the build makes is dated 1999-05-03 02:40, the
  time `setup.pas` stamps for version 2.40 (the 1996 French files have
  02:31, for 2.31).
- **`COMPRESS` and the help compiler.** The 2006 package carries the
  1999-dated `RES_USA.DL_` and `M4W_USA.HL_` unchanged, and the recreated
  environment rebuilds both byte for byte (`CLEAN=1`).

What differed:

- **`F:\WINUNIT`.** The shared units were older revisions: `GetOS` without
  the forced-NT ending, and `TrlNT` without the driver-file lookup (region
  J). `PrtLayer` has three queue routines that the rebuilt unit lacks
  because 2006 didn't use them. `Sam9407` and the other units in regions
  B and E–J, which no project directory has, probably lived here too.
- **`W32Base`** had no `{$C Fixed Preload Permanent}`: it is in moveable
  segments in all three 1999 binaries.
- **Packaging.** A plain ZIP, made with PKZIP writing "made by 2.0"
  (probably 2.04g, see [FINDINGS.md](FINDINGS.md)), no self-extractor, with
  `INSTALL.INF` and `LISEZMOI.TXT` edited by hand (December 2000).

Nothing in the binaries tells whether the build OS, the directory layout,
`RLINK` or the patched `BPC.EXE` were the same as in 2006.

### Can it be built?

Yes, with the same method that rebuilt the missing units (see
[MISSING_UNITS.md](MISSING_UNITS.md)), in this order:

1. **`INSTALL.EXE`:** reproduces byte for byte with the 1999 font code in
   `winunit.pas`, the 1999 `GetOS` and a moveable `W32Base`
   ([HW1999.md](HW1999.md#installexe)).
2. **`MOD4WIN.EXE`:** reproduces byte for byte, as `setup.pas` stamps and
   compresses it (`MOD4WIN.EX_`), once the 2006 changes listed above are
   undone and the GF1/EWS code of the 2.31 sources is back, without OPL4
   ([HW1999.md](HW1999.md#mod4winexe)).
3. **`PLAYER32.DLL`:** reproduces byte for byte, as a file and as
   `setup.pas` compresses it (`PLAYER32.DL_`), with the 1999 places in
   `Player32`/`play.inc` and `Loaders` (from the 1996 `PLAYER32.PAS`,
   `PLAY.INC`, `LOADERS.PAS`), small `PlayDefs`, `TrlNT` and `PrtLayer`
   changes, `GF1`, `EWS` and `Dream` from their 1996 sources, B, `Sam9407`
   (E1), E2 and F–I written from the code, J's routines from the 2006
   `TrlNT`, and a `TPW.TPL` whose `WinAPI` is fixed
   ([HW1999.md](HW1999.md#player32dll)).

Code written without a source:

| Code                                                                                    | Size         |
| --------------------------------------------------------------------------------------- | ------------ |
| B, `Sam9407` (E1), E2, F, G, H, I (no source at all)                                    | about 12 KB  |
| the 81 % of `Dream` that isn't 1996 code                                                | about 7.7 KB |
| the 44 % of `GF1` that isn't 1996 code                                                  | about 2.9 KB |
| the rest of `EWS`, and the 28 % of the `Player32`/`Loaders` hardware places not in 1996 | about 0.8 KB |

That is about 23 KB, roughly one and a half times the missing units of the
2006 build. Much of it is port-level hardware access that can only be
checked against the binary, not run. The reconstructed sources aren't part
of this repository.

Packaging is the `setup.pas` step with `-lUSA -lFRE` (with the 2.31
`RES_FRE.DL_` and `M4W_FRE.HL_`), followed by a plain ZIP of the target
directory.
`INSTALL.INF` and `LISEZMOI.TXT` were evidently edited by hand in
December 2000.

`M4W240HW.ZIP` is the only surviving copy of the hardware edition and of the
French files. Its licence terms aren't clear, so it isn't part of the
repository or this project; it stays an input that each user supplies.
