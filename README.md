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

4. Explore the `agents` and `tools` directories to see example implementations.

5. Run the example agency:
   ```python
   python backend/ExampleAgency/agency.py
   ```
## Code Quality
We use pre-commit hooks with Ruff for linting and formatting. To set up:

Run the Script:
Save the above script as `setup_dev_env.sh` in your project’s root directory, make it executable:

```bash
chmod +x setup_dev_env.sh
```

```bash
./setup_dev_env.sh
```

This updated script should enforce the necessary conditions and help ensure that your development environment is correctly set up before developers begin working on the project.

Pre-commit will now run automatically on `git commit`.

## Running Tests

To run the test suite:

```bash
pytest tests
```