@echo off
rem Side build (./build.sh job xp/jobs/IFACE32.CMD): IFACE32\MAKE.BAT, which
rem sets no PATH of its own (it ran in a prompt where MAKE.BAT's PATH and
rem Delphi's BIN were set), and MCITest32, which was built from the Delphi
rem IDE, with the switches from its .DOF.
set path=C:\tools;f:\exe;f:\compiler;e:\td;e:\bp;f:\winunit;f:\dosunint;C:\BORLAND\DELPHI32\BIN
F:
cd \MOD4WIN\IFACE32
call MAKE.BAT
cd \MOD4WIN\M4W_MCI\Delphi32
dcc32 -CC -B -$A-,B-,D-,I-,L-,O+,R-,S-,V+,X+,Y-,H+,J+,P+,Q-,T-,U-,W-,Z+ MCITest32.dpr
