' hide_console.vbs - Run start-windows.bat without showing a console window
' Usage: wscript.exe hide_console.vbs

' Get the directory where this script is located
scriptDir = Left(WScript.ScriptFullName, Len(WScript.ScriptFullName) - Len(WScript.ScriptName))

' Path to the launcher script
launcherPath = scriptDir & "..\start-windows.bat"

' Run it hidden (0 = hide window, False = don't wait)
CreateObject("WScript.Shell").Run """" & launcherPath & """", 0, False

' Optional: Show a notification
CreateObject("WScript.Shell").Popup "USB Pocket AI is starting in the background...", 2, "Portable AI", 64
