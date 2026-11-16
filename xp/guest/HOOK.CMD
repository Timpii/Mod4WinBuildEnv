@echo off
rem Runs at every logon (HKLM Run key, set by FIRST.CMD). The host passes jobs
rem to the guest on a control floppy; there is no network.
if exist A:\RUN.CMD call A:\RUN.CMD
