@echo off
rem First logon after the unattended install ([GuiRunOnce] in WINNT.SIF):
rem installs the logon hook, quiets the system, and shuts down.
mode COM1: BAUD=9600 PARITY=n DATA=8 STOP=1 to=on xon=off odsr=off octs=off dtr=off rts=off idsr=off > nul
>COM1 echo STEP: First logon: installing the job hook, presetting E: and F:
mkdir C:\BUILDXP
copy A:\HOOK.CMD C:\BUILDXP\HOOK.CMD
reg add HKLM\Software\Microsoft\Windows\CurrentVersion\Run /v BuildHook /d C:\BUILDXP\HOOK.CMD /f
rem drive letters for the build disks, before they are ever attached: XP
rem keys them by disk signature and partition offset (1 MB), which the host
rem always writes the same (E: 4D345745, F: 4D345746)
reg add HKLM\SYSTEM\MountedDevices /v \DosDevices\E: /t REG_BINARY /d 4557344D0000100000000000 /f
reg add HKLM\SYSTEM\MountedDevices /v \DosDevices\F: /t REG_BINARY /d 4657344D0000100000000000 /f
rem no Autoplay, no error reporting, no screen saver, no balloon tips
reg add HKLM\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer /v NoDriveTypeAutoRun /t REG_DWORD /d 255 /f
reg add HKLM\Software\Microsoft\PCHealth\ErrorReporting /v DoReport /t REG_DWORD /d 0 /f
reg add HKLM\Software\Microsoft\PCHealth\ErrorReporting /v ShowUI /t REG_DWORD /d 0 /f
reg add "HKCU\Control Panel\Desktop" /v ScreenSaveActive /d 0 /f
reg add HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced /v EnableBalloonTips /t REG_DWORD /d 0 /f
reg add "HKLM\Software\Microsoft\Security Center" /v FirewallDisableNotify /t REG_DWORD /d 1 /f
reg add "HKLM\Software\Microsoft\Security Center" /v AntiVirusDisableNotify /t REG_DWORD /d 1 /f
reg add "HKLM\Software\Microsoft\Security Center" /v UpdatesDisableNotify /t REG_DWORD /d 1 /f
powercfg /change "Always On" /monitor-timeout-ac 0 /disk-timeout-ac 0 /standby-timeout-ac 0
powercfg /setactive "Always On"
>COM1 echo DONE
shutdown -s -t 5 -f
