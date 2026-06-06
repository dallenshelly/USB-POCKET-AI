' uninstall.vbs - Completely remove Portable AI from USB drive
' Usage: Right-click "Run with VBScript" or wscript.exe uninstall.vbs

title = "Uninstall Portable AI"
message = "WARNING: This will delete all Portable AI files and models from this USB drive." & vbCrLf & vbCrLf & _
          "This action cannot be undone." & vbCrLf & vbCrLf & _
          "Are you sure you want to continue?"

response = MsgBox(message, vbYesNo + vbExclamation + vbSystemModal, title)

If response = vbYes Then
    ' Get the drive where this script is running
    scriptPath = WScript.ScriptFullName
    driveLetter = Left(scriptPath, 2) ' e.g., "D:"
    
    ' Path to PortableAI folder
    portableAIPath = driveLetter & "\PortableAI"
    
    ' Confirm again
    confirm = MsgBox("Delete folder: " & portableAIPath & " ?", vbYesNo + vbCritical, "Final Confirmation")
    
    If confirm = vbYes Then
        ' Create a temporary batch file to delete the folder
        Set objFSO = CreateObject("Scripting.FileSystemObject")
        Set objShell = CreateObject("WScript.Shell")
        
        tempBat = objShell.ExpandEnvironmentStrings("%temp%") & "\uninstall_portable_ai.bat"
        
        ' Write the batch file
        Set objFile = objFSO.CreateTextFile(tempBat, True)
        objFile.WriteLine "@echo off"
        objFile.WriteLine "echo Uninstalling USB Pocket AI..."
        objFile.WriteLine "timeout /t 2 /nobreak >nul"
        objFile.WriteLine "rmdir /S /Q """ & portableAIPath & """"
        objFile.WriteLine "echo."
        objFile.WriteLine "echo Uninstall complete! You can now safely remove the USB drive."
        objFile.WriteLine "timeout /t 3 /nobreak >nul"
        objFile.WriteLine "del ""%~f0"" >nul 2>&1"
        objFile.Close
        
        ' Run the batch file hidden
        objShell.Run """" & tempBat & """", 0, False
        
        MsgBox "Uninstall started. The PortableAI folder will be deleted.", 64, "Uninstalling..."
    End If
Else
    MsgBox "Uninstall cancelled.", 64, "Portable AI"
End If
