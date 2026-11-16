# Testing programs in the guest

The build only shows that files are byte-identical. To see a program run,
for example the player of a [`BIGMEM=1`](BIGMEM.md) build, start it in the
XP guest with a job and operate it from the host. The guest stays headless:
nothing opens on the host's screen, and every run starts from the same
installed system.

## The pieces

- **`QMP=SOCKET`** (`build.sh`): QEMU opens its control socket (QMP) at
  `SOCKET` while the guest runs.
- **`tools/qmp.py`** talks to that socket:
  - `qmp.py SOCKET shot FILE.png`: the guest's screen (640×480) as a PNG;
  - `qmp.py SOCKET keys KEY...`: presses keys, by QEMU's key names (`ret`,
    `tab`, `alt+f4`, …; `+` holds keys together);
  - `qmp.py SOCKET text STRING`: types text.
- **`JOBFILES=DIR`** (`build.sh`): `DIR`'s contents go onto
  `F:\JOBFILES` for the job.
- **`LIMIT=SECONDS`** (`build.sh`): the run's time limit, and the job's own
  (otherwise the job ends after 5 minutes).
- **`xp/jobs/PLAYTEST.CMD`:** compiles the player as the build does (with
  `BIGMEM=1` its variant), unpacks the shipped `MOD4WIN.EXE` and
  `RES_USA.DLL` from `setup\m4w_full`, writes a `MOD4WIN.INI` that plays on
  load to a WAV file (the "HDD" device; the guest has no sound card), and
  starts the player with the first file in `F:\JOBFILES`. The job ends when
  the player is closed; F: then comes back to `out/F`, the WAV file in
  `out/F/OUT`.

A test is a loop of screenshot, decision and keys, by hand or by script.

## Playing a module

```sh
mkdir -p /tmp/mod && cp song.xm /tmp/mod/
BIGMEM=1 QMP=/tmp/m4w.sock JOBFILES=/tmp/mod LIMIT=2400 \
  ./build.sh job xp/jobs/PLAYTEST.CMD &
```

Once the log shows `DOSKEYS: started` and the player has had about half a
minute to start (`python3 tools/qmp.py /tmp/m4w.sock shot s.png` shows
where it is):

| Screen | Keys |
|---|---|
| "Some Module file name extensions are not associated with MOD4WIN" | `tab ret` (No) |
| "Ask the ASSOCIATIONS question again?" | `tab ret` (No) |
| *MOD4WIN File Name Selection* (where the HDD device writes) | `alt+p home shift+end`, then `text 'F:\OUT'`, then `ret` |
| playing (the display counts up), then stopped at 0:00 | `alt+f4` |

For example `python3 tools/qmp.py /tmp/m4w.sock keys tab ret`. The WAV file
is then `out/F/OUT/<module>.WAV`. An error box, such as the player's
out-of-memory message, shows in the screenshot; `ret` closes it.
