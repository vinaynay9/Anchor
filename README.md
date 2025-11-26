# Anchor

Anchor is a native iOS app built with Swift and SwiftUI that helps users stay accountable to their goals by blocking distracting apps using Apple's Screen Time APIs. The app includes social accountability features: friends, photo proof of activities, and friend-approved unlocks.

## Features

- **Screen Time Integration**: Uses Apple's FamilyControls and ManagedSettings to block selected apps during focus sessions
- **Custom Shield Screen**: Displays a custom UI when blocked apps are opened
- **Social Accountability**: Add friends and request unlocks with photo proof
- **Friend-Approved Unlocks**: Friends can approve or deny unlock requests
- **Photo Proof**: Capture and share proof of completed activities
- **Authentication**: Supports Apple Sign-In and Google Sign-In

## Architecture

The app consists of two iOS targets:

1. **AnchorApp**: Main iOS application
   - SwiftUI-based user interface
   - MVVM architecture
   - Handles authentication, friend management, session configuration, and backend communication

2. **AnchorShieldExtension**: Screen Time shield extension
   - Custom shield UI shown when blocked apps are opened
   - Reads session state from shared App Group storage

## Project Structure

```
Anchor/
├── AnchorApp/              # Main iOS application
│   ├── Config/            # App configuration and secrets
│   ├── Core/              # Core models, networking, services, design system
│   ├── Features/          # Feature modules (Auth, Friends, Sessions, etc.)
│   └── Utilities/         # Extensions and utilities
├── AnchorShieldExtension/ # Screen Time shield extension
└── docs/                  # Documentation and diagrams
    └── diagrams/          # Mermaid architecture diagrams
```

## Requirements

- iOS 16.0+
- Xcode 15.0+
- Swift 5.9+
- Apple Developer Account (for Screen Time APIs)

## Setup

1. Clone the repository
2. Open the project in Xcode
3. Configure the App Group identifier in `AnchorApp/Config/AppConfig.swift`
4. Set up your backend (Supabase or similar) and update API endpoints
5. Configure authentication providers (Apple Sign-In, Google Sign-In)
6. Build and run

## Configuration

### App Group

The app uses an App Group to share data between the main app and shield extension. Configure this in:
- `AnchorApp/Config/AppConfig.swift`: `appGroupIdentifier`
- `AnchorShieldExtension/Shared/AppGroupStorage.swift`: Must match the main app's identifier

### Backend

Update the backend configuration in `AnchorApp/Config/AppConfig.swift`:
- `apiBaseURL`: Your Supabase or backend URL
- Create `Secrets.swift` from `Secrets.example.swift` and add your API keys

### Screen Time Permissions

The app requires Screen Time authorization to block apps. Users will be prompted to grant this permission when starting their first session.

## Development

### Code Style

- Follow Swift naming conventions
- Use SwiftUI best practices
- MVVM architecture for view models
- Protocol-oriented design for services

### Testing

- Unit tests for view models and services
- UI tests for critical user flows
- Test Screen Time integration on physical devices

## Documentation

See `docs/diagrams/` for architecture diagrams:
- `architecture.md`: System architecture overview
- `data-model.md`: Database schema and relationships
- `screen-time-flow.md`: Screen Time integration flows
- `friend-unlock-sequence.md`: Unlock request flow

## License

[Add your license here]

## Contributing

[Add contributing guidelines here]

