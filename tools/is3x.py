"""Extract an InstallShield 3 DATA.Z archive (PKWARE DCL "implode" data).
usage: is3x.py DATA.Z --list
       is3x.py DATA.Z OUTDIR [PATH...]
PATHs (archive paths like DIR\\SUB\\FILE.EXT or DIR\\SUB\\, case-insensitive)
limit the extraction to those files or directories.

The decoder (the Blast class and its tables) is an altered version of Mark
Adler's blast.c (zlib, contrib/blast): a Python port, with the InstallShield 3
archive handling added. It is not the original software. Its license:

  blast.h -- interface for blast.c
  Copyright (C) 2003, 2012, 2013 Mark Adler
  version 1.3, 24 Aug 2013

  This software is provided 'as-is', without any express or implied
  warranty.  In no event will the author be held liable for any damages
  arising from the use of this software.

  Permission is granted to anyone to use this software for any purpose,
  including commercial applications, and to alter it and redistribute it
  freely, subject to the following restrictions:

  1. The origin of this software must not be misrepresented; you must not
     claim that you wrote the original software. If you use this software
     in a product, an acknowledgment in the product documentation would be
     appreciated but is not required.
  2. Altered source versions must be plainly marked as such, and must not be
     misrepresented as being the original software.
  3. This notice may not be removed or altered from any source distribution.

  Mark Adler    madler@alumni.caltech.edu
"""
import sys, os, struct

LITLEN = [11, 124, 8, 7, 28, 7, 188, 13, 76, 4, 10, 8, 12, 10, 12, 10, 8, 23, 8,
          9, 7, 6, 7, 8, 7, 6, 55, 8, 23, 24, 12, 11, 7, 9, 11, 12, 6, 7, 22, 5,
          7, 24, 6, 11, 9, 6, 7, 22, 7, 11, 38, 7, 9, 8, 25, 11, 8, 11, 9, 12,
          8, 12, 5, 38, 5, 38, 5, 11, 7, 5, 6, 21, 6, 10, 53, 8, 7, 24, 10, 27,
          44, 253, 253, 253, 252, 252, 252, 13, 12, 45, 12, 45, 12, 61, 12, 45,
          44, 173]
LENLEN = [2, 35, 36, 53, 38, 23]
DISTLEN = [2, 20, 53, 230, 247, 151, 248]
BASE = [3, 2, 4, 5, 6, 7, 8, 9, 10, 12, 16, 24, 40, 72, 136, 264]
EXTRA = [0, 0, 0, 0, 0, 0, 0, 0, 1, 2, 3, 4, 5, 6, 7, 8]


def construct(rep):
    length = []
    for b in rep:
        length += [b & 15] * ((b >> 4) + 1)
    count = [0] * 14
    for l in length: count[l] += 1
    offs = [0] * 14
    for i in range(1, 13): offs[i + 1] = offs[i] + count[i]
    symbol = [0] * len(length)
    for s, l in enumerate(length):
        if l: symbol[offs[l]] = s; offs[l] += 1
    return count, symbol


LIT, LEN, DIST = construct(LITLEN), construct(LENLEN), construct(DISTLEN)


class Blast:
    def __init__(self, data):
        self.d = data; self.p = 0; self.buf = 0; self.cnt = 0

    def bits(self, n):
        while self.cnt < n:
            self.buf |= self.d[self.p] << self.cnt; self.p += 1; self.cnt += 8
        v = self.buf & ((1 << n) - 1); self.buf >>= n; self.cnt -= n
        return v

    def decode(self, h):
        count, symbol = h
        code = first = index = 0
        for l in range(1, 14):
            code |= self.bits(1) ^ 1
            c = count[l]
            if code < first + c: return symbol[index + code - first]
            index += c; first += c; first <<= 1; code <<= 1
        raise ValueError('bad code')

    def run(self):
        lit = self.bits(8); dic = self.bits(8)
        if lit > 1 or not 4 <= dic <= 6: raise ValueError('bad header')
        out = bytearray()
        while True:
            if self.bits(1):
                s = self.decode(LEN)
                ln = BASE[s] + self.bits(EXTRA[s])
                if ln == 519: break
                sh = 2 if ln == 2 else dic
                dist = (self.decode(DIST) << sh) + self.bits(sh) + 1
                if dist > len(out): raise ValueError('distance too far')
                for _ in range(ln): out.append(out[-dist])
            else:
                out.append(self.decode(LIT) if lit else self.bits(8))
        return bytes(out)


def entries(z):
    ndirs = struct.unpack_from('<H', z, 0x31)[0]
    dtoc, ftoc = struct.unpack_from('<I', z, 0x29)[0], struct.unpack_from('<I', z, 0x33)[0]
    nfiles = struct.unpack_from('<H', z, 0x0C)[0]
    dirs, p = [], dtoc
    for _ in range(ndirs):
        nf, esz, nl = struct.unpack_from('<HHH', z, p)
        dirs.append(z[p + 6:p + 6 + nl].decode('latin-1')); p += esz
    p = ftoc
    for _ in range(nfiles):
        di, size, csize, off, date, time = struct.unpack_from('<HIIIHH', z, p + 1)
        esz = struct.unpack_from('<H', z, p + 0x17)[0]
        nl = z[p + 0x1D]
        name = z[p + 0x1E:p + 0x1E + nl].decode('latin-1')
        yield dirs[di], name, size, csize, off, date, time
        p += esz


if __name__ == '__main__':
    if len(sys.argv) < 3:
        sys.exit(__doc__.split('\n\n')[0])
    z = open(sys.argv[1], 'rb').read()
    out = sys.argv[2] if len(sys.argv) > 2 and sys.argv[2] != '--list' else None
    only = [p.upper() for p in sys.argv[3:]]
    for d, name, size, csize, off, date, time in entries(z):
        path = (d + '\\' + name) if d else name
        if not out:
            print(f'{size:9d} {csize:9d} {1980 + (date >> 9)}-{date >> 5 & 15:02d}-{date & 31:02d} {path}')
            continue
        if only and not any(path.upper() == p or (p.endswith('\\') and path.upper().startswith(p)) for p in only):
            continue
        data = Blast(z[off:off + csize]).run()
        assert len(data) == size, (path, len(data), size)
        dst = os.path.join(out, *path.split('\\'))
        os.makedirs(os.path.dirname(dst), exist_ok=True)
        open(dst, 'wb').write(data)
