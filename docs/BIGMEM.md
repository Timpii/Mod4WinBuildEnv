# Modules over 16 MB (`BIGMEM=1`)

`BIGMEM=1 ./build.sh` builds a player that loads, under Wine, modules whose
sample data doesn't fit in one 16-bit memory block, such as _yuki satellites_ by
Radix (`radix_-_yuki_satellites.xm`, 15,421,279 bytes; not stored here). The
default build stays byte-identical; this one isn't, by design.

## The limit

The player keeps all sample data in one block, the play memory, and grows it
with `FitGlobalMem` (`PLAYER/playdefs.pas`) while loading. The song memory
(patterns) and the loader's temporary buffers go through `FitGlobalMem` too.
It has two paths:

- not Windows NT: `HugeAlloc`/`HugeReAlloc` (unit `HugeMem`): DPMI memory
  (int 31h functions 0501h and 0503h) with a tiled array of selectors
  `SelectorInc` apart, which is how the mixer addresses it;
- Windows NT: `GlobalAlloc`/`GlobalReAlloc` of one block, also addressed
  through tiled selectors.

The shipped `GetOS` ends its initialization with `OS:=Windows_NT`, so the
2006 player always takes the second path. A 16-bit global block is limited to
16 MB − 64 KB (16,711,680 bytes) in Windows, and Wine has the same limit.
When the block can't grow, `LoadInstrument` (`PLAYER/loaders.pas`) fails and
`MOD4WIN.EXE` shows "Less than 500 Kbytes of free memory or not enough low
memory."

For the test module the play memory needs:

| Part                                                         | Bytes      |
| ------------------------------------------------------------ | ---------- |
| sample data (102 samples, almost all 16-bit)                 | 15,246,797 |
| ping-pong loops unrolled after their samples (10 samples)    | 3,250,328  |
| per-sample alignment to 4 bytes and 2 leading zeros          | 469        |
| header area (`GetPlayMem`: 64 KB) and surround buffer (8 KB) | 73,728     |
| total                                                        | 18,571,322 |

The 2006 player grows the block to 16,453,632 bytes; the next
`GlobalReAlloc`, to 16,902,702 bytes, fails.

## The change

`tools/patches.py bigmem` edits the build's copies of two units:

- **`PLAYER/playdefs.pas`:** `FitGlobalMem` tests `IF True THEN` instead of
  `IF OS<>WINDOWS_NT THEN`, so it always takes the `HugeMem` path.
  `GetOS` still reports Windows NT for everything else (port access through
  `TRLPLAY.SYS`, timers).
- **`HugeMem`** (both copies: `SOURCE/HUGEMEM.PAS`, which `PLAYER32.DLL`
  gets, and `PLAYER/HUGEMEM.PAS`, which `M4W_MCI.DLL` gets): on Windows NT
  and Wine (`GetWinFlags` with `WF_WINNT`, and the Win32 thunks of
  `W32Base`), the memory comes from Win32 instead of the DPMI server:
  `VirtualAlloc` and `VirtualFree` through `CallProc32W`, growing by
  allocating the new size, copying (`RtlMoveMemory`) and freeing the old
  block; free memory is `GlobalMemoryStatus`' free address space. The tiled
  selectors over the memory are made with DPMI as before, so the mixer
  addresses it the same way. The DPMI routines are kept under new names
  (`DPMIAlloc0`, …) for Windows 3.1/95.

Windows NT's DPMI server for 16-bit Windows programs has only about 15 MB:
on Windows XP (SP3, 32-bit, 512 MB), function 0500h reports 15,728,640
bytes as the largest free block and 2,913 lockable pages (11.9 MB), and
`HugeMem` allocates 1 MB but can't grow it to 20 MB or allocate 20 MB at
once. Selectors over Win32 memory work there: a 20 MB `VirtualAlloc` block
with 320 tiled selectors reads back through the tiles what was written
through 32-bit offsets.

## Tested

The 2006 `MOD4WIN.EXE` with the `BIGMEM=1` `PLAYER32.DLL`, playing the test
module through the "HDD" device (a WAV file):

| System                                                   | Result                                                                   |
| -------------------------------------------------------- | ------------------------------------------------------------------------ |
| Wine 9.0 (16-bit support, as in Ubuntu's `wine` package) | loads (32 channels, 92 patterns), plays to the end (4:36), exits cleanly |
| Windows XP SP3, 32-bit                                   | the same                                                                 |

Both write the same WAV file, byte for byte (48,795,812 bytes). The XP
runs use `xp/jobs/PLAYTEST.CMD` ([TESTING.md](TESTING.md)). With the
2006 `PLAYER32.DLL` both show the out-of-memory message. Not tested:
Windows 3.1 and 95, which keep the DPMI path as in the 2006 player.
