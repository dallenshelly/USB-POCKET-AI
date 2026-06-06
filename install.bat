@echo off
title Portable AI USB Installer - Windows
color 0A

:: ============================================
:: HARDCODED GITHUB REPOSITORY URL - EDIT THIS
:: ============================================
set REPO_URL=https://github.com/dallenshelly/USB-POCKET-AI.git
:: ============================================

:: ============================================
:: CHECK IF RUNNING FROM TEMP FOLDER
:: If not, copy self to temp and relaunch
:: ============================================
echo %cd% | find /i "%temp%" >nul
if %errorLevel% neq 0 (
    echo Script is running from USB. Copying to temp folder...
    
    :: Create unique temp folder
    set TEMP_SCRIPT_DIR=%temp%\PortableAI_Installer_%random%
    mkdir "%TEMP_SCRIPT_DIR%" 2>nul
    
    :: Copy this script to temp
    copy "%~f0" "%TEMP_SCRIPT_DIR%\install.bat" >nul
    
    :: Also copy any helper files if they exist (like VBS scripts)
    if exist "scripts\*.*" xcopy /E /I /Y "scripts" "%TEMP_SCRIPT_DIR%\scripts\" >nul
    
    echo Relaunching from temp folder...
    start "" "%TEMP_SCRIPT_DIR%\install.bat"
    exit /b
)

:: We are now running from temp folder - continue with installation
echo Running from temp folder: %cd%
echo.

:: Check for Administrator privileges
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo Requesting Administrator privileges...
    powershell start-process "%~f0" -verb runas
    exit /b
)

cd /d "%~dp0"
cls
echo ================================================
echo    Portable AI USB Installer - Windows
echo ================================================
echo.

:: List available USB drives
echo Scanning for removable USB drives...
echo.
set drive_count=0
for %%D in (D: E: F: G: H: I: J: K: L: M: N: O: P: Q: R: S: T: U: V: W: X: Y: Z:) do (
    if exist %%D\NUL (
        fsutil fsinfo drivetype %%D | find "Removable" >nul
        if !errorlevel! equ 0 (
            set /a drive_count+=1
            echo [!drive_count!] %%D
            set drive!drive_count!=%%D
        )
    )
)

if %drive_count% equ 0 (
    echo No USB drives found. Please insert a USB drive and try again.
    pause
    exit /b
)

echo.
set /p selection="Select USB drive number (1-%drive_count%): "

set selected_drive=
for /l %%i in (1,1,%drive_count%) do (
    if %%i equ %selection% set selected_drive=!drive%%i!
)

if "%selected_drive%"=="" (
    echo Invalid selection.
    pause
    exit /b
)

echo.
echo Selected drive: %selected_drive%
echo WARNING: This will FORMAT the drive to exFAT and erase ALL data!
set /p confirm="Type YES to continue: "

if not "%confirm%"=="YES" (
    echo Cancelled.
    pause
    exit /b
)

:: Format drive to exFAT
echo.
echo Formatting %selected_drive% to exFAT...
format %selected_drive% /FS:exFAT /Q /Y >nul
if %errorLevel% neq 0 (
    echo Format failed. Try manually formatting the drive.
    pause
    exit /b
)
echo Format complete.

:: Create root folder
set USB_ROOT=%selected_drive%
mkdir "%USB_ROOT%\PortableAI" 2>nul
cd /d "%USB_ROOT%\PortableAI"

