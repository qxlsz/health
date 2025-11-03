#!/bin/bash

# Health Data Aggregator - Complete Setup Script
# This script runs install.sh and then starts the app
# 
# For just installing dependencies, use: ./scripts/install.sh
# For just running the app, use: ./scripts/run.sh

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Helper functions
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

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check prerequisites
check_prerequisites() {
    print_info "Checking prerequisites..."
    
    local missing=0
    
    if ! command_exists docker; then
        print_error "Docker is not installed. Please install Docker first."
        missing=1
    else
        print_success "Docker is installed"
    fi
    
    if ! command_exists docker-compose && ! docker compose version >/dev/null 2>&1; then
        print_error "Docker Compose is not installed."
        missing=1
    else
        print_success "Docker Compose is installed"
    fi
    
    if ! command_exists flutter; then
        print_warning "Flutter is not installed."
        echo "Install Flutter:"
        echo "  macOS: brew install flutter"
        echo "  Or visit: https://flutter.dev/docs/get-started/install"
        missing=1
    else
        print_success "Flutter is installed ($(flutter --version | head -n1 | awk '{print $2}'))"
    fi
    
    if [ $missing -eq 1 ]; then
        print_error "Some prerequisites are missing. Please install them and run this script again."
        exit 1
    fi
}

# Setup Supabase environment
setup_supabase_env() {
    print_info "Setting up Supabase environment..."
    
    cd supabase
    
    if [ ! -f .env ]; then
        print_info "Creating Supabase .env file..."
        cat > .env << 'EOF'
# Supabase Docker Environment Variables
POSTGRES_PASSWORD=your-super-secret-and-long-postgres-password
POSTGRES_DB=postgres
JWT_SECRET=your-super-secret-jwt-token-with-at-least-32-characters-long
JWT_EXP=3600

# API Configuration
API_EXTERNAL_URL=http://localhost:54321
SUPABASE_URL=http://localhost:54321
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0
SUPABASE_SERVICE_ROLE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImV4cCI6MTk4MzgxMjk5Nn0.EGIM96RAZx35lJzdJsyH-qQwv8Hdp7fsn3W0YpN81IU

# Auth Configuration
GOTRUE_SITE_URL=http://localhost:3000
GOTRUE_URI_ALLOW_LIST=
GOTRUE_DISABLE_SIGNUP=false
GOTRUE_EXTERNAL_EMAIL_ENABLED=true
GOTRUE_MAILER_AUTOCONFIRM=true

# Organization
DEFAULT_ORGANIZATION_NAME=Default Organization
DEFAULT_PROJECT_NAME=Default Project
EOF
        print_success "Created Supabase .env file"
    else
        print_info "Supabase .env file already exists"
    fi
    
    cd ..
}

# Setup Flutter app environment
setup_app_env() {
    print_info "Setting up Flutter app environment..."
    
    if [ ! -f .env ]; then
        print_info "Creating Flutter app .env file..."
        cat > .env << 'EOF'
# Supabase Configuration (Localhost for Development)
SUPABASE_URL=http://localhost:54321
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0
SUPABASE_SERVICE_ROLE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImV4cCI6MTk4MzgxMjk5Nn0.EGIM96RAZx35lJzdJsyH-qQwv8Hdp7fsn3W0YpN81IU

# Whoop OAuth (Optional - Add when implementing)
WHOOP_CLIENT_ID=your_whoop_client_id
WHOOP_CLIENT_SECRET=your_whoop_client_secret
WHOOP_REDIRECT_URI=http://localhost:8080/callback

# App Configuration
APP_ENV=development
EOF
        print_success "Created Flutter app .env file"
    else
        print_info "Flutter app .env file already exists"
    fi
}

# Start Supabase
start_supabase() {
    print_info "Starting Supabase services..."
    
    cd supabase
    
    # Check if already running
    if docker-compose ps | grep -q "Up"; then
        print_warning "Supabase services are already running"
        cd ..
        return
    fi
    
    print_info "Starting Docker containers (this may take a minute)..."
    docker-compose up -d
    
    print_info "Waiting for services to be healthy..."
    sleep 5
    
    # Wait for postgres to be ready
    local max_attempts=30
    local attempt=0
    while [ $attempt -lt $max_attempts ]; do
        if docker-compose exec -T postgres pg_isready -U postgres >/dev/null 2>&1; then
            print_success "Supabase services are ready!"
            cd ..
            return
        fi
        attempt=$((attempt + 1))
        echo -n "."
        sleep 2
    done
    
    echo ""
    print_warning "Supabase services are starting but may not be fully ready yet"
    print_info "Check status with: cd supabase && docker-compose ps"
    
    cd ..
}

# Install Flutter dependencies
install_flutter_deps() {
    print_info "Installing Flutter dependencies..."
    
    if ! command_exists flutter; then
        print_warning "Flutter not found, skipping dependency installation"
        return
    fi
    
    flutter pub get
    print_success "Flutter dependencies installed"
}

# Run code generation
run_codegen() {
    print_info "Running code generation..."
    
    if ! command_exists flutter; then
        print_warning "Flutter not found, skipping code generation"
        return
    fi
    
    flutter pub run build_runner build --delete-conflicting-outputs 2>&1 | grep -v "No matching files" || true
    print_success "Code generation complete"
}

# Print summary
print_summary() {
    echo ""
    print_success "Setup complete! 🎉"
    echo ""
    echo "Next steps:"
    echo ""
    echo "1. Start Supabase (if not running):"
    echo "   ${BLUE}cd supabase && docker-compose up -d${NC}"
    echo ""
    echo "2. Run the Flutter app:"
    echo "   ${BLUE}flutter run -d chrome${NC}    # Web"
    echo "   ${BLUE}flutter run -d ios${NC}        # iOS Simulator"
    echo "   ${BLUE}flutter run -d android${NC}    # Android Emulator"
    echo ""
    echo "3. Access services:"
    echo "   ${GREEN}Flutter App:${NC}       http://localhost:3000 (or port shown)"
    echo "   ${GREEN}Supabase Studio:${NC}   http://localhost:54323"
    echo "   ${GREEN}Supabase API:${NC}      http://localhost:54321"
    echo ""
    echo "4. Stop services:"
    echo "   ${BLUE}cd supabase && docker-compose down${NC}"
    echo ""
}

# Main execution
main() {
    echo ""
    echo "=================================="
    echo "  Health Data Aggregator Setup"
    echo "=================================="
    echo ""
    
    # Get script directory
    SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
    cd "$SCRIPT_DIR"
    
    # Run setup steps
    check_prerequisites
    echo ""
    
    setup_supabase_env
    setup_app_env
    echo ""
    
    start_supabase
    echo ""
    
    install_flutter_deps
    echo ""
    
    run_codegen
    echo ""
    
    print_summary
    
    echo ""
    print_info "Setup complete! You can now:"
    echo "  - Run: ./scripts/run.sh"
    echo "  - Or: ./scripts/run.sh chrome"
}

# Run main function
main "$@"

