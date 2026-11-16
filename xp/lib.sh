#!/bin/sh
# Shared by setup.sh and build.sh (POSIX sh). HERE (the project's top
# directory) is set before this is read.

fail() { echo "ERROR: $*" >&2; exit 1; }
VM="$HERE/VM"
CR=$(printf '\015')

# --- Inputs: the Mod4Win repository (the submodule Mod4Win/), the rest in
# inputs/ ---
REPO="${REPO:-$HERE/Mod4Win}"
INPUTS="${INPUTS:-$HERE/inputs}"
# the Mod4Win commit the results in docs/ are for
TESTED=42054cafa097bae3df210ae6bcb7207aa49265ff
# each input is a file in its own folder in inputs/, whatever its name: the
# first (in name order) of the expected types, or else the first file at all
# (check_setup says which, if there are several); a variable set beforehand
# names a file instead
# first DIR EXT...: that file, the types tried in the order given, or DIR/ if
# DIR holds none (then reported missing)
first() {
  _d=$1; shift
  for _e in "$@"; do
    for _f in "$_d"/*; do
      [ -f "$_f" ] && [ "$(printf '%s' "${_f##*.}" | tr 'A-Z' 'a-z')" = "$_e" ] &&
        { printf '%s\n' "$_f"; return; }
    done
  done
  for _f in "$_d"/*; do [ -f "$_f" ] && { printf '%s\n' "$_f"; return; }; done
  printf '%s/\n' "$_d"
}
XPISO="${XPISO:-$(first "$INPUTS/windows_xp" iso)}"
XPKEY="${XPKEY:-$(first "$INPUTS/xp_key" key txt)}"
BP="${BP:-$(first "$INPUTS/borland_pascal" 7z zip rar)}"
DRDOS="${DRDOS:-$(first "$INPUTS/dr_dos" 7z zip rar)}"
PKDOS="${PKDOS:-$(first "$INPUTS/pkzip" exe)}"
DELPHI2="${DELPHI2:-$(first "$INPUTS/delphi_desktop" 7z zip rar iso)}"
DELPHI201="${DELPHI201:-$(first "$INPUTS/delphi_developer" iso)}"
BCB1="${BCB1:-$(first "$INPUTS/cpp_builder" 7z zip rar iso)}"
WZSE="${WZSE:-$(first "$INPUTS/winzip_se" exe)}"
WZSEDAT="${WZSEDAT:-$(first "$INPUTS/winzipse_reg" dat)}"

# --- 7-Zip ----------------------------------------------------------------------
# the full program, as 7z (p7zip; most packages) or 7zz (7-Zip's own build,
# Homebrew's sevenzip); SEVENZIP= names another. (7za, the reduced one, can't
# read CD or disk images.)
if [ -z "$SEVENZIP" ]; then
  for c in 7z 7zz; do command -v "$c" >/dev/null 2>&1 && { SEVENZIP=$c; break; }; done
  SEVENZIP=${SEVENZIP:-7z}
fi

# --- QEMU --------------------------------------------------------------------
# qemu-system-x86_64 runs the 32-bit guest just as well, and every platform's
# QEMU has it. The accelerator: KVM (Linux), Hypervisor.framework (macOS on
# Intel), WHPX (Windows); otherwise QEMU emulates the CPU (TCG), which works
# but is many times slower, so the time limits grow accordingly.
QEMU="${QEMU:-qemu-system-x86_64}"
if [ -z "$ACCEL" ]; then
  case "$(uname -m)" in
    x86_64|amd64|i?86)
      case "$(uname -s)" in
        Linux) [ -r /dev/kvm ] && [ -w /dev/kvm ] && ACCEL=kvm ;;
        Darwin) [ "$(sysctl -n kern.hv_support 2>/dev/null)" = 1 ] && ACCEL=hvf ;;
        MINGW*|MSYS*|CYGWIN*) ACCEL=whpx ;;
      esac ;;
  esac
  ACCEL="${ACCEL:-tcg}"
fi
SLOW=1; [ "$ACCEL" = tcg ] && SLOW=10

# --- Checks: collect everything missing, then report it all and stop --------
missing=""
need() { command -v "$1" >/dev/null || missing="$missing\n  program $1: $2"; }
have() { [ -e "$2" ] || missing="$missing\n  $1: $2"; }
report() {
  if [ -n "$missing" ]; then
    echo "ERROR: these are needed but missing or not what they should be (the" >&2
    echo "repository is looked up in $REPO, the other inputs in $INPUTS;" >&2
    printf 'the variable in brackets points elsewhere):%b\n' "$missing" >&2
    exit 1
  fi
  if [ "$ACCEL" = tcg ]; then
    echo "Note: no hardware virtualisation found; QEMU emulates the CPU, which is much slower." >&2
  fi
}
need_host() {
  need "$QEMU" "QEMU, runs the guest (set QEMU= for another binary)"
  need qemu-img "QEMU, creates the disk images"
  need mformat "mtools, writes the FAT disk images"
  need mcopy "mtools"
  need mtype "mtools"
  need mmd "mtools"
  need python3 "runs tools/*.py"
}
# present NAME FILE: FILE is a file; if not, it's reported (a folder from
# first that holds no file: what to put there)
present() {
  [ -f "$2" ] && return 0
  case $2 in
    */) missing="$missing\n  $1: put it into $2" ;;
    *) missing="$missing\n  $1: $2" ;;
  esac
  return 1
}
need_repo() {
  have "Mod4Win repository (REPO; in a clone of this project: git submodule update --init)" "$REPO/SOURCE/MAKE.BAT"
  have "old_versions.zip in the repository (REPO)" "$REPO/old_versions.zip"
}

