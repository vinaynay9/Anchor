# Anchor

Anchor is a native iOS app built with Swift and SwiftUI that helps users stay accountable to their goals by blocking distracting apps using Apple's Screen Time APIs.

## Features

- **Screen Time Integration**: Uses Apple's FamilyControls and ManagedSettings to block selected apps during focus sessions
- **Custom Shield Screen**: Displays a custom UI when blocked apps are opened
- **Authentication**: Email + password

## Architecture

The app consists of two iOS targets:

1. **AnchorApp**: Main iOS application
   - SwiftUI-based user interface
   - MVVM architecture
   - Handles authentication, session configuration, and backend communication

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
4. Set up your backend and update API endpoints
5. Build and run

## Secrets

- Secrets are stored only in `AnchorApp/Config/Secrets.swift` (git-ignored).
- Do not store AWS access keys in the app. Use temporary credentials or a backend.
- `Secrets.swift` stores only non-secret bootstrap values (API base URL and remote config path).

## Local Setup (Required)

1. Ensure `AnchorApp/Config/Secrets.swift` exists (git-ignored)
2. Set `apiBaseURL` and `remoteConfigPath` in `AnchorApp/Config/Secrets.swift`

## Security Notes

- Never commit `AnchorApp/Config/Secrets.swift`.
- Never put AWS access keys in the iOS app.

## Configuration

### App Group

The app uses an App Group to share data between the main app and shield extension. Configure this in:
- `AnchorApp/Config/AppConfig.swift`: `appGroupIdentifier`
- `AnchorShieldExtension/Shared/AppGroupStorage.swift`: Must match the main app's identifier
The required App Group identifier is: `group.com.vinay.anchor`

### Backend

Update the backend configuration in `AnchorApp/Config/AppConfig.swift` as needed.

### Remote Config

The app calls:
`GET {apiBaseURL}{remoteConfigPath}` (default: `/config`)

The backend (Lambda or equivalent) reads AWS Secrets Manager and returns non-secret configuration required by the app. Secrets never ship in the app bundle.
The endpoint is protected with an auth token; the app authenticates with email + password and sends `Authorization: Bearer <token>`.

Example JSON:
```json
{
  "awsRegion": "us-east-1",
  "updatedAtISO": "2026-02-17T00:00:00Z"
}
```

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

## Anchor V0 Analytics — Current DynamoDB Schema (Implemented)

The analytics backend schema is documented in `infra/aws-v0/README.md`. This reflects the **current deployed** tables and field conventions (flattened daily metrics, weekly rollups, and global aggregates).

## License

[Add your license here]

## Contributing

[Add contributing guidelines here]
