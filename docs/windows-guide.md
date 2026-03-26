# Windows Compatibility Guide

## Overview

This guide provides comprehensive instructions for Windows users to set up and run the EV Charging Slot Booking System. We've created multiple Windows-compatible solutions to ensure smooth operation on Windows environments.

## Windows Setup Options

### Option 1: PowerShell Scripts (Recommended)

**Files**: `setup.ps1` and `start.ps1`

**Requirements**:
- Windows 10/11
- PowerShell 5.1+ (built-in)
- Administrator privileges
- Internet connection

**Setup Process**:
```powershell
# 1. Allow script execution (one-time setup)
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# 2. Run setup script (Administrator)
.\setup.ps1

# 3. Start application
.\start.ps1
```

**Features**:
- ✅ Modern PowerShell syntax
- ✅ Colored output for better visibility
- ✅ Comprehensive error handling
- ✅ Automatic service management
- ✅ Progress indicators
- ✅ System requirements checking

### Option 2: Batch Scripts

**Files**: `setup.bat` and `start.bat`

**Requirements**:
- Windows 10/11
- Command Prompt (built-in)
- Administrator privileges
- Internet connection

**Setup Process**:
```batch
# 1. Run setup script (Administrator)
setup.bat

# 2. Start application
start.bat
```

**Features**:
- ✅ Compatible with older Windows versions
- ✅ No execution policy restrictions
- ✅ Simple and straightforward
- ✅ Works on any Windows system

### Option 3: Manual Setup

If automated scripts don't work, follow these manual steps:

#### 1. Install Chocolatey (Package Manager)
```powershell
# Run as Administrator
Set-ExecutionPolicy Bypass -Scope Process -Force
iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
```

#### 2. Install Dependencies
```cmd
# In Administrator Command Prompt
choco install python3 nodejs mysql git -y
```

#### 3. Setup Python Environment
```cmd
# Create virtual environment
python -m venv venv

# Activate environment
venv\Scripts\activate.bat

# Install Python dependencies
pip install --upgrade pip
pip install -r requirements.txt
```

#### 4. Setup Node.js Environment
```cmd
# Install frontend dependencies
cd frontend
npm install
cd ..
```

#### 5. Configure Environment
```cmd
# Create .env file
copy .env.example .env

# Edit .env with your MySQL credentials
notepad .env
```

#### 6. Start Services
```cmd
# Start MySQL service
net start mysql

# Start backend (in new terminal)
cd backend
..\venv\Scripts\activate.bat
python run.py

# Start frontend (in another new terminal)
cd frontend
npm start
```

## Windows-Specific Considerations

### PowerShell Execution Policy

Windows has security restrictions on running scripts. You may need to:

```powershell
# Check current policy
Get-ExecutionPolicy

# Allow script execution (recommended)
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# Or allow for current session only
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process
```

### Administrator Privileges

Many operations require administrator privileges:

- Installing software (Chocolatey, Python, Node.js, MySQL)
- Managing Windows services (MySQL)
- Modifying system PATH

**Always run setup scripts as Administrator**:
- Right-click PowerShell/Command Prompt
- Select "Run as administrator"
- Navigate to project directory
- Run scripts

### MySQL Service Management

Windows MySQL runs as a Windows service:

```cmd
# Check MySQL service status
sc query mysql

# Start MySQL service
net start mysql

# Stop MySQL service
net stop mysql

# Configure MySQL to start automatically
sc config mysql start=auto
```

### Path Environment

After installing software, you may need to refresh your PATH:

```cmd
# Refresh environment variables
refreshenv

# Or restart PowerShell/Command Prompt
```

### Firewall Configuration

Windows Firewall may block connections. Allow these ports:
- **Port 3000**: React development server
- **Port 5000**: Flask backend server
- **Port 3306**: MySQL database

## Troubleshooting Windows Issues

### Common Problems

#### 1. "Scripts cannot be loaded because running scripts is disabled"
**Solution**: Set PowerShell execution policy
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

