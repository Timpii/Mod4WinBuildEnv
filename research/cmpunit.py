"""Instruction-level diff of one unit's code in two NE files.
usage: cmpunit.py REBUILT SEG OFF LEN ORIGINAL SEG OFF
SEG/OFF/LEN of the rebuilt unit come from a BPC detailed map (/GD); SEG/OFF in
the original from locate.py. Jump targets, far-call targets and data offsets
are masked, so only real code differences show. MAXD limits the output
(default 25 blocks)."""
import sys, re, difflib, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import nedis


def lst(path, seg, off, ln):
    txt = nedis.dis(nedis.NE(path), seg, off, off + ln)
    out = []
    for l in txt.splitlines():
        m = re.match(r'\s*([0-9a-f]+): (.{42}) ?(.*)', l)
        if not m: continue
        ins, note = m.group(2).strip(), m.group(3)
        if 'j' in ins.split()[0] or 'call' in ins or 'loop' in ins:
            ins = re.sub(r'0x[0-9a-f]+', '#', ins)
        ins = re.sub(r"(?<![\$])-?0x[0-9a-f]{3,}", "#", ins)  # absolute memory offsets
        if note.startswith("'"):
            ins = re.sub(r'\$0x[0-9a-f]{3,}', '$#', ins)
        note = re.sub(r'seg\d:[0-9a-f]+', 'seg', note)
        note = re.sub(r"^'.*", '', note)
        out.append((int(m.group(1), 16), (ins + ' ' + note).strip()))
    return out


a = lst(sys.argv[1], int(sys.argv[2]), int(sys.argv[3], 0), int(sys.argv[4], 0))
b = lst(sys.argv[5], int(sys.argv[6]), int(sys.argv[7], 0), int(sys.argv[4], 0))
sm = difflib.SequenceMatcher(None, [x[1] for x in a], [x[1] for x in b], autojunk=False)
nd = 0
for op, i1, i2, j1, j2 in sm.get_opcodes():
    if op == 'equal': continue
    nd += 1
    if nd <= int(os.environ.get('MAXD', '25')):
        print(f'--- {op} new@{a[i1][0] if i1 < len(a) else 0:#x} orig@{b[j1][0] if j1 < len(b) else 0:#x}')
        for x in a[i1:i2][:8]: print('   N', x[1])
        for x in b[j1:j2][:8]: print('   O', x[1])
print(f'diff blocks: {nd}  ratio {sm.ratio():.4f}  ({len(a)} vs {len(b)} ins)')
