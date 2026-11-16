"""Windows NE (16-bit) disassembler with relocation and string annotation.
usage: nedis.py FILE SEG START STOP [symfile]
  symfile: lines "seg:off name" for internal targets.
Needs objdump (binutils). Imported functions are shown by ordinal unless
WINE_SPEC_DIR points to Wine's dlls/*/ *.spec files (e.g. user.exe16.spec)."""
import sys, struct, re, subprocess, os, tempfile

SPEC = os.environ.get('WINE_SPEC_DIR', '')
SPECMAP = {'KERNEL': 'krnl386.exe16', 'USER': 'user.exe16', 'GDI': 'gdi.exe16',
           'MMSYSTEM': 'mmsystem.dll16', 'TOOLHELP': 'toolhelp.dll16', 'VER': 'ver.dll16',
           'SHELL': 'shell.dll16', 'COMMDLG': 'commdlg.dll16', 'KEYBOARD': 'keyboard.drv16',
           'SYSTEM': 'system.drv16', 'WIN87EM': 'win87em.dll16'}
_spec = {}


def ordname(mod, o):
    if mod not in _spec:
        t = {}
        p = os.path.join(SPEC, SPECMAP.get(mod, '_') + '.spec')
        if SPEC and os.path.exists(p):
            for l in open(p):
                m = re.match(r'(\d+)\s+\S+\s+(?:-\S+\s+)*(\w+)', l)
                if m: t[int(m.group(1))] = m.group(2)
        _spec[mod] = t
    return _spec[mod].get(o, f'#{o}')


class NE:
    def __init__(self, path):
        d = self.d = open(path, 'rb').read()
        o = self.o = struct.unpack_from('<I', d, 0x3c)[0]
        nseg, nmod = struct.unpack_from('<HH', d, o + 0x1c)
        st, rt, rnt, mrt, imp = struct.unpack_from('<HHHHH', d, o + 0x22)
        et = struct.unpack_from('<H', d, o + 0x04)[0]
        sh = struct.unpack_from('<H', d, o + 0x32)[0]
        self.mods = []
        for i in range(nmod):
            q = o + imp + struct.unpack_from('<H', d, o + mrt + 2 * i)[0]
            self.mods.append(d[q + 1:q + 1 + d[q]].decode('latin-1'))
        self.impbase = o + imp
        self.segs = []
        for i in range(nseg):
            off, ln, fl, mn = struct.unpack_from('<HHHH', d, o + st + 8 * i)
            ln = ln or 0x10000
            base = off << sh
            data = bytearray(d[base:base + ln]) if off else bytearray(ln)
            relocs = {}
            if fl & 0x100 and off:
                p = base + ln
                n = struct.unpack_from('<H', d, p)[0]
                p += 2
                for _ in range(n):
                    src, flg, so, a, b = struct.unpack_from('<BBHHH', d, p)
                    p += 8
                    kind = flg & 3
                    if kind == 0:
                        tgt = f'seg{a & 0xff}:{b:04x}' if (a & 0xff) != 0xff else f'entry#{b}'
                    elif kind == 1:
                        m = self.mods[a - 1]
                        tgt = f'{m}.{ordname(m, b)}'
                    elif kind == 2:
                        m = self.mods[a - 1]
                        q = self.impbase + b
                        tgt = f'{m}.{d[q + 1:q + 1 + d[q]].decode("latin-1")}'
                    else:
                        tgt = f'OSFIXUP{a}'
                    if flg & 4:  # additive
                        relocs[so] = tgt
                    else:
                        loc = so
                        seen = 0
                        while loc != 0xffff and loc < len(data) and seen < 5000:
                            relocs[loc] = tgt
                            nxt = struct.unpack_from('<H', data, loc)[0]
                            loc = nxt
                            seen += 1
            self.segs.append((fl, bytes(data), relocs))
        # data segment strings
        self.strs = {}
        for fl, data, _ in self.segs:
            if fl & 1:
                for m in re.finditer(rb'[\x20-\x7e]{3,}', data):
                    self.strs[m.start()] = m.group(0).decode('latin-1')
        # exports
        self.exports = {}
        names = {}
        for tbl in (rnt,):
            q = o + tbl
            while d[q]:
                n = d[q + 1:q + 1 + d[q]].decode('latin-1'); q += 1 + d[q]
                names[struct.unpack_from('<H', d, q)[0]] = n; q += 2
        nrt_off, nrt_len = struct.unpack_from('<IH', d, o + 0x2c)[0], struct.unpack_from('<H', d, o + 0x20)[0]
        q = nrt_off
        while q < nrt_off + nrt_len and d[q]:
            n = d[q + 1:q + 1 + d[q]].decode("latin-1"); q += 1 + d[q]
            names[struct.unpack_from('<H', d, q)[0]] = n; q += 2
        q = o + et; ordn = 1
        while True:
            cnt, ind = d[q], d[q + 1]; q += 2
            if cnt == 0: break
            for _ in range(cnt):
                if ind == 0:
                    pass
                elif ind == 0xff:
                    seg, off = d[q + 3], struct.unpack_from('<H', d, q + 4)[0]; q += 6
                    self.exports[(seg, off)] = names.get(ordn, f'ord{ordn}')
                else:
                    off = struct.unpack_from('<H', d, q + 1)[0]; q += 3
                    self.exports[(ind, off)] = names.get(ordn, f'ord{ordn}')
                ordn += 1
        self.byord = {}
        for (sg, of), n in self.exports.items():
            self.byord[n] = (sg, of)


