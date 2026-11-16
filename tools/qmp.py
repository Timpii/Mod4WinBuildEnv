"""Drive a running guest over QEMU's QMP socket (build.sh with QMP=SOCKET):
screenshots and keyboard input, for testing programs in the guest.

usage: qmp.py SOCKET shot FILE.png      the guest's screen as a PNG
       qmp.py SOCKET keys KEY...        press keys (QEMU key codes, e.g. ret,
                                        tab, alt+f4; + holds them together)
       qmp.py SOCKET text STRING        type ASCII text (letters, digits,
                                        \\ : . space)
"""
import json
import socket
import sys
import time

TEXT_KEYS = {'\\': 'backslash', ':': 'shift+semicolon', '.': 'dot', ' ': 'spc',
             '-': 'minus', '_': 'shift+minus', '\n': 'ret'}


def main():
    sock, op, args = sys.argv[1], sys.argv[2], sys.argv[3:]
    s = socket.socket(socket.AF_UNIX)
    s.connect(sock)
    f = s.makefile('rw')
    f.readline()  # the greeting

    def cmd(name, **arguments):
        f.write(json.dumps({'execute': name, 'arguments': arguments}) + '\n')
        f.flush()
        while True:
            reply = json.loads(f.readline())
            if 'error' in reply:
                sys.exit('qmp: %s: %s' % (name, reply['error'].get('desc')))
            if 'return' in reply:
                return reply['return']

    def key(k):
        cmd('send-key', keys=[{'type': 'qcode', 'data': x} for x in k.split('+')])
        time.sleep(0.15)

    cmd('qmp_capabilities')
    if op == 'shot':
        cmd('screendump', filename=args[0], format='png')
    elif op == 'keys':
        for k in args:
            key(k)
    elif op == 'text':
        for ch in args[0]:
            key(TEXT_KEYS.get(ch) or ('shift+' + ch.lower() if ch.isupper() else ch))
    else:
        sys.exit(__doc__)


if __name__ == '__main__':
    main()