# holds NAME FILE PATTERN...: the archive (anything 7-Zip reads) FILE lists
# entries matching each extended regular expression PATTERN (ignoring case);
# a light check that it's the right input, before anything is installed
holds() {
  name=$1; file=$2; shift 2
  present "$name" "$file" || return 0
  [ -n "$have7z" ] || return 0
  if ! "$SEVENZIP" l "$file" > "$VM/list.tmp" 2>/dev/null; then
    missing="$missing\n  $name: $file isn't an archive 7-Zip can read"; return
  fi
  for p in "$@"; do
    grep -Eiq "$p" "$VM/list.tmp" ||
      missing="$missing\n  $name: $file doesn't look right (no $(printf '%s' "$p" |
        sed 's/^ //; s/(^| |\/)//; s/\\\.(img|ima|vfd)/disk images (*.img, *.ima, *.vfd)/; s/[\\$]//g') in it)"
  done
  rm -f "$VM/list.tmp"
}

# lacks NAME FILE PATTERN WHY: the archive FILE lists no entry matching
# PATTERN (a sign it's the wrong input; WHY says what it is instead)
lacks() {
  [ -f "$2" ] && [ -n "$have7z" ] || return 0
  if "$SEVENZIP" l "$2" 2>/dev/null | grep -Eq "$3"; then
    missing="$missing\n  $1: $2 $4"
  fi
}

# several FILE: a note when FILE's folder in inputs/ holds other files too
several() {
  case $1 in "$INPUTS"/*/*) ;; *) return 0 ;; esac
  _n=0
  for _f in "${1%/*}"/*; do [ -f "$_f" ] && _n=$((_n + 1)); done
  [ "$_n" -gt 1 ] && echo "Note: ${1%/*} holds $_n files; using ${1##*/}" >&2
  return 0
}

