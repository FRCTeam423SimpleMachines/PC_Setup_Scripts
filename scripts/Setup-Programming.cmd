@echo off
:: FRC Laptop Setup - Programming/Electrical Team Launcher
:: Double-click to run the Programming team setup (auto-elevates to admin)

net session >nul 2>&1
if %errorLevel% == 0 (
    goto :run_script
)

echo Requesting Administrator privileges...
powershell -Command "Start-Process cmd -Verb RunAs -ArgumentList '/c cd /d \"%~dp0\" && \"%~f0\" elevated'"
exit /b

:run_script
echo.
echo ===============================================
echo FRC Programming/Electrical Team Setup
echo ===============================================
echo.
echo Installing Git, GitHub Desktop, Python, and downloading WPILib...
echo.
powershell -ExecutionPolicy Bypass -File "%~dp0Setup-Programming.ps1"
echo.
echo ===============================================
echo Setup complete. Press any key to close...
echo ===============================================
pause >nul
