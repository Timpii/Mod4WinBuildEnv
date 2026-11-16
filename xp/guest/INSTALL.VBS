' The Windows installers' dialogs, answered by waiting for each window and
' sending it keys; run by INSTALL.CMD as INSTALL.VBS delphi|wzse|links.
' A window may take 5 minutes to appear; this and every other wait is
' multiplied by the host's slowness factor (%SLOW%, from INSTALL.CMD).
Dim sh : Set sh = CreateObject("WScript.Shell")
Dim slow : slow = sh.ExpandEnvironmentStrings("%SLOW%")
If Not IsNumeric(slow) Then slow = 1
Sub Act(title)
  Dim i
  For i = 1 To 600 * CInt(slow)
    If sh.AppActivate(title) Then WScript.Sleep 700 * CInt(slow) : Exit Sub
    WScript.Sleep 500
  Next
  WScript.Echo "window not found: " & title
  WScript.Quit 1
End Sub
' K: send keys, then give the program ms milliseconds (times the slowness
' factor) to act on them
Sub K(keys, ms)
  sh.SendKeys keys
  WScript.Sleep ms * CInt(slow)
End Sub

Select Case LCase(WScript.Arguments(0))
Case "delphi"
  ' Delphi Developer 2.01's InstallShield setup: Full, into C:\BORLAND\DELPHI32
  ' (the path in the project's .DSK files); the other parts at their defaults.
  sh.Run "R:\DELPHI\SETUP.EXE", 1, False
  Act "Welcome" : K "{ENTER}", 2000
  Act "Install Information" : K "%n", 2000
  Act "Setup Type" : K "%n", 2000                                ' Full
  ' focus order from Next: Cancel, Back, Browse, the Delphi directory field
  Act "Select Directories" : K "{TAB 4}{HOME}+{END}C:\BORLAND\DELPHI32", 1000 : K "%n", 3000
  ' a new directory may need confirming first ("Setup": create it?)
  Dim i
  For i = 1 To 10 * CInt(slow)
    If sh.AppActivate("Modify Services") Then Exit For
    WScript.Sleep 500
  Next
  If i > 10 * CInt(slow) Then K "{ENTER}", 2000
  Act "Modify Services" : K "%n", 2000
  Act "Select Program Folder" : K "%n", 2000
  Act "Start Copying Files" : K "%i", 10000
  Act "Information" : K "{ENTER}", 5000                          ' no PVCS
  Act "Online Registration Wizard" : K "{TAB} ", 2000            ' Cancel
  Act "Cancel Registration Wizard?" : K "%y", 10000
Case "wzse"
  ' WinZip Self-Extractor 2.1's setup, to its default folder; its first run
  ' asks to accept the license (remembered in winzipse.ini).
  sh.Run "R:\WZIPSE\WZIPSE21.EXE", 1, False
  Act "WinZip Self-Extractor 2.1" : K "{ENTER}", 2000            ' Setup
  Act "WinZip Self-Extractor Setup" : K "{ENTER}", 5000         ' default folder
  Act "Welcome" : K "%y", 4000                                   ' license
  sh.Run "taskkill /f /im WZIPSE32.EXE", 0, True
Case "links"
  ' Desktop shortcuts for building from the XP desktop (build.sh desktop).
  Dim d, l
  d = sh.SpecialFolders("AllUsersDesktop")
  Set l = sh.CreateShortcut(d & "\Build Mod4Win.lnk")
  l.TargetPath = sh.ExpandEnvironmentStrings("%ComSpec%")
  l.Arguments = "/k MAKE.BAT"
  l.WorkingDirectory = "F:\MOD4WIN"
  l.Save
  Set l = sh.CreateShortcut(d & "\Copy back and shut down.lnk")
  l.TargetPath = "C:\BUILDXP\FINISH.CMD"
  l.WorkingDirectory = "C:\BUILDXP"
  l.Save
Case Else
  WScript.Echo "unknown job: " & WScript.Arguments(0)
  WScript.Quit 1
End Select
