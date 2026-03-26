@echo off
REM EV Charging System - Windows Startup Script
REM This script starts both frontend and backend services on Windows

setlocal enabledelayedexpansion

REM Colors for output (limited in batch)
set "INFO=[INFO]"
set "SUCCESS=[SUCCESS]"
set "WARNING=[WARNING]"
set "ERROR=[ERROR]"

REM Function to check if port is in use
:CheckPort
netstat -an | findstr ":%1" >nul
goto :eof

REM Function to wait for service
:WaitForService
set /a "count=0"
:WaitLoop
if %count% geq 30 (
    echo %ERROR% %2 failed to start within expected time
    exit /b 1
)

curl -s http://localhost:%1 >nul 2>&1
if %errorLevel% equ 0 (
    echo %SUCCESS% %2 is ready!
    exit /b 0
)

set /a "count+=1"
timeout /t 2 /nobreak >nul
goto WaitLoop

REM Main execution
:Main
echo =====================================
echo EV Charging System - Windows Startup
echo =====================================

REM Check prerequisites
echo %INFO% Checking prerequisites...

where python >nul 2>&1
if %errorLevel% neq 0 (
    echo %ERROR% Python is not installed or not in PATH
    echo %INFO% Please run setup.bat first
    pause
    exit /b 1
)

where node >nul 2>&1
if %errorLevel% neq 0 (
    echo %ERROR% Node.js is not installed or not in PATH
    echo %INFO% Please run setup.bat first
    pause
    exit /b 1
)

where npm >nul 2>&1
if %errorLevel% neq 0 (
    echo %ERROR% npm is not installed or not in PATH
    echo %INFO% Please run setup.bat first
    pause
    exit /b 1
)

echo %SUCCESS% Prerequisites check passed

REM Handle command line arguments
if "%1"=="stop" goto StopServices
if "%1"=="status" goto CheckStatus
if "%1"=="help" goto ShowHelp

REM Check if ports are available
call :CheckPort 5000
if %errorLevel% equ 0 (
    echo %WARNING% Port 5000 is already in use. Backend may already be running.
    set /p "continue=Do you want to continue? (y/N): "
    if /i not "!continue!"=="y" exit /b 0
)

call :CheckPort 3000
if %errorLevel% equ 0 (
    echo %WARNING% Port 3000 is already in use. Frontend may already be running.
    set /p "continue=Do you want to continue? (y/N): "
    if /i not "!continue!"=="y" exit /b 0
)

REM Load environment variables
echo %INFO% Loading environment variables...
if exist .env (
    for /f "usebackq tokens=1,2 delims==" %%a in (".env") do (
        if not "%%a"=="" if not "%%a:~0,1%"=="#" set "%%a=%%b"
    )
    echo %SUCCESS% Environment variables loaded
) else (
    echo %WARNING% .env file not found, using defaults
)

REM Check if MySQL is running
echo %INFO% Checking MySQL service...
sc query mysql >nul 2>&1
if %errorLevel% equ 0 (
    for /f "tokens=3" %%a in ('sc query mysql ^| findstr "STATE"') do set "MYSQL_STATE=%%a"
    if "!MYSQL_STATE!"=="RUNNING" (
        echo %SUCCESS% MySQL service is running
    ) else (
        echo %WARNING% MySQL service is not running, attempting to start...
        net start mysql >nul 2>&1
        if %errorLevel% equ 0 (
            echo %SUCCESS% MySQL service started
        ) else (
            echo %ERROR% Failed to start MySQL service
            echo %INFO% Please start MySQL manually: net start mysql
            pause
            exit /b 1
        )
    )
) else (
    echo %WARNING% MySQL service not found, please ensure MySQL is installed
)

REM Start backend
echo %INFO% Starting backend server...
cd backend

REM Activate virtual environment
if exist "..\venv\Scripts\activate.bat" (
    call "..\venv\Scripts\activate.bat"
) else (
    echo %WARNING% Virtual environment not found, using system Python
)

