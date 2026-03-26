#!/bin/bash

# EV Charging System - Environment Setup Script
# This script checks the system environment and installs all missing dependencies

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# System information
SYSTEM_INFO=""
OS_TYPE=""
PACKAGE_MANAGER=""
PYTHON_VERSION=""
NODE_VERSION=""
MYSQL_STATUS=""

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo -e "${CYAN}=====================================${NC}"
    echo -e "${CYAN}$1${NC}"
    echo -e "${CYAN}=====================================${NC}"
}

# Function to detect operating system
detect_os() {
    print_status "Detecting operating system..."
    
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        OS_TYPE="linux"
        if command -v apt-get >/dev/null 2>&1; then
            PACKAGE_MANAGER="apt"
            SYSTEM_INFO="Ubuntu/Debian-based Linux"
        elif command -v yum >/dev/null 2>&1; then
            PACKAGE_MANAGER="yum"
            SYSTEM_INFO="RedHat/CentOS-based Linux"
        elif command -v dnf >/dev/null 2>&1; then
            PACKAGE_MANAGER="dnf"
            SYSTEM_INFO="Fedora/RedHat-based Linux"
        elif command -v pacman >/dev/null 2>&1; then
            PACKAGE_MANAGER="pacman"
            SYSTEM_INFO="Arch Linux"
        else
            print_error "Unsupported Linux distribution"
            exit 1
        fi
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        OS_TYPE="macos"
        PACKAGE_MANAGER="brew"
        SYSTEM_INFO="macOS"
    elif [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]]; then
        OS_TYPE="windows"
        PACKAGE_MANAGER="choco"
        SYSTEM_INFO="Windows (with Git Bash/WSL)"
    else
        print_error "Unsupported operating system: $OSTYPE"
        exit 1
    fi
    
    print_success "Detected: $SYSTEM_INFO"
}

# Function to check system requirements
check_system_requirements() {
    print_header "System Requirements Check"
    
    # Check RAM
    if command -v free >/dev/null 2>&1; then
        RAM_MB=$(free -m | awk 'NR==2{printf "%.0f", $2}')
        if [ "$RAM_MB" -lt 2048 ]; then
            print_warning "Low RAM detected: ${RAM_MB}MB (Recommended: 4GB+)"
        else
            print_success "RAM: ${RAM_MB}MB ✓"
        fi
    fi
    
    # Check disk space
    DISK_SPACE=$(df . | tail -1 | awk '{print $4}')
    if [ "$DISK_SPACE" -lt 1048576 ]; then  # Less than 1GB
        print_warning "Low disk space: ${DISK_SPACE}KB (Recommended: 2GB+ free)"
    else
        print_success "Disk space: $((${DISK_SPACE}/1024))MB free ✓"
    fi
    
    # Check internet connection
    if ping -c 1 google.com >/dev/null 2>&1; then
        print_success "Internet connection: Available ✓"
    else
        print_error "Internet connection: Required but not available"
        exit 1
    fi
}

# Function to install package manager
install_package_manager() {
    print_status "Checking package manager..."
    
    case $PACKAGE_MANAGER in
        "apt")
            if ! command -v apt-get >/dev/null 2>&1; then
                print_error "apt-get not found. Please install manually."
                exit 1
            fi
            ;;
        "yum")
            if ! command -v yum >/dev/null 2>&1; then
                print_error "yum not found. Please install manually."
                exit 1
            fi
            ;;
        "dnf")
            if ! command -v dnf >/dev/null 2>&1; then
                print_error "dnf not found. Please install manually."
                exit 1
            fi
            ;;
        "pacman")
            if ! command -v pacman >/dev/null 2>&1; then
                print_error "pacman not found. Please install manually."
                exit 1
            fi
            ;;
        "brew")
            if ! command -v brew >/dev/null 2>&1; then
                print_status "Installing Homebrew..."
                /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
            fi
            ;;
        "choco")
            if ! command -v choco >/dev/null 2>&1; then
                print_status "Installing Chocolatey..."
                powershell -Command "Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))"
            fi
            ;;
    esac
    
    print_success "Package manager ready ✓"
}

