#!/bin/sh
# Builds Mod4Win 2.40 with its original, unchanged MAKE.BAT in the Windows XP
# guest (see docs/WINXP.md; set it up first with ./setup.sh).
#
# The project is staged fresh from the repository and files/ (the repository
# itself is never touched), goes into the guest on a transfer disk and onto
# its NTFS F:, and comes back with its file dates into out/F, W and X,
# replacing the previous results. QEMU discards all changes to C:, E: and F:,
# so every build starts from the same installed system.
#
# usage: ./build.sh                headless; the log is out/F/BUILD.LOG
#        SHOW=1 ./build.sh         the same, in a window
#        ./build.sh desktop        the XP desktop in a window: build with the
#                                  "Build Mod4Win" shortcut, then "Copy back
#                                  and shut down" hands the results back
#        ./build.sh job FILE.CMD   FILE.CMD instead of MAKE.BAT, between the
#                                  same preparation and copying back (side
#                                  builds such as xp/jobs/IFACE32.CMD)
#   REPO=dir builds another copy of the repository
#   LIMIT=seconds: the run's time limit (default 600); for a job also the
#   job's own (otherwise 5 minutes)
#   JOBFILES=dir puts dir's contents on F:\JOBFILES (e.g. xp/jobs/PLAYTEST.CMD's
#   module)
#   QMP=socket opens QEMU's control socket there, for tools/qmp.py
#   (screenshots, keys; docs/TESTING.md)
#   CLEAN=1 rebuilds the repository's prebuilt RES_*.DLL, INST_*.DLL and help
#   archives (*.HL_) instead of reusing them, as setup.pas otherwise does
#   SHIPPED=1 builds REGDLG.PAS and CUSTOM\MAKE.BAT as the shipped
#   MOD4WIN.EXE was built (docs/BIT_EXACT.md), for byte-identical installers
#   BIGMEM=1 builds a player that loads modules over 16 MB (docs/BIGMEM.md);
#   not byte-identical
set -e
HERE="$(cd "$(dirname "$0")" && pwd)"
G="$HERE/xp/guest"
MODE=$1; JOBFILE=$2
. "$HERE/xp/lib.sh"
check_build
[ "$MODE" = job ] && have "the job file" "$JOBFILE"
[ -n "$JOBFILES" ] && have "the job's files (JOBFILES)" "$JOBFILES"
report
repo_note
begin 1500
stage_project "$TMP/in"
# JOBFILES=dir: its contents on F:\JOBFILES (for a job, e.g. a module to play)
if [ -n "$JOBFILES" ]; then
  mkdir -p "$TMP/in/F/JOBFILES"; cp -r "$JOBFILES/." "$TMP/in/F/JOBFILES/"
fi

# the transfer disk: F\, W\ and X\ (label XFER, which the guest looks for)
mkfatdisk "$VM/t.img" 512 4D345854 XFER
T="$(fatimg "$VM/t.img")"
for d in F W X; do
  mmd -i "$T" "::/$d"
  mcopy -s -m -Q -i "$T" "$TMP/in/$d"/* "::/$d/"
done

if [ "$MODE" = desktop ]; then
  cp "$G/DESKTOP.CMD" "$TMP/RUN.CMD"; SHOW=${SHOW-1}; LIMIT=${LIMIT:-86400}
  echo "Starting the XP desktop; finish with \"Copy back and shut down\""
elif [ "$MODE" = job ]; then
  cp "$G/SIDEJOB.CMD" "$TMP/RUN.CMD"
  cp "$JOBFILE" "$TMP/JOB.CMD"
  # LIMIT= also gives the job itself that long, less two minutes for starting
  # the guest and copying (otherwise DOSKEYS ends it after 5 minutes)
  if [ -n "$LIMIT" ] && [ "$LIMIT" -gt 420 ]; then
    printf '%s\r\n' $(( (LIMIT - 120) * SLOW )) > "$TMP/JOBLIMIT.TXT"
  fi
  echo "Running $JOBFILE in the XP guest"
else
  cp "$G/BUILD.CMD" "$TMP/RUN.CMD"
  echo "Building in the XP guest"
fi
slowfile "$TMP"
set -- "$TMP/RUN.CMD" "$TMP/SLOW.TXT" "$G/PREPARE.CMD" "$G/FINISH.CMD" "$G/MAKE.KEY"
[ -f "$TMP/JOB.CMD" ] && set -- "$@" "$TMP/JOB.CMD"
[ -f "$TMP/JOBLIMIT.TXT" ] && set -- "$@" "$TMP/JOBLIMIT.TXT"
mkfloppy "$VM/ctl.img" "$@"
LIMIT=${LIMIT:-600} runvm "$VM/tools.qcow2,qcow2,snap" "$VM/e.img,raw,snap" "$VM/f.img,raw,snap" \
  "$VM/t.img,raw" "$VM/ctl.img"
rm -f "$VM/ctl.img"

# the results, from the transfer disk into out/F, W and X
mtype -i "$T" ::/DONE.TXT >/dev/null 2>&1 ||
  { keeptransfer=1; fail "the guest shut down without copying the results back ($VM/t.img kept)"; }
OUT="$HERE/out"
rm -rf "$OUT/F" "$OUT/W" "$OUT/X"; mkdir -p "$OUT"
mcopy -s -m -Q -i "$T" ::/F ::/W ::/X "$OUT/"
rm -f "$VM/t.img"
[ "$MODE" = desktop ] && { echo "Done. Results are in $OUT/F"; exit 0; }

# did it work? DOSKEYS's verdict (it ends the run if MAKE.BAT or the job
# asks a question, stops with an error box or doesn't end in time); error
# messages of BPC, TASM, DCC32, MAKE, RTL and the command shell in the log;
# for MAKE.BAT also the three installers and what goes into them
LOG="$OUT/F/BUILD.LOG"
[ -f "$LOG" ] || fail "the guest left no out/F/BUILD.LOG (the build or job didn't start; see the guest's messages above)"
problems=$(tr -d '\015' < "$VM/serial.log" | grep 'DOSKEYS: FAILED' || true)
logerr=$(tr -d '\015' < "$LOG" | grep -E -i 'ERROR!|Error [0-9]+:|Fatal|Runtime error|Abnormal program termination|is not recognized as an internal or external command|Bad command or file name|cannot find the (file|path)|Access is denied|not enough space on the disk|Insufficient disk space' || true)
[ -n "$logerr" ] && problems="${problems:+$problems
}$logerr"
if [ -z "$MODE" ]; then
  for f in setup/m4w24ins.exe setup/m4w24cin.exe setup/mci24ins.exe \
           setup/m4w_full/MOD4WIN.EX_ setup/m4w_full/INSTALL.EXE setup/mci_full/INST_MCI.EXE; do
    [ -n "$(find "$OUT/F/MOD4WIN" -ipath "*/MOD4WIN/$f" 2>/dev/null)" ] ||
      problems="${problems:+$problems
}missing: out/F/MOD4WIN/$f"
  done
fi
if [ -n "$problems" ]; then
  echo "The build had problems:" >&2
  echo "$problems" | sed 's/^/  /' >&2
  echo "The end of out/F/BUILD.LOG:" >&2
  tr -d '\015' < "$LOG" | tail -n 20 | awk '{ print "  " $0 }' >&2
  fail "the build didn't complete (results so far are in $OUT/F)"
fi
echo "Done. Results are in $OUT/F (log: out/F/BUILD.LOG)"