def dis(ne, segno, start, stop, syms=None):
    fl, data, relocs = ne.segs[segno - 1]
    with tempfile.NamedTemporaryFile(suffix='.bin') as tmp:
        tmp.write(data); tmp.flush()
        out = subprocess.run(['objdump', '-D', '-b', 'binary', '-m', 'i8086', f'--start-address={start}',
                              f'--stop-address={stop}', tmp.name], capture_output=True, text=True).stdout
    syms = syms or {}
    lines = []
    for l in out.splitlines():
        m = re.match(r'\s*([0-9a-f]+):\t([0-9a-f ]+)\t(.*)', l)
        if not m: continue
        addr = int(m.group(1), 16); nb = len(m.group(2).split()); txt = m.group(3).strip()
        notes = []
        if (segno, addr) in ne.exports: lines.append(f'\n==== EXPORT {ne.exports[(segno, addr)]}')
        if f'seg{segno}:{addr:04x}' in syms: lines.append(f'\n---- {syms[f"seg{segno}:{addr:04x}"]}')
        for k in range(addr, addr + nb):
            if k in relocs:
                t = relocs[k]
                if t.startswith('entry#') and f'ord{t[6:]}' in ne.byord:
                    sg, of = ne.byord[f'ord{t[6:]}']; t = f'seg{sg}:{of:04x}'
                if t in syms: t += f' <{syms[t]}>'
                notes.append(t)
        for v in re.findall(r'\$0x([0-9a-f]+)', txt) + re.findall(r'(?<![\$\w])0x([0-9a-f]+)(?=,|$|\()', txt):
            v = int(v, 16)
            if v in ne.strs and not notes: notes.append(repr(ne.strs[v][:40]))
        lines.append(f'{addr:5x}: {txt:42s} {"; " + " ".join(notes) if notes else ""}')
    return '\n'.join(lines)


if __name__ == '__main__':
    ne = NE(sys.argv[1])
    syms = {}
    if len(sys.argv) > 5:
        for l in open(sys.argv[5]):
            p = l.split(None, 1)
            if len(p) == 2: syms[p[0]] = p[1].strip()
    print(dis(ne, int(sys.argv[2]), int(sys.argv[3], 0), int(sys.argv[4], 0), syms))
