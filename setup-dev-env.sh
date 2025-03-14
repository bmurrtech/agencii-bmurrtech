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
    # Enforce rebase by default
    if ! git config --get pull.rebase > /dev/null; then
        log_info "Setting git pull to use rebase by default..."
        git config --global pull.rebase true
    fi
    
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

# Virtual Environment Setup
VENV_DIR=".venv"
VENV_ACTIVATE="$VENV_DIR/bin/activate"
VENV_REQUIRED=true

if [ -d "$VENV_DIR" ]; then
    log_info "Using existing virtual environment at $VENV_DIR"
else
    log_info "Creating Python virtual environment at $VENV_DIR..."
    if command_exists python3; then
        python3 -m venv "$VENV_DIR" || {
            log_error "Failed to create virtual environment"
            exit 1
        }
        log_success "Virtual environment created"
    else
        log_error "Python 3 is required but not found"
        exit 1
    fi
fi

# Cross-platform activation
log_info "Activating virtual environment..."
if [ -f "$VENV_ACTIVATE" ]; then
    source "$VENV_ACTIVATE" || {
        log_error "Failed to activate virtual environment"
        exit 1
    }
    log_success "Virtual environment activated"
else
    log_warning "Virtual environment activation script not found at $VENV_ACTIVATE"
    VENV_REQUIRED=false
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
        ruff check "main.py" "run_tests.py" "tools/" --no-fix --show-fixes
        ruff format "main.py" "run_tests.py" "tools/" --check

    - name: Check for secrets
      run: |
        detect-secrets scan main.py run_tests.py tools/

    - name: Run tests
      run: |
        if [ -d "tests" ]; then
          pytest tests/
        else
          echo "No tests directory found, skipping tests"
          exit 0
        fi

    - name: Type checking
      run: |
        mypy main.py run_tests.py tools/ --ignore-missing-imports
EOL
    log_success "python-tests.yaml created"
fi

# Create DEV_README.md if it doesn't exist
if [ ! -f "DEV_README.md" ]; then
    log_info "Creating DEV_README.md..."
    cat > DEV_README.md << 'EOL'
# Development Guide

## Linear Git History Enforcement

We enforce a clean, linear history without merge commits:
```bash
* a1b2c3d (HEAD -> main) Add feature Z
* e4f5g6h Refactor module Y
* i7j8k9l Fix bug in component X
```

**Why Linear?**
- Enables efficient debugging with `git bisect`
- Clear chronological change tracking
- Eliminates merge commit noise

**Enforcement:**
```bash
# Always rebase when updating
git pull --rebase origin main
```

## 🔄 Git Workflow & Conventions

1. **Branch Strategy & Commit Convention**
   ```bash
   # Branch Format: prefix/DEV-####-SP-#-description
   git checkout -b feat/DEV-2157-SP-3-add-search-api
   
   # Commit Format: prefix/SP-#: Description
   git commit -m "feat/SP-3: Add search API endpoint"
   ```
   - Branch directly from `main`
   - Single task focus per branch
   - Branch & commit naming components:
     * `prefix/` - Semantic prefix indicating change type
     * `DEV-####` - Notion task ID (copy from task properties, branches only)
     * `SP-#` - Story point estimate (1,2,3,5,8,13)
     * Description in kebab-case for branches, sentence case for commits

   **Semantic Prefix Legend:**
   ```
   feat/   - New feature or significant enhancement
   fix/    - Bug fixes and patches
   hotfix/ - Critical production fixes
   refac/  - Code restructuring without behavior change
   docs/   - Documentation updates only
   test/   - Adding or modifying tests
   style/  - Code style/formatting changes
   perf/   - Performance improvements
   chore/  - Maintenance tasks, dependencies, etc.
   ci/     - CI/CD pipeline changes
   ```

   **Examples:**
   Branch names:
   ```bash
   feat/DEV-2157-SP-3-add-search-api
   fix/DEV-3891-SP-1-login-validation
   refac/DEV-4200-SP-5-optimize-auth-flow
   ```
   
   Commit messages:
   ```bash
   feat/SP-3: Add search API endpoint with rate limiting
   fix/SP-1: Resolve login validation edge case
   refac/SP-5: Optimize authentication flow for better performance
   ```

**Story Points (SP):**
- `SP-1` - Quick fix (< 1 hour)
- `SP-2` - Simple task (2-4 hours)
- `SP-3` - Medium task (1 day)
- `SP-5` - Complex task (2-3 days)
- `SP-8` - Major feature (3+ days)
- `SP-13` - Project milestone (5+ days)

2. **Commit Standards**
   - Atomic, self-contained changes
   - Imperative mood ("Add feature" not "Added feature")
   - Max 24h between commits
   - Short & precise messages
   - Never repeat previous commits
   - Self-contained changes only

