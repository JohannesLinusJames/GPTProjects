@echo off
setlocal
title DutyDesk - Keep this window open while using the app
cd /d "%~dp0"
if not exist "%~dp0.venv-windows\Scripts\python.exe" (
    echo Please run Install DutyDesk.bat first.
    pause
    exit /b 1
)
"%~dp0.venv-windows\Scripts\python.exe" "%~dp0desktop.py"
if errorlevel 1 (
    echo.
    echo DutyDesk could not start. Try running Install DutyDesk.bat again.
    pause
    exit /b 1
)
exit /b 0
