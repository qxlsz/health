# Contributing to Health Data Aggregator

Thank you for your interest in contributing to Health Data Aggregator! This document provides guidelines and instructions for contributing.

## Code of Conduct

- Be respectful and inclusive
- Welcome newcomers and help them learn
- Focus on constructive feedback
- Respect different viewpoints and experiences

## How to Contribute

### Reporting Bugs

1. Check if the bug has already been reported
2. Use a clear and descriptive title
3. Provide steps to reproduce the issue
4. Include environment details (OS, Flutter version, etc.)
5. Add screenshots if applicable

### Suggesting Features

1. Check if the feature has already been suggested
2. Use a clear and descriptive title
3. Provide a detailed description of the feature
4. Explain why this feature would be useful
5. Consider implementation complexity

### Pull Requests

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Make your changes
4. Follow the code style guidelines
5. Write or update tests if applicable
6. Commit your changes (`git commit -m 'Add some amazing feature'`)
7. Push to the branch (`git push origin feature/amazing-feature`)
8. Open a Pull Request

## Code Style

### Dart/Flutter

- Follow [Effective Dart](https://dart.dev/guides/language/effective-dart)
- Use trailing commas
- Prefer arrow functions when appropriate
- Use meaningful variable and function names
- Add comments for complex logic
- Run `dart format` before committing

### SQL

- Use meaningful table and column names
- Add comments for complex queries
- Follow PostgreSQL naming conventions (snake_case)

### Python

- Follow PEP 8 style guide
- Use type hints where appropriate
- Add docstrings for functions and classes

## Development Setup

1. Clone the repository
2. Set up Supabase (see README.md)
3. Create a `.env` file from `.env.example`
4. Run `flutter pub get`
5. Run `flutter pub run build_runner build` if needed
6. Start the app

## Testing

- Write unit tests for business logic
- Test authentication flows
- Test data sync services
- Verify RLS policies in Supabase

## Commit Messages

Use clear, descriptive commit messages:
- Use imperative mood ("Add feature" not "Added feature")
- Reference issues when applicable
- Keep the first line under 50 characters
- Add detailed description if needed

## Questions?

Feel free to open an issue for questions or reach out to the maintainers.