3. **PR Management**
   - "Rebase and merge" only to maintain linear history
   - Max 3 days old
   - Attach Notion task link
   - PM-controlled merges to `main`

## Essential Commands
```bash
# Update branch safely with latest main
git pull --rebase origin main

# Add forgotten changes to last commit
git commit --amend --no-edit

# Create PR quickly
git push --set-upstream origin $(git branch --show-current)

# Revert safely
git revert <commit-hash>

# Rebase with auto-stash for local changes
git pull --rebase --autostash

# Add all modified files and commit
git commit --all --message "feat/SP-3: your message"
```

## Code Quality Tools

### Pre-commit Checks (Advisory Mode)
```bash
# Run all checks
pre-commit run --all-files

# Format main files
ruff format main.py run_tests.py tools/

# Lint check
ruff check main.py run_tests.py tools/ --no-fix --show-fixes
```

## Protected Branch Policy
- `main` - Production code (PM access only)
- All changes via PR with rebase
- Linear history enforced
- Pre-commit checks required

## Development Flow
1. Create branch from `main`
2. Make atomic commits
3. Rebase onto latest main
4. Create PR
5. PM reviews and merges via rebase

## Troubleshooting

If pre-commit hooks fail:
1. Review the error messages
2. Run format and lint fixes
3. Commit changes
4. If issues persist, consult team lead

## Security Considerations

- No credentials in code
- Use environment variables
- Regular dependency updates
- Security scanning in CI/CD

For more detailed information, refer to the main README.md
EOL
    log_success "DEV_README.md created"
fi

# Update .pre-commit-config.yaml creation
if [ ! -f ".pre-commit-config.yaml" ]; then
    log_info "Creating .pre-commit-config.yaml..."
    cat > .pre-commit-config.yaml << 'EOL'
repos:
  # ... existing hooks ...

  # Merge commit prevention
  - repo: local
    hooks:
      - id: prevent-merge-commits
        name: Block merge commits
        entry: |
          #!/bin/bash
          if git log --merges -n 1 --pretty=%H HEAD^..HEAD | grep -q .; then
            echo "❌ Merge commits prohibited! Use rebase instead."
            exit 1
          fi
        language: system
        stages: [commit-msg]
        verbose: true

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

# Update workflow guidance to match new strategy
echo ""
log_info "Development Workflow Guidelines:"
echo "1. Branch & Commit Convention:"
echo "   TYPE/SP-X: Brief Description"
echo ""
echo "   Types:"
echo "   • FEAT  - New feature"
echo "   • FIX   - Bug fix"
echo "   • REFAC - Code restructuring"
echo "   • DOCS  - Documentation"
echo "   • TEST  - Testing changes"
echo ""
echo "   Story Points:"
echo "   • SP-1 - Quick fix (< 1 hour)"
echo "   • SP-2 - Simple task (2-4 hours)"
echo "   • SP-3 - Medium task (1 day)"
echo "   • SP-5 - Complex task (2-3 days)"
echo "   • SP-8 - Major feature (3+ days)"
echo ""
echo "2. Code Quality Tools (Advisory Mode):"
echo "   • Check issues : pre-commit run --all-files"
echo "   • Format check: pre-commit run ruff-format"
echo "   • Lint check  : ruff check main.py run_tests.py tools/ --no-fix --show-fixes"
echo ""
echo "3. Branch Flow:"
echo "   • Branch directly from main"
echo "   • Rebase onto latest main before PR"
echo "   • PM merges to main after review"

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

# Install pre-commit within virtual environment
if $VENV_REQUIRED; then
    log_info "Installing pre-commit inside virtual environment..."
    python -m pip install --upgrade pip || {
        log_error "Failed to upgrade pip"
        exit 1
    }
    python -m pip install pre-commit || {
        log_error "Failed to install pre-commit"
        exit 1
    }
else
    log_warning "Installing pre-commit system-wide (not recommended)"
    if command_exists pip3; then
        pip3 install --user pre-commit || {
            log_error "Failed to install pre-commit"
            exit 1
        }
    else
        pip install --user pre-commit || {
            log_error "Failed to install pre-commit"
            exit 1
        }
    fi
fi

# Add cross-platform deactivation guidance
echo ""
log_success "---------------------------------------------"
log_success "Setup complete! Virtual environment active."
log_info "To exit the virtual environment later, run:"
log_info "  deactivate"
log_info ""
log_info "To reactivate the environment:"
log_info "  Unix/MacOS: source $VENV_ACTIVATE"
log_info "  Windows:    $VENV_DIR\\Scripts\\activate.bat"
log_success "---------------------------------------------"