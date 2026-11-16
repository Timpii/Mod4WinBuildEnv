#!/bin/sh
# Sets up the Windows XP build guest for Mod4Win 2.40 (see docs/WINXP.md):
#   1. installs Windows XP unattended            -> VM/xp.qcow2
#   2. builds the tools disk from the archives   -> VM/tools.img
#   3. installs the tools in the guest           -> VM/tools.qcow2, e.img, f.img
# About seven minutes with hardware virtualisation. Each step is skipped if its
# result exists; delete VM/ to start over. Everything third-party comes from
# the original archives and installers in inputs/; nothing copyrighted is
# stored in this project. Nothing needs a person at the keyboard.
#
# usage: ./setup.sh             (the inputs and their variables: xp/lib.sh)
#   SHOW=1 shows the guest in a window
set -e
HERE="$(cd "$(dirname "$0")" && pwd)"
G="$HERE/xp/guest"
. "$HERE/xp/lib.sh"
check_setup
begin 4000

# --- 1. Windows XP -------------------------------------------------------------
# Unattended from the CD (xp/winnt.sif on a floppy: minimal, no network
# adapter); the first logon (FIRST.CMD) installs the job hook, presets the
# drive letters E: and F:, and shuts down.
if [ ! -f "$VM/xp.qcow2" ]; then
  key=$(tr -d ' \015\n' < "$XPKEY")
  sed "s/@PRODUCTKEY@/$key/" "$HERE/xp/winnt.sif" > "$TMP/WINNT.SIF"
  mkfloppy "$TMP/sif.img" "$TMP/WINNT.SIF" "$G/FIRST.CMD" "$G/HOOK.CMD"
  rm -f "$VM/xp.qcow2.part"
  qemu-img create -q -f qcow2 "$VM/xp.qcow2.part" 8G
  echo "Installing Windows XP (it restarts a few times; no progress shows until its first logon)"
  [ -n "$XPMEDIA" ] && echo "(The CD is $XPMEDIA media, so the key has to be a $XPMEDIA key.)"
  # (set and cleared explicitly: a shell may keep assignments made in front
  # of a function call)
  HINT="if XP's setup is waiting for a product key, the key in $XPKEY doesn't fit the CD${XPMEDIA:+ (it needs a $XPMEDIA key)}"
  BOOTCD=$XPISO
  LIMIT=3600 runvm "$VM/xp.qcow2.part,qcow2" "" "" "" "$TMP/sif.img"
  unset HINT BOOTCD
  rm -f "$TMP/WINNT.SIF" "$TMP/sif.img"     # they hold the product key
  mv "$VM/xp.qcow2.part" "$VM/xp.qcow2"
  chmod a-w "$VM/xp.qcow2"     # the base of everything else
fi

