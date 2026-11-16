# The Windows XP build guest

The original `MAKE.BAT` ran in a DOS prompt under Windows XP (or a close
relative). In a Windows XP guest under QEMU it runs completely and unchanged.
The guest has no network adapter, and its clock starts at the 2.40 build date
(the guest's clock only; the host clock is never touched). Usage and inputs
are in the [README](../README.md); doing the same by hand is described in
[MANUAL_XP.md](MANUAL_XP.md).

## Result

| | Result |
|---|---|
| Everything `MAKE.BAT` builds and stages, with time stamps | identical to the shipped files, except `MOD4WIN.EXE` (the [`REGDLG.PAS` revision](BIT_EXACT.md#the-remaining-difference-regdlgpas)) |
| `setup/mci24ins.exe` | identical |
| `setup/m4w24ins.exe`, `m4w24cin.exe` | identical except `MOD4WIN.EX_` inside |
| the same with the two `REGDLG.PAS`/`-31` edits (`SHIPPED=1`) | all three installers identical |
| `IFACE32\MAKE.BAT` (`xp/jobs/IFACE32.CMD`) | `PLAYTEST.EXE`, `DSTEST16.EXE` identical; `IFACE16.BIN` from an older `W32Base` (see [BIT_EXACT.md](BIT_EXACT.md#iface16bin)) |
| `MCITest32.exe` (Delphi 2.0 compiler) | identical except the unused byte at 0xFF |

Setting up takes about seven minutes, a build about 30 seconds (with KVM).

## Requirements

Besides the inputs and programs in the README: hardware virtualisation makes
it fast (KVM on Linux, with your user able to read and write `/dev/kvm`;
Hypervisor.framework on Intel Macs; WHPX on Windows), but it isn't required:
without it QEMU emulates the CPU, and all time limits grow tenfold.
`setup.sh` and `build.sh` check everything they need first (programs, inputs,
the key's format) and list whatever is missing before doing anything. The
input locations and their variables are in `xp/lib.sh`. The scripts are
POSIX `sh` (`checkbashisms` finds nothing).

## Drives and disks

| Drive | What | Image |
|---|---|---|
| C: | Windows XP with `C:\TOOLS`, Delphi in `C:\BORLAND\DELPHI32`, WinZip SE | `VM/xp.qcow2` (XP) ← `VM/tools.qcow2` (the tools) |
| E: | Borland Pascal in `E:\BP`, `E:\TD` (FAT) | `VM/e.img` |
| F: | the compiler files (NTFS); each build adds the project | `VM/f.img` |
| W:, X: | the side scripts' targets: `SUBST` to `F:\_W`, `F:\_X` | — |
| A: | the control floppy: the job for this run | made per run |
| (4th disk) | the tools disk (label `M4WTOOLS`, as R:) during setup; the transfer disk (label `XFER`) in builds | `VM/tools.img`; made per build |

- **Every build starts clean:** QEMU discards all changes to C:, E: and F:
  (`snapshot=on`).
- **F: is NTFS,** like the original's. PKZIP adds files in directory order,
  which is alphabetical on NTFS; on FAT it's creation order, and the ZIPs
  come out in a different order. The host can't write NTFS, so the project
  goes in and out on a FAT transfer disk: the guest copies it onto F: with
  `XCOPY` (which keeps file dates) and back after the build
  (`xp/guest/PREPARE.CMD`, `FINISH.CMD`).
- **Drive letters** are fixed by disk signature: the first logon writes
  `\DosDevices\E:` and `F:` into `HKLM\SYSTEM\MountedDevices` before those
  disks ever appear, and the host gives the images the same signatures every
  time. The tools and transfer disks are found by their volume labels.
- **Jobs** reach the guest on a floppy: a logon hook (`C:\BUILDXP\HOOK.CMD`,
  from the first logon) runs `A:\RUN.CMD` if there is one.
- **Progress and errors** come back on the guest's first serial port (COM1),
  which QEMU writes to `VM/serial.log`: the guest's scripts report each step
  (`STEP: …`), errors (`ERROR: …`) and the outcome (`DONE` or `FAILED`), and
  `DOSKEYS` each installer screen it recognises, or the screen it didn't
  expect. The host shows these lines as they arrive (`runvm` in `xp/lib.sh`).
  It's one-way, guest to host, and gives the guest no access to anything.
- **Time limits:** every run has one, as a safety net for real hangs (an hour
  for the XP install, 40 minutes for the tools, 10 for a build; tenfold
  without hardware virtualisation). If the guest is still running then, it is
  stopped; its last report is what was showing above. The guest's own waits
  (for an installer window or screen, or a disk to appear) are a few minutes,
  times the same factor, which the host passes on the control floppy
  (`SLOW.TXT`).
- **One run at a time:** `setup.sh` and `build.sh` lock `VM/` (`VM/lock`) and
  check the free space there first (about 4 GB for setup, 1.5 GB for a build).
  Interrupted (Ctrl-C), they stop the guest and remove unfinished images.
- **No network:** QEMU gives the guest no network adapter at all.
- **The disk images** are written on the host with mtools; `tools/mkdisk.py`
  writes their partition tables.

## Setup (`setup.sh`)

1. **Windows XP:** an unattended install from the CD with `xp/winnt.sif` on a
   floppy (minimal: no optional components; no network). The first logon
   (`xp/guest/FIRST.CMD`) installs the job hook, presets E: and F:, turns off
   Autoplay, error reporting and the screen saver, and shuts down.
2. **The tools disk** (`VM/tools.img`, removed once the tools are installed):
   the installers as they are, and what has no installer of its own or
   replaces installed files, extracted with 7-Zip (and `tools/is3x.py` for
   InstallShield 3 archives); Borland's library sources patched with
   `tools/patches.py`.
3. **The tools** (`xp/guest/INSTALL.CMD`), on an overlay of the XP image:

| Tool | How | Where |
|---|---|---|
| Borland Pascal 7.01 | its DOS `INSTALL.EXE`, from the ten disks in one folder | `E:\BP` (executables directly in it, as `MAKE.BAT`'s `PATH` has `e:\bp`), units in `E:\BP\UNITS`; Turbo Debugger and the Windows utilities (with `RC.EXE`, used as `e:\td\rc`) in `E:\TD` |
| its run-time library source | the RTL disk's `INSTALL.EXE` | `E:\BP\RTL` |
| the rebuilt libraries | the patched sources over Borland's (originals as `*.ORG`), then Borland's `MAKE rtlwin`, `owl`, `rtldos` | the ObjectWindows units into `E:\BP\UNITS`; `TPW.TPL`, `TURBO.TPL` into `F:\MOD4WIN\COMPILER` |
| the other compiler files | copied, as on the original (`COMPILER\dir.txt`) | `BPC.EXE`, `RTM.EXE`, `DPMI16BI.OVL`, `COMPRESS.EXE` into `F:\MOD4WIN\COMPILER` |
| `COMMAND.COM`, `XCOPY.EXE` | copied from XP | `C:\TOOLS` (`MAKE.BAT`'s `PATH` has no Windows directory) |
| DR DOS `XDEL`, `FORMAT`, `LABEL` | copied | `F:\COMPILER` and `F:\MOD4WIN\COMPILER`; `LABEL` in `C:\TOOLS` |
| PKZIP 2.50 | its self-extractor, run in the guest only | `C:\TOOLS` |
| WinZip SE 2.1 | its setup, to its default folder; then copied as `C:\TOOLS\WZIPSE.EXE` with its help file, `.ini` and `winzipse.dat` | see below |
| Delphi 2 | the 2.01 CD's setup (Full) | `C:\BORLAND\DELPHI32`; `SYSTEM.DCU` rebuilt with C++Builder 1.0's `GETMEM.INC` (Turbo Assembler 3.2, then 2.01's `DCC32`), then Delphi 2.0's `DCC32.EXE`/`RLINK32.DLL` over 2.01's |
| desktop shortcuts | `xp/guest/INSTALL.VBS` | All Users desktop |

The installers are interactive, and all of them are driven inside the guest,
each step waiting for what the installer shows:

- **The Windows ones** (WinZip SE, Delphi): `xp/guest/INSTALL.VBS`, which
  waits for each dialog by its title and answers it.
- **Borland's DOS installers:** `DOSKEYS` (`xp/guest/DOSKEYS.DPR`), which the
  tools phase compiles with the just-installed Delphi. It runs the installer
  in its own console, reads that console's text, and writes keystrokes into
  its input, where XP's DOS subsystem reads the keyboard from (keystrokes sent
  to the window, as VBScript's `SendKeys` does, don't reach DOS programs).
  Its scripts (`BPINST.KEY`, `BPRTL.KEY`) wait for each screen's text before
  answering, and fail with a dump of the screen if something else appears.
  That's why Delphi is installed first.

## A build (`build.sh`)

1. The project is staged from the repository (`REPO`) and `files/`: the
   repository's `SOURCE\` as `F:\MOD4WIN` with its other folders inside,
   `PLAYER\TASK.RES` and (with two changes) `F:\WINUNIT\MATHS.PAS` from
   `old_versions.zip`, `F:\WINUNIT\GETOS.PAS` from `M4W_MCI\GETOS.PAS` (also
   with changes), the original file dates,
   and the empty W: and X: target trees.
2. It goes onto the transfer disk, and the guest copies it onto F: over the
   compiler files already there.
3. The guest runs `MAKE.BAT` (or the job) under `DOSKEYS` (`xp/guest/MAKE.KEY`).
   That only matters if a step fails: `setup.exe` then asks for a key
   ("ERROR! press a key to abort", read from the keyboard, so redirecting its
   input doesn't help), and `DOSKEYS` presses it, as someone at the keyboard
   would. A failing build then ends at once instead of waiting for nobody.
   A question nobody should answer, such as `xcopy`'s "Overwrite …
   (Yes/No/All)?" or DOS's "Abort, Retry, Fail?", ends the run at once as a
   failure, and so does NTVDM's error box ("16 bit MS-DOS Subsystem") when a
   DOS program crashes. `DOSKEYS` looks for the questions on the screen and
   at the end of `F:\BUILD.LOG`, where a redirected program writes them.
   Without this the run would wait for its time limit (5 minutes, longer
   without hardware virtualisation). The host treats any `DOSKEYS` failure
   (`DOSKEYS: FAILED` on the serial line, with the screen) as a failed build.
4. The guest copies F:, W: and X: back to the transfer disk and shuts down;
   the host puts them into `out/F`, `out/W`, `out/X`.
5. The host checks the result: `out/F/BUILD.LOG` for compiler and tool errors
   (BPC's `Error nn:`, `ERROR!`, "not recognized" and so on), and for
   `MAKE.BAT` the three installers and their main contents. If anything is
   wrong, it lists it with the end of the log and exits with an error.

## Design choices

The goal: the original `MAKE.BAT` runs unchanged and produces the shipped
files. No changes to `MAKE.BAT`, `setup.pas` or the other sources, and no
extra steps around them.

| Choice | Reason |
|---|---|
| The Mod4Win repository as a git submodule at the tested commit, never modified; `build.sh` notes another commit or local changes | the repository stays the original source; the documented results are for that commit |
| Never store third-party files; `setup.sh` installs them in the guest from the original archives and installers | copyright |
| Rebuild missing units from the binaries only (no book or third-party source, e.g. no D5DG code for WOW32) | copyright; fidelity |
| Keep the original drive letters and directory tree, with the project at `F:\MOD4WIN`; also create the fixed target directories on `W:`, `X:` and `F:\MOD4WIN\_BURGER_` | `MAKE.BAT`, `CLEANUP.BAT`, `setup.pas` and the side scripts depend on them |
| No `G:` drive | only `MAKECODE` (registration-code generator) uses `g:\net_temp` when run; it is not part of a build |
| Use the genuine BP 7.01 compiler, unpatched | the original patch is unknown and doesn't affect output |
| Rebuild `TPW.TPL`, `TURBO.TPL` and the OWL units in the guest, keeping originals as `*.ORG` | the original machine had locally rebuilt libraries |
| Put `/$K-` and the recovered paths in the recreated `BPC.CFG` | required for identical code |
| Add layout-only details to the rebuilt units (`uses` order, `{$C}` attributes, unused constants) | required for identical link layout; listed in [MISSING_UNITS.md](MISSING_UNITS.md#layout-details) |
| By default, don't change `REGDLG.PAS` or `CUSTOM\MAKE.BAT` (`-31`); `SHIPPED=1` makes the two edits in the build's copy | the default build reproduces the repository as it is; the option shows the rest is exact |
| `BIGMEM=1` edits `PLAYER/playdefs.pas` and `HugeMem` in the build's copy | a player for modules over 16 MB ([BIGMEM.md](BIGMEM.md)), kept apart from the exact build |
| Start the guest's clock at the 2.40 build date (2006-12-10); never touch the host clock | time stamps and full recompiles as in the original |
| Restore the original time stamps of `DEFAULTS\*`, `WHATSNEW.TXT` and `TASK.RES` in `build.sh` | git doesn't keep them; all but `TASK.RES` go into the packages unchanged |
| Build every time from a fresh copy of the repository on a clean system | `MAKE.BAT` changes its own tree, and `setup.pas` reuses outputs that exist |
| Substitute tools where the originals are missing: DR DOS 6.0 `XDEL`/`FORMAT`/`LABEL` | the originals aren't available |
| Treat provided binaries as untrusted: run them only inside the offline guest (e.g. the PKZIP self-extractor) | safety |
| WinZip SE 2.1 with its registration (`winzipse.dat`, required) | the installers carry the licensee's name |
| No extra packaging script around `MAKE.BAT` | the build structure must stay original |
| Run `MAKE.BAT` in a Windows XP guest | the original ran in a Windows DOS prompt; XP provides DPMI, `start`, `COMMAND.COM` and `XCOPY` as it did |
| The XP guest: minimal install, no network adapter, tools installed with their own installers where they can reach the original locations, a desktop shortcut for the build | as close to the original as the media allow; isolated |
| Drive every installer inside the guest, waiting for what it shows: a VBScript for the Windows ones, `DOSKEYS` (compiled in the guest with Delphi) for Borland's DOS installers | completely unattended, and independent of the host's speed |
| Plain POSIX `sh` scripts; QEMU's accelerator picked per host, emulation as the fallback | runs on other hosts than Linux |
| Apply the recovered `Crt` fix (`tools/patches.py`) | the original had it; without it `setup.exe` crashes on fast CPUs |
| WinZip SE in XP: the installed program copied as `C:\TOOLS\WZIPSE.EXE` with its help file, `.ini` and `winzipse.dat` | the original evidently ran it from a short `PATH` directory; how exactly isn't known |
| Install Delphi 2 in `C:\BORLAND\DELPHI32` (2.01 setup, 2.0 compiler), rebuilding `SYSTEM.DCU` with C++Builder 1.0's `GETMEM.INC` (originals as `*.ORG`) | reproduces `MCITest32.exe` |
| Use Turbo Assembler 3.2 (from the BP disks) for Delphi's RTL, with a `.DATA` line added in `HALT.ASM`/`OPENFILE.ASM` | `TASM32` 4.0+ isn't available; the code is the same |

## What the original machine evidently had

These show only when the build runs under Windows:

- **F: was NTFS:** the shipped ZIPs list their files alphabetically.
- **`WZIPSE` was a renamed `WZIPSE32.EXE` in a short directory on the
  `PATH`,** with `WINZIPSE.HLP` next to it. WinZip SE 2.1 refuses `MAKE.BAT`'s
  command line ("The command line is too long") when started from
  `C:\Program Files\...` (through an App Paths entry), and it wants its help
  file in its own folder.
- **The DOS run-time library had a Runtime Error 200 fix.** Without it,
  `setup.exe` crashes on a fast CPU. The fix was recovered from the shipped
  `CUSTOM/CHECKSUM.EXE` and reproduces it exactly
  ([BUILD_TOOLS.md](BUILD_TOOLS.md#tpwtpl-turbotpl-tpptpl-runtime-libraries)).
