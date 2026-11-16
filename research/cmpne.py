"""Compare two Windows NE files segment by segment.
usage: cmpne.py ORIGINAL REBUILT
For each segment: lengths and the number of differing bytes, not counting
bytes covered by relocations (their contents depend on the link)."""
import sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import nedis

a, b = nedis.NE(sys.argv[1]), nedis.NE(sys.argv[2])
if len(a.segs) != len(b.segs):
    print(f'segment count {len(a.segs)} vs {len(b.segs)}')
for i in range(min(len(a.segs), len(b.segs))):
    fa, da, ra = a.segs[i]
    fb, db, rb = b.segs[i]
    mask = set()
    for r in (ra, rb):
        for k in r: mask.update(range(k, k + 4))
    diff = [k for k in range(min(len(da), len(db))) if da[k] != db[k] and k not in mask]
    print(f'seg{i + 1} {"DATA" if fb & 1 else "CODE"} len {len(da)} vs {len(db)}: '
          f'{len(diff)} differing bytes outside relocations' + (f', first at {diff[0]:#x}' if diff else ''))
