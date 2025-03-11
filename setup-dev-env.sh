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

# Create .pre-commit-config.yaml if it doesn't exist
if [ ! -f ".pre-commit-config.yaml" ]; then
    log_info "Creating .pre-commit-config.yaml..."
    cat > .pre-commit-config.yaml << 'EOL'
repos:
  # Essential code quality checks - informative only
  - repo: https://github.com/pre-commit/pre-commit-hooks
    rev: v4.5.0
    hooks:
      - id: trailing-whitespace
        verbose: true
        args: [--check-only]
      - id: end-of-file-fixer
        verbose: true
      - id: check-yaml
        verbose: true
      - id: check-toml
        verbose: true
      - id: debug-statements
        language_version: python3

  # Linting - check only mode
  - repo: https://github.com/astral-sh/ruff-pre-commit
    rev: v0.3.4
    hooks:
      - id: ruff
        args: [--no-fix, --show-fixes]
        stages: [pre-commit]
        fail_fast: false
      - id: ruff-format
        args: [--check]
        stages: [pre-commit]
        fail_fast: false

  # Security checks
  - repo: https://github.com/Yelp/detect-secrets
    rev: v1.3.0
    hooks:
      - id: detect-secrets
        exclude: "package-lock.json|poetry.lock"
        stages: [pre-commit]
        fail_fast: false

  # Simple branch protection
  - repo: local
    hooks:
      - id: protected-branch-check
        name: Protected Branch Warning
        entry: |
          #!/bin/bash
          branch=$(git rev-parse --abbrev-ref HEAD)
          if [[ $branch =~ ^(main|master|develop|production|staging)$ ]]; then
              echo "⚠️  Warning: You're on protected branch: $branch"
              exit 1
          fi
          exit 0
        language: system
        stages: [pre-push]
        verbose: true
EOL
    log_success ".pre-commit-config.yaml created"
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
for hook_type in "pre-commit" "commit-msg" "pre-push" "post-checkout" "prepare-commit-msg" "post-commit"; do
    log_info "Installing $hook_type hook..."
    pre-commit install --hook-type $hook_type
done
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

# Create GitHub Actions workflow directory and file if they don't exist
if [ ! -d ".github/workflows" ]; then
    log_info "Creating GitHub Actions workflow directory..."
    mkdir -p .github/workflows
fi

if [ ! -f ".github/workflows/python-tests.yaml" ]; then
    log_info "Creating python-tests.yaml..."
    cat > .github/workflows/python-tests.yaml << 'EOL'
name: Python Tests

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  test:
    runs-on: ubuntu-latest
    env:
      OPENAI_API_KEY: ${{ secrets.OPENAI_API_KEY }}

    steps:
    - uses: actions/checkout@v3

    - name: Set up Python
      uses: actions/setup-python@v4
      with:
        python-version: '3.12'

    - name: Install dependencies
      run: |
        python -m pip install --upgrade pip
        pip install -r requirements.txt

    - name: Run Ruff linting
      run: |
        # Only check main deployment files and tools
        ruff check "main.py" "run_tests.py" "tools/" --no-fix --show-fixes
        ruff format "main.py" "run_tests.py" "tools/" --check

    - name: Check for secrets
      run: |
        # Only scan crucial files
        detect-secrets scan main.py run_tests.py tools/

    - name: Run tests
      run: |
        # Only if tests directory exists
        if [ -d "tests" ]; then
          pytest tests/
        else
          echo "No tests directory found, skipping tests"
          exit 0
        fi

    - name: Type checking
      run: |
        # Only check main deployment files and tools
        mypy main.py run_tests.py tools/
EOL
    log_success "python-tests.yaml created"
fi

# Create DEV_README.md if it doesn't exist
if [ ! -f "DEV_README.md" ]; then
    log_info "Creating DEV_README.md..."
    cat > DEV_README.md << 'EOL'
# Development Guide

## Quick Start
1. Activate virtual environment:
   ```bash
   source .venv/bin/activate   # Unix
   .venv\Scripts\activate.bat  # Windows
   ```

2. Install dependencies:
   ```bash
   pip install -r requirements.txt
   ```

## Code Quality Tools

### Pre-commit Hooks (Advisory Mode)
```bash
# Run all checks
pre-commit run --all-files

# Format code (main deployment files and tools only)
ruff format main.py run_tests.py tools/

# Check linting (main deployment files and tools only)
ruff check main.py run_tests.py tools/ --no-fix --show-fixes
```

### Testing
```bash
pytest tests/
```

## Branch Naming Convention
```bash
[TYPE][SP-X] Brief Description #IssueNumber

# Examples:
[FEAT][SP-5] OAuth2 Social Login Integration #123
[FIX][SP-2] Resolve API Rate Limiting Bug #456
[REFACTOR][SP-3] Optimize Database Query Performance #789
[DOCS][SP-1] Update API Authentication Docs #234
[TEST][SP-2] Add E2E Tests for Payment Flow #567
```