# check_setup: everything setup.sh needs, before it starts: programs, the
# repository, and the inputs, lightly checked (their contents, never values)
check_setup() {
  mkdir -p "$VM"
  need_host
  need "$SEVENZIP" "7-Zip (7z or 7zz; SEVENZIP= for another), reads the archives"
  have7z=$(command -v "$SEVENZIP" || true)
  need_repo
  for _i in "$XPISO" "$XPKEY" "$BP" "$DRDOS" "$PKDOS" "$DELPHI2" "$DELPHI201" "$BCB1" "$WZSE" "$WZSEDAT"; do
    several "$_i"
  done
  holds "Windows XP CD image (XPISO)" "$XPISO" ' I386/TXTSETUP\.SIF$' ' WIN51IP$'
  # 64-bit XP can't run DOS programs, which the whole build depends on
  lacks "Windows XP CD image (XPISO)" "$XPISO" ' AMD64/TXTSETUP\.SIF$' \
    "is 64-bit Windows XP, which can't run DOS programs; the 32-bit (x86) edition is needed"
  # English: the guest's scripts use English names (C:\Program Files, format's
  # Y/N); the CD's licence type, which the key has to match
  if [ -f "$XPISO" ] && [ -n "$have7z" ] &&
     "$SEVENZIP" l -ssc- "$XPISO" I386/HIVESFT.INF 2>/dev/null | grep -qi 'HIVESFT\.INF'; then
    "$SEVENZIP" e -so -ssc- "$XPISO" I386/HIVESFT.INF 2>/dev/null | grep -q '"Program Files (x86)"' ||
      missing="$missing\n  Windows XP CD image (XPISO): $XPISO isn't an English Windows XP, which the setup needs (it uses English folder names and answers)"
    XPMEDIA=$("$SEVENZIP" e -so -ssc- "$XPISO" I386/SETUPP.INI 2>/dev/null | tr -d '\015' | sed -n 's/^Pid=//p' | head -n 1)
    case $XPMEDIA in
      *OEM*) XPMEDIA=OEM ;;
      ?????270*) XPMEDIA=volume-licence ;;
      ?*) XPMEDIA=retail ;;
    esac
  fi
  present "Windows XP product key file (XPKEY)" "$XPKEY"
  if [ -f "$XPKEY" ] && ! tr -d ' \015\n' < "$XPKEY" | grep -Eq '^[A-Z0-9]{5}(-[A-Z0-9]{5}){4}$'; then
    missing="$missing\n  Windows XP product key file (XPKEY): $XPKEY should hold one key, XXXXX-XXXXX-XXXXX-XXXXX-XXXXX"
  fi
  holds "Borland Pascal 7.01 (BP)" "$BP" '\.(img|ima|vfd)$'
  holds "DR DOS 6.0 (DRDOS)" "$DRDOS" '\.(img|ima|vfd)$'
  holds "PKZIP 2.50 for DOS (PKDOS)" "$PKDOS" ' PKZIP\.EXE$' ' PKUNZIP\.EXE$'
  holds "Delphi Desktop 2.0 (DELPHI2)" "$DELPHI2" '(^| |/)DATA\.Z$' '(^| |/)SETUP\.EXE$'
  holds "Delphi Developer 2.01 CD image (DELPHI201)" "$DELPHI201" ' INSTALL/SETUP\.EXE$' ' INSTALL/DATA\.Z$' \
    ' RUNIMAGE/DELPHI20/SOURCE/RTL/SYS/HALT\.ASM$'
  holds "C++Builder 1.0 Client/Server Suite (BCB1)" "$BCB1" '(^| |/)Setup/DATA\.Z$'
  holds "WinZip Self-Extractor 2.1, wzipse21.exe (WZSE)" "$WZSE" ' WZIPSE32\.EXE$' ' WINZIPSE\.HLP$' ' SETUP\.EXE$'
  present "WinZip SE registration, winzipse.dat (WZSEDAT)" "$WZSEDAT"
  if [ -f "$WZSEDAT" ] && ! { [ "$(wc -c < "$WZSEDAT")" -le 200 ] &&
       [ "$(tr -d '\015' < "$WZSEDAT" | grep -c .)" -eq 2 ] &&
       tr -d '\015' < "$WZSEDAT" | sed -n 2p | grep -Eq '^[0-9]+$'; }; then
    missing="$missing\n  WinZip SE registration, winzipse.dat (WZSEDAT): $WZSEDAT should be two short lines, a name and a number"
  fi
  report
}

# repo_note: says so if the repository (when it's a git checkout) isn't the
# tested commit or has local changes; both build fine, but the results may
# differ from the documented ones
repo_note() {
  command -v git >/dev/null && git -C "$REPO" rev-parse --git-dir >/dev/null 2>&1 || return 0
  if [ "$(git -C "$REPO" rev-parse HEAD)" != "$TESTED" ]; then
    echo "Note: $REPO is at commit $(git -C "$REPO" rev-parse --short HEAD), not the tested $(echo "$TESTED" | cut -c1-7)." >&2
  fi
  if [ -n "$(git -C "$REPO" status --porcelain)" ]; then
    echo "Note: $REPO has local changes; they are built too." >&2
  fi
}

# check_build: everything build.sh needs (report follows in build.sh)
check_build() {
  need_host
  need "$SEVENZIP" "7-Zip (7z or 7zz; SEVENZIP= for another), extracts TASK.RES"
  need_repo
  for f in xp.qcow2 tools.qcow2 e.img f.img; do have "from ./setup.sh (run it first)" "$VM/$f"; done
}

