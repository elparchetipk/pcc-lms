# Contributing to PCC LMS

First off, thank you for considering contributing to PCC LMS! 🎉

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [How Can I Contribute?](#how-can-i-contribute)
- [Development Setup](#development-setup)
- [Pull Request Process](#pull-request-process)
- [Coding Standards](#coding-standards)
- [Testing](#testing)
- [Documentation](#documentation)

## Code of Conduct

This project and everyone participating in it is governed by our Code of Conduct. By participating, you are expected to uphold this code.

### Our Pledge

We pledge to make participation in our project a harassment-free experience for everyone, regardless of age, body size, disability, ethnicity, gender identity and expression, level of experience, nationality, personal appearance, race, religion, or sexual identity and orientation.

### Our Standards

Examples of behavior that contributes to creating a positive environment include:

- Using welcoming and inclusive language
- Being respectful of differing viewpoints and experiences
- Gracefully accepting constructive criticism
- Focusing on what is best for the community
- Showing empathy towards other community members

## How Can I Contribute?

### Reporting Bugs

Before creating bug reports, please check the existing issues to avoid duplicates. When you create a bug report, include as many details as possible:

- **Use a clear and descriptive title**
- **Describe the exact steps to reproduce the problem**
- **Provide specific examples and screenshots if applicable**
- **Describe the behavior you observed and what you expected**
- **Include your environment details** (OS, browser, versions)

### Suggesting Enhancements

Enhancement suggestions are welcome! Please provide:

- **Use a clear and descriptive title**
- **Provide a step-by-step description of the suggested enhancement**
- **Provide specific examples to demonstrate the enhancement**
- **Explain why this enhancement would be useful**

### Pull Requests

We actively welcome your pull requests:

1. Fork the repo and create your branch from `main`
2. If you've added code that should be tested, add tests
3. If you've changed APIs, update the documentation
4. Ensure the test suite passes
5. Make sure your code lints
6. Create the pull request

## Development Setup

### Prerequisites

- **Node.js** 20+ and npm/yarn
- **Python** 3.11+ with pip
- **Go** 1.21+
- **Java** 17+ and Maven
- **Kotlin** with Gradle
- **Docker** and Docker Compose
- **PostgreSQL** 15+
- **MongoDB** 6+
- **ClickHouse** 23+
- **Redis** 7+

### Setup Instructions

1. **Clone the repository**

   ```bash
   git clone https://github.com/your-org/pcc-lms.git
   cd pcc-lms
   ```

2. **Initialize the database**

   ```bash
   cp db/.env.example db/.env
   # Edit db/.env with your database configurations
   ./db/scripts/db-manager.sh init
   ```

3. **Choose your stack and setup environment**

   **FastAPI (Python)**:

   ```bash
   cd be/fastapi/auth-service
   python -m venv venv
   source venv/bin/activate  # On Windows: venv\Scripts\activate
   pip install -r requirements.txt
   ```

   **Express (Node.js)**:

   ```bash
   cd be/express/auth-service
   npm install
   ```

   **Go**:

   ```bash
   cd be/go/auth-service
   go mod tidy
   ```

   **Spring Boot (Java)**:

   ```bash
   cd be/sb-java/auth-service
   ./mvnw install
   ```

   **Spring Boot (Kotlin)**:

   ```bash
   cd be/sb-kotlin/auth-service
   ./gradlew build
   ```

4. **Run tests**

   ```bash
   # Database tests
   ./db/scripts/db-manager.sh status

   # Service tests (example for FastAPI)
   cd be/fastapi/auth-service
   pytest
   ```

## Pull Request Process

1. **Create a feature branch**

   ```bash
   git checkout -b feature/your-feature-name
   ```

2. **Make your changes**

   - Follow the coding standards
   - Add tests for new functionality
   - Update documentation as needed

3. **Test your changes**

   ```bash
   # Run relevant tests for your stack
   # Example for FastAPI:
   cd be/fastapi/your-service
   pytest
   black .
   ruff check .
   ```

4. **Commit your changes**

   ```bash
   git add .
   git commit -m "feat(service): add new feature"
   ```

5. **Push and create PR**
   ```bash
   git push origin feature/your-feature-name
   ```

## Coding Standards

### General Guidelines

- **All technical names** (files, folders, variables, functions, endpoints) must be in **English**
- **Documentation and comments** can be in Spanish or English
- Follow **Clean Architecture** principles
- Use **snake_case** for database objects
- Use **camelCase** for JSON payloads
- Use **kebab-case** for REST endpoints

### Language-Specific Standards

**Python (FastAPI)**:

- Use `black` for formatting
- Use `ruff` for linting
- Follow PEP 8
- Use type hints
- Functions and variables: `snake_case`
- Classes: `PascalCase`
- Constants: `UPPER_SNAKE_CASE`

**JavaScript/TypeScript (Express/Next.js)**:

- Use `prettier` for formatting
- Use `eslint` for linting
- Variables and functions: `camelCase`
- Classes: `PascalCase`
- Constants: `UPPER_SNAKE_CASE`

**Go**:

- Use `gofmt` for formatting
- Use `golangci-lint` for linting
- Follow Go naming conventions
- Exported functions: `PascalCase`
- Unexported functions: `camelCase`

**Java/Kotlin (Spring Boot)**:

- Use `spotless` or `google-java-format`
- Follow standard Java/Kotlin conventions
- Classes: `PascalCase`
- Methods and variables: `camelCase`
- Constants: `UPPER_SNAKE_CASE`

### Database Standards

- **Table names**: `snake_case`, plural (e.g., `users`, `course_modules`)
- **Column names**: `snake_case` (e.g., `created_at`, `user_id`)
- **Indexes**: `idx_table_column` format
- **Foreign keys**: `fk_table_referenced_table`

## Testing

### Test Structure

Each microservice should have:

```
tests/
├── unit/          # Unit tests for business logic
├── integration/   # Integration tests with database
├── e2e/          # End-to-end API tests
└── fixtures/     # Test data and mocks
```

### Test Guidelines

- **Unit tests**: Test business logic in isolation
- **Integration tests**: Test database interactions
- **E2E tests**: Test complete API endpoints
- **Coverage target**: Minimum 80% code coverage
- **Test naming**: Descriptive test names in English

### Running Tests

```bash
# Database integration tests
./db/scripts/db-manager.sh status

# Service-specific tests
cd be/{stack}/{service}
# Run stack-specific test command
```

## Documentation

### API Documentation

- Use **OpenAPI/Swagger** for REST APIs
- Document all endpoints with examples
- Include error responses and status codes
- Generate documentation automatically

### Code Documentation

- Document complex business logic
- Use docstrings for functions and classes
- Include usage examples for public APIs
- Keep documentation up to date with code changes

### Architecture Documentation

- Update `_docs/` folder when making architectural changes
- Document design decisions and trade-offs
- Include diagrams for complex workflows
- Update database schema documentation

## Commit Message Convention

Use [Conventional Commits](https://conventionalcommits.org/):

```
<type>[optional scope]: <description>

[optional body]

[optional footer(s)]
```

**Types**:

- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code style changes (formatting, etc.)
- `refactor`: Code refactoring
- `test`: Adding or modifying tests
- `chore`: Maintenance tasks

**Examples**:

```
feat(auth): add JWT token refresh functionality
fix(courses): resolve enrollment count calculation bug
docs(api): update authentication endpoint documentation
```

## Release Process

1. **Version Bump**: Update version in relevant files
2. **Changelog**: Update CHANGELOG.md with new features and fixes
3. **Tag Release**: Create git tag with version number
4. **Docker Images**: Build and push updated container images
5. **Documentation**: Update deployment documentation

## Getting Help

- **Documentation**: Check `_docs/` folder for detailed guides
- **Issues**: Search existing issues or create a new one
- **Discussions**: Use GitHub Discussions for questions
- **Discord**: Join our Discord community (link in README)

## Recognition

Contributors will be recognized in:

- CONTRIBUTORS.md file
- Release notes
- Annual contributor appreciation posts

Thank you for contributing to PCC LMS! 🚀
