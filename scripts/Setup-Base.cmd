@echo off
:: FRC Laptop Setup - Base Configuration Launcher
:: Double-click to run the base setup (auto-elevates to admin)

:: Check if already running as admin
net session >nul 2>&1
if %errorLevel% == 0 (
    goto :run_script
)

:: Request elevation
echo Requesting Administrator privileges...
powershell -Command "Start-Process '%~f0' -Verb RunAs -ArgumentList 'elevated'"
exit /b

:run_script
:: Change to script directory
cd /d "%~dp0"

echo.
echo ===============================================
echo FRC Laptop Base Setup
echo ===============================================
echo.
echo Installing common software and configuring Firefox...
echo.
powershell -ExecutionPolicy Bypass -File "%~dp0Setup-Base.ps1"
echo.
echo ===============================================
echo Setup complete. Press any key to close...
echo ===============================================
pause >nul