# Function to install Python
install_python() {
    print_header "Python Installation"
    
    if command -v python3 >/dev/null 2>&1; then
        PYTHON_VERSION=$(python3 --version | cut -d' ' -f2)
        print_success "Python found: $PYTHON_VERSION ✓"
        
        # Check if version is 3.8+
        PYTHON_MAJOR=$(echo $PYTHON_VERSION | cut -d'.' -f1)
        PYTHON_MINOR=$(echo $PYTHON_VERSION | cut -d'.' -f2)
        
        if [ "$PYTHON_MAJOR" -eq 3 ] && [ "$PYTHON_MINOR" -ge 8 ]; then
            print_success "Python version meets requirements (3.8+) ✓"
        else
            print_warning "Python version $PYTHON_VERSION is below recommended (3.8+)"
        fi
    else
        print_status "Installing Python 3..."
        
        case $PACKAGE_MANAGER in
            "apt")
                sudo apt-get update
                sudo apt-get install -y python3 python3-pip python3-venv
                ;;
            "yum")
                sudo yum install -y python3 python3-pip
                ;;
            "dnf")
                sudo dnf install -y python3 python3-pip
                ;;
            "pacman")
                sudo pacman -S --noconfirm python python-pip
                ;;
            "brew")
                brew install python3
                ;;
            "choco")
                choco install python3 -y
                ;;
        esac
        
        print_success "Python 3 installed ✓"
    fi
    
    # Install pip if not present
    if ! command -v pip3 >/dev/null 2>&1; then
        print_status "Installing pip..."
        python3 -m ensurepip --upgrade
        print_success "pip installed ✓"
    fi
}

# Function to install Node.js
install_nodejs() {
    print_header "Node.js Installation"
    
    if command -v node >/dev/null 2>&1; then
        NODE_VERSION=$(node --version)
        print_success "Node.js found: $NODE_VERSION ✓"
        
        # Check if version is 14+
        NODE_MAJOR=$(echo $NODE_VERSION | sed 's/v//' | cut -d'.' -f1)
        if [ "$NODE_MAJOR" -ge 14 ]; then
            print_success "Node.js version meets requirements (14+) ✓"
        else
            print_warning "Node.js version $NODE_VERSION is below recommended (14+)"
        fi
    else
        print_status "Installing Node.js..."
        
        case $PACKAGE_MANAGER in
            "apt")
                # Install Node.js 18.x
                curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
                sudo apt-get install -y nodejs
                ;;
            "yum")
                curl -fsSL https://rpm.nodesource.com/setup_18.x | sudo bash -
                sudo yum install -y nodejs npm
                ;;
            "dnf")
                curl -fsSL https://rpm.nodesource.com/setup_18.x | sudo bash -
                sudo dnf install -y nodejs npm
                ;;
            "pacman")
                sudo pacman -S --noconfirm nodejs npm
                ;;
            "brew")
                brew install node
                ;;
            "choco")
                choco install nodejs -y
                ;;
        esac
        
        print_success "Node.js installed ✓"
    fi
    
    # Verify npm
    if command -v npm >/dev/null 2>&1; then
        NPM_VERSION=$(npm --version)
        print_success "npm found: $NPM_VERSION ✓"
    else
        print_error "npm not found. Installing..."
        case $PACKAGE_MANAGER in
            "apt")
                sudo apt-get install -y npm
                ;;
            "yum")
                sudo yum install -y npm
                ;;
            "dnf")
                sudo dnf install -y npm
                ;;
            "pacman")
                sudo pacman -S --noconfirm npm
                ;;
        esac
    fi
}

