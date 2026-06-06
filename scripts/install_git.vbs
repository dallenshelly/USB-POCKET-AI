' install_git.vbs - Show popup when Git is missing
' Usage: cscript.exe install_git.vbs

title = "Git Not Found"
message = "Git is required to clone the repository and install Portable AI." & vbCrLf & vbCrLf & _
          "Would you like to open the Git download page?" & vbCrLf & vbCrLf & _
          "After installing Git, please run the installer again."

response = MsgBox(message, vbYesNo + vbQuestion + vbSystemModal, title)

If response = vbYes Then
    ' Open Git download page
    CreateObject("WScript.Shell").Run "https://git-scm.com/download/win", 1, False
    MsgBox "Install Git, then restart the installer.", vbInformation, "Portable AI"
Else
    MsgBox "Git is required. Installation cancelled.", vbExclamation, "Portable AI"
End If
