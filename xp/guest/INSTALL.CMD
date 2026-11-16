@echo off
rem Tools phase (setup.sh): installs the build tools from the tools disk (R:)
rem the way the original machine had them, then shuts down. Each step is
rem announced on COM1 (STEP:, ERROR:, then DONE or FAILED), which the host
rem shows as it goes; everything is logged to C:\BUILDXP\INSTALL.LOG, copied
rem to A: at the end.
rem the host's slowness factor (1, or 10 without hardware virtualisation):
rem the guest's waits are multiplied by it
set SLOW=1
if exist A:\SLOW.TXT set /p SLOW=< A:\SLOW.TXT
set LOG=C:\BUILDXP\INSTALL.LOG
echo Tools phase > %LOG%
mode COM1: BAUD=9600 PARITY=n DATA=8 STOP=1 to=on xon=off odsr=off octs=off dtr=off rts=off idsr=off > nul
for %%f in (HOOK PREPARE FINISH) do copy /y A:\%%f.CMD C:\BUILDXP\ >> %LOG%

rem --- drives: E: and F: are preset (FIRST.CMD); the tools disk becomes R:
call :step "Preparing the drives (F: as NTFS, the tools disk as R:)"
rem XP may mount new disks a moment after logon: wait for them (2 minutes,
rem times SLOW; F: can't be tested before it's formatted)
set n=0
set /a max=120*SLOW
:drives
set TD=
for %%d in (D G H I J K L M N O P Q S T U V Y Z) do vol %%d: 2>nul | find "M4WTOOLS" >nul && set TD=%%d:
if defined TD if exist E:\nul goto drivesok
set /a n+=1
if %n% gtr %max% goto drivesok
ping -n 2 127.0.0.1 > nul
goto drives
:drivesok
if not defined TD (call :fail "the tools disk (label M4WTOOLS) wasn't found" & goto end)
subst R: %TD%\
if not exist E:\nul (call :fail "there is no drive E:" & goto end)
echo Y| format F: /FS:NTFS /V:BUILD_F /Q /X >> %LOG% 2>&1
if not exist F:\nul (call :fail "drive F: couldn't be formatted as NTFS" & goto end)

rem --- Delphi 2.01 (docs/BUILD_TOOLS.md, "Delphi 2"); first, because its
rem compiler builds DOSKEYS
call :step "Installing Delphi 2.01 (its setup, driven by INSTALL.VBS)"
cscript //nologo A:\INSTALL.VBS delphi >> %LOG% 2>&1
set D32=C:\BORLAND\DELPHI32
if not exist %D32%\BIN\DCC32.EXE (call :fail "Delphi's setup didn't finish" & goto end)

rem --- DOSKEYS, compiled with Delphi's own (2.01) compiler: it drives
rem Borland's DOS installers from scripts, reading the console screen and
rem writing the keystrokes into the console input (XP's DOS subsystem ignores
rem keystrokes sent to the window); it reports on COM1 too
call :step "Compiling DOSKEYS"
mkdir C:\BUILDXP\DOSKEYS
copy /y A:\DOSKEYS.DPR C:\BUILDXP\DOSKEYS\ > nul
cd /d C:\BUILDXP\DOSKEYS
%D32%\BIN\DCC32.EXE -CC DOSKEYS.DPR >> %LOG% 2>&1
if not exist DOSKEYS.EXE (call :fail "DOSKEYS didn't compile" & goto end)

