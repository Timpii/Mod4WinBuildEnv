@echo off
rem Desktop session (build.sh desktop): the project onto F:; then build
rem with the "Build Mod4Win" shortcut and finish with "Copy back and shut down".
rem the current helper scripts from the control floppy
rem the host's slowness factor (1, or 10 without hardware virtualisation):
rem the guest's waits are multiplied by it
set SLOW=1
if exist A:\SLOW.TXT set /p SLOW=< A:\SLOW.TXT
for %%f in (PREPARE FINISH) do copy /y A:\%%f.CMD C:\BUILDXP\ > nul
call C:\BUILDXP\PREPARE.CMD
>COM1 echo STEP: Ready: build with "Build Mod4Win" on the desktop, then "Copy back and shut down"