# Function to install MySQL
install_mysql() {
    print_header "MySQL Installation"
    
    # Check if MySQL is running
    if command -v mysql >/dev/null 2>&1; then
        if mysqladmin ping >/dev/null 2>&1; then
            MYSQL_VERSION=$(mysql --version)
            print_success "MySQL found and running: $MYSQL_VERSION ✓"
            MYSQL_STATUS="running"
        else
            print_warning "MySQL installed but not running"
            MYSQL_STATUS="installed"
        fi
    else
        print_status "Installing MySQL..."
        
        case $PACKAGE_MANAGER in
            "apt")
                sudo apt-get update
                sudo DEBIAN_FRONTEND=noninteractive apt-get install -y mysql-server
                sudo systemctl start mysql
                sudo systemctl enable mysql
                ;;
            "yum")
                sudo yum install -y mysql-server
                sudo systemctl start mysqld
                sudo systemctl enable mysqld
                ;;
            "dnf")
                sudo dnf install -y mysql-server
                sudo systemctl start mysqld
                sudo systemctl enable mysqld
                ;;
            "pacman")
                sudo pacman -S --noconfirm mysql
                sudo systemctl start mysqld
                sudo systemctl enable mysqld
                ;;
            "brew")
                brew install mysql
                brew services start mysql
                ;;
            "choco")
                choco install mysql -y
                ;;
        esac
        
        print_success "MySQL installed ✓"
        MYSQL_STATUS="installed"
    fi
    
    # Setup MySQL for first time
    if [ "$MYSQL_STATUS" = "installed" ]; then
        print_status "Configuring MySQL..."
        
        # Generate temporary root password
        TEMP_PASSWORD=$(openssl rand -base64 12)
        
        case $PACKAGE_MANAGER in
            "apt"|"yum"|"dnf"|"pacman")
                sudo mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '$TEMP_PASSWORD';"
                sudo mysql -e "FLUSH PRIVILEGES;"
                ;;
        esac
        
        print_warning "MySQL root password set to: $TEMP_PASSWORD"
        print_warning "Please save this password and update .env file"
    fi
}

# Function to install Git
install_git() {
    print_header "Git Installation"
    
    if command -v git >/dev/null 2>&1; then
        GIT_VERSION=$(git --version)
        print_success "Git found: $GIT_VERSION ✓"
    else
        print_status "Installing Git..."
        
        case $PACKAGE_MANAGER in
            "apt")
                sudo apt-get install -y git
                ;;
            "yum")
                sudo yum install -y git
                ;;
            "dnf")
                sudo dnf install -y git
                ;;
            "pacman")
                sudo pacman -S --noconfirm git
                ;;
            "brew")
                brew install git
                ;;
            "choco")
                choco install git -y
                ;;
        esac
        
        print_success "Git installed ✓"
    fi
}

# Function to setup Python virtual environment
setup_python_env() {
    print_header "Python Environment Setup"
    
    if [ ! -d "venv" ]; then
        print_status "Creating Python virtual environment..."
        python3 -m venv venv
        print_success "Virtual environment created ✓"
    else
        print_success "Virtual environment already exists ✓"
    fi
    
    # Activate virtual environment and install requirements
    print_status "Installing Python dependencies..."
    source venv/bin/activate
    pip install --upgrade pip
    pip install -r requirements.txt
    print_success "Python dependencies installed ✓"
}

# Function to setup Node.js environment
setup_node_env() {
    print_header "Node.js Environment Setup"
    
    if [ -d "frontend" ]; then
        print_status "Installing Node.js dependencies..."
        cd frontend
        npm install
        cd ..
        print_success "Node.js dependencies installed ✓"
    else
        print_error "Frontend directory not found"
    fi
}

# Function to create environment file
create_env_file() {
    print_header "Environment Configuration"
    
    if [ ! -f ".env" ]; then
        print_status "Creating .env file..."
        
        # Get MySQL password if not set
        MYSQL_PASSWORD=""
        if [ "$MYSQL_STATUS" = "installed" ]; then
            echo -n "Enter MySQL root password (leave empty for default): "
            read -s MYSQL_PASSWORD
            echo
        fi
        
        cat > .env << EOF
# Database Configuration
MYSQL_HOST=localhost
MYSQL_USER=root
MYSQL_PASSWORD=$MYSQL_PASSWORD
MYSQL_DATABASE=ev_charging_db

# Flask Configuration
SECRET_KEY=$(openssl rand -hex 32)
DEBUG=True
PORT=5000

# Frontend Configuration
REACT_APP_API_URL=http://localhost:5000/api
EOF
        
        print_success ".env file created ✓"
        print_warning "Please review and update .env file with your MySQL credentials"
    else
        print_success ".env file already exists ✓"
    fi
}

