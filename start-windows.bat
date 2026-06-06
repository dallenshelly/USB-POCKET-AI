@echo off
title Portable AI - USB Pocket AI
color 0A

cd /d "%~dp0"

:: Set environment variables for portable operation
set OLLAMA_MODELS=%~dp0models
set OLLAMA_HOST=127.0.0.1:11434

:: Check if Ollama is already running
tasklist /FI "IMAGENAME eq ollama.exe" 2>NUL | find /I "ollama.exe" >NUL
if %errorLevel% equ 0 (
    echo Ollama is already running.
) else (
    echo Starting Portable AI from USB...
    start /b "" "%~dp0ollama_bin\ollama.exe" serve > logs\ollama.log 2>&1
    echo Ollama server running in background.
    timeout /t 2 /nobreak >nul
)

:: Add Ollama to PATH for this session
set PATH=%~dp0ollama_bin;%PATH%

echo.
echo ================================================
echo    USB Pocket AI - Ready to Use
echo ================================================
echo.
echo Available models:
ollama list
echo.
echo Commands:
echo   ollama list              - Show installed models
echo   ollama run <model>       - Start chatting with a model
echo   ollama pull <model>      - Download a new model
echo   ollama help              - Show all commands
echo.
echo Example:
echo   ollama run lily-uncensored
echo.
echo Type 'exit' to close this window and stop Ollama.
echo ================================================
echo.

cmd /k
