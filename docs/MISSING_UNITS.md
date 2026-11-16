# Missing Pascal units

The project `uses` units whose source was never in the Mod4Win repository. On the
original machine they lived in a shared unit library (`f:\winunit`, which is on
the PATH in every `MAKE.BAT`). They have been rebuilt from the shipped
binaries. The sources are in [`files/F/WINUNIT/`](../files/F/WINUNIT), which
every build puts in `F:\WINUNIT` (see [README.md](../README.md)). `Maths` is
the exception: the build makes it from the 2.31 source in the repository's
`old_versions.zip` (`tools/patches.py maths`), and so is `GETOS.PAS` (below).

Every rebuilt unit compiles, with Borland Pascal 7.01, to the same code and data
as in the shipped binaries. Together with the recreated build environment, the
original `MAKE.BAT` reproduces `PLAYER32.DLL`, `M4W_MCI.DLL` and `INST_MCI.EXE`
byte for byte (see [BIT_EXACT.md](BIT_EXACT.md)). Some details of the units
exist only to get the link layout right; they are listed under
[Layout details](#layout-details). Every unit was transcribed from the
disassembly of Mod4Win's own binaries; none was copied from a third-party
source ([Origin](#origin) has what is known about who wrote them).

## Units

### Units named in the sources (14)

| Unit | Used by | Rebuilt from | Match |
|---|---|---|---|
| `W32DEFS` | player32, loaders, playdefs, winunit | `PLAYER32.DLL` | data identical (unit has no code) |
| `W32BASE` | IFACE16 (and the units below) | `PLAYER32.DLL` | 0x220 bytes, identical |
| `FILE32` | player32, loaders, REGISTER | `PLAYER32.DLL` | 0x8A4 bytes, identical |
| `Wave` | player32 | `PLAYER32.DLL` | 0x409 bytes, identical |
| `VALCONV` | player32, loaders, Wave | `PLAYER32.DLL` | 0xF4 bytes, identical |
| `Maths` | player32 | 2.31 source from `old_versions.zip` with two edits, made by the build | 0x4B bytes, identical |
| `Crc` | player32 | `PLAYER32.DLL` | 0x129 bytes, identical |
| `MemList` | player32 | `PLAYER32.DLL` | 0x770 bytes, identical |
| `PrtLayer` | player32 / play.inc | `PLAYER32.DLL` | identical |
| `User32` | winunit | `MOD4WIN.EXE` | 0x185 bytes, identical |
| `WOW32` | winunit | `MOD4WIN.EXE` | 0x88 bytes, identical |
| `oFarProc` | winunit | `MOD4WIN.EXE` | 0x180 bytes, identical |
| `Ctl3DV2` | player32 (MCI build) | `M4W_MCI.DLL` | 0x194 bytes, identical |
| `VK_KEYS` | makecode | — | empty placeholder |

`F:\WINUNIT` also gets `GETOS.PAS`, the revision of the existing `GetOS`
unit that the shipped binaries were built with (see [GetOS](#getos-two-revisions)).

### Units that no surviving source names (7)

Only the missing units above use these, so they show up only in the binaries.
Their unit names are guesses.

| Unit | Used by | Rebuilt from | What it is |
|---|---|---|---|
| `TrlNT` | PrtLayer | `PLAYER32.DLL` | NT driver interface (`TRLPLAY.SYS` via `DeviceIoControl`) |
| `TrlVxD` | PrtLayer | `PLAYER32.DLL` | VxD interface (`TRLPLAY.VXD` / `TRLPLAY.386`) |
| `WinSvc` | TrlNT | `PLAYER32.DLL` | ADVAPI32 service-manager calls through generic thunks |
| `VxDLdr` | TrlVxD | `PLAYER32.DLL` | INT 2Fh/1684h VxD entry points, VXDLDR load/unload |
| `NoDOSMem` | oFarProc | `MOD4WIN.EXE` | `GlobalAlloc` that avoids conventional memory |
| `NetDrv` | ValConv | `PLAYER32.DLL`, `M4W_MCI.DLL` | probes `USER.WNetGetCaps`; nothing reads its results |
| `DragDet` | ValConv | `PLAYER32.DLL`, `M4W_MCI.DLL` | initialization only: looks up `USER` ordinal 465 (`DragDetect`) and stores a magic value; nothing reads either |

### What each unit does

- **`W32BASE` / `W32DEFS`**: access from 16-bit code to Win32 under Windows 95/NT,
  through Windows' generic thunks (`LoadLibraryEx32W`, `GetProcAddress32W`,
  `CallProc32W`).
  - `W32BASE` resolves the thunk functions and loads `KERNEL32`, `USER32`,
    `GDI32`, `SHELL32`, `ADVAPI32`, `MPR`, `WOW32` and `VERSION`.
  - `W32DEFS` holds the module handles, `Win32Available`, `Handle32`,
    `tRect32` and the Win32 constants. `INVALID_HANDLE_VALUE` is a typed
    constant there, not a true constant.
- **`FILE32`**: file I/O with long file names through the Win32 API, falling back
  to the 16-bit API. Each handle carries an `Is32` flag, and errors go to
  `WinDos.DosError`. It also wraps `CreateFile`, `SetFilePointer`, `CloseHandle`
  and `DeviceIoControl` for `PrtLayer`.
- **`PrtLayer`**: port I/O and timer layer.
  - It exposes 20 procedure variables: timer, port grant/release, and byte,
    word and dword in/out.
  - These point at direct `in`/`out` instructions, at the TRLPLAY VxD, or at
    the TRLPLAY NT driver, depending on the OS.
  - On NT it installs and starts the driver as service "TrlPlay".
  - The player itself only uses `StartTimer`/`StopTimer`.
- **`Wave`**: direct-to-disk `.WAV` writer, ported to `FILE32` handles.
  `CloseWaveFile` can append a 60-byte `smpl` chunk.
- **`MemList`**: sorted list of fixed-size records in one global memory block.
  It's an object with a VMT and is used for merging the peak-level cache.
- **`Crc`**: table-driven CRC-16 (polynomial `$A001`). Its init also builds a
  CRC-32 table (polynomial `$EDB88320`). `CCT_PolyCRC16 = $8408` is used as the
  start value.
- **`VALCONV`**: `Long2Ptr` (huge-pointer arithmetic), `UpStrComp`,
  `IsValidSelector` and `StrRScanCounted`.
- **`Maths`**: 2.40 uses `lg` (the FPU version) and `exp10`, and its
  initialization runs `finit`.
  - The rest of the unit (log, hyperbolic functions, DFT/FFT) is the 2.31 code
    and can't be checked against a binary.
  - The FFT routine is probably copied from a German numerics textbook (umlauts
    written as `ue`, a `fehler` error parameter, "(C) Wb"). The book hasn't
    been identified, and 2.40 doesn't use the routine. That's why this
    project doesn't store the unit: the build takes the 2.31 file from
    `old_versions.zip` (`m4w231/PLAYER/FILTER/MATHS.PAS`) and makes the two
    changes (the FPU `lg` instead of the Pascal one, and `finit`).
- **`User32` / `WOW32`**: thunked `SetWindowRgn`, `DrawCaption` and
  `WOWHandle32`.
  - The handle-type constants are the values from Microsoft's `wownt32.h`.
  - `WOWHandle16` and `WOWDirectedYield16` are resolved by the init code. Their
    wrappers weren't linked into any binary, so they follow `WOWHandle32`'s
    pattern and can't be verified.
  - The names of `User32`'s nine other USER32 function pointers are known, but
    their wrappers weren't linked, so they aren't declared.
- **`oFarProc`**: `MakeObjProcInstance` / `FreeObjProcInstances`. These are
  135-byte callback stubs, 100 per block, each with its own small return stack,
  so a method can serve as a `SetTimer` or `timeSetEvent` callback.
- **`Ctl3DV2`**: run-time binding to `CTL3DV2.DLL`, falling back to `CTL3D.DLL`.
  It registers and auto-subclasses on load and unregisters on exit.

### Origin

The units are compiled into Mod4Win's binaries and used by its surviving
sources, and the binaries carry no third-party copyright or author notice
besides Borland's run-time library (and Microsoft's default copyright field in
a bitmap font resource of Mod4Win's own). For most units the code itself shows
they are Mod4Win's: they implement Mod4Win's own features, port its older
units (`Wave`, `Coroner`) or wrap its helper drivers (`TrlNT`, `TrlVxD`). Two
have no surviving source and less obvious authorship:

- **`oFarProc`** (`MOD4WIN.EXE`, used by `winunit.pas` for its timers) is
  very likely the authors' own. Its stubs are written for Mod4Win's
  interrupt-time multimedia timer, and it allocates them through `NoDOSMem`,
  which uses the same technique as `GetAllDOSMem`/`FreeAllDOSMem` in the
  surviving `player32.pas` (all conventional memory reserved in 4,096-byte
  `GlobalDosAlloc` blocks chained through their first word, then freed). No
  unit of that name is on the Borland Pascal 7.01 or Delphi 2.01 media.
- **`Ctl3DV2`** (`M4W_MCI.DLL`, used by `player32.pas` in the MCI build) may
  be a borrowed general-purpose unit: it binds all eleven functions of
  Microsoft's `CTL3D.H`, though Mod4Win calls three. It isn't on the Borland
  Pascal 7.01 media or in the 16-bit Delphi 1 sources on the Delphi 2.01 CD.
  Its content is fixed by Microsoft's API: the library names, the eleven
  function names and signatures, and the usual load, register and unregister
  sequence.

### Guessed names

Names used by the surviving sources are exact. Everything else was named from
what the code does: other routine names, all field, variable and typed-constant
names, the six extra units' names, and `FILE32`'s `_lCreat32`, `_lWrite32` and
`GetCurrentDirectory`. `GetCurrentDirectory`'s signature only has to compile
against `MAKECODE/REGISTER.PAS`, because no binary contains it.

The unit headers say what was guessed in each case.

### Original bugs kept

The reconstructions reproduce the original code, including its bugs:

- **`FILE32`:**
  - `SetFilePointer` tests the wrong function pointer.
  - `_lOpen32` returns `$0001FFFF` on Win32 failure.
- **`Crc`:** uses `DB 66h` (operand size) where `67h` (address size) was meant,
  so it doesn't actually use 32-bit offsets.
- **`User32`:** `DrawCaption` is passed a 16-bit `hDC` without conversion.
- **The NT driver service:** its display name is "Trinity Labs Helper Service0",
  including the trailing `0`.

## Building

The compiler is Borland Pascal **7.01**. The shipped 2.40 binaries contain the
7.01 runtime library: its longint-shift helper is byte-identical to the one in
the genuine 7.01 `TPW.TPL`.

The original `BPC.CFG`, compiler batch files and tool directories are lost.
They have been recreated as a build environment (this project). See
[README.md](../README.md) for the drive layout and usage, and
[BUILD_TOOLS.md](BUILD_TOOLS.md) for each tool. The switches in `BPC.CFG` were
recovered by comparing compiled code with the shipped binaries:

```
/CW /M /$V- /$S- /$W- /$G+ /$I- /$K-
/UE:\BP\UNITS;F:\WINUNIT;F:\MOD4WIN\M4W_MCI;F:\MOD4WIN\PLAYER;F:\MOD4WIN\INSTALL;F:\MOD4WIN
/IF:\MOD4WIN\PLAYER  /RF:\MOD4WIN\INTL;F:\MOD4WIN\PLAYER
```

The run-time library and the ObjectWindows units were also rebuilt locally
from Borland's source, with the same switches. `setup.sh` repeats that
(see [BUILD_TOOLS.md](BUILD_TOOLS.md#tpwtpl-turbotpl-tpptpl-runtime-libraries)).

**Per-target notes:**

- **`MOD4WIN.PAS`:** `setup.pas` compiles it with `/Q /DCheck`. `/DDEMO` is
  added for the shareware build.
- **MCI driver:** `M4W_MCI/MAKE.BAT` copies `player32.pas` to `M4W_MCI.PAS`
  and compiles it with `/DMCI`.
- **`PLAYER/TASK.RES`:** the build needs it, and it is missing from the
  repository's `PLAYER/`. `old_versions.zip` has it as `M4W230/TASK.RES`,
  byte-identical to the resource in the shipped `PLAYER32.DLL`, and
  `build.sh` extracts it from there. It contains the small `TASKEXE`
  helper program, for which no source exists.

The original `SOURCE/MAKE.BAT`, `CUSTOM/MAKE.BAT` and `M4W_MCI/MAKE.BAT` run
unchanged in the environment and build every binary. The final packaging
steps need Windows, as on the original (see [INSTALLERS.md](INSTALLERS.md)).

### GetOS: two revisions

`GetOS` isn't a missing unit (`M4W_MCI/GETOS.PAS` exists), but that copy is not
the one the shipped 2.40 binaries were built with. The shipped revision has been
recovered from the binaries; it is the repository's file with two changes, so
the build makes it from that file into `F:\WINUNIT\GETOS.PAS`
(`tools/patches.py getos`).
Because `F:\WINUNIT` comes before `F:\MOD4WIN\M4W_MCI` on the unit path, builds
use it.

| | `M4W_MCI/GETOS.PAS` (repo) | `WINUNIT\GETOS.PAS` (shipped 2006 builds) |
|---|---|---|
| Resolves and calls `FreeLibrary32W` on `KERNEL32` | yes | no |
| After detecting the OS, forces `OS := Windows_NT; ExOS := Ex_NewWin` | no | **yes** |

The forced ending means the 2006 binaries believe they are running on Windows
NT under every Windows version. This affects everything that tests `GetOS.OS`:

- `PrtLayer`/`TrlNT`/`TrlVxD` choose the NT driver path.
- `NetDrv`.
- `winunit`'s Windows 95 caption and window-region code.

Which binaries contain which revision:

| Binary | Forced-NT ending |
|---|---|
| 2006 builds: `PLAYER/PLAYER32.DLL`, `CUSTOM/Full/MOD4WIN.EXE`, `M4W_MCI/M4W_MCI.DLL`, `setup/m4w_full/INSTALL.exe` | yes |
| 1999 builds in `M4W240HW.ZIP` (`PLAYER32.DLL`, `MOD4WIN.EXE`, `INSTALL.EXE`) | no |

None of the shipped binaries calls `FreeLibrary32W` from `GetOS`, so the repo
copy, which does, matches neither build.

The forcing was probably added for the 2006 release. That release removed the
hardware support, and by 2006 practically every system ran an NT-based Windows.
Whether it was deliberate isn't recorded anywhere.

To build with the repo revision instead, leave out the `getos` step in
`stage_project` (`xp/lib.sh`). The `M4W_MCI` tools that are
compiled inside `M4W_MCI/` (`inst_mci.pas`, `rjmod4wn.pas`) pick up the repo
revision anyway, because BPC searches the current directory first.

### Coroner: the revision in `M4W_MCI.DLL`

`SOURCE/coroner.pas` (the crash handler) is what `PLAYER32.DLL` and
`MOD4WIN.EXE` contain. `M4W_MCI.DLL` contains an older revision, which lies
between the 2.30 and 2.31 copies in `old_versions.zip`:

- Its messages are grouped by exception first, then by language.
- It has four message languages: English (also used for Spanish and Italian),
  Greek, French and German.
- `CriticalErrorName` is a `PChar`, `AddCriticalSeg` is a function, and
  exception 0 is ignored.

It has been rebuilt from the DLL into
[`files/F/MOD4WIN/M4W_MCI/CORONER.PAS`](../files/F/MOD4WIN/M4W_MCI/CORONER.PAS).
Its location explains why only the MCI build used it. `M4W_MCI\MAKE.BAT`
compiles in `PLAYER\`, so BPC finds a `CORONER` on the unit path before the
project root. `setup.pas` compiles everything else from the root, where the
root's `coroner.pas` comes first. Whether the original lived in `M4W_MCI\` or
`F:\WINUNIT` makes no difference. This relies on the
unit path in the recreated `BPC.CFG`, which puts `F:\WINUNIT` and
`F:\MOD4WIN\M4W_MCI` before `F:\MOD4WIN`; the original order isn't known.

### Layout details

Byte-identical output needs more than identical code per unit. These rules
decide where the linker puts things:

- **Link order** is the reverse of the order in which units finish compiling.
  That is a depth-first walk of the `uses` clauses: interface `uses`, then
  implementation `uses`, then the unit itself. The run-time library units in
  `TPW.TPL` follow the same rule. So the order of names in a `uses` clause
  matters even when it adds no code.
- **Code placement:** units are grouped by their `{$C …}` attributes (fixed
  or moveable). Each unit goes into the first segment of its group with room
  under the `{$S 60000}` limit set in `player32.pas`. A unit without `{$C}` is
  moveable.
- **Typed constants** are kept or dropped per `CONST` section. An unreferenced
  constant survives if another constant in the same section is used.
- **Variables** are laid out in link order.
- **Entry ordinals** of a DLL are numbered in link order: each unit's
  initialization, then its referenced routines in interface order.

Because of this, some details of the rebuilt units are there only for the
layout:

| Unit | Detail | Evidence |
|---|---|---|
| PrtLayer, TrlNT, WinSvc, TrlVxD, MemList, Crc, GetOS, File32, W32Base | `{$C Fixed Preload Permanent}` | segment placement |
| Wave, ValConv, NetDrv, Maths, VxDLdr | no `{$C}` (moveable) | segment placement |
| ValConv | implementation `uses … NetDrv, DragDet`; interface routine order | link order, entry ordinals |
| MemList | interface `uses …, Crc` | link order |
| File32 | implementation `uses WinProcs, W32Base, WinDos, Strings` | variable order in `M4W_MCI.DLL` |
| Ctl3DV2 | implementation `uses WinProcs, Objects, Win31` (no code from either) | link order in `M4W_MCI.DLL` |
| W32Defs | `INVALID_HANDLE_VALUE` in its own `CONST` section | dropped from `MOD4WIN.EXE`, kept in `PLAYER32.DLL` |
| NetDrv | 88 unused zero bytes before `sDriveA` | data layout |
| Wave | unused `Unknown1: Word` after `sSMPL` | data layout of both DLLs |
