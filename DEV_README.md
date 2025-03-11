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

## Branch & Commit Convention
```bash
TYPE/SP-X: Brief Description

# Examples:
FEAT/SP-5: OAuth2 Social Login Integration
FIX/SP-2: Resolve API Rate Limiting Bug
REFAC/SP-3: Optimize Database Query Performance
DOCS/SP-1: Update API Authentication Docs
TEST/SP-2: Add E2E Tests for Payment Flow
```

### Type Categories
- `FEAT` - New feature
- `FIX` - Bug fix
- `REFAC` - Code restructuring
- `DOCS` - Documentation
- `TEST` - Testing changes

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
