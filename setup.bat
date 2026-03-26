@echo off
REM EV Charging System - Windows Setup Script
REM This script checks the system and installs all dependencies for Windows

setlocal enabledelayedexpansion

echo =====================================
echo EV Charging System - Windows Setup
echo =====================================
echo.

REM Check if running as Administrator
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo [ERROR] This script requires Administrator privileges
    echo Please right-click the script and select "Run as administrator"
    pause
    exit /b 1
)

echo [INFO] Running with Administrator privileges
echo.

REM Check if Chocolatey is installed
where choco >nul 2>&1
if %errorLevel% neq 0 (
    echo [INFO] Installing Chocolatey package manager...
    powershell -NoProfile -ExecutionPolicy Bypass -Command "iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))"
    if %errorLevel% neq 0 (
        echo [ERROR] Failed to install Chocolatey
        pause
        exit /b 1
    )
    echo [SUCCESS] Chocolatey installed
) else (
    echo [SUCCESS] Chocolatey already installed
)

REM Refresh environment variables
call refreshenv

REM Install Python
echo [INFO] Checking Python installation...
python --version >nul 2>&1
if %errorLevel% neq 0 (
    echo [INFO] Installing Python...
    choco install python3 -y
    if %errorLevel% neq 0 (
        echo [ERROR] Failed to install Python
        pause
        exit /b 1
    )
    echo [SUCCESS] Python installed
) else (
    for /f "tokens=2" %%i in ('python --version 2^>^&1') do set PYTHON_VERSION=%%i
    echo [SUCCESS] Python found: !PYTHON_VERSION!
)

REM Install Node.js
echo [INFO] Checking Node.js installation...
node --version >nul 2>&1
if %errorLevel% neq 0 (
    echo [INFO] Installing Node.js...
    choco install nodejs -y
    if %errorLevel% neq 0 (
        echo [ERROR] Failed to install Node.js
        pause
        exit /b 1
    )
    echo [SUCCESS] Node.js installed
) else (
    for /f "tokens=*" %%i in ('node --version') do set NODE_VERSION=%%i
    echo [SUCCESS] Node.js found: !NODE_VERSION!
)

REM Install MySQL
echo [INFO] Checking MySQL installation...
mysql --version >nul 2>&1
if %errorLevel% neq 0 (
    echo [INFO] Installing MySQL...
    choco install mysql --params="'/port:3306'" -y
    if %errorLevel% neq 0 (
        echo [ERROR] Failed to install MySQL
        pause
        exit /b 1
    )
    echo [SUCCESS] MySQL installed
    
    REM Start MySQL service
    echo [INFO] Starting MySQL service...
    net start mysql
    if %errorLevel% neq 0 (
        echo [WARNING] Could not start MySQL service automatically
        echo [INFO] Please start MySQL service manually
    )
) else (
    for /f "tokens=*" %%i in ('mysql --version') do set MYSQL_VERSION=%%i
    echo [SUCCESS] MySQL found: !MYSQL_VERSION!
)

REM Install Git
echo [INFO] Checking Git installation...
git --version >nul 2>&1
if %errorLevel% neq 0 (
    echo [INFO] Installing Git...
    choco install git -y
    if %errorLevel% neq 0 (
        echo [ERROR] Failed to install Git
        pause
        exit /b 1
    )
    echo [SUCCESS] Git installed
) else (
    for /f "tokens=3" %%i in ('git --version') do set GIT_VERSION=%%i
    echo [SUCCESS] Git found: !GIT_VERSION!
)

REM Refresh PATH
call refreshenv

REM Create Python virtual environment
echo [INFO] Setting up Python environment...
if not exist "venv" (
    echo [INFO] Creating Python virtual environment...
    python -m venv venv
    if %errorLevel% neq 0 (
        echo [ERROR] Failed to create virtual environment
        pause
        exit /b 1
    )
    echo [SUCCESS] Virtual environment created
) else (
    echo [SUCCESS] Virtual environment already exists
)

