# Open-Source LLM App

A cross-platform Flutter application that enables users to interact with open-source Large Language Models (LLMs) on Windows, Linux, Android, and iOS devices.

## Project Overview

This application provides a secure, high-performance interface for chatting with LLMs, browsing a marketplace of models, and managing user profiles. It is built following clean architecture principles and is designed to be cross-platform compatible.

## Features (Planned)

- Seamless LLM interaction experience on all major platforms
- Chat interface with file upload capability
- Marketplace for discovering and selecting open-source LLMs
- User profile management with theme customization
- Secure authentication and data storage
- Cross-device synchronization for logged-in users

## Current Progress

### Completed:
- Project setup and initial configuration
- Basic theme system implementation (Light/Dark/System modes)
- Navigation system with tab-based interface
- Splash screen implementation
- Basic UI placeholders for all main sections
- Cross-platform support (iOS, Android, Windows, macOS, Linux, Web)

### Next Steps:
- Gradually reintroduce advanced architecture components (BLoC, GetIt, GoRouter)
- Implement Ollama integration for LLM interactions
- Add authentication and user management
- Build out the functionality of each tab
- Implement form validation and error handling

## Simplified Architecture

We are currently using a simplified architecture to ensure the application runs smoothly across all platforms. This includes:

- Basic state management with StatefulWidget
- Simple navigation using MaterialPageRoute
- Direct theme management without complex state management

We plan to transition to a more robust architecture with BLoC pattern, dependency injection, and advanced routing as we resolve dependency conflicts.

## Getting Started

### Prerequisites
- Flutter 3.x (3.24.0+)
- Dart 3.x (3.4.4+)
- For development on specific platforms, their respective SDKs:
  - Android SDK
  - iOS SDK (macOS only)
  - Windows SDK
  - macOS SDK
  - Linux dependencies

### Installation

1. Clone the repository:
```
git clone <repository-url>
```

2. Navigate to the project directory:
```
cd llm_app
```

3. Install dependencies:
```
flutter pub get
```

4. Run the app:
```
flutter run
```

## Contributing

Please see our [CONTRIBUTING.md](CONTRIBUTING.md) for details on how to contribute to this project.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
