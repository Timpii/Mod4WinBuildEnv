"""Find where each unit of a rebuilt NE lies in the original NE.
usage: locate.py REBUILT MAPFILE ORIGINAL
MAPFILE is the detailed map (BPC /GD) of the rebuilt file. Each unit's
instruction sequence is matched against the original's code segments; the
anchor count says how much of the unit matched in one piece."""
import sys, re, subprocess, difflib, os, tempfile
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import nedis


def ins(data):
    with tempfile.NamedTemporaryFile(suffix='.bin') as tmp:
        tmp.write(data); tmp.flush()
        out = subprocess.run(['objdump', '-D', '-b', 'binary', '-m', 'i8086', tmp.name],
                             capture_output=True, text=True).stdout
    r = []
    for l in out.splitlines():
        m = re.match(r'\s*([0-9a-f]+):\t[0-9a-f ]+\t(\S+)', l)
        if m: r.append((int(m.group(1), 16), m.group(2)))
    return r


new, mapf, orig = sys.argv[1:4]
units = []
for l in open(mapf, encoding='latin-1'):
    m = re.match(r'\s*(\d{4}):([0-9A-F]{4})\s+([0-9A-F]{4})H\s+(\w+)\s+CODE', l)
    if m: units.append((int(m.group(1)), int(m.group(2), 16), int(m.group(3), 16), m.group(4)))
ns, os_ = nedis.NE(new).segs, nedis.NE(orig).segs
oins = {i + 1: ins(os_[i][1]) for i in range(len(os_)) if not os_[i][0] & 1}
oseq = {k: [x[1] for x in v] for k, v in oins.items()}
for sg, off, ln, name in units:
    if name == 'System': continue
    u = ins(ns[sg - 1][1][off:off + ln]); useq = [x[1] for x in u]
    best = (0, None, None)
    for k, seq in oseq.items():
        mb = difflib.SequenceMatcher(None, seq, useq, autojunk=False).find_longest_match(0, len(seq), 0, len(useq))
        if mb.size > best[0]: best = (mb.size, k, mb)
    n, k, mb = best
    if n == 0:
        print(f'{name:10s} new {sg}:{off:04x}+{ln:04x}  NOT FOUND'); continue
    start = oins[k][mb.a][0] - u[mb.b][0]
    print(f'{name:10s} new {sg}:{off:04x}+{ln:04x}  -> orig seg{k}:{start:04x}..{start + ln:04x}  (anchor {n}/{len(useq)} ins)')
