@echo off
rem Side build (build.sh job FILE.CMD): the project onto F:, then A:\JOB.CMD
rem (FILE.CMD) instead of MAKE.BAT, then the results back to the host.
rem the host's slowness factor (1, or 10 without hardware virtualisation):
rem the guest's waits are multiplied by it
set SLOW=1
if exist A:\SLOW.TXT set /p SLOW=< A:\SLOW.TXT
for %%f in (PREPARE FINISH) do copy /y A:\%%f.CMD C:\BUILDXP\ > nul
call C:\BUILDXP\PREPARE.CMD || goto fail
>COM1 echo STEP: Running the job (its output goes to F:\BUILD.LOG)
rem run by DOSKEYS like MAKE.BAT (see MAKE.KEY), answering setup.exe's
rem key prompt if a step fails, and failing on questions nobody should answer
> C:\BUILDXP\JOB.KEY echo answer press a key to abort^|ENTER
rem the job's time limit in seconds, if build.sh got LIMIT= (A:\JOBLIMIT.TXT)
if exist A:\JOBLIMIT.TXT set /p JL=< A:\JOBLIMIT.TXT
if defined JL >> C:\BUILDXP\JOB.KEY echo limit %JL%
>> C:\BUILDXP\JOB.KEY echo watch F:\BUILD.LOG
>> C:\BUILDXP\JOB.KEY echo fail (Yes/No/All)
>> C:\BUILDXP\JOB.KEY echo fail Abort, Retry, Fail
>> C:\BUILDXP\JOB.KEY echo run cmd /c A:\JOB.CMD ^> F:\BUILD.LOG 2^>^&1
>> C:\BUILDXP\JOB.KEY echo done
start "JOB" /wait C:\BUILDXP\DOSKEYS\DOSKEYS.EXE C:\BUILDXP\JOB.KEY C:\BUILDXP\JOB.LOG
call C:\BUILDXP\FINISH.CMD
exit /b 0
:fail
>COM1 echo FAILED
%SystemRoot%\system32\shutdown.exe -s -t 0 -f
