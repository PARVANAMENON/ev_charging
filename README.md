# EV Charging Slot Booking System

A minimal, functional MVP for booking EV charging slots based on SRS requirements.

## Tech Stack
- **Frontend**: React (minimal UI, black & white theme)
- **Backend**: Flask (Python)
- **Database**: MySQL (auto-schema creation)
- **Authentication**: Session-based with local database

## Quick Start

### For Linux/macOS Users
```bash
# Automatically detect system and install all dependencies
./setup.sh

# Start the application
./start.sh
```

### For Windows Users

#### Option 1: PowerShell (Recommended)
```powershell
# Allow script execution (one-time)
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# Install dependencies (run as Administrator)
.\setup.ps1

# Start application
.\start.ps1
```

#### Option 2: Batch Scripts
```batch
# Install dependencies (run as Administrator)
setup.bat

# Start application
start.bat
```

#### Option 3: Manual Setup
See [Windows Guide](docs/windows-guide.md) for detailed manual instructions.

### Option 4: Manual Setup (All Platforms)
```bash
# Install dependencies manually
pip install -r requirements.txt
npm install

# Start everything (auto-creates database schema)
./start.sh  # or start.bat on Windows
```

## Project Structure
```
├── backend/                 # Flask API server
│   ├── app/
│   │   ├── models/         # Database models
│   │   ├── routes/         # API endpoints
│   │   ├── utils/          # Helper functions
│   │   └── config.py       # Configuration
│   ├── tests/              # Backend tests
│   └── run.py              # Flask entry point
├── frontend/               # React application
│   ├── src/
│   │   ├── components/     # React components
│   │   ├── pages/          # Page components
│   │   ├── services/       # API calls
│   │   └── utils/          # Helper functions
│   └── public/
├── docs/                   # Documentation
│   ├── user-guide.md       # Non-technical user guide
│   ├── api-docs.md         # API documentation
│   └── testing.md          # Testing procedures
├── scripts/                # Utility scripts
│   ├── setup.sh           # Unix environment setup
│   ├── setup.ps1          # PowerShell environment setup
│   ├── setup.bat          # Batch environment setup
│   ├── start.sh           # Unix application startup
│   ├── start.ps1          # PowerShell application startup
│   └── start.bat          # Batch application startup
├── tests/                  # Integration tests
├── .env.example           # Environment template
├── .gitignore            # Git ignore file
└── README.md              # This file
```

## Features Implemented
- ✅ User registration & login
- ✅ Vehicle type selection
- ✅ Location-based station search
- ✅ Slot availability checking
- ✅ Exclusive slot booking
- ✅ Booking cancellation
- ✅ Admin station management
- ✅ Session-based authentication

## Documentation
- [User Guide](docs/user-guide.md) - For non-technical users
- [API Documentation](docs/api-docs.md) - API reference
- [Testing Guide](docs/testing.md) - Test procedures
- [Windows Guide](docs/windows-guide.md) - Windows-specific setup and troubleshooting

## Requirements
- Python 3.8+
- Node.js 14+
- MySQL 8.0+
- Modern web browser

## Setup Scripts

### Linux/macOS Scripts
- **`setup.sh`** - Environment setup for Unix systems
- **`start.sh`** - Application startup for Unix systems

### Windows Scripts
- **`setup.ps1`** - PowerShell environment setup (recommended)
- **`start.ps1`** - PowerShell application startup
- **`setup.bat`** - Batch environment setup (alternative)
- **`start.bat`** - Batch application startup (alternative)

### Cross-Platform Features
All setup scripts automatically:
- Detect operating system and package manager
- Install Python 3.8+, Node.js 14+, MySQL 8.0+
- Set up virtual environments
- Install all project dependencies
- Create secure configuration files
- Run system tests

### Windows-Specific Support
- **PowerShell Scripts**: Modern, colored output, comprehensive error handling
- **Batch Scripts**: Compatible with older Windows versions
- **Manual Setup Guide**: Step-by-step instructions for manual installation
- **Troubleshooting Guide**: Common Windows issues and solutions

See [Windows Guide](docs/windows-guide.md) for detailed Windows instructions.
