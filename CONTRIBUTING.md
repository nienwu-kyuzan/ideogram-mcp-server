# Contributing to Ideogram MCP Server

Thank you for your interest in contributing to the Ideogram MCP Server! We welcome contributions from the community.

## 📋 Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [Development Setup](#development-setup)
- [Making Changes](#making-changes)
- [Coding Standards](#coding-standards)
- [Testing](#testing)
- [Pull Request Process](#pull-request-process)
- [Reporting Issues](#reporting-issues)

## Code of Conduct

This project follows a standard code of conduct. By participating, you are expected to:

- Be respectful and inclusive
- Use welcoming and inclusive language
- Be collaborative and constructive
- Focus on what is best for the community
- Show empathy towards other community members

## Getting Started

### Prerequisites

- **Node.js** 18.0.0 or higher
- **npm** 9.0.0 or higher
- An **Ideogram API key** for testing (get one at [ideogram.ai/manage-api](https://ideogram.ai/manage-api))
- Git for version control

### Development Setup

1. **Fork the repository**

   Click the "Fork" button on GitHub to create your own copy.

2. **Clone your fork**

   ```bash
   git clone https://github.com/YOUR_USERNAME/ideogram-mcp-server.git
   cd ideogram-mcp-server
   ```

3. **Install dependencies**

   ```bash
   npm install
   ```

4. **Set up environment variables**

   ```bash
   cp .env.example .env
   # Edit .env and add your IDEOGRAM_API_KEY
   ```

5. **Build the project**

   ```bash
   npm run build
   ```

6. **Run tests to verify setup**

   ```bash
   npm test
   ```

## Making Changes

### Branch Naming Convention

Create a descriptive branch name:

- `feature/add-batch-processing` - New features
- `fix/rate-limit-handling` - Bug fixes
- `docs/update-api-reference` - Documentation updates
- `refactor/improve-error-handling` - Code refactoring
- `test/add-integration-tests` - Test additions

### Commit Message Guidelines

Follow the [Conventional Commits](https://www.conventionalcommits.org/) specification:

```
<type>(<scope>): <description>

[optional body]

[optional footer]
```

**Types:**
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Formatting, missing semicolons, etc.
- `refactor`: Code refactoring
- `test`: Adding or updating tests
- `chore`: Maintenance tasks

**Examples:**
```
feat(tools): add support for style presets
fix(client): handle rate limit response correctly
docs(readme): update Claude Desktop setup instructions
test(generate): add edge case tests for aspect ratios
```

## Coding Standards

### TypeScript Guidelines

- **Strict mode**: All code must compile with `strict: true`
- **No `any` types**: Use proper typing or `unknown` with type guards
- **Explicit return types**: All exported functions should have explicit return types
- **Use Zod for validation**: Input validation must use Zod schemas

### Code Style

The project uses ESLint and Prettier. Run before committing:

```bash
npm run lint        # Check for issues
npm run lint:fix    # Auto-fix issues
npm run format      # Format with Prettier
```

### File Organization

```
src/
├── config/         # Configuration and constants
├── services/       # Core business logic
├── tools/          # MCP tool implementations
├── types/          # TypeScript type definitions
├── utils/          # Shared utilities
└── __tests__/      # Test files
```

### Best Practices

1. **Error Handling**
   - Use `IdeogramMCPError` for all custom errors
   - Include user-friendly messages
   - Mark errors as retryable when appropriate

2. **Logging**
   - Use the structured logger from `utils/logger.ts`
   - Don't log sensitive information (API keys, credentials)
   - Use appropriate log levels (debug, info, warn, error)

3. **Testing**
   - Write tests for new features
   - Maintain >90% code coverage
   - Use mocks for external API calls

## Testing

### Running Tests

```bash
# Run all tests
npm test

# Run with coverage
npm run test:coverage

# Run specific test file
npm test -- --run src/__tests__/unit/tools.test.ts

# Run tests in watch mode
npm run test:watch
```

### Test Categories

- **Unit tests** (`src/__tests__/unit/`): Test individual functions and classes
- **Integration tests** (`src/__tests__/integration/`): Test component interactions

### Writing Tests

```typescript
import { describe, it, expect, vi } from 'vitest';

describe('MyFeature', () => {
  it('should do something correctly', () => {
    // Arrange
    const input = 'test';

    // Act
    const result = myFunction(input);

    // Assert
    expect(result).toBe('expected');
  });
});
```

### Coverage Requirements

| Metric | Minimum |
|--------|---------|
| Statements | 90% |
| Branches | 85% |
| Functions | 75% |
| Lines | 90% |

## Pull Request Process

### Before Submitting

1. **Update your branch** with the latest main:
   ```bash
   git fetch origin
   git rebase origin/main
   ```

2. **Run all checks**:
   ```bash
   npm run lint
   npm run typecheck
   npm test
   npm run build
   ```

3. **Update documentation** if needed (README, API docs, etc.)

### Submitting a PR

1. Push your branch to your fork
2. Open a Pull Request against `main`
3. Fill out the PR template with:
   - Description of changes
   - Related issue numbers
   - Testing performed
   - Screenshots (if UI-related)

### PR Review Process

1. **Automated checks** must pass (tests, lint, build)
2. **Code review** by maintainers
3. **Address feedback** with additional commits
4. **Squash and merge** when approved

### After Merge

- Delete your feature branch
- Pull the latest main to your local repo

## Reporting Issues

### Bug Reports

Include:
- **Description**: What happened vs. what you expected
- **Steps to reproduce**: Minimal steps to trigger the bug
- **Environment**: Node.js version, OS, etc.
- **Error messages**: Full error output if applicable
- **Screenshots**: If relevant

### Feature Requests

Include:
- **Use case**: Why you need this feature
- **Proposed solution**: How you envision it working
- **Alternatives considered**: Other approaches you've thought about

### Security Issues

For security vulnerabilities, please **do not** open a public issue. Instead, contact the maintainers directly.

## Questions?

If you have questions that aren't covered here, please open a discussion or issue on GitHub.

---

Thank you for contributing! 🙏