### Type Categories
- `[FEAT]` - New feature
- `[FIX]` - Bug fix
- `[REFACTOR]` - Code restructuring
- `[DOCS]` - Documentation
- `[TEST]` - Testing changes

### Story Points (SP)
- `SP-1` - Quick fix (< 1 hour)
- `SP-2` - Simple task (2-4 hours)
- `SP-3` - Medium task (1 day)
- `SP-5` - Complex task (2-3 days)
- `SP-8` - Major feature (3+ days)

## Branch Management
- Always branch from `staging`
- Push changes to `staging` via PR
- PM controls merges to `main`
- Delete branches after merge

## Protected Branches
- `main` - Production code (PM access only)
- `staging` - Pre-production testing
- `production` - Live deployment

## Development Flow
1. Branch from `staging`
2. Make changes
3. Run pre-commit checks
4. Push to your branch
5. Create PR to `staging`
6. Wait for review & Railway testing
7. PM merges to `main` if approved

## Common Issues & Solutions

### Pre-commit Failures
1. Review error messages
2. Run format and lint fixes
3. Commit changes
4. If issues persist, consult team lead

### Environment Setup
1. Ensure virtual environment is activated
2. Verify all dependencies are installed
3. Check .env file configuration

For more detailed information, refer to the main README.md
EOL
    log_success "DEV_README.md created"
fi

# Display development workflow guidance
echo ""
log_info "Development Workflow Guidelines:"
echo "1. Branch Naming Conventions:"
echo "   • feat/XXX-description  : For new features"
echo "   • fix/XXX-description     : For bug fixes"
echo "   • hotfix/XXX-description  : For urgent fixes"
echo "   • release/X.Y.Z          : For releases"
echo "   • dev/username/description: For personal development"

echo ""
echo "2. Code Quality Tools (Advisory Mode):"
echo "   • Check issues : pre-commit run --all-files"
echo "   • Format check: ruff format . --check"
echo "   • Lint check  : ruff check . --no-fix --show-fixes"

echo ""
echo "3. Commit Message Format:"
echo "   [TYPE][SP-X] Brief Description #IssueNumber"
echo "   Types: FEAT, FIX, DOCS, REFACTOR, TEST"

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

# Update final message to reference both READMEs
echo ""
log_info "Development Setup Complete!"
echo "📚 Please review:"
echo "   • README.md     - Project overview and setup"
echo "   • DEV_README.md - Development guidelines and workflows"
echo ""
log_info "IMPORTANT: To activate the Python virtual environment, please run:"
echo "For macOS/Linux:  source .venv/bin/activate"
echo "For Windows CMD:   .venv\\Scripts\\activate.bat"
echo "For Windows PowerShell: .venv\\Scripts\\Activate.ps1"
echo ""
log_success "---------------------------------------------"
log_success "Development environment setup complete!"
log_success "---------------------------------------------"

# Add this function near the start of the script, after other function definitions
check_requirements() {
    local req_file="requirements.txt"
    log_info "Checking development dependencies..."
    
    # List of required development packages with versions
    local dev_packages=(
        "pre-commit>=3.5.0"
        "ruff>=0.3.4"
        "pytest>=7.0.0"
        "mypy>=1.0.0"
        "detect-secrets>=1.3.0"
    )
    
    if [ -f "$req_file" ]; then
        echo ""
        log_info "Found existing requirements.txt. Checking for missing development dependencies..."
        
        # Check for missing packages
        local missing_packages=()
        for package in "${dev_packages[@]}"; do
            package_name=$(echo "$package" | cut -d'>=' -f1)
            if ! grep -q "^$package_name" "$req_file"; then
                missing_packages+=("$package")
            fi
        done
        
        if [ ${#missing_packages[@]} -gt 0 ]; then
            echo ""
            log_info "Missing development dependencies:"
            for package in "${missing_packages[@]}"; do
                echo "   $package"
            done
            echo ""
            read -p "Would you like to add these dependencies to requirements.txt? (y/N) " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                echo -e "\n# Development dependencies" >> "$req_file"
                for package in "${missing_packages[@]}"; do
                    echo "$package" >> "$req_file"
                done
                log_success "Dependencies added to requirements.txt"
                log_info "Installing new dependencies..."
                if command_exists pip3; then
                    pip3 install -r "$req_file"
                else
                    pip install -r "$req_file"
                fi
            else
                log_warning "Skipped adding dependencies. You may need to add them manually later."
            fi
        else
            log_success "All development dependencies are present!"
        fi
    else
        echo ""
        log_warning "No requirements.txt found."
        read -p "Would you like to create requirements.txt with development dependencies? (y/N) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            echo "# Development dependencies" > "$req_file"
            for package in "${dev_packages[@]}"; do
                echo "$package" >> "$req_file"
            done
            log_success "Created requirements.txt with development dependencies"
            log_info "Installing dependencies..."
            if command_exists pip3; then
                pip3 install -r "$req_file"
            else
                pip install -r "$req_file"
            fi
        else
            log_warning "Skipped creating requirements.txt. You may need to create it manually later."
        fi
    fi
}