#### 2. "Access denied" errors
**Solution**: Run scripts as Administrator

#### 3. "Command not found" errors
**Solution**: Refresh PATH or restart terminal
```cmd
refreshenv
```

#### 4. MySQL connection failures
**Solutions**:
- Ensure MySQL service is running: `net start mysql`
- Check .env file credentials
- Verify MySQL installation

#### 5. Port already in use
**Solutions**:
- Check what's using the port: `netstat -an | findstr ":3000"`
- Stop conflicting services
- Use different ports in configuration

#### 6. Virtual environment issues
**Solutions**:
- Delete venv folder and recreate
- Ensure Python is installed correctly
- Check antivirus software interference

### Debug Mode

Enable verbose logging for troubleshooting:

```powershell
# PowerShell debug mode
$VerbosePreference = "Continue"

# Batch script debug mode
@echo on
```

### Log Files

Check these locations for error logs:
- Backend logs: Console output from backend server
- Frontend logs: Browser developer console
- MySQL logs: MySQL error logs (usually in MySQL data directory)

## Windows Development Tools

### Recommended Tools

1. **Windows Terminal** - Modern terminal with tabs and multiple shells
2. **Visual Studio Code** - Code editor with PowerShell support
3. **PowerShell ISE** - Built-in PowerShell script editor
4. **MySQL Workbench** - MySQL database management tool

### VS Code Extensions

- PowerShell
- Python
- ES7+ React/Redux/React-Native snippets
- GitLens
- Live Server

## Performance Optimization

### Windows-Specific Optimizations

1. **Exclude from Antivirus**: Add project folder to antivirus exclusions
2. **SSD Storage**: Use SSD for better performance
3. **RAM**: Ensure at least 4GB RAM available
4. **Background Services**: Disable unnecessary background services

### Service Configuration

Configure services for automatic startup:

```cmd
# MySQL auto-start
sc config mysql start=auto

# Check startup type
sc qc mysql
```

## Security Considerations

### Windows Security

1. **User Account Control (UAC)**: May prompt for administrator privileges
2. **Windows Defender**: May flag scripts as suspicious
3. **Network Profiles**: Ensure network allows local connections

### Best Practices

1. Run scripts with minimum required privileges
2. Use Windows Defender exclusions for development
3. Keep software updated
4. Use strong MySQL passwords
5. Regular security updates

## Alternative Windows Setups

### WSL (Windows Subsystem for Linux)

For users comfortable with Linux:

```powershell
# Install WSL
wsl --install

# Use Linux setup scripts in WSL environment
```

### Docker Desktop

For containerized setup:

```powershell
# Install Docker Desktop
# Use Docker Compose setup (if available)
```

### Git Bash

Use Git Bash with Unix-like commands:

```bash
# Use original shell scripts in Git Bash
./setup.sh
./start.sh
```

## Support Resources

### Windows Documentation

- [PowerShell Documentation](https://docs.microsoft.com/en-us/powershell/)
- [Chocolatey Documentation](https://docs.chocolatey.org/)
- [Windows Service Management](https://docs.microsoft.com/en-us/windows-server/administration/windows-commands/windows-commands)

### Community Support

- Windows PowerShell forums
- Stack Overflow tags: [windows] [powershell] [batch-file]
- GitHub issues for this project

## Quick Reference

### Essential Commands

```powershell
# Execution policy
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser

# Service management
Get-Service mysql
Start-Service mysql
Stop-Service mysql

# Environment variables
refreshenv
$env:PATH

# Process management
Get-Process python
Stop-Process -Name python -Force

# Network testing
Test-NetConnection -ComputerName localhost -Port 3000
```

### File Locations

- Scripts: Project root directory
- Virtual environment: `venv\` folder
- Node modules: `frontend\node_modules\`
- Environment file: `.env`
- Logs: Console output and browser dev tools

This comprehensive Windows support ensures that your team members can successfully set up and run the EV Charging Slot Booking System regardless of their Windows environment or preferred tools.
