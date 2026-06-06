@echo off
title USB Pocket AI Installer - Windows
color 0A

:: ============================================
:: HARDCODED GITHUB REPOSITORY URL - EDIT THIS
:: ============================================
set REPO_URL=https://github.com/dallenshelly/USB-POCKET-AI.git
:: ============================================

:: Check if running from temp folder
echo %cd% | find /i "%temp%" >nul
if %errorLevel% neq 0 (
    echo Script is running from USB. Copying to temp folder...
    set TEMP_SCRIPT_DIR=%temp%\PortableAI_Installer_%random%
    mkdir "%TEMP_SCRIPT_DIR%" 2>nul
    copy "%~f0" "%TEMP_SCRIPT_DIR%\install.bat" >nul
    if exist "scripts\*.*" xcopy /E /I /Y "scripts" "%TEMP_SCRIPT_DIR%\scripts\" >nul
    echo Relaunching from temp folder...
    start "" "%TEMP_SCRIPT_DIR%\install.bat"
    exit /b
)

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
echo    USB Pocket AI Installer - Windows
echo ================================================
echo.

:: List available USB drives
echo Scanning for removable USB drives...
echo.
set drive_count=0
setlocal enabledelayedexpansion
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
:: CHECK FOR GIT
:: ============================================
where git >nul 2>&1
if %errorLevel% neq 0 (
    echo Git is not installed.
    (
        echo MsgBox "Git is required to continue installation." ^& vbCrLf ^& vbCrLf ^& _
               "Would you like to open the Git download page?", _
               vbYesNo + vbQuestion, "Git Not Found"
    ) > "%temp%\git_prompt.vbs"
    
    for /f %%a in ('cscript //nologo "%temp%\git_prompt.vbs"') do set result=%%a
    del "%temp%\git_prompt.vbs"
    
    if "%result%"=="6" (
        start https://git-scm.com/download/win
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
git clone "%REPO_URL%" temp_repo
if %errorLevel% neq 0 (
    echo Failed to clone repository.
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
:: DOWNLOAD AND INSTALL OLLAMA TO USB
:: ============================================
echo.
echo ================================================
echo    Installing Ollama to USB...
echo ================================================
echo.

mkdir ollama_bin 2>nul

echo Downloading Ollama for Windows...
powershell -Command "Invoke-WebRequest -Uri 'https://github.com/ollama/ollama/releases/download/v0.5.7/ollama-windows-amd64.zip' -OutFile '%USB_ROOT%\PortableAI\ollama.zip'"

echo Extracting Ollama to USB...
powershell -Command "Expand-Archive -Path '%USB_ROOT%\PortableAI\ollama.zip' -DestinationPath '%USB_ROOT%\PortableAI\ollama_bin' -Force"
del "%USB_ROOT%\PortableAI\ollama.zip"

echo Ollama installed successfully to USB.

:: ============================================
:: DOWNLOAD AND INSTALL ANYTHINGLLM TO USB
:: ============================================
echo.
echo ================================================
echo    Installing AnythingLLM to USB...
echo ================================================
echo.

mkdir anythingllm 2>nul
mkdir anythingllm_data 2>nul

echo Downloading AnythingLLM for Windows...
powershell -Command "Invoke-WebRequest -Uri 'https://cdn.anythingllm.com/latest/AnythingLLMDesktop.exe' -OutFile '%USB_ROOT%\PortableAI\anythingllm\AnythingLLM_Setup.exe'"

echo.
echo ================================================
echo    IMPORTANT: Install AnythingLLM to USB
echo ================================================
echo.
echo The AnythingLLM installer will now open.
echo.
echo **CRITICAL STEP - DO THIS EXACTLY:**
echo.
echo 1. When asked "Choose Install Location", click BROWSE
echo 2. Navigate to: %USB_ROOT%\PortableAI\anythingllm
echo 3. Click "Install"
echo 4. DO NOT launch AnythingLLM after installation
echo.
echo This keeps EVERYTHING on your USB drive!
echo.
pause

:: Run the AnythingLLM installer
start /wait "" "%USB_ROOT%\PortableAI\anythingllm\AnythingLLM_Setup.exe" /SILENT /DIR="%USB_ROOT%\PortableAI\anythingllm"

:: If silent install fails, try normal
if %errorLevel% neq 0 (
    echo Silent install failed. Please install manually.
    start /wait "" "%USB_ROOT%\PortableAI\anythingllm\AnythingLLM_Setup.exe"
)

:: Delete installer
del "%USB_ROOT%\PortableAI\anythingllm\AnythingLLM_Setup.exe" 2>nul

:: Create portable data config
(
echo # USB Pocket AI - AnythingLLM Portable Configuration
echo STORAGE_DIR=./anythingllm_data
echo OLLAMA_HOST=http://localhost:11434
echo OLLAMA_MODEL_TOKEN_LIMIT=4096
) > "%USB_ROOT%\PortableAI\anythingllm_data\.env"

echo AnythingLLM installed successfully to USB.

:: ============================================
:: CREATE VBS HELPER SCRIPTS
:: ============================================
if not exist "scripts\elevate.vbs" (
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
    (
        echo Set objWMIService = GetObject^("winmgmts:\\.\root\CIMV2"^)
        echo Set colItems = objWMIService.ExecQuery^("SELECT * FROM Win32_VideoController"^)
        echo For Each objItem in colItems
        echo   name = objItem.Name
        echo   adapterRAM = objItem.AdapterRAM / 1073741824
        echo   WScript.Echo "GPU: " ^& name ^& " - VRAM: " ^& Round^(adapterRAM,1^) ^& " GB"
        echo Next
    ) > "scripts\check_gpu.vbs"
)

:: ============================================
:: CREATE WINDOWS LAUNCHER
:: ============================================
(
echo @echo off
echo title USB Pocket AI
echo color 0A
echo cd /d "%%~dp0"
echo set OLLAMA_MODELS=%%~dp0models
echo set OLLAMA_HOST=127.0.0.1:11434
echo set ANYTHINGLLM_DATA=%%~dp0anythingllm_data
echo tasklist /FI "IMAGENAME eq ollama.exe" 2^>NUL ^| find /I "ollama.exe" ^>NUL
echo if %%errorLevel%% equ 0 ^(
echo     echo Ollama is already running.
echo ^) else ^(
echo     echo Starting Ollama AI Engine...
echo     start /b "" "%%~dp0ollama_bin\ollama.exe" serve ^> logs\ollama.log 2^>^&1
echo     timeout /t 3 /nobreak ^>nul
echo ^)
echo set PATH=%%~dp0ollama_bin;%%PATH%%
echo echo.
echo echo Starting AnythingLLM Chat Interface...
echo echo.
echo if exist "anythingllm\AnythingLLM.exe" ^(
echo     start "" "anythingllm\AnythingLLM.exe"
echo ^) else if exist "anythingllm\AnythingLLM Desktop.exe" ^(
echo     start "" "anythingllm\AnythingLLM Desktop.exe"
echo ^) else ^(
echo     echo AnythingLLM not found. Using command line mode.
echo     echo.
echo     echo Available models:
echo     ollama list
echo     echo.
echo     echo Commands:
echo     echo   ollama list
echo     echo   ollama run ^<model^>
echo     echo.
echo     cmd /k
echo     exit
echo ^)
echo.
echo ================================================
echo    USB Pocket AI is Running!
echo ================================================
echo.
echo - Ollama AI Engine: Active
echo - AnythingLLM Chat: Launching...
echo - Data stays on USB - No traces left
echo.
echo Close this window to shut down the AI.
echo ================================================
echo.
pause ^>nul
echo Cleaning up...
taskkill /f /im ollama.exe ^>nul 2^>^&1
echo Done.
) > "start-windows.bat"

:: ============================================
:: IMPORT GGUF FILES
:: ============================================
echo.
echo Checking for GGUF files in gguf folder...

if exist "gguf\*.gguf" (
    echo Found GGUF files. Importing to Ollama...
    
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
    
    taskkill /f /im ollama.exe >nul 2>&1
    echo Import complete.
) else (
    echo No GGUF files found in 'gguf' folder.
    echo Place your .gguf files there and re-run to import.
)

:: Create version file
echo 1.0 > version.txt

:: Clean up temp script folder
rmdir /S /Q "%cd%" 2>nul

echo.
echo ================================================
echo    Installation Complete!
echo ================================================
echo.
echo USB Pocket AI installed to: %selected_drive%\PortableAI
echo.
echo Contents installed:
echo   - Ollama AI Engine (portable)
echo   - AnythingLLM Chat Interface (portable)
echo   - Your cloned repository
echo   - Imported GGUF models (if any)
echo.
echo To use:
echo   1. Eject and re-insert the USB drive
echo   2. Open the PortableAI folder
echo   3. Double-click 'start-windows.bat'
echo   4. AnythingLLM will open automatically
echo.
echo In AnythingLLM Settings:
echo   - LLM Provider: Ollama
echo   - API Base URL: http://localhost:11434
echo   - Select your imported model
echo.
pause