:: ============================================
:: CHECK FOR GIT AND SHOW VBS POPUP IF MISSING
:: ============================================
where git >nul 2>&1
if %errorLevel% neq 0 (
    echo Git is not installed.
    
    :: Create VBS popup message
    (
        echo MsgBox "Git is required to continue installation." ^& vbCrLf ^& vbCrLf ^& _
               "Would you like to open the Git download page?", _
               vbYesNo + vbQuestion, "Git Not Found"
    ) > "%temp%\git_prompt.vbs"
    
    :: Run the VBS and capture result (6 = Yes, 7 = No)
    for /f %%a in ('cscript //nologo "%temp%\git_prompt.vbs"') do set result=%%a
    del "%temp%\git_prompt.vbs"
    
    if "%result%"=="6" (
        echo Opening Git download page...
        start https://git-scm.com/download/win
        echo.
        echo Please install Git, then run this installer again.
        pause
        exit /b
    ) else (
        echo Git is required. Installation cancelled.
        pause
        exit /b
    )
)

echo Git is installed. Continuing...

:: ============================================
:: CLONE YOUR GITHUB REPOSITORY
:: ============================================
echo.
echo Cloning repository from: %REPO_URL%
echo This may take a moment...

git clone "%REPO_URL%" temp_repo
if %errorLevel% neq 0 (
    echo Failed to clone repository. Check URL and try again.
    pause
    exit /b
)

echo Copying files...
xcopy /E /I /Y temp_repo\* . >nul
rmdir /S /Q temp_repo
echo Repository cloned successfully.

:: Ensure required folders exist
if not exist "gguf" mkdir gguf
if not exist "scripts" mkdir scripts
if not exist "models" mkdir models
if not exist "logs" mkdir logs

:: ============================================
:: INSTALL OLLAMA PORTABLE
:: ============================================
echo.
echo Installing Ollama portable...
mkdir ollama_bin 2>nul

echo Downloading Ollama...
powershell -Command "Invoke-WebRequest -Uri 'https://github.com/ollama/ollama/releases/download/v0.5.7/ollama-windows-amd64.zip' -OutFile '%USB_ROOT%\PortableAI\ollama.zip'"

echo Extracting Ollama...
powershell -Command "Expand-Archive -Path '%USB_ROOT%\PortableAI\ollama.zip' -DestinationPath '%USB_ROOT%\PortableAI\ollama_bin' -Force"
del "%USB_ROOT%\PortableAI\ollama.zip"

:: ============================================
:: CREATE VBS HELPER SCRIPTS (if not in repo)
:: ============================================
if not exist "scripts\elevate.vbs" (
    echo Creating elevate.vbs...
    (
        echo If WScript.Arguments.Count ^>= 1 Then
        echo   If Not WScript.Arguments.Named.Exists^("elevated"^) Then
        echo     CreateObject^("Shell.Application"^).ShellExecute "wscript.exe", """" ^& WScript.ScriptFullName ^& """ /elevated", "", "runas", 1
        echo     WScript.Quit
        echo   End If
        echo End If
        echo RunAction
        echo Sub RunAction^(^)
        echo   For Each arg In WScript.Arguments
        echo     If arg ^<^> "/elevated" Then cmd = cmd ^& " " ^& arg
        echo   Next
        echo   CreateObject^("WScript.Shell"^).Run cmd, 1, True
        echo End Sub
    ) > "scripts\elevate.vbs"
)

if not exist "scripts\check_gpu.vbs" (
    echo Creating check_gpu.vbs...
    (
        echo Set objWMIService = GetObject^("winmgmts:\\.\root\CIMV2"^)
        echo Set colItems = objWMIService.ExecQuery^("SELECT * FROM Win32_VideoController"^)
        echo For Each objItem in colItems
        echo   name = objItem.Name
        echo   adapterRAM = objItem.AdapterRAM / 1073741824
        echo   If InStr^(name, "NVIDIA"^) ^> 0 Or InStr^(name, "AMD"^) ^> 0 Then
        echo     If adapterRAM ^>= 8 Then
        echo       WScript.Echo "GPU: " ^& name ^& " (" ^& Round^(adapterRAM,1^) ^& "GB^) - Can run 13B+ models"
        echo     ElseIf adapterRAM ^>= 4 Then
        echo       WScript.Echo "GPU: " ^& name ^& " (" ^& Round^(adapterRAM,1^) ^& "GB^) - Can run 7B models"
        echo     Else
        echo       WScript.Echo "GPU: " ^& name ^& " (" ^& Round^(adapterRAM,1^) ^& "GB^) - CPU mode recommended"
        echo     End If
        echo   Else
        echo     WScript.Echo "No dedicated GPU detected. CPU mode only."
        echo   End If
        echo Next
    ) > "scripts\check_gpu.vbs"
)

