@echo off
title USB Pocket AI - AnythingLLM Interface
color 0A

cd /d "%~dp0"

:: Set environment variables for portable operation
set OLLAMA_MODELS=%~dp0models
set OLLAMA_HOST=127.0.0.1:11434
set OLLAMA_ORIGINS=*
set ANYTHINGLLM_DATA=%~dp0anythingllm_data

echo ================================================
echo    USB Pocket AI - Starting...
echo ================================================
echo.

:: Check if Ollama is already running
tasklist /FI "IMAGENAME eq ollama.exe" 2>NUL | find /I "ollama.exe" >NUL
if %errorLevel% equ 0 (
    echo [OK] Ollama is already running.
) else (
    echo [1/2] Starting Ollama AI Engine...
    start /b "" "%~dp0ollama_bin\ollama.exe" serve > logs\ollama.log 2>&1
    echo       Waiting for Ollama to initialize...
    timeout /t 3 /nobreak >nul
    echo [OK] Ollama is running on http://localhost:11434
)

:: Add Ollama to PATH for this session
set PATH=%~dp0ollama_bin;%PATH%

:: Display available models
echo.
echo Available Ollama models:
ollama list
echo.

:: Find and launch AnythingLLM
echo [2/2] Starting AnythingLLM Chat Interface...
echo.

:: Try different possible executable names
if exist "anythingllm\AnythingLLM.exe" (
    echo Launching AnythingLLM from: anythingllm\AnythingLLM.exe
    start "" "anythingllm\AnythingLLM.exe"
    goto :launched
)

if exist "anythingllm\AnythingLLM Desktop.exe" (
    echo Launching AnythingLLM from: anythingllm\AnythingLLM Desktop.exe
    start "" "anythingllm\AnythingLLM Desktop.exe"
    goto :launched
)

if exist "anythingllm\AnythingLLM\AnythingLLM.exe" (
    echo Launching AnythingLLM from: anythingllm\AnythingLLM\AnythingLLM.exe
    start "" "anythingllm\AnythingLLM\AnythingLLM.exe"
    goto :launched
)

:: If AnythingLLM not found, show instructions
echo [WARNING] AnythingLLM not found in 'anythingllm' folder.
echo.
echo ================================================
echo    AnythingLLM Not Installed
echo ================================================
echo.
echo Please install AnythingLLM to your USB drive first.
echo The installer should have done this automatically.
echo.
echo To manually install:
echo   1. Download from: https://anythingllm.com
echo   2. Install to: %~dp0anythingllm
echo   3. Set data folder to: %~dp0anythingllm_data
echo.
echo For now, using command line mode...
echo.
echo Commands:
echo   ollama list              - Show available models
echo   ollama run <model>       - Start chatting
echo.
echo Example: ollama run lily-uncensored
echo ================================================
echo.
cmd /k
exit /b

:launched
echo.
echo ================================================
echo    USB Pocket AI is Running!
echo ================================================
echo.
echo - Ollama AI Engine: Active (http://localhost:11434)
echo - AnythingLLM Chat: Launched
echo - Data stored on USB: %ANYTHINGLLM_DATA%
echo.
echo AnythingLLM Setup Instructions:
echo   1. In AnythingLLM, go to Settings (⚙️)
echo   2. Click "LLM Provider"
echo   3. Select "Ollama"
echo   4. Base URL: http://localhost:11434
echo   5. Model: Select your imported model (e.g., lily-uncensored)
echo   6. Click "Save Changes"
echo.
echo Close this window to shut down Ollama.
echo ================================================
echo.
echo Press any key to exit and stop Ollama...
pause >nul

:: Clean shutdown
echo.
echo Shutting down Ollama...
taskkill /f /im ollama.exe >nul 2>&1
echo Done. You can safely remove the USB drive.
timeout /t 2 /nobreak >nul