rem --- Borland Pascal 7.01 and its run-time library source: everything in
rem E:\BP (MAKE.BAT's PATH has e:\bp, not \BP\BIN), Turbo Debugger and the
rem Windows utilities (RC.EXE, used as e:\td\rc) in E:\TD; see the scripts
call :step "Installing Borland Pascal 7.01 (its installer, driven by DOSKEYS with BPINST.KEY)"
start "BPINSTALL" /wait C:\BUILDXP\DOSKEYS\DOSKEYS.EXE A:\BPINST.KEY C:\BUILDXP\BPINST.LOG
type C:\BUILDXP\BPINST.LOG >> %LOG%
if not exist E:\BP\BPC.EXE (call :fail "Borland Pascal's installer didn't finish" & goto end)
call :step "Installing its run-time library source (driven by DOSKEYS with BPRTL.KEY)"
start "BPRTL" /wait C:\BUILDXP\DOSKEYS\DOSKEYS.EXE A:\BPRTL.KEY C:\BUILDXP\BPRTL.LOG
type C:\BUILDXP\BPRTL.LOG >> %LOG%
if not exist E:\BP\RTL\MAKEFILE (call :fail "the run-time library source installer didn't finish" & goto end)
cd /d C:\

rem --- the locally rebuilt libraries (docs/BUILD_TOOLS.md, TPW.TPL/TURBO.TPL):
rem patched sources over Borland's (originals kept as *.ORG), then Borland's
rem own makefile
call :step "Rebuilding the run-time libraries and ObjectWindows (Borland's MAKE)"
E:
cd \BP\RTL
copy MAKEFILE MAKEFILE.ORG > nul
for %%f in (str\STRINGS win\WIN31 win\WINDOS owl\OMEMORY owl\OWINDOWS crt\CRT) do copy %%f.PAS %%f.ORG > nul
copy crt\CRT.ASM crt\CRTASM.ORG > nul
copy /y R:\PATCH\BPRTL\MAKEFILE . > nul
copy /y R:\PATCH\BPRTL\STRINGS.PAS str > nul
copy /y R:\PATCH\BPRTL\WIN31.PAS win > nul
copy /y R:\PATCH\BPRTL\WINDOS.PAS win > nul
copy /y R:\PATCH\BPRTL\OMEMORY.PAS owl > nul
copy /y R:\PATCH\BPRTL\OWINDOWS.PAS owl > nul
copy /y R:\PATCH\BPRTL\CRT.ASM crt > nul
copy /y R:\PATCH\BPRTL\CRT.PAS crt > nul
attrib -r /s *.* > nul
set OLDPATH=%PATH%
set PATH=E:\BP;%PATH%
MAKE rtlwin >> %LOG% 2>&1
MAKE owl >> %LOG% 2>&1
MAKE rtldos >> %LOG% 2>&1
set PATH=%OLDPATH%
if not exist bin\TPW.TPL (call :fail "TPW.TPL wasn't rebuilt" & goto end)
if not exist bin\TURBO.TPL (call :fail "TURBO.TPL wasn't rebuilt" & goto end)
if not exist bin\owl\OWINDOWS.TPW (call :fail "ObjectWindows wasn't rebuilt" & goto end)
for %%f in (bin\owl\*.TPW) do (copy E:\BP\UNITS\%%~nf.TPW E:\BP\UNITS\%%~nf.ORG > nul & copy /y %%f E:\BP\UNITS\ > nul)

rem --- F:'s fixed part (each build adds the project): the compiler files the
rem original kept in F:\MOD4WIN\COMPILER (see its dir.txt), with the rebuilt
rem libraries, and the DR DOS tools, also in F:\COMPILER (on the PATH)
call :step "Putting the compiler files on F:"
mkdir F:\COMPILER F:\MOD4WIN\COMPILER F:\WINUNIT F:\DOSUNINT F:\EXE
for %%f in (BPC.EXE RTM.EXE DPMI16BI.OVL COMPRESS.EXE) do copy E:\BP\%%f F:\MOD4WIN\COMPILER\ > nul
copy bin\TPW.TPL F:\MOD4WIN\COMPILER\ > nul
copy bin\TURBO.TPL F:\MOD4WIN\COMPILER\ > nul
for %%f in (XDEL.EXE FORMAT.COM) do (copy R:\DRDOS\%%f F:\COMPILER\ > nul & copy R:\DRDOS\%%f F:\MOD4WIN\COMPILER\ > nul)
if not exist F:\MOD4WIN\COMPILER\TURBO.TPL (call :fail "the compiler files couldn't be copied to F:" & goto end)
C:

rem --- C:\TOOLS: XP's own COMMAND.COM and XCOPY (MAKE.BAT's PATH has no
rem Windows directory), DR DOS LABEL, PKZIP 2.50 from its self-extractor
call :step "Setting up C:\TOOLS (COMMAND.COM, XCOPY, LABEL, PKZIP 2.50)"
mkdir C:\TOOLS
cd /d C:\TOOLS
copy %SystemRoot%\system32\command.com . > nul
copy %SystemRoot%\system32\xcopy.exe . > nul
copy R:\DRDOS\LABEL.COM . > nul
R:\PKZIP\PK250DOS.EXE >> %LOG% 2>&1
if not exist C:\TOOLS\PKZIP.EXE (call :fail "PKZIP's self-extractor didn't unpack it" & goto end)