if not exist "scripts\hide_console.vbs" (
    echo Creating hide_console.vbs...
    (
        echo CreateObject^("WScript.Shell"^).Run "cmd /c start-windows.bat", 0, False
    ) > "scripts\hide_console.vbs"
)

:: ============================================
:: CREATE WINDOWS LAUNCHER (if not in repo)
:: ============================================
if not exist "start-windows.bat" (
    echo Creating start-windows.bat...
    (
        echo @echo off
        echo cd /d "%%~dp0"
        echo set OLLAMA_MODELS=%%~dp0models
        echo set OLLAMA_HOST=127.0.0.1:11434
        echo echo Starting Portable AI from USB...
        echo start /b "" "%%~dp0ollama_bin\ollama.exe" serve ^> logs\ollama.log 2^>^&1
        echo echo Ollama server running in background.
        echo echo.
        echo echo Available models:
        echo "%%~dp0ollama_bin\ollama.exe" list
        echo echo.
        echo echo Commands:
        echo echo   ollama list
        echo echo   ollama run ^<model^>
        echo echo   ollama pull ^<model^>
        echo echo.
        echo set PATH=%%~dp0ollama_bin;%%PATH%%
        echo cmd /k
    ) > "start-windows.bat"
)

:: ============================================
:: IMPORT GGUF FILES FROM gguf FOLDER
:: ============================================
echo.
echo Checking for GGUF files in gguf folder...

if exist "gguf\*.gguf" (
    echo Found GGUF files. Starting Ollama for import...
    
    :: Start Ollama in background
    start /b "" "%USB_ROOT%\PortableAI\ollama_bin\ollama.exe" serve
    timeout /t 3 /nobreak >nul
    
    for %%F in ("gguf\*.gguf") do (
        echo Importing %%~nxF...
        set filename=%%~nF
        set modelname=!filename:_=!
        
        (
            echo FROM ./gguf/%%~nxF
        ) > "%USB_ROOT%\PortableAI\Modelfile_temp"
        
        "%USB_ROOT%\PortableAI\ollama_bin\ollama.exe" create !modelname! -f "%USB_ROOT%\PortableAI\Modelfile_temp"
        del "%USB_ROOT%\PortableAI\Modelfile_temp"
    )
    
    :: Stop Ollama
    taskkill /f /im ollama.exe >nul 2>&1
    echo Import complete.
) else (
    echo No GGUF files found in 'gguf' folder.
    echo.
    echo Please place your .gguf files in the 'gguf' folder, then run:
    echo   cd /d "%USB_ROOT%\PortableAI"
    echo   start /b "" ollama_bin\ollama.exe serve
    echo   ollama create MODELNAME -f ./Modelfile
)

:: Create version file
echo 1.0 > version.txt

:: Clean up temp script folder (optional - keep for debugging)
:: rmdir /S /Q "%cd%" 2>nul

echo.
echo ================================================
echo    Installation Complete!
echo ================================================
echo.
echo Portable AI installed to: %selected_drive%\PortableAI
echo.
echo Repository cloned from: %REPO_URL%
echo.
echo To use:
echo   1. Run 'start-windows.bat' from the PortableAI folder
echo   2. Type 'ollama list' to see available models
echo   3. Type 'ollama run MODELNAME' to start chatting
echo.
echo VBS helper scripts are in the 'scripts' folder:
echo   - elevate.vbs : Request admin privileges
echo   - check_gpu.vbs : Check GPU capability
echo   - hide_console.vbs : Run with console hidden
echo.
pause
