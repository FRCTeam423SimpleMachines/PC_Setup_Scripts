@echo off
:: FRC Laptop Setup - Base Configuration Launcher
:: Double-click to run the base setup (auto-elevates to admin)

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