# archpath ARCHIVE PATTERN: the first entry of ARCHIVE whose path matches the
# extended regular expression PATTERN (ignoring case; / between folders)
archpath() {
  "$SEVENZIP" l -slt "$1" 2>/dev/null | sed -n 's/^Path = //p' | tr '\\' / | grep -Ei "$2" | head -n 1
}
# images DIR: the floppy disk images anywhere in DIR, one per line
images() {
  find "$1" -type f \( -iname '*.img' -o -iname '*.ima' -o -iname '*.vfd' \) | sort
}

# unpack WHAT 7Z-ARGUMENTS...: 7-Zip, with a clear message if it fails
unpack() {
  what=$1; shift
  "$SEVENZIP" "$@" > "$VM/7z.log" 2>&1 || { tail -n 5 "$VM/7z.log" >&2; fail "7-Zip couldn't extract $what"; }
  rm -f "$VM/7z.log"
}

# --- A run --------------------------------------------------------------------
# begin NEED_MB: one run at a time (VM/lock), enough free space in VM/, a
# temporary folder (TMP, VM/tmp; cleared here too, in case a run was killed
# outright), and cleanup on exit or interruption: a running guest is
# stopped, unfinished images are removed
begin() {
  mkdir -p "$VM"
  mkdir "$VM/lock" 2>/dev/null ||
    fail "another setup.sh or build.sh is using $VM (if none is running, remove $VM/lock)"
  locked=1
  trap cleanup EXIT
  trap 'exit 130' INT TERM HUP
  free=$(df -Pk "$VM" | awk 'NR == 2 { print int($4 / 1024) }')
  [ "$free" -ge "$1" ] || fail "$VM needs about $1 MB of free space, but has $free MB"
  TMP="$VM/tmp"
  rm -rf "$TMP"; mkdir "$TMP"
}
cleanup() {
  if [ -n "$pid" ]; then kill "$pid" 2>/dev/null; wait "$pid" 2>/dev/null; fi
  [ -n "$TMP" ] && rm -rf "$TMP"
  rm -f "$VM"/*.part "$VM/ctl.img" "$VM/crlf.tmp" "$VM/list.tmp" "$VM/7z.log"
  [ -n "$keeptransfer" ] || rm -f "$VM/t.img"
  if [ -n "$locked" ]; then rmdir "$VM/lock"; fi
}

# --- Disk images -----------------------------------------------------------
# mkdisk IMAGE SIZE_MB SIGNATURE TYPE: an image with one partition from 1 MB
# on. XP remembers drive letters by disk signature and partition offset, so a
# fixed signature keeps a regenerated image on the same letter.
FATOFF=1048576
mkdisk() {
  rm -f "$1"
  python3 -I "$HERE/tools/mkdisk.py" "$@"
}
# mkfatdisk IMAGE SIZE_MB SIGNATURE LABEL: the same with FAT16 on it
mkfatdisk() {
  mkdisk "$1" "$2" "$3" 6
  mformat -i "$1@@$FATOFF" -T $(( $2 * 2048 - 2048 )) -h 16 -s 63 -H 2048 -v "$4" ::
}
# slowfile DIR: DIR/SLOW.TXT, the host's slowness factor for the guest's own
# waits (on the control floppy)
slowfile() { printf '%s\r\n' "$SLOW" > "$1/SLOW.TXT"; }

# mtools access to the partition of such an image
fatimg() { echo "$1@@$FATOFF"; }

# mkfloppy IMAGE FILE...: a control floppy; text files get DOS line ends
mkfloppy() {
  img=$1; shift
  rm -f "$img"
  mformat -C -f 1440 -v CONTROL -i "$img" ::
  for f in "$@"; do
    case "$f" in
      *.CMD|*.BAT|*.VBS|*.TXT|*.SIF|*.DPR|*.PAS|*.KEY)
        tr -d '\015' < "$f" | sed "s/\$/$CR/" > "$VM/crlf.tmp"
        mcopy -m -i "$img" "$VM/crlf.tmp" "::$(basename "$f")"; rm -f "$VM/crlf.tmp" ;;
      *) mcopy -m -i "$img" "$f" "::$(basename "$f")" ;;
    esac
  done
}

# --- Running the guest -------------------------------------------------------
# runvm C E F D3 FLOPPY: boots the guest with the fixed device layout (IDE 0
# C:, 1 E:, 2 F:, 3 the tools disk or the transfer disk; floppy A:) and waits
# until it powers off. Disks are "file,format" pairs, or "file,format,snap"
# for a disk whose changes QEMU discards; E, F and D3 may be empty. BOOTCD=iso
# boots from that CD (as IDE 2) once. The guest clock starts at the 2.40
# build date (the guest's clock only; the host clock is never touched) and
# runs only while the guest runs. SHOW=1 opens a window.
# The guest reports on its COM1 (STEP:, ERROR:, DOSKEYS: lines, and DONE or
# FAILED at the end), which QEMU writes to VM/serial.log; those lines are
# shown as they arrive. If the guest doesn't power off within LIMIT seconds,
# it is stopped.
BUILDDATE=2006-12-10T09:00:00
runvm() {
  c=$1; e=$2; f=$3; d3=$4; fl=$5
  limit=$(( ${LIMIT:-3600} * SLOW ))
  set -- -machine pc -accel "$ACCEL" -m 512 -smp 1 -nic none -vga std \
    -rtc "base=$BUILDDATE,clock=vm" -serial "file:$VM/serial.log"
  # (-serial file: takes the rest literally; -drive and -qmp need ,, for a comma)
  i=0
  for d in "$c" "$e" "$f" "$d3"; do
    if [ -n "$d" ]; then
      # PATH,FORMAT[,snap], taken apart from the right: PATH may hold commas
      snap=""
      [ "${d##*,}" = snap ] && { snap=",snapshot=on"; d=${d%,*}; }
      fmt=${d##*,}; path=${d%,*}
      set -- "$@" -drive "file=$(qemuesc "$path"),format=$fmt,if=ide,index=$i$snap"
    fi
    i=$((i + 1))
  done
  if [ -n "$BOOTCD" ]; then
    set -- "$@" -drive "file=$(qemuesc "$BOOTCD"),media=cdrom,if=ide,index=2,readonly=on" -boot once=d
  fi
  set -- "$@" -drive "file=$(qemuesc "$fl"),format=raw,if=floppy,index=0"
  [ -n "$SHOW" ] || set -- "$@" -display none
  # QMP=SOCKET: QEMU's control socket, for screenshots and keys (tools/qmp.py)
  if [ -n "$QMP" ]; then
    rm -f "$QMP"; set -- "$@" -qmp "unix:$(qemuesc "$QMP"),server=on,wait=off"
  fi
  : > "$VM/serial.log"
  "$QEMU" "$@" &
  pid=$!
  t=0; shown=0
  while kill -0 "$pid" 2>/dev/null; do
    shown=$(guestsays "$shown")
    if [ "$t" -ge "$limit" ]; then
      kill "$pid"; wait "$pid" 2>/dev/null || true; pid=""
      fail "the guest didn't finish within $limit seconds (its last report is above)${HINT:+; $HINT}"
    fi
    sleep 1; t=$((t + 1))
  done
  guestsays "$shown" all >/dev/null
  wait "$pid" || { pid=""; fail "QEMU failed (see its messages above)"; }
  pid=""
}
# guestsays N [all]: shows (on stderr) the guest's complete report lines
# after the first N, or with "all" also a last unfinished one, and prints the
# new count
guestsays() {
  if [ "$2" = all ]; then n=$(tr -d '\015' < "$VM/serial.log" | grep -c '') || n=0
  else n=$(tr -d '\015' < "$VM/serial.log" | wc -l | tr -d ' '); fi
  if [ "$n" -gt "$1" ]; then
    # (Windows probes the port at boot, leaving "DSs" before the first line)
    tr -d '\015' < "$VM/serial.log" | sed -n "$(( $1 + 1 )),${n}p" | sed 's/^\(DSs\)*//; s/^/  guest: /' >&2
  fi
  echo "$n"
}
# QEMU option values double their commas
qemuesc() { printf '%s' "$1" | sed 's/,/,,/g'; }

