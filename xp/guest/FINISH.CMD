@echo off
rem Copies F:, W: and X: back onto the transfer disk for the host, and shuts
rem the guest down.
set XF=
set /p XF=< C:\BUILDXP\XFER.TXT
if not defined XF goto off
>COM1 echo STEP: Copying F:, W: and X: back onto the transfer disk
C:
rmdir /s /q %XF%\F
rmdir /s /q %XF%\W
rmdir /s /q %XF%\X
for /d %%d in (F:\*) do if /i not "%%~nxd"=="System Volume Information" if /i not "%%~nxd"=="_W" if /i not "%%~nxd"=="_X" xcopy "%%d" "%XF%\F\%%~nxd\" /E /K /H /Y /Q
for %%f in (F:\*.*) do copy "%%f" %XF%\F\ > nul
xcopy F:\_W %XF%\W\ /E /K /H /Y /Q
xcopy F:\_X %XF%\X\ /E /K /H /Y /Q
echo done> %XF%\DONE.TXT
del C:\BUILDXP\XFER.TXT
>COM1 echo DONE
:off
%SystemRoot%\system32\shutdown.exe -s -t 0 -f
