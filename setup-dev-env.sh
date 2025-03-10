#!/bin/bash
set -e

echo "---------------------------------------------"
echo "Setting up development environment..."
echo "---------------------------------------------"

# Create a function to display colored output
function log_success() { echo -e "\033[0;32m$1\033[0m"; }
function log_info() { echo -e "\033[0;34m$1\033[0m"; }
function log_warning() { echo -e "\033[0;33m$1\033[0m"; }
function log_error() { echo -e "\033[0;31m$1\033[0m"; }

# Display environment info
log_info "OS: $(uname -s)"
log_info "Shell: $SHELL"
log_info "Python: $(python3 --version 2>/dev/null || python --version 2>/dev/null || echo 'Not found')"
log_info "Git: $(git --version 2>/dev/null || echo 'Not found')"

# Function to check if a command is available
command_exists() {
  command -v "$1" &> /dev/null
}

# Check Git installation and configuration
if command_exists git; then
    # Check if git user is configured
    if ! git config --get user.name > /dev/null || ! git config --get user.email > /dev/null; then
        log_warning "Git user not fully configured. Please configure:"
        echo "git config --global user.name 'Your Name'"
        echo "git config --global user.email 'your.email@example.com'"
    else
        log_success "Git configuration verified"
    fi
else
    log_error "Git is required but not installed. Please install Git and try again."
    exit 1
fi

# Ensure the .pre-commit-config.yaml exists in the repository root
if [ ! -f "./.pre-commit-config.yaml" ]; then
    log_error "Error: .pre-commit-config.yaml not found in the repository root."
    log_error "Please ensure the file exists before running this script."
    exit 1
fi

# Setup code quality tools
log_info "Setting up code quality tools..."

# Check and install ruff if needed (for manual formatting/linting)
if ! command_exists ruff; then
    log_info "Installing ruff for code quality checks..."
    if command_exists pip3; then
        pip3 install ruff
    elif command_exists pip; then
        pip install ruff
    else
        log_error "Error: pip is not installed. Please install pip and re-run the script."
        exit 1
    fi
    log_success "ruff installed successfully"
else
    log_info "ruff is already installed"
fi

# Create necessary baseline files for hooks
log_info "Setting up pre-commit environment..."

# Create an empty secrets baseline if it doesn't exist
if [ ! -f ".secrets.baseline" ]; then
    log_info "Creating empty .secrets.baseline file"
    echo "{\"version\": \"1.4.0\", \"plugins_used\": [], \"filters\": {}, \"results\": {}, \"generated_at\": \"$(date -u +"%Y-%m-%dT%H:%M:%SZ")\"}" > .secrets.baseline
    log_success ".secrets.baseline created"
else
    log_info ".secrets.baseline already exists"
fi

# Check if pre-commit is installed; if not, install it
if ! command_exists pre-commit; then
    log_info "pre-commit not found. Installing pre-commit via pip..."
    if command_exists pip3; then
        pip3 install pre-commit
    elif command_exists pip; then
        pip install pre-commit
    else
        log_error "Error: pip is not installed. Please install pip and re-run the script."
        exit 1
    fi
    log_success "pre-commit installed successfully"
else
    log_info "pre-commit is already installed"
fi

# Update pre-commit configuration (fixes deprecated stage names)
log_info "Updating pre-commit configuration..."
pre-commit migrate-config
log_success "pre-commit configuration updated"

# Install pre-commit hooks with all necessary hook types
log_info "Installing pre-commit hooks..."
pre-commit install --install-hooks --hook-types pre-commit,commit-msg,pre-push,post-checkout,prepare-commit-msg
log_success "pre-commit hooks installed"

# Virtual Environment Setup
if [ ! -d ".venv" ]; then
    log_info "Creating a Python virtual environment in .venv..."
    if command_exists python3; then
        python3 -m venv .venv
    elif command_exists python; then
        python -m venv .venv
    else
        log_error "Error: Python is not installed. Please install Python and re-run the script."
        exit 1
    fi
    log_success "Virtual environment created in .venv directory"
else
    log_info "Virtual environment already exists"
fi

# Check if we need to create an initial .env file
if [ ! -f ".env" ] && [ -f ".env.example" ]; then
    log_info "Creating initial .env file from .env.example..."
    cp .env.example .env
    log_success ".env file created (remember to update with your actual values)"
fi

# Display development workflow guidance
echo ""
log_info "Development Workflow Guidelines:"
echo "1. Branch Naming Conventions:"
echo "   • feature/XXX-description  : For new features"
echo "   • fix/XXX-description     : For bug fixes"
echo "   • hotfix/XXX-description  : For urgent fixes"
echo "   • release/X.Y.Z          : For releases"
echo "   • dev/username/description: For personal development"

echo ""
echo "2. Code Quality Tools:"
echo "   • Check issues : pre-commit run --all-files"
echo "   • Manual format: ruff format ."
echo "   • Manual lint  : ruff check --fix ."

echo ""
echo "3. Commit Message Format:"
echo "   <type>(<scope>): <description>"
echo "   Types: feat, fix, docs, style, refactor, test, chore"

echo ""
log_info "IMPORTANT: To activate the Python virtual environment, please run:"
echo "For macOS/Linux:  source .venv/bin/activate"
echo "For Windows CMD:   .venv\\Scripts\\activate.bat"
echo "For Windows PowerShell: .venv\\Scripts\\Activate.ps1"
echo ""
log_success "---------------------------------------------"
log_success "Development environment setup complete!"
log_success "Use pre-commit checks for guidance and manual fixes as needed."
log_success "---------------------------------------------"