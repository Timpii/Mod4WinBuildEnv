"""Expand a file made by Microsoft COMPRESS (SZDD, *.EX_ / *.DL_ / *.HL_).
usage: szdd.py IN OUT"""
import sys

d = open(sys.argv[1], 'rb').read()
assert d[:8] == b'SZDD\x88\xf0\x27\x33', 'not an SZDD file'
n = int.from_bytes(d[10:14], 'little')
w = bytearray(b' ' * 4096); p = 4096 - 16; out = bytearray(); i = 14
while i < len(d) and len(out) < n:
    f = d[i]; i += 1
    for b in range(8):
        if i >= len(d): break
        if f >> b & 1:
            c = d[i]; i += 1; out.append(c); w[p] = c; p = (p + 1) & 4095
        else:
            o = d[i] | (d[i + 1] & 0xF0) << 4; l = (d[i + 1] & 15) + 3; i += 2
            for k in range(l):
                c = w[(o + k) & 4095]; out.append(c); w[p] = c; p = (p + 1) & 4095
open(sys.argv[2], 'wb').write(out[:n])
