"""A raw disk image with one partition, for the XP guest (xp/lib.sh).

usage: mkdisk.py IMAGE SIZE_MB SIGNATURE TYPE
The partition (type TYPE, hex) starts at 1 MB and fills the disk; the MBR
carries the disk signature SIGNATURE (hex), by which XP remembers the drive
letter. The partition is left unformatted.
"""
import struct, sys

img, mb, sig, typ = sys.argv[1], int(sys.argv[2]), int(sys.argv[3], 16), int(sys.argv[4], 16)
total = mb * 2048


def chs(lba):                 # 255 heads, 63 sectors; beyond cylinder 1023: maximum
    c, r = divmod(lba, 255 * 63)
    h, s = divmod(r, 63)
    if c > 1023:
        return bytes([0xFE, 0xFF, 0xFF])
    return bytes([h, ((c >> 2) & 0xC0) | (s + 1), c & 0xFF])


mbr = bytearray(512)
mbr[440:444] = struct.pack('<I', sig)
mbr[446:462] = (b'\0' + chs(2048) + bytes([typ]) + chs(total - 1)
                + struct.pack('<II', 2048, total - 2048))
mbr[510:512] = b'\x55\xaa'
with open(img, 'wb') as f:
    f.truncate(total * 512)
    f.write(mbr)
