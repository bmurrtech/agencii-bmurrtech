# Agency Swarm Base Template

This repository serves as an example implementation of the Agency Swarm framework, showcasing example agents, tools, and a CI testing workflow.

## Project Description

This template provides a starting point for building AI agent teams using the Agency Swarm framework. It includes:

- Example agent implementations
- Custom tool examples
- A CI testing workflow
- A comprehensive test suite
- A `.cursorrules` file containing the prompt for AI assistance

The purpose of this template is to demonstrate best practices for setting up an Agency Swarm project and to provide a foundation that developers can build upon for their own AI agent applications.

## Getting Started

1. Clone this repository:

   ```bash
   git clone https://github.com/vrsen-ai-solutions/agency-swarm-base-template.git
   cd agency-swarm-base-template
   ```

2. Install the required dependencies:

   ```bash
   pip install -r requirements.txt
   ```

3. Set up your OpenAI API key:
   Use the `.env.example` file to create your own `.env` file. It will be read automatically by `dotenv`.

4. Set up development environment:
   ```bash
   chmod +x setup_dev_env.sh
   ./setup_dev_env.sh
   ```

5. Explore the `agents` and `tools` directories to see example implementations.

6. Run the example agency:
   ```python
   python backend/ExampleAgency/agency.py
   ```

## Development Workflow & Standards

### 🌿 Branch Structure
```bash
main        # Production-ready code
develop     # Integration branch
feature/*   # New features (e.g., feature/AUTH-123-oauth)
fix/*       # Bug fixes (e.g., fix/UI-456-button-alignment)
hotfix/*    # Urgent fixes (e.g., hotfix/SEC-789-vulnerability)
release/*   # Release branches (e.g., release/1.2.0)
dev/*       # Personal development branches
```

### 💬 Commit Message Format
We follow Conventional Commits standard:
```bash
<type>(<scope>): <description>

# Examples:
feat(auth): implement OAuth2 login
fix(api): resolve rate limiting issue
docs: update installation guide
```

#### Type Prefixes
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation
- `style`: Formatting
- `refactor`: Code restructuring
- `test`: Testing
- `chore`: Maintenance
- `perf`: Performance
- `ci`: CI/CD changes

### 🔄 Development Workflow

1. **Start New Work**
   ```bash
   git checkout main
   git pull
   git checkout -b feature/XXX-description
   ```

2. **Pre-commit Checks**
   The following checks run automatically:
   - Code formatting (Ruff)
   - Linting
   - Secret scanning
   - Branch naming
   - Tests

3. **Making Changes**
   ```bash
   git add .
   git commit -m "type(scope): description"
   ```

4. **Create Pull Request**
   ```bash
   git checkout main
   git pull
   git checkout your-branch
   git merge main
   git push origin your-branch
   ```

## Code Quality

### Pre-commit Hooks
We use pre-commit hooks with Ruff for linting and formatting:

```bash
# Format code
ruff format .

# Fix lint issues
ruff check --fix .

# Run all hooks
pre-commit run --all-files
```

### 🎯 Pull Request Guidelines

#### PR Naming Convention
```bash
[TYPE][SP-X] Brief Description #IssueNumber

# Real Examples:
[FEAT][SP-5] OAuth2 Social Login Integration #123
[FIX][SP-2] Resolve API Rate Limiting Bug #456
[REFACTOR][SP-3] Optimize Database Query Performance #789
[DOCS][SP-1] Update API Authentication Docs #234
[TEST][SP-2] Add E2E Tests for Payment Flow #567
```

**Type Categories:**
- `[FEAT]` - New feature
- `[FIX]` - Bug fix
- `[REFACTOR]` - Code restructuring
- `[DOCS]` - Documentation
- `[TEST]` - Testing changes

**Story Points (SP):**
- `SP-1` - Quick fix (< 1 hour)
- `SP-2` - Simple task (2-4 hours)
- `SP-3` - Medium task (1 day)
- `SP-5` - Complex task (2-3 days)
- `SP-8` - Major feature (3+ days)
- `SP-13` - Project milestone (5+ days)

#### Review Process

**Status Tags:**
- 🟢 `[READY]` - Ready for review
- 🟡 `[WIP]` - Work in progress
- 🔴 `[BLOCKED]` - Needs help

**Merge Checklist:**
- [ ] Tests passing
- [ ] Code formatted (ruff)
- [ ] No secrets exposed

#### Quick Tips
1. Keep PRs focused and under SP-5 (for agile DevOps)
2. Add screenshots for UI changes
3. Tag your Project Manager in urgent reviews (on Slack)
4. Use draft PRs for early feedback

## Running Tests

Run the test suite:
```bash
pytest tests
```

## CI/CD Pipeline

Our GitHub Actions workflow includes:
- Code formatting check
- Linting
- Security scanning
- Unit tests
- Integration tests

## Security Considerations

- No credentials in code
- Use environment variables
- Regular dependency updates
- Security scanning in CI/CD

## Best Practices

1. **Code Review**
   - Review for performance
   - Check security implications
   - Verify test coverage
   - Ensure documentation

2. **Branch Management**
   - Keep branches up to date
   - Delete merged branches
   - Use meaningful branch names

3. **Documentation**
   - Update README for new features
   - Document API changes
   - Add inline code comments

4. **Testing**
   - Write tests for new features
   - Maintain test coverage
   - Test edge cases

## Troubleshooting

If pre-commit hooks fail:
1. Review the error messages
2. Run format and lint fixes
3. Commit changes
4. If issues persist, consult team lead

## Additional Resources

- [Conventional Commits](https://www.conventionalcommits.org/)
- [Pre-commit Documentation](https://pre-commit.com/)
- [Ruff Documentation](https://docs.astral.sh/ruff/)