# --- 2. The tools disk -----------------------------------------------------------
# Installers as they are; extracted only what has no installer of its own or
# replaces installed files; Borland's library sources patched (tools/patches.py).
# (only needed until the tools are installed)
if [ ! -f "$VM/tools.img" ] && [ ! -f "$VM/tools.qcow2" ]; then
  echo "Building the tools disk"
  D="$TMP/disk"
  for d in BP BPRTL DRDOS PKZIP WZIPSE DELPHI D20 BCB PATCH/BPRTL PATCH/D32RTL; do mkdir -p "$D/$d"; done
  # Borland Pascal 7.01: its disk images, wherever they are in the archive and
  # whatever their names, told apart by their contents: the run-time library
  # source disk has RTL.ZIP; the ten install disks (labelled DISKn.DSK) go
  # into one folder (no other names clash)
  unpack "$BP" x -y -o"$TMP/bp" "$BP"
  images "$TMP/bp" > "$TMP/bp.lst"
  ndisks=0; nrtl=0
  while read -r img <&3; do
    "$SEVENZIP" l -slt "$img" 2>/dev/null | sed -n 's/^Path = //p' > "$TMP/img.lst"
    if grep -qix 'RTL\.ZIP' "$TMP/img.lst"; then
      unpack "$img" x -y -o"$D/BPRTL" "$img"; nrtl=$((nrtl + 1))
    elif grep -qiE '^DISK[0-9]+\.DSK$' "$TMP/img.lst"; then
      unpack "$img" x -y -o"$D/BP" "$img"; ndisks=$((ndisks + 1))
    fi
  done 3< "$TMP/bp.lst"
  [ "$ndisks" -eq 10 ] && [ "$nrtl" -eq 1 ] ||
    fail "$BP should hold the ten install disks and the run-time library source disk as disk images; found $ndisks and $nrtl"
  # DR DOS 6.0: XDEL, FORMAT, LABEL (no installer of their own), from whichever
  # of its disk images they're on
  unpack "$DRDOS" x -y -o"$TMP/drdos" "$DRDOS"
  images "$TMP/drdos" > "$TMP/drdos.lst"
  while read -r img <&3; do "$SEVENZIP" x -y -o"$TMP/drdos/x" "$img" >/dev/null 2>&1 || true; done 3< "$TMP/drdos.lst"
  for f in XDEL.EXE FORMAT.COM LABEL.COM; do
    p=$(find "$TMP/drdos/x" -type f -iname "$f" | head -n 1)
    [ -n "$p" ] && cp "$p" "$D/DRDOS/$f" || fail "$f wasn't on the DR DOS disks in $DRDOS"
  done
  cp "$PKDOS" "$D/PKZIP/PK250DOS.EXE"
  cp "$WZSE" "$D/WZIPSE/WZIPSE21.EXE"
  # the registration: the shipped installers carry the licensee's name, which
  # only a registered WinZip SE writes (unregistered, it stops at a notice)
  cp "$WZSEDAT" "$D/WZIPSE/WINZIPSE.DAT"
  # Delphi Developer 2.01: the CD's InstallShield 3 installer
  R=RUNIMAGE/DELPHI20/SOURCE/RTL
  unpack "$DELPHI201" x -y -o"$TMP/d201" "$DELPHI201" 'INSTALL/*' "$R/MAKEFILE" "$R/SYS/HALT.ASM" "$R/SYS/OPENFILE.ASM"
  cp "$TMP"/d201/INSTALL/* "$D/DELPHI/"
  # Delphi Desktop 2.0's compiler, which replaces the installed 2.01 one, and
  # C++Builder 1.0's GETMEM.INC (the memory-manager fix for Delphi's System),
  # both from InstallShield 3 DATA.Z archives
  p=$(archpath "$DELPHI2" '(^|/)DATA\.Z$')
  unpack "$DELPHI2" e -y -o"$TMP/d20" "$DELPHI2" "$p"
  [ -f "$TMP/d20/DATA.Z" ] || mv "$TMP/d20/$(basename "$p")" "$TMP/d20/DATA.Z"
  python3 -I "$HERE/tools/is3x.py" "$TMP/d20/DATA.Z" "$TMP/d20/x" \
    'DELPHI32\MINIMAL\BIN\DCC32.EXE' 'DELPHI32\MINIMAL\BIN\RLINK32.DLL' >/dev/null
  cp "$TMP/d20/x/DELPHI32/MINIMAL/BIN/DCC32.EXE" "$TMP/d20/x/DELPHI32/MINIMAL/BIN/RLINK32.DLL" "$D/D20/"
  p=$(archpath "$BCB1" '(^|/)Setup/DATA\.Z$')
  unpack "$BCB1" e -y -o"$TMP/bcb" "$BCB1" "$p"
  [ -f "$TMP/bcb/DATA.Z" ] || mv "$TMP/bcb/$(basename "$p")" "$TMP/bcb/DATA.Z"
  python3 -I "$HERE/tools/is3x.py" "$TMP/bcb/DATA.Z" "$TMP/bcb/x" 'EBONY\OPTIONS\SOURCE\VCL\GETMEM.INC' >/dev/null
  cp "$TMP/bcb/x/EBONY/OPTIONS/SOURCE/VCL/GETMEM.INC" "$D/BCB/"
  # the patched library sources, copied over the installed ones in the guest
  mkdir -p "$TMP/rtlsrc" "$TMP/d32src"
  for z in RTL:MAKEFILE RTLSTR:STRINGS.PAS RTLWIN:WIN31.PAS RTLWIN:WINDOS.PAS \
           RTLOWL:OMEMORY.PAS RTLOWL:OWINDOWS.PAS RTLCRT:CRT.ASM RTLCRT:CRT.PAS; do
    unpack "${z#*:} from ${z%%:*}.ZIP" e -y -o"$TMP/rtlsrc" "$D/BPRTL/${z%%:*}.ZIP" "${z#*:}"
  done
  python3 -I "$HERE/tools/patches.py" bp "$TMP/rtlsrc" "$D/PATCH/BPRTL"
  cp "$TMP/d201/$R/MAKEFILE" "$TMP/d201/$R/SYS/HALT.ASM" "$TMP/d201/$R/SYS/OPENFILE.ASM" "$TMP/d32src/"
  python3 -I "$HERE/tools/patches.py" delphi "$TMP/d32src" "$D/PATCH/D32RTL"
  # as a FAT disk (label M4WTOOLS), which the guest maps to R:
  mkfatdisk "$VM/tools.img.part" 256 4D34544F M4WTOOLS
  mcopy -s -m -Q -i "$(fatimg "$VM/tools.img.part")" "$D"/* ::/
  mv "$VM/tools.img.part" "$VM/tools.img"
fi

# --- 3. The tools ----------------------------------------------------------------
# xp/guest/INSTALL.CMD on a fresh overlay of the XP image, with new E: (FAT)
# and F: (NTFS, formatted by the guest) disks of fixed signatures. The
# Windows installers are driven by xp/guest/INSTALL.VBS, Borland's DOS
# installers by DOSKEYS (xp/guest/*.KEY), all inside the guest.
if [ ! -f "$VM/tools.qcow2" ]; then
  rm -f "$VM/tools.qcow2.part" "$VM/e.img.part" "$VM/f.img.part"
  qemu-img create -q -f qcow2 -b xp.qcow2 -F qcow2 "$VM/tools.qcow2.part"
  mkfatdisk "$VM/e.img.part" 256 4D345745 BUILD_E
  mkdisk "$VM/f.img.part" 1024 4D345746 7
  cp "$G/INSTALL.CMD" "$TMP/RUN.CMD"; slowfile "$TMP"
  mkfloppy "$VM/ctl.img" "$TMP/RUN.CMD" "$TMP/SLOW.TXT" "$G/HOOK.CMD" "$G/PREPARE.CMD" "$G/FINISH.CMD" \
    "$G/INSTALL.VBS" "$G/DOSKEYS.DPR" "$G/BPINST.KEY" "$G/BPRTL.KEY"
  echo "Installing the tools in the XP guest"
  LIMIT=2400 runvm "$VM/tools.qcow2.part,qcow2" "$VM/e.img.part,raw" "$VM/f.img.part,raw" \
    "$VM/tools.img,raw" "$VM/ctl.img"
  mtype -i "$VM/ctl.img" ::INSTALL.LOG | tr -d '\015' > "$VM/install.log" || true
  if ! mtype -i "$VM/ctl.img" ::OK.TXT >/dev/null 2>&1; then
    echo "The end of the guest's log ($VM/install.log):" >&2
    tail -n 25 "$VM/install.log" >&2
    fail "the tools phase failed (see the guest's ERROR above)"
  fi
  for f in tools.qcow2 e.img f.img; do mv "$VM/$f.part" "$VM/$f"; done
  rm -f "$VM/ctl.img" "$VM/tools.img"
fi
echo "Done. Build with ./build.sh"
