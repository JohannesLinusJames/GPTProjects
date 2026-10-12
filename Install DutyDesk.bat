@echo off
setlocal
title DutyDesk - Automatic Installation
cd /d "%~dp0"
echo.
echo Installing DutyDesk. Please keep this window open.
echo An internet connection is needed for the first installation.
echo.
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\install-windows.ps1"
if errorlevel 1 (
    echo.
    echo Installation could not finish. See the message above and install.log.
    echo Check your internet connection, then run this installer again.
    pause
    exit /b 1
)
echo.
echo Installation complete. Opening DutyDesk...
call "%~dp0Start DutyDesk.bat"
exit /b %errorlevel%
