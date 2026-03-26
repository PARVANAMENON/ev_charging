# EV Charging Slot Booking System

A minimal, functional MVP for booking EV charging slots based on SRS requirements.

## Tech Stack
- **Frontend**: React (minimal UI, black & white theme)
- **Backend**: Flask (Python)
- **Database**: MySQL (auto-schema creation)
- **Authentication**: Session-based with local database

## Quick Start

### Option 1: Full Setup (Recommended for first-time users)
```bash
# Automatically detect system and install all dependencies
./setup.sh

# Start the application
./start.sh
```

### Option 2: Manual Setup
```bash
# Install dependencies manually
pip install -r requirements.txt
npm install

# Start everything (auto-creates database schema)
./start.sh
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
│   ├── setup.sh           # Environment setup script
│   └── start.sh           # Application startup script
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

## Requirements
- Python 3.8+
- Node.js 14+
- MySQL 8.0+
- Modern web browser

## Setup Scripts

### `setup.sh` - Environment Setup
Automatically detects your system and installs all dependencies:
- Python 3.8+ with pip
- Node.js 14+ with npm  
- MySQL 8.0+
- Git
- All project dependencies

```bash
./setup.sh
```

**Supported Systems:**
- Ubuntu/Debian (apt)
- CentOS/RHEL (yum/dnf)
- Arch Linux (pacman)
- macOS (Homebrew)
- Windows (Chocolatey with Git Bash/WSL)

### `start.sh` - Application Startup
Starts both frontend and backend services:

```bash
./start.sh          # Start all services
./start.sh stop     # Stop all services
./start.sh status   # Check service status
```
