#!/bin/bash

# Health Data Aggregator - Run Script
# Starts the application and all required services

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

# Get script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_DIR="$( cd "$SCRIPT_DIR/.." && pwd )"
cd "$PROJECT_DIR"

echo ""
echo "=================================="
echo "  Health Data Aggregator"
echo "=================================="
echo ""

# Check if dependencies are installed
print_info "Checking dependencies..."

if ! command -v flutter &> /dev/null; then
    print_error "Flutter is not installed. Run: ./scripts/install.sh"
    exit 1
fi

if ! command -v docker &> /dev/null; then
    print_error "Docker is not installed. Run: ./scripts/install.sh"
    exit 1
fi

# Check for .env file
if [ ! -f ".env" ]; then
    print_warning ".env file not found. Creating from template..."
    if [ -f "env.template" ]; then
        cp env.template .env
        print_success "Created .env file"
    else
        print_error "env.template not found"
        exit 1
    fi
fi

# Start Supabase services
print_info "Starting Supabase services..."
cd supabase

if [ ! -f ".env" ]; then
    print_warning "supabase/.env not found. Creating..."
    if [ -f ".env.example" ]; then
        cp .env.example .env
    else
        print_warning "Using default configuration"
    fi
fi

# Check if Supabase is already running
if docker-compose ps | grep -q "Up"; then
    print_info "Supabase services are already running"
else
    print_info "Starting Supabase (this may take a minute)..."
    docker-compose up -d
    
    print_info "Waiting for services to be ready..."
    sleep 5
    
    # Wait for postgres to be ready
    MAX_ATTEMPTS=30
    ATTEMPT=0
    while [ $ATTEMPT -lt $MAX_ATTEMPTS ]; do
        if docker-compose exec -T postgres pg_isready -U postgres >/dev/null 2>&1; then
            print_success "Supabase services are ready!"
            break
        fi
        ATTEMPT=$((ATTEMPT + 1))
        echo -n "."
        sleep 2
    done
    echo ""
    
    if [ $ATTEMPT -eq $MAX_ATTEMPTS ]; then
        print_warning "Supabase services are starting but may not be fully ready yet"
    fi
fi

cd ..

# Start Python analysis service (optional)
print_info "Starting Python analysis service..."
if [ -d "analysis" ] && [ -f "analysis/requirements.txt" ]; then
    cd analysis
    
    if [ -d "venv" ]; then
        source venv/bin/activate 2>/dev/null || . venv/bin/activate
        print_info "Python virtual environment activated"
    else
        print_warning "Python venv not found. Install dependencies first: ./scripts/install.sh"
    fi
    
    # Check if service is already running
    if lsof -Pi :8000 -sTCP:LISTEN -t >/dev/null 2>&1; then
        print_info "Python service already running on port 8000"
    else
        print_info "Starting Python analysis service on port 8000..."
        if [ -f "venv/bin/python" ] || command -v python3 &> /dev/null; then
            # Start in background
            if [ -f "venv/bin/python" ]; then
                venv/bin/python app.py > /tmp/health-python-service.log 2>&1 &
            else
                python3 app.py > /tmp/health-python-service.log 2>&1 &
            fi
            PYTHON_PID=$!
            echo $PYTHON_PID > /tmp/health-python-service.pid
            sleep 2
            print_success "Python service started (PID: $PYTHON_PID)"
        else
            print_warning "Python not available, skipping analysis service"
        fi
    fi
    
    cd ..
else
    print_warning "Analysis service not configured, skipping"
fi

# Start Flutter app
print_info "Starting Flutter app..."
cd "$PROJECT_DIR"

# Check for device/platform
DEVICE=""
if [ "$1" != "" ]; then
    DEVICE="$1"
else
    # Auto-detect available devices
    if command -v flutter &> /dev/null; then
        DEVICES=$(flutter devices --machine 2>/dev/null || echo "")
        if echo "$DEVICES" | grep -q "chrome"; then
            DEVICE="chrome"
        elif echo "$DEVICES" | grep -q "ios"; then
            DEVICE="ios"
        elif echo "$DEVICES" | grep -q "android"; then
            DEVICE="android"
        else
            DEVICE="web"
        fi
    else
        DEVICE="web"
    fi
fi

print_info "Running on: $DEVICE"

# Display service URLs
echo ""
echo "=================================="
echo "  Services Running"
echo "=================================="
echo ""
print_success "Supabase Studio:    http://localhost:54323"
print_success "Supabase API:       http://localhost:54321"
print_success "Python Analysis:    http://localhost:8000"
echo ""
print_info "Flutter app will start on the selected device..."
echo ""

# Run Flutter app
if command -v flutter &> /dev/null; then
    # Enable web if running on web
    if [ "$DEVICE" = "web" ] || [ "$DEVICE" = "chrome" ]; then
        flutter config --enable-web >/dev/null 2>&1 || true
    fi
    
    print_info "Starting Flutter app..."
    flutter run -d "$DEVICE"
else
    print_error "Flutter is not installed. Run: ./scripts/install.sh"
    exit 1
fi

# Cleanup function (runs on exit)
cleanup() {
    echo ""
    print_info "Cleaning up..."
    
    # Stop Python service if we started it
    if [ -f "/tmp/health-python-service.pid" ]; then
        PYTHON_PID=$(cat /tmp/health-python-service.pid)
        if kill -0 "$PYTHON_PID" 2>/dev/null; then
            kill "$PYTHON_PID" 2>/dev/null || true
            print_info "Stopped Python service"
        fi
        rm -f /tmp/health-python-service.pid
    fi
    
    print_info "To stop Supabase: cd supabase && docker-compose down"
}

trap cleanup EXIT INT TERM

