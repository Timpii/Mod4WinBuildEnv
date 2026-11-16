# Mod4Win 2.40 build environment

[![License: MIT (mostly)](https://img.shields.io/badge/license-MIT%20%28mostly%29-blue)](#license)
![Output: bit-identical](https://img.shields.io/badge/output-bit--identical-brightgreen)
![Guest: Windows XP](https://img.shields.io/badge/guest-Windows%20XP-0078D7)
![Runs on: QEMU 7.1+](https://img.shields.io/badge/runs%20on-QEMU%207.1%2B-orange)
![Target: Win16](https://img.shields.io/badge/target-Win16-lightgrey)

This project recreates a build environment of
[Mod4Win](https://github.com/shamblernaut/Mod4Win) that can produce
bit-identical output to the original, given the right
proprietary software & licenses.

It sets up Windows XP with the original drive letters, directories, compilers
and tools, in a QEMU virtual machine. The original `MAKE.BAT` runs in it
unchanged and reproduces the shipped release, the three installers included.
The Mod4Win repository is a git submodule (`Mod4Win/`) and is never modified;
each build works on a fresh copy of it.

The compilers and tools are copyrighted, so they aren't included: you provide
the original media, and `setup.sh` installs everything from them into the
virtual machine, unattended.

## Getting started

### 1. Install the host programs

QEMU (`qemu-system-x86_64` and `qemu-img`, 7.1 or newer; tested with 8.2),
mtools, 7-Zip (the full program, as the `7z` or `7zz` command; `7za` can't
read the CD and disk images) and Python 3. For example (package names vary):

| Host             | Command                                                                                                            |
| ---------------- | ------------------------------------------------------------------------------------------------------------------ |
| Debian, Ubuntu   | `sudo apt install qemu-system-x86 qemu-utils mtools 7zip python3` (older releases: `p7zip-full` instead of `7zip`) |
| Fedora           | `sudo dnf install qemu-system-x86 qemu-img mtools p7zip p7zip-plugins python3`                                     |
| Arch             | `sudo pacman -S qemu-system-x86 qemu-img mtools 7zip python`                                                       |
| macOS (Homebrew) | `brew install qemu mtools sevenzip python`                                                                         |

On Linux, give your user access to `/dev/kvm` (usually by adding it to the
`kvm` group) for hardware virtualisation; without it everything still works,
emulated, several times slower. Other hosts: see [Hosts](#hosts).

### 2. Get this project

```sh
git clone --recurse-submodules <this project's URL>
cd <its folder>
```

In a clone made without `--recurse-submodules`, `Mod4Win/` is empty; fill it
with `git submodule update --init`.

### 3. Put the original media into `inputs/`

Ten files, each in its own folder in `inputs/`. The file names don't matter:
the scripts read the one file in each folder. If a folder holds more, they
take the first of the expected type (the `.iso` of a CD, for example) and say
which; hidden files don't count. (Or point the variables in
`xp/lib.sh` at the files, e.g. `XPISO=/path/to/xp.iso`.) Archives can be
anything 7-Zip reads (`.7z`, `.zip`, …), with their contents in any folder;
disk images can be `.img`, `.ima` or `.vfd`, under any names, as the scripts
tell the disks apart by what's on them.

| Folder in `inputs/` | What to put there                                                                                                                                                      | What the build uses from it                                                                                                                                                                    |
| ------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `windows_xp/`       | Windows XP Professional install CD, as an `.iso` image: 32-bit, English (see below; tested: SP3, volume licence)                                                       | the guest system                                                                                                                                                                               |
| `xp_key/`           | a text file with its product key, `XXXXX-XXXXX-XXXXX-XXXXX-XXXXX` (one that fits the CD: a volume-licence key for volume-licence media, a retail key for retail media) | the unattended XP install                                                                                                                                                                      |
| `borland_pascal/`   | Borland Pascal 7.01: an archive of the ten 3.5" install disks and the run-time library source disk, as disk images                                                     | the compilers, TASM, the units and the library source, installed with Borland's installers                                                                                                     |
| `delphi_developer/` | Delphi Developer 2.01 CD, as an `.iso` image                                                                                                                           | Delphi 2, installed with its setup                                                                                                                                                             |
| `delphi_desktop/`   | Delphi Desktop 2.0: an archive of its InstallShield setup (with `DATA.Z`)                                                                                              | the Delphi 2.0 compiler (`DCC32.EXE`, `RLINK32.DLL`), which the shipped `MCITest32.exe` was built with                                                                                         |
| `cpp_builder/`      | C++Builder 1.0 Client/Server Suite: an archive of its setup (with `Setup\DATA.Z`)                                                                                      | `GETMEM.INC`, the memory-manager fix in the original's Delphi `System`                                                                                                                         |
| `dr_dos/`           | DR DOS 6.0: an archive of its install disks, as disk images                                                                                                            | `XDEL.EXE`, `FORMAT.COM`, `LABEL.COM`                                                                                                                                                          |
| `pkzip/`            | PKZIP 2.50 for DOS: the shareware self-extractor (`.exe`)                                                                                                              | PKZIP, unpacked only inside the guest                                                                                                                                                          |
| `winzip_se/`        | WinZip Self-Extractor 2.1: its setup program, `wzipse21.exe`                                                                                                           | WinZip SE, installed with its setup                                                                                                                                                            |
| `winzipse_reg/`     | `winzipse.dat`, your WinZip Self-Extractor registration: the file a registered copy keeps next to `WZIPSE32.EXE`, two lines (name and number)                          | the licensee's name, which goes into the three installers: they are byte-identical only with a registration to the original licensee ("Kay Bruns"); with another name they differ in that name |

All ten are required.
Which Windows XP:

- **Professional, 32-bit (x86):** required. The build runs DOS programs,
  which 64-bit Windows can't; `setup.sh` rejects Home Edition and 64-bit CDs.
- **English:** required. The guest's scripts use English names
  (`C:\Program Files`, `format`'s Y/N answer); `setup.sh` rejects CDs in
  other languages.
- **Service pack and licence type:** tested with SP3, volume licence. Others
  should work but are untested. Retail and OEM copies need activation within
  30 days, which never pass for the guest (its clock starts at the 2006 build
  date on every boot), but an activation reminder might get in the way.
  The key has to fit the CD's licence type; `setup.sh` says which type the CD
  is before it installs XP.

They're copyrighted software: use copies you're licensed to use (this project
doesn't say where to get them). The folders are part of the project (each
holds a hidden `.gitkeep`, which the scripts skip), but git ignores what you
put in them, so none of it can end up in a commit.

### 4. Set up the virtual machine (once)

```sh
./setup.sh
```

It first checks the programs and every input: that the archives and CD images
open and contain the expected files, that the key file holds one key of the
right form, and that the registration file has the right shape (it never
looks at the key's or the registration's values). Anything missing or wrong
is listed before it starts.

Then it installs Windows XP, builds a disk with the tools, and installs them
in the guest, with no one at the keyboard: about 7 minutes with KVM, 20
without. It shows each step as the guest reports it. The result is the set
of disk images in `VM/` (about 1.6 GB); each step is skipped if its result is
already there, and deleting `VM/` starts over.

### 5. Build

```sh
./build.sh             # the repository as it is
SHIPPED=1 ./build.sh   # as the shipped MOD4WIN.EXE was built (see below)
```

A build takes about 30 seconds with KVM. It copies the repository into the
guest, runs `MAKE.BAT`, and brings F:, W: and X: back into `out/F`, `out/W`
and `out/X`. The installers are in `out/F/MOD4WIN/setup/` (`m4w24ins.exe`,
`m4w24cin.exe`, `mci24ins.exe`), the log in `out/F/BUILD.LOG`.

Compare with the shipped files, e.g.
`cmp Mod4Win/setup/mci24ins.exe out/F/MOD4WIN/setup/mci24ins.exe`. With
`SHIPPED=1`, `MOD4WIN.EXE` and all three installers are byte-identical;
without it, `MOD4WIN.EXE` and the two installers that contain it differ (see
[What does and doesn't work](#what-does-and-doesnt-work)).

More build options are under [Building](#building).

### If something goes wrong

Both scripts say what failed: a missing or wrong input, the guest step that
failed with its error and the end of its log, or the compiler errors of a
failed build. `SHOW=1 ./setup.sh` (or `./build.sh`) shows the guest's screen
in a window. Every run has a time limit, so nothing hangs forever.

## Contents

| Path                         | What                                                                                                                                                                                                                                                                                                                        | Origin                                              |
| ---------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------- |
| `setup.sh`, `build.sh`       | set up the guest; build in it                                                                                                                                                                                                                                                                                               | ours                                                |
| `xp/`                        | their shared code (`lib.sh`), the guest's job scripts (`guest/`), the XP answer file, side-build jobs (`jobs/`)                                                                                                                                                                                                             | ours                                                |
| `xp/guest/DOSKEYS.DPR`       | drives Borland's DOS installers from scripts inside the guest (compiled there with Delphi)                                                                                                                                                                                                                                  | ours                                                |
| `files/`                     | the reconstructed project files, copied into each build (see below)                                                                                                                                                                                                                                                         | ours                                                |
| `tools/`                     | `is3x.py` (unpacks InstallShield 3 `DATA.Z` archives), `patches.py` (the original machine's changes to Borland's library sources, and the edits of `SHIPPED=1` and `BIGMEM=1`), `mkdisk.py` (partition tables for the disk images), `qmp.py` (screenshots and keys for a running guest, [docs/TESTING.md](docs/TESTING.md)) | ours                                                |
| `research/`                  | Python scripts for comparing builds with the shipped binaries; not needed by setup or build ([docs/BIT_EXACT.md](docs/BIT_EXACT.md#finding-source-revisions))                                                                                                                                                               | ours                                                |
| `docs/`                      | documentation                                                                                                                                                                                                                                                                                                               | ours                                                |
| `Mod4Win/`                   | the Mod4Win repository, a git submodule at the tested commit                                                                                                                                                                                                                                                                | [upstream](https://github.com/shamblernaut/Mod4Win) |
| `inputs/`                    | the original media, which you provide, one folder each                                                                                                                                                                                                                                                                      | folders ours; contents yours, git-ignored           |
| `VM/`                        | the guest's disk images and logs                                                                                                                                                                                                                                                                                            | generated, git-ignored                              |
| `out/F/`, `out/W/`, `out/X/` | the last build's F:, W: and X:                                                                                                                                                                                                                                                                                              | generated, git-ignored                              |

How it works: [docs/WINXP.md](docs/WINXP.md). The same environment by hand,
without these scripts: [docs/MANUAL_XP.md](docs/MANUAL_XP.md).

## Hosts

The scripts are plain POSIX `sh`.

| Host                                              | Acceleration                                       | Status                                                  |
| ------------------------------------------------- | -------------------------------------------------- | ------------------------------------------------------- |
| Linux (x86)                                       | KVM (your user needs access to `/dev/kvm`)         | tested: setup ~7 minutes, a build ~30 seconds           |
| Linux without KVM, or any other host QEMU runs on | none: QEMU emulates the CPU (`ACCEL=tcg`)          | tested on Linux: setup ~20 minutes, a build ~1½ minutes |
| macOS on Intel                                    | Hypervisor.framework (`hvf`)                       | expected to work; not tested                            |
| macOS on Apple Silicon, FreeBSD, OpenBSD          | none (emulation)                                   | expected to work, slowly; not tested                    |
| Windows 11                                        | WSL2 with nested virtualisation (gives `/dev/kvm`) | expected to work like Linux; not tested                 |

The accelerator is picked automatically (`ACCEL=` overrides it); `QEMU=`
names another QEMU binary, `SEVENZIP=` another 7-Zip. Without hardware
virtualisation, all time limits grow tenfold.

## Drive layout

The original build machine's layout, reconstructed from the build scripts
(`MAKE.BAT`'s `PATH` is `C:\tools;f:\exe;f:\compiler;e:\td;e:\bp;f:\winunit;f:\dosunint`,
`CLEANUP.BAT` uses `\compiler\xdel`, `setup.pas` builds paths as
`ROOT+'compiler\…'`, the old Delphi files refer to `F:\MOD4WIN\…`):

```
C:\TOOLS            XP's COMMAND.COM and XCOPY; DR DOS LABEL; PKZIP 2.50; WZIPSE (WinZip SE 2.1)
C:\BORLAND\DELPHI32 Delphi 2 (2.01 setup; 2.0 compiler; rebuilt SYSTEM.DCU)
E:\BP               Borland Pascal 7.01 (compilers, TASM, utilities directly in it)
E:\BP\UNITS         standard units      E:\BP\RTL  run-time library source
E:\TD               Turbo Debugger, Windows utilities (RC.EXE)
F:\MOD4WIN          the project: the repository's SOURCE\ plus its other folders
F:\MOD4WIN\COMPILER BPC.EXE, BPC.CFG, the rebuilt TPW.TPL and TURBO.TPL, RTM, COMPRESS, XDEL, FORMAT
F:\COMPILER         BP.BAT, BPW.BAT, BPW32.BAT, DELBAK.BAT, XDEL.EXE, FORMAT.COM
F:\WINUNIT          the rebuilt units (docs/MISSING_UNITS.md)
F:\DOSUNINT, F:\EXE empty (original contents unknown; F:\EXE is the Delphi projects' output folder)
F:\MOD4WIN\_BURGER_ target of SOURCE\MKEWSPLY.BAT
W:\M4W_HTML\MOD4WIN.COM\FILES   web site tree, target of M4W_MCI\MAKERJ.BAT
X:\SOUND\MOD4WIN\MCI_DEMO       target of M4W_MCI\MAKEDEMO.BAT
```

F: is NTFS, like the original's: PKZIP adds files in directory order, which
is alphabetical only on NTFS. `MAKECODE` (the registration-code generator)
writes `g:\net_temp\M4W.REG` when run; that isn't part of any build, so there
is no G:. The project must be in a subdirectory, not at a drive's root:
`setup.pas` strips a trailing `\` before `ChDir`, so with `ROOT = F:\` its
`ChDir(ROOT)` only selects the drive.

### Our own files (`files/`)

| File                                                      | What                                                                                                                                                                                                                                                      |
| --------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `F/WINUNIT/*.PAS`                                         | 20 of the 22 rebuilt units; the build makes the other two from the repository's own files: `Maths` from the 2.31 source in `old_versions.zip`, and the shipped `GetOS` revision from `M4W_MCI/GETOS.PAS` ([docs/MISSING_UNITS.md](docs/MISSING_UNITS.md)) |
| `F/MOD4WIN/M4W_MCI/CORONER.PAS`                           | the older `Coroner` that `M4W_MCI.DLL` was built with                                                                                                                                                                                                     |
| `F/MOD4WIN/COMPILER/BPC.CFG`                              | the recreated compiler configuration                                                                                                                                                                                                                      |
| `F/COMPILER/BP.BAT`, `BPW.BAT`, `BPW32.BAT`, `DELBAK.BAT` | the recreated compiler wrappers                                                                                                                                                                                                                           |

The guest also changes some third-party files the way the original machine
had them, keeping each original as `*.ORG`:

- Borland Pascal's Windows and DOS run-time libraries (`TPW.TPL`, `TURBO.TPL`)
  and ObjectWindows, rebuilt from Borland's source with `tools/patches.py`'s
  changes (among them the original's Runtime Error 200 fix in `Crt`);
- Delphi's `SYSTEM.DCU`, rebuilt with C++Builder 1.0's `GETMEM.INC`.

`build.sh` also sets the original dates of six files that go into the
installers unchanged, and of `TASK.RES` (git doesn't keep them).

## Building

```sh
./build.sh                         # headless; the log is out/F/BUILD.LOG
./build.sh desktop                 # the XP desktop in a window, see below
./build.sh job xp/jobs/IFACE32.CMD # another script instead of MAKE.BAT
REPO=/path/to/copy ./build.sh      # build another copy of the repository
CLEAN=1 ./build.sh                 # rebuild the repository's prebuilt DLLs and help archives too
SHIPPED=1 ./build.sh               # REGDLG.PAS and CUSTOM\MAKE.BAT as shipped (see below)
BIGMEM=1 ./build.sh                # a player that loads modules over 16 MB (not byte-identical)
LIMIT=1200 ./build.sh              # another time limit for the run, in seconds (default 600)
QMP=/tmp/m4w.sock JOBFILES=/tmp/mod ./build.sh job xp/jobs/PLAYTEST.CMD
                                   # play the module in /tmp/mod in the guest (docs/TESTING.md)
```

Each build starts from the installed system with a fresh copy of the
repository; its F:, W: and X: come back into `out/F`, `out/W` and `out/X`,
replacing the previous ones. On the desktop, the shortcut **Build Mod4Win** runs
`MAKE.BAT` in a window, and **Copy back and shut down** hands the results to
the host.

After a headless build, `build.sh` checks the result: no compiler or tool
errors in `out/F/BUILD.LOG`, and the three installers and their main contents
present. If a step fails, the build ends at once (the guest answers
`setup.exe`'s "press a key to abort"), and `build.sh` lists the errors with
the end of the log, for example:

```
The build had problems:
  ABOUT.PAS(29): Error 37: END expected.
  missing: out/F/MOD4WIN/setup/m4w24ins.exe
  ...
ERROR: the build didn't complete (results so far are in .../out/F)
```

## What does and doesn't work

- **Exactness:** with `SHIPPED=1`, everything the build produces is
  byte-identical to the shipped files, with the original time stamps,
  `MOD4WIN.EXE` and all three installers included. Without it, `MOD4WIN.EXE`
  and the two installers that contain it differ: the repository's
  `REGDLG.PAS` isn't quite the shipped revision, and the original `RLINK`
  marked programs as Windows 3.10 by default. `SHIPPED=1` makes that
  revision's edit, and adds `-31` to `RLINK`, in the build's copy
  ([docs/BIT_EXACT.md](docs/BIT_EXACT.md)). The installers also carry the
  WinZip SE licensee's name, so this needs a registration to the original
  licensee; with another, they differ in that name.
- **Delphi 2:** `./build.sh job xp/jobs/IFACE32.CMD` runs `IFACE32\MAKE.BAT`
  and compiles `MCITest32`. `PLAYTEST.EXE` and `DSTEST16.EXE` are identical,
  `MCITest32.exe` is identical except one unused byte, and `IFACE16.BIN`
  differs: the repository's copy was linked with an older `W32Base`.
- **Side scripts:** `M4W_MCI\MAKEDEMO.BAT`, `M4W_MCI\MAKERJ.BAT` and
  `SOURCE\MKEWSPLY.BAT` run and write to X:, W: and `F:\MOD4WIN\_BURGER_`.
- **Prebuilt files are reused:** `setup.pas` skips outputs that already
  exist, and the repository contains `RES_*.DLL`/`.DL_`, `INST_*.DLL` and
  `*.HL_`. `CLEAN=1` leaves them out of the build's copy, so they're rebuilt
  (the compiled help files, `.hlp`, stay: recompiling them gives the same
  content, but not byte for byte, and the German help source is a later
  revision than the shipped help). With `SHIPPED=1`, a `CLEAN=1` build still
  gives all three installers byte for byte.

## Documentation

- [docs/WINXP.md](docs/WINXP.md): how the guest is set up and how a build
  runs, and the design choices.
- [docs/MANUAL_XP.md](docs/MANUAL_XP.md): the same environment by hand, step
  by step.
- [docs/BIT_EXACT.md](docs/BIT_EXACT.md): what is reproduced exactly, the
  remaining difference, the build date, what remains unknown, and how to find
  source revisions.
- [docs/MISSING_UNITS.md](docs/MISSING_UNITS.md): the rebuilt units, the
  `GetOS` and `Coroner` revisions, and the layout rules.
- [docs/BUILD_TOOLS.md](docs/BUILD_TOOLS.md): every tool the build uses, and
  its status.
- [docs/FINDINGS.md](docs/FINDINGS.md): what is known about the original
  build machine, and what identifies its PKZIP, WinZip SE and Delphi.
- [docs/INSTALLERS.md](docs/INSTALLERS.md): the distribution packages, and how
  they're built.
- [docs/HW1999.md](docs/HW1999.md): the 1999 hardware edition in detail: where
  its code comes from, its unknown units, its layout, the card driver's
  interface, and its French files.
- [docs/BIGMEM.md](docs/BIGMEM.md): the `BIGMEM=1` player for modules over
  16 MB.
- [docs/TESTING.md](docs/TESTING.md): running and operating programs in the
  guest, e.g. the player on a module.

## License

MIT ([LICENSE](LICENSE)), with two exceptions: the decoder in `tools/is3x.py`
is under the zlib license, and the reconstructed Pascal units in `files/` (and
what `tools/patches.py` makes of `MATHS.PAS` and `GETOS.PAS`) are under
Mod4Win's MIT license. The Mod4Win repository has its own license.
