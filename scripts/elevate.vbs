' elevate.vbs - Request administrator privileges for scripts
' Usage: wscript.exe elevate.vbs "your_script.bat"

If WScript.Arguments.Count >= 1 Then
    command = WScript.Arguments(0)
    
    ' Check if already elevated
    If Not WScript.Arguments.Named.Exists("elevated") Then
        CreateObject("Shell.Application").ShellExecute "cmd.exe", "/c " & command & " /elevated", "", "runas", 1
        WScript.Quit
    End If
End If

' Run the actual command
Set objShell = CreateObject("WScript.Shell")
objShell.Run command, 1, True
