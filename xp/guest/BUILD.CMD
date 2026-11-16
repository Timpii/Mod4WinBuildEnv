@echo off
rem Headless build job (build.sh): the project onto F:, the original
rem MAKE.BAT, unchanged, and the results back to the host.
rem the current helper scripts from the control floppy
rem the host's slowness factor (1, or 10 without hardware virtualisation):
rem the guest's waits are multiplied by it
set SLOW=1
if exist A:\SLOW.TXT set /p SLOW=< A:\SLOW.TXT
for %%f in (PREPARE FINISH) do copy /y A:\%%f.CMD C:\BUILDXP\ > nul
call C:\BUILDXP\PREPARE.CMD || goto fail
>COM1 echo STEP: Running MAKE.BAT (its output goes to F:\BUILD.LOG)
start "MAKE" /wait C:\BUILDXP\DOSKEYS\DOSKEYS.EXE A:\MAKE.KEY C:\BUILDXP\MAKE.LOG
call C:\BUILDXP\FINISH.CMD
exit /b 0
:fail
>COM1 echo FAILED
%SystemRoot%\system32\shutdown.exe -s -t 0 -f
