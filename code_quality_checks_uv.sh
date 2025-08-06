#!/bin/bash
set -euo pipefail

# ======================================================================
# Code Quality Checks for Zen MCP Server (UV Version)
#
# This script runs comprehensive code quality checks using UV:
# - Ruff for linting
# - Black for code formatting
# - isort for import sorting
# - pytest for unit tests
# ======================================================================

# Colors for output
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly RED='\033[0;31m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# Exit codes
readonly SUCCESS=0
readonly FAILURE=1

# Ensure UV is in PATH
export PATH="$HOME/.local/bin:$PATH"

# ----------------------------------------------------------------------
# Utility Functions
# ----------------------------------------------------------------------

print_header() {
    echo ""
    echo -e "${BLUE}🔍 Running Code Quality Checks for Zen MCP Server${NC}"
    echo "================================================="
}

print_section() {
    echo ""
    echo -e "${BLUE}$1${NC}"
    echo "----------------------------------------"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

# ----------------------------------------------------------------------
# Check UV Installation
# ----------------------------------------------------------------------

check_uv() {
    if ! command -v uv &> /dev/null; then
        print_error "UV is not installed. Please run ./run-server-uv.sh first"
        exit $FAILURE
    fi
    print_success "Using UV $(uv --version)"
}

# ----------------------------------------------------------------------
# Ensure Dependencies
# ----------------------------------------------------------------------

ensure_dependencies() {
    print_section "🔍 Checking development dependencies..."
    
    if ! uv sync --all-extras > /dev/null 2>&1; then
        print_warning "Syncing dependencies..."
        uv sync --all-extras
    fi
    print_success "Development dependencies are installed"
}

# ----------------------------------------------------------------------
# Run Linting Checks
# ----------------------------------------------------------------------

run_ruff() {
    print_section "🔍 Running Ruff linting..."
    
    if uv run ruff check . --fix; then
        print_success "Ruff linting passed!"
        return $SUCCESS
    else
        print_error "Ruff linting failed"
        return $FAILURE
    fi
}

# ----------------------------------------------------------------------
# Run Formatting Checks
# ----------------------------------------------------------------------

run_black() {
    print_section "🎨 Running Black formatting..."
    
    if uv run black .; then
        print_success "Black formatting applied!"
        return $SUCCESS
    else
        print_error "Black formatting failed"
        return $FAILURE
    fi
}

# ----------------------------------------------------------------------
# Run Import Sorting
# ----------------------------------------------------------------------

run_isort() {
    print_section "📦 Running isort import sorting..."
    
    if uv run isort .; then
        print_success "Import sorting completed!"
        return $SUCCESS
    else
        print_error "Import sorting failed"
        return $FAILURE
    fi
}

# ----------------------------------------------------------------------
# Run Unit Tests
# ----------------------------------------------------------------------

run_tests() {
    print_section "🧪 Running unit tests..."
    
    # Run tests excluding integration tests
    if uv run pytest tests/ -v -m "not integration" --tb=short; then
        print_success "All tests passed!"
        return $SUCCESS
    else
        print_error "Some tests failed"
        return $FAILURE
    fi
}

# ----------------------------------------------------------------------
# Main Execution
# ----------------------------------------------------------------------

main() {
    local exit_code=$SUCCESS
    
    print_header
    
    # Check UV is installed
    check_uv
    
    # Ensure dependencies are installed
    ensure_dependencies
    
    # Run all checks
    if ! run_ruff; then
        exit_code=$FAILURE
    fi
    
    if ! run_black; then
        exit_code=$FAILURE
    fi
    
    if ! run_isort; then
        exit_code=$FAILURE
    fi
    
    if ! run_tests; then
        exit_code=$FAILURE
    fi
    
    # Final summary
    echo ""
    echo "================================================="
    if [[ $exit_code -eq $SUCCESS ]]; then
        print_success "All quality checks passed! 🎉"
    else
        print_error "Some quality checks failed. Please fix the issues above."
    fi
    echo "================================================="
    
    exit $exit_code
}

# Run main function
main "$@"