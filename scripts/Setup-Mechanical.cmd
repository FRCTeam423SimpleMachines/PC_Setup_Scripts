@echo off
:: FRC Laptop Setup - Mechanical/CAD Team Launcher
:: Double-click to run the Mechanical team setup (auto-elevates to admin)

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
echo FRC Mechanical/CAD Team Setup
echo ===============================================
echo.
echo Installing Mechanical team software and creating shortcuts...
echo.
powershell -ExecutionPolicy Bypass -File "%~dp0Setup-Mechanical.ps1"
echo.
echo ===============================================
echo Setup complete. Press any key to close...
echo ===============================================
pause >nul
