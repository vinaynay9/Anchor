# Contributing to Anchor

Thank you for your interest in contributing to Anchor! This document provides guidelines and instructions for contributing.

## Getting Started

1. Fork the repository
2. Clone your fork locally
3. Create a new branch for your feature or bugfix
4. Make your changes
5. Test thoroughly
6. Submit a pull request

## Development Setup

1. Ensure you have Xcode 15.0+ installed
2. Open the project in Xcode
3. Configure your App Group identifier
4. Set up your backend credentials (see `AnchorApp/Config/Secrets.example.swift`)
5. Build and run the project

## Code Style

- Follow Swift naming conventions
- Use SwiftUI best practices
- Maintain MVVM architecture
- Write clear, self-documenting code
- Add comments for complex logic

## Commit Messages

Use clear, descriptive commit messages:
- Use the imperative mood ("Add feature" not "Added feature")
- Keep the first line under 50 characters
- Add more detail in the body if needed

## Pull Requests

- Keep PRs focused on a single feature or bugfix
- Include a clear description of changes
- Reference any related issues
- Ensure all tests pass
- Update documentation as needed

## Testing

- Test on physical devices when possible (Screen Time APIs require this)
- Test both the main app and shield extension
- Verify App Group communication works correctly

## Questions?

Feel free to open an issue for questions or discussions about the project.

