#!/bin/bash
set -euo pipefail

# ============================================================================
# Zen MCP Server Setup Script (UV Version)
# 
# A platform-agnostic setup script that works on macOS, Linux, and WSL.
# Uses UV package manager for dependency management.
# ============================================================================

# ----------------------------------------------------------------------------
# Constants and Configuration
# ----------------------------------------------------------------------------

# Colors for output (ANSI codes work on all platforms)
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly RED='\033[0;31m'
readonly NC='\033[0m' # No Color

# Configuration
readonly VENV_PATH=".venv"  # UV uses .venv by default
readonly DOCKER_CLEANED_FLAG=".docker_cleaned"
readonly DESKTOP_CONFIG_FLAG=".desktop_configured"
readonly LOG_DIR="logs"
readonly LOG_FILE="mcp_server.log"

# ----------------------------------------------------------------------------
# Utility Functions
# ----------------------------------------------------------------------------

# Print colored output
print_success() {
    echo -e "${GREEN}✓${NC} $1" >&2
}

print_error() {
    echo -e "${RED}✗${NC} $1" >&2
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1" >&2
}

print_info() {
    echo -e "ℹ️  $1" >&2
}

# ----------------------------------------------------------------------------
# UV Installation
# ----------------------------------------------------------------------------

install_uv() {
    if ! command -v uv &> /dev/null; then
        print_info "UV not found. Installing UV..."
        curl -LsSf https://astral.sh/uv/install.sh | sh
        export PATH="$HOME/.local/bin:$PATH"
        print_success "UV installed successfully"
    else
        print_success "UV is already installed ($(uv --version))"
    fi
}

# ----------------------------------------------------------------------------
# Python Environment Setup
# ----------------------------------------------------------------------------

setup_python_environment() {
    print_info "Setting up Python environment with UV..."
    
    # Ensure UV is in PATH
    export PATH="$HOME/.local/bin:$PATH"
    
    # Sync dependencies (this creates venv if needed)
    if uv sync --all-extras; then
        print_success "Dependencies installed successfully"
    else
        print_error "Failed to install dependencies"
        return 1
    fi
}

# ----------------------------------------------------------------------------
# Environment File Management
# ----------------------------------------------------------------------------

create_env_file() {
    if [[ ! -f .env ]]; then
        print_info "Creating .env file from template..."
        
        if [[ -f .env.example ]]; then
            cp .env.example .env
            print_success ".env file created from .env.example"
            print_warning "Please edit .env and add your API keys"
        else
            print_error ".env.example not found"
            return 1
        fi
    else
        print_success ".env file already exists"
    fi
}

# ----------------------------------------------------------------------------
# Log Management
# ----------------------------------------------------------------------------

setup_logs() {
    if [[ ! -d "$LOG_DIR" ]]; then
        mkdir -p "$LOG_DIR"
        print_success "Created logs directory"
    fi
    
    # Create empty log files if they don't exist
    touch "$LOG_DIR/$LOG_FILE"
    touch "$LOG_DIR/mcp_activity.log"
}

# ----------------------------------------------------------------------------
# Main Execution
# ----------------------------------------------------------------------------

main() {
    print_info "🚀 Zen MCP Server Setup (UV Version)"
    echo ""
    
    # Check for command line arguments
    local follow_logs=false
    if [[ "${1:-}" == "-f" ]] || [[ "${1:-}" == "--follow" ]]; then
        follow_logs=true
    fi
    
    # Install UV if needed
    install_uv
    
    # Setup Python environment
    setup_python_environment
    
    # Create .env file if needed
    create_env_file
    
    # Setup logs
    setup_logs
    
    echo ""
    print_success "Setup complete!"
    echo ""
    print_info "To run the server:"
    echo "    uv run python server.py"
    echo ""
    print_info "To run tests:"
    echo "    uv run pytest tests/"
    echo ""
    print_info "To run code quality checks:"
    echo "    uv run ruff check ."
    echo "    uv run black --check ."
    echo ""
    
    if [[ "$follow_logs" == true ]]; then
        print_info "Following logs (Ctrl+C to stop)..."
        tail -f "$LOG_DIR/$LOG_FILE"
    else
        print_info "To follow logs, run: ./run-server-uv.sh -f"
    fi
}

# Run main function
main "$@"