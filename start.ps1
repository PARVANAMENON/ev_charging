# EV Charging System - PowerShell Startup Script
# This script starts both frontend and backend services on Windows

param(
    [string]$Command = "",
    [switch]$Help
)

# Colors for output
$Colors = @{
    Red = "Red"
    Green = "Green"
    Yellow = "Yellow"
    Blue = "Blue"
    Cyan = "Cyan"
}

function Write-ColorOutput {
    param(
        [string]$Message,
        [string]$Color = "White"
    )
    Write-Host $Message -ForegroundColor $Colors[$Color]
}

function Write-Status {
    param([string]$Message)
    Write-ColorOutput "[INFO] $Message" "Blue"
}

function Write-Success {
    param([string]$Message)
    Write-ColorOutput "[SUCCESS] $Message" "Green"
}

function Write-Warning {
    param([string]$Message)
    Write-ColorOutput "[WARNING] $Message" "Yellow"
}

function Write-Error {
    param([string]$Message)
    Write-ColorOutput "[ERROR] $Message" "Red"
}

function Write-Header {
    param([string]$Title)
    Write-ColorOutput "=====================================" "Cyan"
    Write-ColorOutput $Title "Cyan"
    Write-ColorOutput "=====================================" "Cyan"
}

function Test-PortInUse {
    param([int]$Port)
    
    try {
        $connection = New-Object System.Net.Sockets.TcpClient
        $connection.Connect("localhost", $Port)
        $connection.Close()
        return $true
    }
    catch {
        return $false
    }
}

function Wait-ForService {
    param(
        [int]$Port,
        [string]$ServiceName,
        [int]$MaxAttempts = 30
    )
    
    Write-Status "Waiting for $ServiceName to be ready on port $Port..."
    
    for ($attempt = 1; $attempt -le $MaxAttempts; $attempt++) {
        try {
            $response = Invoke-WebRequest -Uri "http://localhost:$Port" -TimeoutSec 2 -ErrorAction Stop
            Write-Success "$ServiceName is ready!"
            return $true
        }
        catch {
            Write-Host "." -NoNewline
            Start-Sleep -Seconds 2
        }
    }
    
    Write-Error "$ServiceName failed to start within expected time"
    return $false
}

function Stop-Services {
    Write-Status "Shutting down services..."
    
    # Stop Python processes
    Get-Process python -ErrorAction SilentlyContinue | Stop-Process -Force
    Get-Process node -ErrorAction SilentlyContinue | Stop-Process -Force
    
    # Stop specific service windows
    Get-Process cmd -ErrorAction SilentlyContinue | Where-Object {$_.MainWindowTitle -like "*Backend*"} | Stop-Process -Force
    Get-Process cmd -ErrorAction SilentlyContinue | Where-Object {$_.MainWindowTitle -like "*Frontend*"} | Stop-Process -Force
    
    Start-Sleep -Seconds 2
    Write-Success "All services stopped"
}

function Get-ServiceStatus {
    Write-Status "Checking service status..."
    
    if (Test-PortInUse -Port 5000) {
        Write-Success "Backend is running on port 5000"
    } else {
        Write-Warning "Backend is not running"
    }
    
    if (Test-PortInUse -Port 3000) {
        Write-Success "Frontend is running on port 3000"
    } else {
        Write-Warning "Frontend is not running"
    }
    
    try {
        $mysqlService = Get-Service -Name "mysql*" -ErrorAction SilentlyContinue
        if ($mysqlService) {
            if ($mysqlService.Status -eq "Running") {
                Write-Success "MySQL service is running"
            } else {
                Write-Warning "MySQL service is not running"
            }
        } else {
            Write-Warning "MySQL service not found"
        }
    }
    catch {
        Write-Warning "Could not check MySQL service status"
    }
}

