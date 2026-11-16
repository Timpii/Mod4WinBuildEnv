@echo off
rem The player as this build compiles it (its BIGMEM=1 variant with BIGMEM=1),
rem with the shipped MOD4WIN.EXE, playing the module in F:\JOBFILES (build.sh
rem JOBFILES=) to a WAV file through the "HDD" device; driven from the host
rem over QMP= with tools/qmp.py (docs/TESTING.md). Close the player to end.
md F:\OUT
md F:\PLAY
cd /d F:\MOD4WIN
COMPILER\BPC /Q /B /EF:\PLAY PLAYER\player32.pas
if not exist F:\PLAY\PLAYER32.DLL exit /b 1
expand setup\m4w_full\MOD4WIN.EX_ F:\PLAY\MOD4WIN.EXE
expand setup\m4w_full\RES_USA.DL_ F:\PLAY\RES_USA.DLL
copy DEFAULTS\TRLPLAY.* F:\PLAY\
> F:\PLAY\MOD4WIN.INI echo [State]
>> F:\PLAY\MOD4WIN.INI echo PlayOnLoad=1
>> F:\PLAY\MOD4WIN.INI echo [Playing Device]
>> F:\PLAY\MOD4WIN.INI echo DeviceID=-2
>> F:\PLAY\MOD4WIN.INI echo DeviceName=HDD
set MODULE=
rem its short (8.3) name, as a 16-bit program takes it, without quotes
for %%f in (F:\JOBFILES\*.*) do set MODULE=%%~sf
if not defined MODULE exit /b 1
cd /d F:\PLAY
start /wait "" F:\PLAY\MOD4WIN.EXE %MODULE%
dir F:\OUT