REM Set environment variables for backend
if exist "..\.env" (
    for /f "usebackq tokens=1,2 delims==" %%a in ("..\.env") do (
        if not "%%a"=="" if not "%%a:~0,1%"=="#" set "%%a=%%b"
    )
)

start "Backend Server" cmd /c "python run.py"
set "BACKEND_PID=%ERRORLEVEL%"
cd ..

REM Wait for backend to be ready
echo %INFO% Waiting for backend to be ready...
call :WaitForService 5000 "Backend"
if %errorLevel% neq 0 (
    echo %ERROR% Backend failed to start
    taskkill /f /im python.exe >nul 2>&1
    pause
    exit /b 1
)

REM Start frontend
echo %INFO% Starting frontend server...
cd frontend
start "Frontend Server" cmd /c "npm start"
set "FRONTEND_PID=%ERRORLEVEL%"
cd ..

REM Wait for frontend to be ready
echo %INFO% Waiting for frontend to be ready...
call :WaitForService 3000 "Frontend"
if %errorLevel% neq 0 (
    echo %ERROR% Frontend failed to start
    taskkill /f /im node.exe >nul 2>&1
    taskkill /f /im python.exe >nul 2>&1
    pause
    exit /b 1
)

REM Success message
echo.
echo =====================================
echo EV Charging System is now running!
echo =====================================
echo.
echo Frontend: http://localhost:3000
echo Backend:  http://localhost:5000
echo API:      http://localhost:5000/api
echo.
echo Default Admin Credentials:
echo Username: admin
echo Password: admin123
echo.
echo Press Ctrl+C in each service window to stop
echo Or run 'start.bat stop' to stop all services
echo.
echo To stop all services, close this window or run: start.bat stop
echo =====================================

REM Keep script running
pause
goto :eof

:StopServices
echo %INFO% Stopping all services...
taskkill /f /im python.exe >nul 2>&1
taskkill /f /im node.exe >nul 2>&1
taskkill /f /im cmd.exe /fi "WINDOWTITLE eq Backend Server*" >nul 2>&1
taskkill /f /im cmd.exe /fi "WINDOWTITLE eq Frontend Server*" >nul 2>&1
timeout /t 2 /nobreak >nul
echo %SUCCESS% All services stopped
pause
goto :eof

:CheckStatus
echo %INFO% Checking service status...
netstat -an | findstr ":5000" >nul
if %errorLevel% equ 0 (
    echo %SUCCESS% Backend is running on port 5000
) else (
    echo %WARNING% Backend is not running
)

netstat -an | findstr ":3000" >nul
if %errorLevel% equ 0 (
    echo %SUCCESS% Frontend is running on port 3000
) else (
    echo %WARNING% Frontend is not running
)

sc query mysql >nul 2>&1
if %errorLevel% equ 0 (
    for /f "tokens=3" %%a in ('sc query mysql ^| findstr "STATE"') do set "MYSQL_STATE=%%a"
    if "!MYSQL_STATE!"=="RUNNING" (
        echo %SUCCESS% MySQL service is running
    ) else (
        echo %WARNING% MySQL service is not running
    )
) else (
    echo %WARNING% MySQL service not found
)
pause
goto :eof

:ShowHelp
echo EV Charging Slot Booking System - Windows Startup Script
echo.
echo Usage: start.bat [command]
echo.
echo Commands:
echo   (no args)  Start all services
echo   stop       Stop all services
echo   status     Check service status
echo   help       Show this help message
echo.
echo Examples:
echo   start.bat              # Start all services
echo   start.bat stop         # Stop all services
echo   start.bat status       # Check status
echo.
echo Troubleshooting:
echo   • Run setup.bat if this is your first time
echo   • Ensure MySQL service is running: net start mysql
echo   • Check .env file for correct database credentials
echo   • Run as Administrator if you get permission errors
pause
goto :eof
