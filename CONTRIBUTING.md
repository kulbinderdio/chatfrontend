# Contributing to MacOS AI Chat App

Thank you for considering contributing to the MacOS AI Chat App! This document provides guidelines and instructions for contributing to the project.

## Code of Conduct

Please be respectful and considerate of others when contributing to this project. We aim to foster an inclusive and welcoming community.

## How to Contribute

### Reporting Bugs

If you find a bug, please create an issue with the following information:

1. A clear, descriptive title
2. Steps to reproduce the bug
3. Expected behavior
4. Actual behavior
5. Screenshots (if applicable)
6. Environment information (macOS version, app version)

### Suggesting Features

Feature suggestions are welcome! Please create an issue with:

1. A clear, descriptive title
2. A detailed description of the proposed feature
3. Any relevant mockups or examples
4. Why this feature would be beneficial

### Pull Requests

1. Fork the repository
2. Create a new branch from `main`
3. Make your changes
4. Run tests to ensure they pass
5. Submit a pull request

Please include a clear description of the changes and reference any related issues.

## Development Setup

1. Clone the repository:
   ```bash
   git clone https://github.com/yourusername/macoschatapp.git
   cd macoschatapp
   ```

2. Open the project in Xcode:
   ```bash
   open MacOSChatApp.xcodeproj
   ```

3. Build and run the project

## Project Structure

The project follows the MVVM (Model-View-ViewModel) architecture:

- **Models**: Data structures and business logic
- **Views**: User interface components
- **ViewModels**: Mediators between Models and Views

### Directory Structure

```
MacOSChatApp/
├── App/
│   └── MacOSChatApp.swift
├── UI/
│   ├── Views/
│   │   ├── ChatView.swift
│   │   ├── SettingsView.swift
│   │   └── ProfilesView.swift
│   ├── Components/
│   │   ├── MessageBubble.swift
│   │   ├── DocumentDropArea.swift
│   │   └── MenuBarComponent.swift
│   └── ViewModels/
│       ├── ChatViewModel.swift
│       └── SettingsViewModel.swift
├── Data/
│   ├── Models/
│   │   ├── Message.swift
│   │   ├── Conversation.swift
│   │   └── ModelProfile.swift
│   ├── Managers/
│   │   ├── DatabaseManager.swift
│   │   ├── KeychainManager.swift
│   │   └── UserDefaultsManager.swift
│   └── Services/
│       ├── APIClient.swift
│       └── DocumentHandler.swift
└── Utils/
    ├── Extensions/
    └── Constants.swift
```

## Coding Guidelines

### Swift Style Guide

- Follow the [Swift API Design Guidelines](https://swift.org/documentation/api-design-guidelines/)
- Use Swift's native conventions and idioms
- Write clear, self-documenting code with descriptive names

### Formatting

- Use 4 spaces for indentation
- Keep lines to a reasonable length (around 100 characters)
- Use blank lines to separate logical sections of code

### Documentation

- Add comments for complex logic
- Use documentation comments (`///`) for public APIs
- Keep documentation up-to-date with code changes

### Testing

- Write unit tests for new functionality
- Ensure existing tests pass before submitting a PR
- Aim for good test coverage

## Git Workflow

1. Create a branch for your feature or bugfix:
   ```bash
   git checkout -b feature/your-feature-name
   ```
   or
   ```bash
   git checkout -b fix/your-bugfix-name
   ```

2. Make your changes and commit them with clear, descriptive messages:
   ```bash
   git commit -m "Add feature: description of the feature"
   ```

3. Push your branch to your fork:
   ```bash
   git push origin feature/your-feature-name
   ```

4. Create a pull request against the `main` branch

## Release Process

1. Version numbers follow [Semantic Versioning](https://semver.org/)
2. Releases are tagged in Git
3. Release notes document significant changes

## License

By contributing to this project, you agree that your contributions will be licensed under the project's [MIT License](LICENSE).

## Questions?

If you have any questions or need help, please create an issue or reach out to the maintainers.

Thank you for contributing to the MacOS AI Chat App!