REM Activate virtual environment and install dependencies
echo [INFO] Installing Python dependencies...
call venv\Scripts\activate.bat
pip install --upgrade pip
pip install -r requirements.txt
if %errorLevel% neq 0 (
    echo [ERROR] Failed to install Python dependencies
    pause
    exit /b 1
)
echo [SUCCESS] Python dependencies installed

REM Install Node.js dependencies
echo [INFO] Installing Node.js dependencies...
if exist "frontend" (
    cd frontend
    npm install
    if %errorLevel% neq 0 (
        echo [ERROR] Failed to install Node.js dependencies
        cd ..
        pause
        exit /b 1
    )
    echo [SUCCESS] Node.js dependencies installed
    cd ..
) else (
    echo [ERROR] Frontend directory not found
    pause
    exit /b 1
)

REM Create .env file
echo [INFO] Creating environment configuration...
if not exist ".env" (
    echo [INFO] Generating secure configuration...
    
    REM Generate random secret key
    for /f "tokens=*" %%i in ('python -c "import secrets; print(secrets.token_hex(32))"') do set SECRET_KEY=%%i
    
    REM Prompt for MySQL password
    set /p MYSQL_PASSWORD="Enter MySQL root password (press Enter for default): "
    
    REM Create .env file
    (
        echo # Database Configuration
        echo MYSQL_HOST=localhost
        echo MYSQL_USER=root
        echo MYSQL_PASSWORD=!MYSQL_PASSWORD!
        echo MYSQL_DATABASE=ev_charging_db
        echo.
        echo # Flask Configuration
        echo SECRET_KEY=!SECRET_KEY!
        echo DEBUG=True
        echo PORT=5000
        echo.
        echo # Frontend Configuration
        echo REACT_APP_API_URL=http://localhost:5000/api
    ) > .env
    
    echo [SUCCESS] .env file created
) else (
    echo [SUCCESS] .env file already exists
)

REM Create backend .env file
if not exist "backend\.env" (
    copy .env backend\.env >nul
    echo [SUCCESS] Backend .env file created
)

REM Test installations
echo [INFO] Testing installations...
python -c "import flask, mysql.connector, bcrypt" >nul 2>&1
if %errorLevel% neq 0 (
    echo [ERROR] Python dependencies test failed
    pause
    exit /b 1
)
echo [SUCCESS] Python dependencies test passed

cd frontend
npm list react react-dom react-router-dom >nul 2>&1
if %errorLevel% neq 0 (
    echo [ERROR] Node.js dependencies test failed
    cd ..
    pause
    exit /b 1
)
echo [SUCCESS] Node.js dependencies test passed
cd ..

REM Test MySQL connection
echo [INFO] Testing MySQL connection...
mysqladmin ping -h localhost -u root -p!MYSQL_PASSWORD! >nul 2>&1
if %errorLevel% neq 0 (
    echo [WARNING] MySQL connection test failed
    echo [INFO] Please ensure MySQL is running and password is correct
    echo [INFO] You can start MySQL service with: net start mysql
) else (
    echo [SUCCESS] MySQL connection test passed
)

echo.
echo =====================================
echo Setup Complete!
echo =====================================
echo.
echo System Information:
echo   • Python: !PYTHON_VERSION!
echo   • Node.js: !NODE_VERSION!
echo   • MySQL: !MYSQL_VERSION!
echo.
echo Next Steps:
echo   1. Review and update .env file with your MySQL credentials
echo   2. Ensure MySQL service is running: net start mysql
echo   3. Run 'start.bat' to start the application
echo   4. Open http://localhost:3000 in your browser
echo.
echo Useful Commands:
echo   • start.bat          - Start the application
echo   • start.bat stop     - Stop all services
echo   • start.bat status   - Check service status
echo   • venv\Scripts\activate.bat - Activate Python environment
echo.
echo Note: If you encounter any issues, please check:
echo   • MySQL service is running
echo   • .env file contains correct MySQL password
echo   • All dependencies installed successfully
echo.
pause
