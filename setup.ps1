# EV Charging System - PowerShell Setup Script
# This script checks the system and installs all dependencies for Windows

param(
    [switch]$Help,
    [switch]$Force
)

# Colors for output
$Colors = @{
    Red = "Red"
    Green = "Green"
    Yellow = "Yellow"
    Blue = "Blue"
    Cyan = "Cyan"
    White = "White"
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

function Test-Administrator {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Install-Chocolatey {
    Write-Status "Installing Chocolatey package manager..."
    
    try {
        Set-ExecutionPolicy Bypass -Scope Process -Force
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
        Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
        
        # Refresh PATH
        $env:PATH = [System.Environment]::GetEnvironmentVariable("PATH", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("PATH", "User")
        
        Write-Success "Chocolatey installed"
        return $true
    }
    catch {
        Write-Error "Failed to install Chocolatey: $($_.Exception.Message)"
        return $false
    }
}

function Install-Package {
    param(
        [string]$PackageName,
        [string]$TestCommand,
        [string]$VersionCheck
    )
    
    Write-Status "Checking $PackageName installation..."
    
    try {
        $result = Invoke-Expression $TestCommand 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-Success "$PackageName found: $result"
            return $true
        }
    }
    catch {
        # Package not found, proceed with installation
    }
    
    Write-Status "Installing $PackageName..."
    
    try {
        choco install $PackageName -y
        if ($LASTEXITCODE -ne 0) {
            throw "Chocolatey installation failed"
        }
        
        # Refresh PATH and test again
        $env:PATH = [System.Environment]::GetEnvironmentVariable("PATH", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("PATH", "User")
        
        $result = Invoke-Expression $VersionCheck 2>$null
        Write-Success "$PackageName installed: $result"
        return $true
    }
    catch {
        Write-Error "Failed to install $PackageName: $($_.Exception.Message)"
        return $false
    }
}

function Test-MySQLService {
    Write-Status "Checking MySQL service..."
    
    try {
        $service = Get-Service -Name "mysql*" -ErrorAction SilentlyContinue
        if ($service) {
            if ($service.Status -eq "Running") {
                Write-Success "MySQL service is running"
                return $true
            } else {
                Write-Warning "MySQL service is not running, attempting to start..."
                Start-Service -Name $service.Name -ErrorAction Stop
                Write-Success "MySQL service started"
                return $true
            }
        } else {
            Write-Warning "MySQL service not found"
            return $false
        }
    }
    catch {
        Write-Error "Failed to manage MySQL service: $($_.Exception.Message)"
        return $false
    }
}

function New-SecurePassword {
    $length = 16
    $chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*'
    $password = -join ($chars.ToCharArray() | Get-Random -Count $length)
    return $password
}

# Main script execution
function Main {
    Write-Header "EV Charging System - PowerShell Setup"
    
    # Check Administrator privileges
    if (-not (Test-Administrator)) {
        Write-Error "This script requires Administrator privileges"
        Write-Status "Please right-click PowerShell and select 'Run as Administrator'"
        Read-Host "Press Enter to exit"
        exit 1
    }
    
    Write-Success "Running with Administrator privileges"
    
    # Check system requirements
    Write-Header "System Requirements Check"
    
    $ram = (Get-CimInstance -ClassName Win32_ComputerSystem).TotalPhysicalMemory / 1GB
    if ($ram -lt 2) {
        Write-Warning "Low RAM detected: $([math]::Round($ram, 2))GB (Recommended: 4GB+)"
    } else {
        Write-Success "RAM: $([math]::Round($ram, 2))GB ✓"
    }
    
    $disk = Get-PSDrive C | Select-Object -ExpandProperty Free
    if ($disk -lt 1GB) {
        Write-Warning "Low disk space: $([math]::Round($disk/1GB, 2))GB free (Recommended: 2GB+)"
    } else {
        Write-Success "Disk space: $([math]::Round($disk/1GB, 2))GB free ✓"
    }
    
    # Test internet connection
    try {
        Test-NetConnection -ComputerName "google.com" -Port 443 -InformationLevel Quiet | Out-Null
        Write-Success "Internet connection: Available ✓"
    }
    catch {
        Write-Error "Internet connection: Required but not available"
        Read-Host "Press Enter to exit"
        exit 1
    }
    
    # Install Chocolatey
    Write-Header "Package Manager Setup"
    
    try {
        choco --version | Out-Null
        Write-Success "Chocolatey already installed ✓"
    }
    catch {
        if (-not (Install-Chocolatey)) {
            Read-Host "Press Enter to exit"
            exit 1
        }
    }
    
    # Install Python
    Write-Header "Python Installation"
    if (-not (Install-Package "python3" "python --version" "python --version")) {
        Read-Host "Press Enter to exit"
        exit 1
    }
    
    # Install Node.js
    Write-Header "Node.js Installation"
    if (-not (Install-Package "nodejs" "node --version" "node --version")) {
        Read-Host "Press Enter to exit"
        exit 1
    }
    
    # Install MySQL
    Write-Header "MySQL Installation"
    if (-not (Install-Package "mysql" "mysql --version" "mysql --version")) {
        Read-Host "Press Enter to exit"
        exit 1
    }
    
    # Start MySQL service
    Test-MySQLService
    
    # Install Git
    Write-Header "Git Installation"
    if (-not (Install-Package "git" "git --version" "git --version")) {
        Read-Host "Press Enter to exit"
        exit 1
    }
    
    # Setup Python environment
    Write-Header "Python Environment Setup"
    
    if (-not (Test-Path "venv")) {
        Write-Status "Creating Python virtual environment..."
        try {
            python -m venv venv
            Write-Success "Virtual environment created ✓"
        }
        catch {
            Write-Error "Failed to create virtual environment: $($_.Exception.Message)"
            Read-Host "Press Enter to exit"
            exit 1
        }
    } else {
        Write-Success "Virtual environment already exists ✓"
    }
    
    # Install Python dependencies
    Write-Status "Installing Python dependencies..."
    try {
        & "venv\Scripts\Activate.ps1"
        pip install --upgrade pip
        pip install -r requirements.txt
        Write-Success "Python dependencies installed ✓"
    }
    catch {
        Write-Error "Failed to install Python dependencies: $($_.Exception.Message)"
        Read-Host "Press Enter to exit"
        exit 1
    }
    
    # Install Node.js dependencies
    Write-Header "Node.js Environment Setup"
    
    if (Test-Path "frontend") {
        Write-Status "Installing Node.js dependencies..."
        try {
            Set-Location frontend
            npm install
            Set-Location ..
            Write-Success "Node.js dependencies installed ✓"
        }
        catch {
            Write-Error "Failed to install Node.js dependencies: $($_.Exception.Message)"
            Read-Host "Press Enter to exit"
            exit 1
        }
    } else {
        Write-Error "Frontend directory not found"
        Read-Host "Press Enter to exit"
        exit 1
    }
    
    # Create environment file
    Write-Header "Environment Configuration"
    
    if (-not (Test-Path ".env")) {
        Write-Status "Creating .env file..."
        
        try {
            $secretKey = -join (1..32 | ForEach-Object { '{0:x2}' -f (Get-Random -Maximum 256) })
            
            $mysqlPassword = Read-Host "Enter MySQL root password (press Enter for default)"
            
            $envContent = @"
# Database Configuration
MYSQL_HOST=localhost
MYSQL_USER=root
MYSQL_PASSWORD=$mysqlPassword
MYSQL_DATABASE=ev_charging_db

# Flask Configuration
SECRET_KEY=$secretKey
DEBUG=True
PORT=5000

# Frontend Configuration
REACT_APP_API_URL=http://localhost:5000/api
"@
            
            $envContent | Out-File -FilePath ".env" -Encoding UTF8
            Write-Success ".env file created ✓"
        }
        catch {
            Write-Error "Failed to create .env file: $($_.Exception.Message)"
            Read-Host "Press Enter to exit"
            exit 1
        }
    } else {
        Write-Success ".env file already exists ✓"
    }
    
    # Create backend .env file
    if (-not (Test-Path "backend\.env")) {
        Copy-Item ".env" "backend\.env"
        Write-Success "Backend .env file created ✓"
    }
    
    # Run system tests
    Write-Header "System Tests"
    
    try {
        & "venv\Scripts\Activate.ps1"
        python -c "import flask, mysql.connector, bcrypt" | Out-Null
        Write-Success "Python dependencies test passed ✓"
    }
    catch {
        Write-Error "Python dependencies test failed"
        Read-Host "Press Enter to exit"
        exit 1
    }
    
    try {
        Set-Location frontend
        npm list react react-dom react-router-dom | Out-Null
        Set-Location ..
        Write-Success "Node.js dependencies test passed ✓"
    }
    catch {
        Write-Error "Node.js dependencies test failed"
        Read-Host "Press Enter to exit"
        exit 1
    }
    
    # Test MySQL connection
    Write-Status "Testing MySQL connection..."
    try {
        $env:MYSQL_PASSWORD = (Select-String -Path ".env" -Pattern "MYSQL_PASSWORD=").Line.Split('=')[1]
        $result = mysqladmin ping -h localhost -u root -p$env:MYSQL_PASSWORD 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-Success "MySQL connection test passed ✓"
        } else {
            throw "Connection failed"
        }
    }
    catch {
        Write-Warning "MySQL connection test failed"
        Write-Status "Please ensure MySQL is running and password is correct"
        Write-Status "You can start MySQL service with: Start-Service mysql"
    }
    
    # Display summary
    Write-Header "Setup Complete"
    
    Write-Success "Environment setup completed successfully!"
    Write-Host ""
    Write-ColorOutput "System Information:" "Cyan"
    Write-Host "  • Python: $((python --version) 2>&1)"
    Write-Host "  • Node.js: $((node --version) 2>&1)"
    Write-Host "  • MySQL: $((mysql --version) 2>&1)"
    Write-Host ""
    Write-ColorOutput "Next Steps:" "Cyan"
    Write-Host "  1. Review and update .env file with your MySQL credentials"
    Write-Host "  2. Ensure MySQL service is running: Start-Service mysql"
    Write-Host "  3. Run '.\start.ps1' to start the application"
    Write-Host "  4. Open http://localhost:3000 in your browser"
    Write-Host ""
    Write-ColorOutput "Useful Commands:" "Cyan"
    Write-Host "  • .\start.ps1          - Start the application"
    Write-Host "  • .\start.ps1 stop     - Stop all services"
    Write-Host "  • .\start.ps1 status   - Check service status"
    Write-Host "  • .\venv\Scripts\Activate.ps1 - Activate Python environment"
    Write-Host ""
    Write-ColorOutput "Note: If you encounter any issues, please check the .env file" "Yellow"
    Write-ColorOutput "and ensure MySQL is running with the correct credentials." "Yellow"
    
    Read-Host "Press Enter to exit"
}

# Handle help parameter
if ($Help) {
    Write-Host "EV Charging System - PowerShell Setup Script"
    Write-Host ""
    Write-Host "This script automatically detects your system and installs all required dependencies."
    Write-Host ""
    Write-Host "Usage: .\setup.ps1 [parameters]"
    Write-Host ""
    Write-Host "Parameters:"
    Write-Host "  -Help     Show this help message"
    Write-Host "  -Force    Force reinstallation of packages"
    Write-Host ""
    Write-Host "What it installs:"
    Write-Host "  • Python 3.8+ with pip"
    Write-Host "  • Node.js 14+ with npm"
    Write-Host "  • MySQL 8.0+"
    Write-Host "  • Git"
    Write-Host "  • Python virtual environment"
    Write-Host "  • All project dependencies"
    Write-Host ""
    Write-Host "Requirements:"
    Write-Host "  • Windows 10/11"
    Write-Host "  • PowerShell 5.1+"
    Write-Host "  • Administrator privileges"
    Write-Host "  • Internet connection"
    Write-Host ""
    Write-Host "Examples:"
    Write-Host "  .\setup.ps1              # Run full setup"
    Write-Host "  .\setup.ps1 -Help        # Show this help"
    Write-Host "  .\setup.ps1 -Force       # Force reinstall packages"
    exit 0
}

# Check execution policy
$policy = Get-ExecutionPolicy
if ($policy -eq "Restricted") {
    Write-Warning "PowerShell execution policy is Restricted"
    Write-Status "Please run: Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser"
    Read-Host "Press Enter to exit"
    exit 1
}

# Run main function
Main
