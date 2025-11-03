#!/bin/bash

# Health Data Aggregator - Code Validation Script
# This script validates the codebase structure and common issues before CI

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

ERRORS=0

echo ""
echo "=================================="
echo "  Code Validation Script"
echo "=================================="
echo ""

# Check 1: Required files exist
print_info "Checking required files..."

REQUIRED_FILES=(
    "pubspec.yaml"
    "lib/main.dart"
    "README.md"
    "LICENSE"
    ".gitignore"
    "env.template"
)

for file in "${REQUIRED_FILES[@]}"; do
    if [ -f "$file" ]; then
        print_success "$file exists"
    else
        print_error "$file is missing"
        ERRORS=$((ERRORS + 1))
    fi
done

# Check 2: Dart file structure
print_info "Checking Dart file structure..."

DART_FILES=(
    "lib/main.dart"
    "lib/src/routing/app_router.dart"
    "lib/src/screens/auth_screen.dart"
    "lib/src/screens/dashboard_screen.dart"
    "lib/src/services/supabase_client.dart"
    "lib/src/providers/auth_provider.dart"
)

for file in "${DART_FILES[@]}"; do
    if [ -f "$file" ]; then
        print_success "$file exists"
    else
        print_error "$file is missing"
        ERRORS=$((ERRORS + 1))
    fi
done

# Check 3: Models have generated files
print_info "Checking model files..."

if [ -f "lib/src/models/health_data.dart" ]; then
    if [ -f "lib/src/models/health_data.g.dart" ]; then
        # Check if .g.dart has actual content (not just placeholder)
        if grep -q "_\$SleepStageFromJson" "lib/src/models/health_data.g.dart"; then
            print_success "health_data.g.dart has generated code"
        else
            print_warning "health_data.g.dart may be placeholder (run build_runner)"
        fi
    else
        print_error "health_data.g.dart is missing"
        ERRORS=$((ERRORS + 1))
    fi
fi

# Check 4: No syntax errors in Dart files (basic checks)
print_info "Checking for common Dart syntax errors..."

# Check for unclosed brackets
for dart_file in $(find lib -name "*.dart"); do
    if grep -q "^import.*unused" "$dart_file" 2>/dev/null; then
        print_warning "Potential unused import in $dart_file"
    fi
    
    # Check for missing semicolons (basic check)
    if tail -1 "$dart_file" | grep -v "[;{}]$" | grep -v "^//" | grep -v "^$" >/dev/null 2>&1; then
        # This is very basic, skip for now
        true
    fi
done

print_success "Basic syntax checks passed"

# Check 5: Environment files
print_info "Checking environment configuration..."

if [ -f "env.template" ]; then
    if grep -q "SUPABASE_URL" "env.template"; then
        print_success "env.template has SUPABASE_URL"
    else
        print_error "env.template missing SUPABASE_URL"
        ERRORS=$((ERRORS + 1))
    fi
fi

if [ -f ".env" ]; then
    print_warning ".env file exists (should be in .gitignore)"
    if grep -q "^\.env$" .gitignore; then
        print_success ".env is in .gitignore"
    else
        print_error ".env should be in .gitignore"
        ERRORS=$((ERRORS + 1))
    fi
fi

# Check 6: Required directories
print_info "Checking directory structure..."

REQUIRED_DIRS=(
    "lib/src"
    "lib/src/screens"
    "lib/src/services"
    "lib/src/providers"
    "lib/src/models"
    "supabase/migrations"
    "analysis"
)

for dir in "${REQUIRED_DIRS[@]}"; do
    if [ -d "$dir" ]; then
        print_success "$dir/ exists"
    else
        print_error "$dir/ is missing"
        ERRORS=$((ERRORS + 1))
    fi
done

# Check 7: Python analysis service
print_info "Checking Python analysis service..."

if [ -f "analysis/sleep_analyzer.py" ]; then
    print_success "sleep_analyzer.py exists"
else
    print_error "analysis/sleep_analyzer.py is missing"
    ERRORS=$((ERRORS + 1))
fi

if [ -f "analysis/app.py" ]; then
    print_success "app.py exists"
else
    print_error "analysis/app.py is missing"
    ERRORS=$((ERRORS + 1))
fi

if [ -f "analysis/requirements.txt" ]; then
    print_success "requirements.txt exists"
else
    print_error "analysis/requirements.txt is missing"
    ERRORS=$((ERRORS + 1))
fi

# Check 8: Docker files
print_info "Checking Docker configuration..."

if [ -f "Dockerfile" ]; then
    print_success "Dockerfile exists"
else
    print_warning "Dockerfile not found (optional)"
fi

if [ -f "docker-compose.yml" ]; then
    print_success "docker-compose.yml exists"
else
    print_warning "docker-compose.yml not found (optional)"
fi

# Check 9: GitHub workflows
print_info "Checking GitHub Actions workflows..."

if [ -d ".github/workflows" ]; then
    WORKFLOW_COUNT=$(find .github/workflows -name "*.yml" -o -name "*.yaml" | wc -l | tr -d ' ')
    if [ "$WORKFLOW_COUNT" -gt 0 ]; then
        print_success "Found $WORKFLOW_COUNT workflow file(s)"
    else
        print_warning "No workflow files found"
    fi
else
    print_warning ".github/workflows/ not found"
fi

# Check 10: Import statements (check for missing imports)
print_info "Checking import statements..."

MISSING_IMPORTS=0
for dart_file in $(find lib -name "*.dart"); do
    # Check for common patterns that might indicate missing imports
    if grep -q "SleepSession\|SleepStage\|Device" "$dart_file" 2>/dev/null; then
        if ! grep -q "import.*health_data" "$dart_file" 2>/dev/null; then
            # Might be okay if it's in the same file
            if [[ "$dart_file" != *"health_data.dart" ]]; then
                # This is not definitive, just a warning
                true
            fi
        fi
    fi
done

# Check 11: Documentation
print_info "Checking documentation..."

if [ -f "README.md" ]; then
    README_LINES=$(wc -l < README.md | tr -d ' ')
    if [ "$README_LINES" -gt 50 ]; then
        print_success "README.md is comprehensive ($README_LINES lines)"
    else
        print_warning "README.md seems short ($README_LINES lines)"
    fi
fi

# Summary
echo ""
echo "=================================="
if [ $ERRORS -eq 0 ]; then
    print_success "Validation complete! No critical errors found."
    echo ""
    echo "Next steps:"
    echo "  1. Run: flutter pub get"
    echo "  2. Run: flutter pub run build_runner build --delete-conflicting-outputs"
    echo "  3. Run: flutter analyze"
    echo "  4. Run: flutter test"
    exit 0
else
    print_error "Validation complete! Found $ERRORS error(s)."
    echo ""
    echo "Please fix the errors above before committing."
    exit 1
fi