function Start-Services {
    Write-Header "EV Charging System - PowerShell Startup"
    
    # Check prerequisites
    Write-Status "Checking prerequisites..."
    
    try {
        python --version | Out-Null
        Write-Success "Python found"
    }
    catch {
        Write-Error "Python is not installed or not in PATH"
        Write-Status "Please run .\setup.ps1 first"
        Read-Host "Press Enter to exit"
        exit 1
    }
    
    try {
        node --version | Out-Null
        Write-Success "Node.js found"
    }
    catch {
        Write-Error "Node.js is not installed or not in PATH"
        Write-Status "Please run .\setup.ps1 first"
        Read-Host "Press Enter to exit"
        exit 1
    }
    
    try {
        npm --version | Out-Null
        Write-Success "npm found"
    }
    catch {
        Write-Error "npm is not installed or not in PATH"
        Write-Status "Please run .\setup.ps1 first"
        Read-Host "Press Enter to exit"
        exit 1
    }
    
    Write-Success "Prerequisites check passed"
    
    # Check if ports are available
    if (Test-PortInUse -Port 5000) {
        Write-Warning "Port 5000 is already in use. Backend may already be running."
        $continue = Read-Host "Do you want to continue? (y/N)"
        if ($continue -ne "y") {
            exit 0
        }
    }
    
    if (Test-PortInUse -Port 3000) {
        Write-Warning "Port 3000 is already in use. Frontend may already be running."
        $continue = Read-Host "Do you want to continue? (y/N)"
        if ($continue -ne "y") {
            exit 0
        }
    }
    
    # Load environment variables
    Write-Status "Loading environment variables..."
    if (Test-Path ".env") {
        Get-Content ".env" | ForEach-Object {
            if ($_ -notmatch '^#' -and $_ -match '^(.+?)=(.*)$') {
                $name = $matches[1]
                $value = $matches[2]
                Set-Item -Path "env:$name" -Value $value
            }
        }
        Write-Success "Environment variables loaded"
    } else {
        Write-Warning ".env file not found, using defaults"
    }
    
    # Check MySQL service
    Write-Status "Checking MySQL service..."
    try {
        $mysqlService = Get-Service -Name "mysql*" -ErrorAction Stop
        if ($mysqlService.Status -ne "Running") {
            Write-Warning "MySQL service is not running, attempting to start..."
            Start-Service -Name $mysqlService.Name -ErrorAction Stop
            Write-Success "MySQL service started"
        } else {
            Write-Success "MySQL service is running"
        }
    }
    catch {
        Write-Error "Failed to manage MySQL service"
        Write-Status "Please start MySQL manually: Start-Service mysql"
        Read-Host "Press Enter to exit"
        exit 1
    }
    
    # Start backend
    Write-Status "Starting backend server..."
    Set-Location backend
    
    # Activate virtual environment
    if (Test-Path "..\venv\Scripts\Activate.ps1") {
        try {
            & "..\venv\Scripts\Activate.ps1"
        }
        catch {
            Write-Warning "Could not activate virtual environment, using system Python"
        }
    }
    
    # Set environment variables for backend
    if (Test-Path "..\.env") {
        Get-Content "..\.env" | ForEach-Object {
            if ($_ -notmatch '^#' -and $_ -match '^(.+?)=(.*)$') {
                $name = $matches[1]
                $value = $matches[2]
                Set-Item -Path "env:$name" -Value $value
            }
        }
    }
    
    # Start backend in new window
    Start-Process cmd -ArgumentList "/k", "title Backend Server && python run.py" -WindowStyle Normal
    Set-Location ..
    
    # Wait for backend to be ready
    if (-not (Wait-ForService -Port 5000 -ServiceName "Backend")) {
        Write-Error "Backend failed to start"
        Stop-Services
        Read-Host "Press Enter to exit"
        exit 1
    }
    
    # Start frontend
    Write-Status "Starting frontend server..."
    Set-Location frontend
    
    # Start frontend in new window
    Start-Process cmd -ArgumentList "/k", "title Frontend Server && npm start" -WindowStyle Normal
    Set-Location ..
    
    # Wait for frontend to be ready
    if (-not (Wait-ForService -Port 3000 -ServiceName "Frontend")) {
        Write-Error "Frontend failed to start"
        Stop-Services
        Read-Host "Press Enter to exit"
        exit 1
    }
    
    # Success message
    Write-Host ""
    Write-Header "EV Charging System is now running!"
    Write-Host ""
    Write-ColorOutput "Frontend: http://localhost:3000" "Green"
    Write-ColorOutput "Backend:  http://localhost:5000" "Green"
    Write-ColorOutput "API:      http://localhost:5000/api" "Green"
    Write-Host ""
    Write-ColorOutput "Default Admin Credentials:" "Cyan"
    Write-Host "Username: admin"
    Write-Host "Password: admin123"
    Write-Host ""
    Write-ColorOutput "Press Ctrl+C in each service window to stop" "Yellow"
    Write-ColorOutput "Or run '.\start.ps1 stop' to stop all services" "Yellow"
    Write-Host ""
    Write-ColorOutput "To stop all services, close this window or run: .\start.ps1 stop" "Yellow"
    Write-ColorOutput "=====================================" "Cyan"
    
    # Keep script running
    try {
        while ($true) {
            Start-Sleep -Seconds 1
        }
    }
    catch {
        Write-Status "Shutting down..."
        Stop-Services
    }
}

# Handle command line arguments
switch ($Command.ToLower()) {
    "stop" {
        Stop-Services
        Read-Host "Press Enter to exit"
        exit 0
    }
    "status" {
        Get-ServiceStatus
        Read-Host "Press Enter to exit"
        exit 0
    }
    "help" {
        Show-Help
        exit 0
    }
    "" {
        Start-Services
    }
    default {
        Write-Error "Unknown command: $Command"
        Show-Help
        exit 1
    }
}

function Show-Help {
    Write-Host "EV Charging Slot Booking System - PowerShell Startup Script"
    Write-Host ""
    Write-Host "Usage: .\start.ps1 [command]"
    Write-Host ""
    Write-Host "Commands:"
    Write-Host "  (no args)  Start all services"
    Write-Host "  stop       Stop all services"
    Write-Host "  status     Check service status"
    Write-Host "  help       Show this help message"
    Write-Host ""
    Write-Host "Examples:"
    Write-Host "  .\start.ps1              # Start all services"
    Write-Host "  .\start.ps1 stop         # Stop all services"
    Write-Host "  .\start.ps1 status       # Check status"
    Write-Host ""
    Write-Host "Troubleshooting:"
    Write-Host "  • Run .\setup.ps1 if this is your first time"
    Write-Host "  • Ensure MySQL service is running: Start-Service mysql"
    Write-Host "  • Check .env file for correct database credentials"
    Write-Host "  • Run as Administrator if you get permission errors"
    Write-Host "  • Check PowerShell execution policy: Get-ExecutionPolicy"
    Write-Host ""
    Write-Host "PowerShell Execution Policy:"
    Write-Host "  Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser"
}
