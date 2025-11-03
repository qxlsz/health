#!/bin/bash

# Health Data Aggregator - Dependency Installation Script
# Installs all required dependencies for the project

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

echo ""
echo "=================================="
echo "  Installing Dependencies"
echo "=================================="
echo ""

# Get script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_DIR="$( cd "$SCRIPT_DIR/.." && pwd )"
cd "$PROJECT_DIR"

# Check prerequisites
print_info "Checking prerequisites..."

MISSING_DEPS=0

if ! command -v flutter &> /dev/null; then
    print_error "Flutter is not installed"
    echo "  Install: https://flutter.dev/docs/get-started/install"
    echo "  Or: brew install flutter"
    MISSING_DEPS=$((MISSING_DEPS + 1))
else
    FLUTTER_VERSION=$(flutter --version | head -n1 | awk '{print $2}')
    print_success "Flutter is installed ($FLUTTER_VERSION)"
fi

if ! command -v docker &> /dev/null; then
    print_error "Docker is not installed"
    echo "  Install: https://docs.docker.com/get-docker/"
    MISSING_DEPS=$((MISSING_DEPS + 1))
else
    print_success "Docker is installed"
fi

if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
    print_error "Docker Compose is not installed"
    MISSING_DEPS=$((MISSING_DEPS + 1))
else
    print_success "Docker Compose is installed"
fi

if [ $MISSING_DEPS -gt 0 ]; then
    print_error "Missing prerequisites. Please install them first."
    exit 1
fi

# Install Flutter dependencies
print_info "Installing Flutter dependencies..."
if command -v flutter &> /dev/null; then
    cd "$PROJECT_DIR"
    flutter pub get
    print_success "Flutter dependencies installed"
else
    print_warning "Flutter not found, skipping Flutter dependencies"
fi

# Run code generation
print_info "Running code generation..."
if command -v flutter &> /dev/null; then
    cd "$PROJECT_DIR"
    flutter pub run build_runner build --delete-conflicting-outputs || {
        print_warning "Code generation completed with warnings"
    }
    print_success "Code generation completed"
else
    print_warning "Flutter not found, skipping code generation"
fi

# Install Python dependencies (optional)
print_info "Installing Python dependencies..."
if command -v python3 &> /dev/null; then
    cd "$PROJECT_DIR/analysis"
    if [ -f "requirements.txt" ]; then
        # Check if virtual environment exists
        if [ ! -d "venv" ]; then
            print_info "Creating Python virtual environment..."
            python3 -m venv venv
        fi
        
        print_info "Activating virtual environment and installing packages..."
        source venv/bin/activate 2>/dev/null || . venv/bin/activate
        pip install --upgrade pip --quiet
        pip install -r requirements.txt --quiet
        print_success "Python dependencies installed"
    else
        print_warning "requirements.txt not found"
    fi
else
    print_warning "Python 3 not found, skipping Python dependencies"
fi

# Setup environment files
print_info "Setting up environment files..."

# Flutter app .env
if [ ! -f "$PROJECT_DIR/.env" ]; then
    if [ -f "$PROJECT_DIR/env.template" ]; then
        cp "$PROJECT_DIR/env.template" "$PROJECT_DIR/.env"
        print_success "Created .env file from template"
        print_warning "Please edit .env file with your configuration"
    else
        print_warning "env.template not found"
    fi
else
    print_info ".env file already exists"
fi

# Supabase .env
if [ ! -f "$PROJECT_DIR/supabase/.env" ]; then
    if [ -f "$PROJECT_DIR/supabase/.env.example" ]; then
        cp "$PROJECT_DIR/supabase/.env.example" "$PROJECT_DIR/supabase/.env"
        print_success "Created supabase/.env file from template"
        print_warning "Please edit supabase/.env file with your configuration"
    else
        print_info "Creating default supabase/.env..."
        cat > "$PROJECT_DIR/supabase/.env" << 'EOF'
POSTGRES_PASSWORD=your-super-secret-and-long-postgres-password
POSTGRES_DB=postgres
JWT_SECRET=your-super-secret-jwt-token-with-at-least-32-characters-long
JWT_EXP=3600
API_EXTERNAL_URL=http://localhost:54321
SUPABASE_URL=http://localhost:54321
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0
SUPABASE_SERVICE_ROLE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImV4cCI6MTk4MzgxMjk5Nn0.EGIM96RAZx35lJzdJsyH-qQwv8Hdp7fsn3W0YpN81IU
GOTRUE_SITE_URL=http://localhost:3000
GOTRUE_URI_ALLOW_LIST=
GOTRUE_DISABLE_SIGNUP=false
GOTRUE_EXTERNAL_EMAIL_ENABLED=true
GOTRUE_MAILER_AUTOCONFIRM=true
DEFAULT_ORGANIZATION_NAME=Default Organization
DEFAULT_PROJECT_NAME=Default Project
EOF
        print_success "Created supabase/.env file"
    fi
else
    print_info "supabase/.env file already exists"
fi

# Verify installation
print_info "Verifying installation..."

if command -v flutter &> /dev/null; then
    cd "$PROJECT_DIR"
    flutter doctor || print_warning "Flutter doctor found some issues"
fi

echo ""
print_success "Installation complete! 🎉"
echo ""
echo "Next steps:"
echo "  1. Edit .env file if needed"
echo "  2. Edit supabase/.env if needed"
echo "  3. Run: ./scripts/run.sh"
echo ""