rem --- WinZip Self-Extractor 2.1: installed, then as WZIPSE on the PATH with
rem its help file, settings and registration next to it
rem (WZIPSE32.EXE needs them in its own folder, and refuses a long command
rem line, so it can't be started from "C:\Program Files" by App Paths)
call :step "Installing WinZip Self-Extractor 2.1 (its setup, driven by INSTALL.VBS)"
cscript //nologo A:\INSTALL.VBS wzse >> %LOG% 2>&1
set WZ=C:\Program Files\WinZip Self-Extractor
copy /y "%WZ%\WZIPSE32.EXE" C:\TOOLS\WZIPSE.EXE >> %LOG%
copy /y "%WZ%\WINZIPSE.HLP" C:\TOOLS\ >> %LOG%
copy /y "%WZ%\winzipse.ini" C:\TOOLS\ >> %LOG%
copy /y R:\WZIPSE\WINZIPSE.DAT "%WZ%\winzipse.dat" >> %LOG%
copy /y R:\WZIPSE\WINZIPSE.DAT C:\TOOLS\winzipse.dat >> %LOG%
if not exist C:\TOOLS\winzipse.ini (call :fail "WinZip SE's setup didn't finish" & goto end)
if not exist C:\TOOLS\winzipse.dat (call :fail "the WinZip SE registration couldn't be copied" & goto end)

rem --- Delphi's System rebuilt with C++Builder 1.0's GETMEM.INC (with Turbo
rem Assembler from E:\BP), then Delphi 2.0's compiler over 2.01's
call :step "Rebuilding Delphi's System unit, then putting in Delphi 2.0's compiler"
cd /d %D32%\SOURCE\RTL
copy SYS\GETMEM.INC SYS\GETMEM.ORG > nul
copy SYS\HALT.ASM SYS\HALT.ORG > nul
copy SYS\OPENFILE.ASM SYS\OPENFILE.ORG > nul
copy /y R:\BCB\GETMEM.INC SYS > nul
copy /y R:\PATCH\D32RTL\HALT.ASM SYS > nul
copy /y R:\PATCH\D32RTL\OPENFILE.ASM SYS > nul
attrib -r /s *.* > nul
call R:\PATCH\D32RTL\ASMRTL.BAT >> %LOG% 2>&1
mkdir OUT
%D32%\BIN\DCC32.EXE -q SYS\SYSTEM -y -z -$D- -NOUT >> %LOG% 2>&1
if not exist OUT\SYSTEM.DCU (call :fail "SYSTEM.DCU wasn't rebuilt" & goto end)
copy %D32%\LIB\SYSTEM.DCU %D32%\LIB\SYSTEM.ORG > nul
copy /y OUT\SYSTEM.DCU %D32%\LIB\ > nul
copy %D32%\BIN\DCC32.EXE %D32%\BIN\DCC32.ORG > nul
copy %D32%\BIN\RLINK32.DLL %D32%\BIN\RLINK32.ORG > nul
copy /y R:\D20\DCC32.EXE %D32%\BIN\ > nul
copy /y R:\D20\RLINK32.DLL %D32%\BIN\ > nul
cd /d C:\

call :step "Creating the desktop shortcuts"
cscript //nologo A:\INSTALL.VBS links >> %LOG% 2>&1
echo OK >> %LOG%
echo OK > A:\OK.TXT
>COM1 echo DONE
:end
if not exist A:\OK.TXT >COM1 echo FAILED
copy /y %LOG% A:\INSTALL.LOG > nul
%SystemRoot%\system32\shutdown.exe -s -t 0 -f
goto :eof

rem :step TEXT / :fail TEXT: into the log and onto COM1
:step
echo.>> %LOG%
>>%LOG% echo === %~1
>COM1 echo STEP: %~1
goto :eof
:fail
>>%LOG% echo ERROR: %~1
>COM1 echo ERROR: %~1
goto :eof