# Function to run system tests
run_system_tests() {
    print_header "System Tests"
    
    # Test Python
    if python3 -c "import flask, mysql.connector, bcrypt" 2>/dev/null; then
        print_success "Python dependencies test passed ✓"
    else
        print_error "Python dependencies test failed"
        return 1
    fi
    
    # Test Node.js
    if [ -f "frontend/package.json" ]; then
        cd frontend
        if npm list react react-dom react-router-dom >/dev/null 2>&1; then
            print_success "Node.js dependencies test passed ✓"
        else
            print_error "Node.js dependencies test failed"
            cd ..
            return 1
        fi
        cd ..
    fi
    
    # Test MySQL connection
    if mysqladmin ping >/dev/null 2>&1; then
        print_success "MySQL connection test passed ✓"
    else
        print_warning "MySQL connection test failed - MySQL may need to be started"
    fi
    
    return 0
}

# Function to display final summary
display_summary() {
    print_header "Setup Complete"
    
    echo -e "${GREEN}Environment setup completed successfully!${NC}"
    echo ""
    echo -e "${CYAN}System Information:${NC}"
    echo "  • OS: $SYSTEM_INFO"
    echo "  • Python: $PYTHON_VERSION"
    echo "  • Node.js: $NODE_VERSION"
    echo "  • MySQL: $MYSQL_STATUS"
    echo ""
    echo -e "${CYAN}Next Steps:${NC}"
    echo "  1. Review and update .env file with your MySQL credentials"
    echo "  2. Run './start.sh' to start the application"
    echo "  3. Open http://localhost:3000 in your browser"
    echo ""
    echo -e "${CYAN}Useful Commands:${NC}"
    echo "  • ./start.sh          - Start the application"
    echo "  • ./start.sh stop      - Stop all services"
    echo "  • ./start.sh status    - Check service status"
    echo "  • source venv/bin/activate - Activate Python environment"
    echo ""
    echo -e "${YELLOW}Note: If you encounter any issues, please check the .env file${NC}"
    echo -e "${YELLOW}and ensure MySQL is running with the correct credentials.${NC}"
}

# Main execution
main() {
    print_header "EV Charging System - Environment Setup"
    
    # Check if running as root (for package installations)
    if [[ $EUID -ne 0 ]]; then
        print_warning "This script requires sudo privileges for package installation"
        print_warning "You may be prompted for your password"
    fi
    
    detect_os
    check_system_requirements
    install_package_manager
    install_python
    install_nodejs
    install_mysql
    install_git
    setup_python_env
    setup_node_env
    create_env_file
    
    if run_system_tests; then
        display_summary
    else
        print_error "System tests failed. Please check the error messages above."
        exit 1
    fi
}

# Handle script arguments
case "${1:-}" in
    "help"|"-h"|"--help")
        echo "EV Charging System - Environment Setup Script"
        echo ""
        echo "This script automatically detects your system and installs all required dependencies."
        echo ""
        echo "Usage: $0 [command]"
        echo ""
        echo "Commands:"
        echo "  (no args)  Run full setup"
        echo "  help       Show this help message"
        echo ""
        echo "What it installs:"
        echo "  • Python 3.8+ with pip"
        echo "  • Node.js 14+ with npm"
        echo "  • MySQL 8.0+"
        echo "  • Git"
        echo "  • Python virtual environment"
        echo "  • All project dependencies"
        echo ""
        echo "Supported Systems:"
        echo "  • Ubuntu/Debian (apt)"
        echo "  • CentOS/RHEL (yum/dnf)"
        echo "  • Arch Linux (pacman)"
        echo "  • macOS (Homebrew)"
        echo "  • Windows (Chocolatey with Git Bash/WSL)"
        ;;
    *)
        main
        ;;
esac
