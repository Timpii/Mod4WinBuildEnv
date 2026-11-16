@echo off
rem Puts the project from the transfer disk (label XFER: F\, W\, X\) onto F:,
rem which is NTFS like the original's (PKZIP adds files in directory order,
rem which is alphabetical on NTFS), and maps W: and X: to folders on it.
rem Reports on COM1 (STEP:, ERROR:), which the host shows.
mode COM1: BAUD=9600 PARITY=n DATA=8 STOP=1 to=on xon=off odsr=off octs=off dtr=off rts=off idsr=off > nul
>COM1 echo STEP: Copying the project from the transfer disk onto F:
set XF=
set n=0
if not defined SLOW set SLOW=1
set /a max=120*SLOW
:find
for %%d in (D G H I J K L M N O P Q S T U V Y Z) do vol %%d: 2>nul | find "XFER" >nul && set XF=%%d:
if defined XF if exist %XF%\F\MOD4WIN\MAKE.BAT goto ready
set /a n+=1
if %n% gtr %max% goto nodisk
ping -n 2 127.0.0.1 > nul
goto find
:ready
echo %XF%> C:\BUILDXP\XFER.TXT
xcopy %XF%\F F:\ /E /K /H /Y /Q || goto nocopy
xcopy %XF%\W F:\_W\ /E /K /H /Y /Q
xcopy %XF%\X F:\_X\ /E /K /H /Y /Q
if not exist F:\_W\nul mkdir F:\_W
if not exist F:\_X\nul mkdir F:\_X
subst W: F:\_W
subst X: F:\_X
exit /b 0
:nodisk
>COM1 echo ERROR: the transfer disk, label XFER, was not found
exit /b 1
:nocopy
>COM1 echo ERROR: copying the project onto F: failed
exit /b 1
