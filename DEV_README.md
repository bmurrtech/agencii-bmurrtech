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

# Run type checking (main deployment files and tools only)
mypy main.py run_tests.py tools/ --ignore-missing-imports
```

### Testing
```bash
pytest tests/
```