# --- The project tree --------------------------------------------------------
# stage_project DIR: DIR/F, W and X as the build expects them: the repository
# in the original layout (SOURCE\ is F:\MOD4WIN), our reconstructed files
# (files/F), and the side scripts' target folders. The compiler files are on
# the guest's F: already (setup.sh).
stage_project() {
  d=$1
  mkdir -p "$d/F/MOD4WIN" "$d/W/M4W_HTML/MOD4WIN.COM/FILES" "$d/X/SOUND/MOD4WIN/MCI_DEMO"
  cp -r "$REPO/SOURCE/." "$d/F/MOD4WIN/"
  for x in "$REPO"/*/; do
    x=$(basename "$x"); [ "$x" = SOURCE ] || cp -r "$REPO/$x" "$d/F/MOD4WIN/"
  done
  # SOURCE\MKEWSPLY.BAT copies its DLL to ..\_burger_
  mkdir -p "$d/F/MOD4WIN/_BURGER_"
  cp -r "$HERE/files/F/." "$d/F/"
  # F:\WINUNIT\GETOS.PAS: the revision in the 2006 binaries, made from the
  # repository's M4W_MCI\GETOS.PAS (tools/patches.py getos)
  python3 -I "$HERE/tools/patches.py" getos "$REPO/M4W_MCI" "$d/F/WINUNIT" ||
    fail "the repository's M4W_MCI/GETOS.PAS isn't the one expected"
  # F:\WINUNIT\MATHS.PAS: the repository's old_versions.zip has the 2.31 unit;
  # the 2.40 revision differs in two places (tools/patches.py maths)
  unpack "m4w231/PLAYER/FILTER/MATHS.PAS from $REPO/old_versions.zip" \
    e -y -o"$d/maths" "$REPO/old_versions.zip" m4w231/PLAYER/FILTER/MATHS.PAS
  python3 -I "$HERE/tools/patches.py" maths "$d/maths" "$d/F/WINUNIT" ||
    fail "the 2.31 MATHS.PAS in $REPO/old_versions.zip isn't the one expected"
  rm -rf "$d/maths"
  # PLAYER\TASK.RES (task.pas: {$R TASK.RES}) is missing from the repository's
  # PLAYER\, but its old_versions.zip has it from 2.30, identical to the one
  # in the shipped PLAYER32.DLL
  unpack "M4W230/TASK.RES from $REPO/old_versions.zip" \
    e -y -o"$d/F/MOD4WIN/PLAYER" "$REPO/old_versions.zip" M4W230/TASK.RES
  [ -f "$d/F/MOD4WIN/PLAYER/TASK.RES" ] ||
    fail "could not extract M4W230/TASK.RES from $REPO/old_versions.zip"
  # CLEAN=1: without the repository's prebuilt outputs, which setup.pas would
  # otherwise reuse (it skips what exists), so they're rebuilt from source;
  # the compiled help files (.hlp) stay (recompiling them gives the same
  # content, but not byte for byte)
  if [ -n "$CLEAN" ]; then
    find "$d/F/MOD4WIN" -maxdepth 1 -type f \( -iname 'RES_*.DLL' -o -iname 'RES_*.DL_' \) -exec rm -f {} +
    find "$d/F/MOD4WIN/INSTALL" -maxdepth 1 -type f -iname 'INST_*.DLL' -exec rm -f {} +
    find "$d/F/MOD4WIN/HELP" -maxdepth 1 -type f -iname '*.HL_' -exec rm -f {} +
  fi
  # SHIPPED=1: REGDLG.PAS and CUSTOM\MAKE.BAT as the shipped MOD4WIN.EXE was
  # built (docs/BIT_EXACT.md); then all three installers come out identical
  if [ -n "$SHIPPED" ]; then
    python3 -I "$HERE/tools/patches.py" shipped "$d/F/MOD4WIN" "$d/F/MOD4WIN" ||
      fail "the repository's REGDLG.PAS or CUSTOM/MAKE.BAT isn't the one SHIPPED=1 knows"
  fi
  # BIGMEM=1: the player keeps samples in HugeMem's memory (Win32 memory on
  # Windows NT) instead of one 16-bit block, so modules over 16 MB load
  # (docs/BIGMEM.md); not byte-identical by design
  if [ -n "$BIGMEM" ]; then
    python3 -I "$HERE/tools/patches.py" bigmem "$d/F/MOD4WIN" "$d/F/MOD4WIN" ||
      fail "the repository's PLAYER/playdefs.pas or HUGEMEM.PAS isn't the one BIGMEM=1 knows"
  fi
  # original dates (git doesn't keep them): TASK.RES's from its DOS time
  # stamp in old_versions.zip, the files the build packages unchanged from
  # the shipped setup/*.exe; in local time
  while read -r stamp f; do touch -t "$stamp" "$d/F/MOD4WIN/$f"; done <<'EOF'
199701280928.00 PLAYER/TASK.RES
199807101859.38 DEFAULTS/CRYSTALS.66_
199807101859.38 DEFAULTS/FREEDANC.MO_
199807101859.40 DEFAULTS/TRLPLAY.386
199807101859.40 DEFAULTS/TRLPLAY.SYS
199807101859.40 DEFAULTS/TRLPLAY.VXD
200612101106.10 WHATSNEW.TXT
EOF
}
