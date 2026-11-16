"""Place-by-place diff of units in a rebuilt NE against an original NE.
usage: diffunits.py REBUILT MAPFILE ORIGINAL LOCFILE UNIT...
MAPFILE is the rebuilt file's detailed map (BPC /GD, which has line numbers);
LOCFILE is the output of locate.py for the same files. Each UNIT is a unit
name from the map, or NAME@SEG:START..END=SEG:START..END to give both ranges
by hand (hex offsets) when locate.py's start is wrong or units were merged.

The original's range for a unit runs from its located start (aligned within
+-0x80 bytes on the unit's first instructions) to the next located unit in
that segment. Differences in addresses only (code, data, jump targets) are
ignored; imported calls are compared by name. Each differing place is
printed with the rebuilt side's source file:line and nearest public
procedure, and both instruction sequences. Places whose instructions differ
only by one constant offset (a shifted field or data address) are marked
[shift +N]. Data embedded in code (jump tables, typed constants) can still
show up as places; check those against the bytes."""
import sys, re, difflib, bisect, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import nedis

newp, mapp, origp, locp = sys.argv[1:5]
want = sys.argv[5:]
mp = open(mapp, encoding='latin-1').read().replace('\r', '')
units = [(int(a), int(b, 16), int(c, 16), n) for a, b, c, n in
         re.findall(r'^\s*(\d{4}):([0-9A-F]{4})\s+([0-9A-F]{4})H\s+(\w+)\s+CODE', mp, re.M)]
pub = sorted((int(a), int(b, 16), n) for a, b, n in
             re.findall(r'^ (\d{4}):([0-9A-F]{4})\s{7}(\w+)\s*$', mp, re.M))
lines = []
for m in re.finditer(r'Line numbers for \w+\(([^)]+)\) segment \w+\n\n(.*?)\n\n', mp, re.S):
    f = m.group(1).split('\\')[-1]
    for ln, sg, off in re.findall(r'(\d+) (\d{4}):([0-9A-F]{4})', m.group(2)):
        lines.append((int(sg), int(off, 16), f, int(ln)))
lines.sort()


def where(sg, off):
    i = bisect.bisect_right(lines, (sg, off, '\xff', 0)) - 1
    j = bisect.bisect_right(pub, (sg, off, '\xff')) - 1
    l = f'{lines[i][2]}:{lines[i][3]}' if i >= 0 and lines[i][0] == sg else '?'
    p = pub[j][2] if j >= 0 and pub[j][0] == sg else '?'
    return f'{l} ({p})'


loc = {}
for l in open(locp):
    m = re.match(r'(\w+)\s+new.*orig seg(\d+):(-?[0-9a-f]+)\.\.', l)
    if m: loc[m.group(1)] = (int(m.group(2)), max(0, int(m.group(3), 16)))
N, O = nedis.NE(newp), nedis.NE(origp)


def lst(ne, sg, a, b):
    """(address, comparison key, text) per instruction"""
    out = []
    for x in nedis.dis(ne, sg, a, b).splitlines():
        m = re.match(r'\s*([0-9a-f]+): (.{42}) ?(.*)', x)
        if not m: continue
        ins, note = m.group(2).strip(), m.group(3).strip()
        key = re.sub(r'0x[0-9a-f]{3,}', '#', ins)
        key = re.sub(r'(?<![\$\w-])0x[0-9a-f]+(?![\w(])', '@', key)  # absolute memory operands
        if key.split()[0].startswith(('j', 'call', 'loop', 'lcall', 'ljmp')):
            key = re.sub(r'0x[0-9a-f]+|@', '#', key)
        key = key.replace('-#', '#').replace('-@', '@')
        imp = re.findall(r'\b([A-Z0-9]+\.\w+)', re.sub(r"'[^']*'", '', note))  # not string annotations
        out.append((int(m.group(1), 16), key + (' ' + imp[0] if imp else ''), f'{ins}  {note}'.rstrip()))
    return out


def shift(na, oa):
    """the one constant offset that turns na into oa, if that is all that differs"""
    if len(na) != len(oa): return None
    ds = set()
    for n, o in zip(na, oa):
        n, o = n.split('  ;')[0].strip(), o.split('  ;')[0].strip()
        if re.sub(r'0x[0-9a-f]+', '#', n) != re.sub(r'0x[0-9a-f]+', '#', o): return None
        ds.update(int(c, 16) - int(a, 16) for a, c in zip(re.findall(r'0x[0-9a-f]+', n),
                                                        re.findall(r'0x[0-9a-f]+', o)) if a != c)
    return ds.pop() if len(ds) == 1 else None


todo = []
for w in want:
    m = re.match(r'(\w+)@(\d+):([0-9a-f]+)\.\.([0-9a-f]+)=(\d+):([0-9a-f]+)\.\.([0-9a-f]+)$', w, re.I)
    if m:
        g = [int(m.group(2)), int(m.group(3), 16), int(m.group(4), 16),
             int(m.group(5)), int(m.group(6), 16), int(m.group(7), 16)]
        todo.append((g[0], g[1], g[2] - g[1], m.group(1), g[3], g[4], g[5]))
    else:
        u = [x for x in units if x[3] == w]
        if not u or w not in loc: sys.exit(f'{w}: not in the map or not located')
        todo.append(u[0] + (None, None, None))

for sg, off, ln, name, osg, ostart, oend in todo:
    a = lst(N, sg, off, off + ln)
    if osg is None:
        osg, ostart = loc[name]
        starts = sorted(s for (k, s) in loc.values() if k == osg and s > ostart)
        oend = starts[0] if starts else len(O.segs[osg - 1][1])
        head, best = [x[1] for x in a[:40]], (-1, ostart)
        for d in range(-0x80, 0x81):
            s = ostart + d
            if s < 0: continue
            k = [x[1] for x in lst(O, osg, s, min(s + 0x180, len(O.segs[osg - 1][1])))[:40]]
            n = 0
            while n < min(len(k), len(head)) and k[n] == head[n]: n += 1
            if n > best[0]: best = (n, s)
        ostart = best[1]
    b = lst(O, osg, ostart, oend)
    sm = difflib.SequenceMatcher(None, [x[1] for x in a], [x[1] for x in b], autojunk=False)
    ops = [o for o in sm.get_opcodes() if o[0] != 'equal']
    print(f'#### {name}: new {sg}:{off:04x}+{ln:04x} ({len(a)} ins), '
          f'orig seg{osg}:{ostart:04x}..{oend:04x} ({len(b)} ins), {len(ops)} places')
    for op, i1, i2, j1, j2 in ops:
        na = a[i1][0] if i1 < len(a) else off + ln
        oa = b[j1][0] if j1 < len(b) else oend
        s = shift([x[2] for x in a[i1:i2]], [x[2] for x in b[j1:j2]])
        tag = f' [shift {s:+#x}]' if s is not None else ''
        print(f'--- {op} new {sg}:{na:04x} {where(sg, na)}  orig seg{osg}:{oa:04x}  (-{i2 - i1} +{j2 - j1}){tag}')
        for x in a[i1:i2][:12]: print('   N', x[2])
        if i2 - i1 > 12: print(f'   N ... {i2 - i1 - 12} more')
        for x in b[j1:j2][:12]: print('   O', x[2])
        if j2 - j1 > 12: print(f'   O ... {j2 - j1 - 12} more')
