#!/bin/bash

# EV Charging Slot Booking System - Startup Script
# This script starts both frontend and backend services automatically

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to check if port is in use
port_in_use() {
    lsof -i :$1 >/dev/null 2>&1
}

# Function to wait for service to be ready
wait_for_service() {
    local port=$1
    local service=$2
    local max_attempts=30
    local attempt=1
    
    print_status "Waiting for $service to be ready on port $port..."
    
    while [ $attempt -le $max_attempts ]; do
        if curl -s http://localhost:$port >/dev/null 2>&1; then
            print_success "$service is ready!"
            return 0
        fi
        
        sleep 2
        attempt=$((attempt + 1))
        echo -n "."
    done
    
    print_error "$service failed to start within expected time"
    return 1
}

# Main execution
main() {
    print_status "Starting EV Charging Slot Booking System..."
    echo "=================================================="
    
    # Check prerequisites
    print_status "Checking prerequisites..."
    
    if ! command_exists python3; then
        print_error "Python 3 is required but not installed"
        exit 1
    fi
    
    if ! command_exists node; then
        print_error "Node.js is required but not installed"
        exit 1
    fi
    
    if ! command_exists npm; then
        print_error "npm is required but not installed"
        exit 1
    fi
    
    print_success "Prerequisites check passed"
    
    # Check if ports are available
    if port_in_use 5000; then
        print_warning "Port 5000 is already in use. Backend may already be running."
        read -p "Do you want to continue? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
    
    if port_in_use 3000; then
        print_warning "Port 3000 is already in use. Frontend may already be running."
        read -p "Do you want to continue? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
    
    # Install Python dependencies
    print_status "Installing Python dependencies..."
    if [ -f "requirements.txt" ]; then
        pip3 install -r requirements.txt
        print_success "Python dependencies installed"
    else
        print_error "requirements.txt not found"
        exit 1
    fi
    
    # Install Node.js dependencies
    print_status "Installing Node.js dependencies..."
    if [ -d "frontend" ] && [ -f "frontend/package.json" ]; then
        cd frontend
        npm install
        cd ..
        print_success "Node.js dependencies installed"
    else
        print_error "frontend/package.json not found"
        exit 1
    fi
    
    # Create environment file if it doesn't exist
    if [ ! -f ".env" ]; then
        print_status "Creating .env file..."
        cat > .env << EOF
# Database Configuration
MYSQL_HOST=localhost
MYSQL_USER=root
MYSQL_PASSWORD=
MYSQL_DATABASE=ev_charging_db

# Flask Configuration
SECRET_KEY=your-secret-key-change-in-production
DEBUG=True
PORT=5000

# Frontend Configuration
REACT_APP_API_URL=http://localhost:5000/api
EOF
        print_success ".env file created"
        print_warning "Please update .env file with your MySQL credentials if needed"
    fi
    
    # Start backend
    print_status "Starting backend server..."
    cd backend
    
    # Export environment variables from project root
    if [ -f "../.env" ]; then
        export $(cat ../.env | grep -v '^#' | xargs)
    fi
    
    python3 run.py &
    BACKEND_PID=$!
    cd ..
    
    # Wait for backend to be ready
    if ! wait_for_service 5000 "Backend"; then
        print_error "Backend failed to start"
        kill $BACKEND_PID 2>/dev/null
        exit 1
    fi
    
    # Start frontend
    print_status "Starting frontend server..."
    cd frontend
    npm start &
    FRONTEND_PID=$!
    cd ..
    
    # Wait for frontend to be ready
    if ! wait_for_service 3000 "Frontend"; then
        print_error "Frontend failed to start"
        kill $BACKEND_PID $FRONTEND_PID 2>/dev/null
        exit 1
    fi
    
    # Success message
    echo "=================================================="
    print_success "EV Charging Slot Booking System is now running!"
    echo ""
    echo -e "${GREEN}Frontend:${NC} http://localhost:3000"
    echo -e "${GREEN}Backend:${NC}  http://localhost:5000"
    echo -e "${GREEN}API:${NC}      http://localhost:5000/api"
    echo ""
    echo -e "${BLUE}Default Admin Credentials:${NC}"
    echo -e "Username: admin"
    echo -e "Password: admin123"
    echo ""
    echo -e "${YELLOW}Press Ctrl+C to stop all services${NC}"
    echo "=================================================="
    
    # Create cleanup function
    cleanup() {
        print_status "Shutting down services..."
        kill $BACKEND_PID 2>/dev/null || true
        kill $FRONTEND_PID 2>/dev/null || true
        
        # Wait a moment for processes to terminate
        sleep 2
        
        # Force kill if still running
        pkill -f "python3 run.py" 2>/dev/null || true
        pkill -f "npm start" 2>/dev/null || true
        pkill -f "react-scripts" 2>/dev/null || true
        
        print_success "All services stopped"
        exit 0
    }
    
    # Set up signal handlers
    trap cleanup SIGINT SIGTERM
    
    # Keep script running
    wait
}

# Handle script arguments
case "${1:-}" in
    "stop")
        print_status "Stopping all services..."
        pkill -f "python3 run.py" 2>/dev/null || true
        pkill -f "npm start" 2>/dev/null || true
        pkill -f "react-scripts" 2>/dev/null || true
        print_success "Services stopped"
        ;;
    "status")
        print_status "Checking service status..."
        if port_in_use 5000; then
            print_success "Backend is running on port 5000"
        else
            print_warning "Backend is not running"
        fi
        
        if port_in_use 3000; then
            print_success "Frontend is running on port 3000"
        else
            print_warning "Frontend is not running"
        fi
        ;;
    "help"|"-h"|"--help")
        echo "EV Charging Slot Booking System - Startup Script"
        echo ""
        echo "Usage: $0 [command]"
        echo ""
        echo "Commands:"
        echo "  (no args)  Start all services"
        echo "  stop       Stop all services"
        echo "  status     Check service status"
        echo "  help       Show this help message"
        echo ""
        echo "Examples:"
        echo "  $0              # Start all services"
        echo "  $0 stop         # Stop all services"
        echo "  $0 status       # Check status"
        ;;
    *)
        main
        ;;
esac
