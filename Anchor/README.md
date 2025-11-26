# Anchor iOS App

This directory contains the source code for the Anchor iOS application.

## Structure

- **AnchorApp/**: Main iOS application target
- **AnchorShieldExtension/**: Screen Time shield extension target
- **docs/**: Documentation and architecture diagrams

## Building

1. Open `Anchor.xcworkspace` (or create an Xcode project)
2. Select the appropriate target (AnchorApp or AnchorShieldExtension)
3. Build and run

## Targets

### AnchorApp
The main application that users interact with. Handles:
- Authentication
- Friend management
- Session configuration
- Unlock requests
- Backend communication

### AnchorShieldExtension
The Screen Time extension that displays a custom shield UI when blocked apps are opened.

## App Group

Both targets share data through an App Group container. Ensure the App Group identifier matches in:
- `AnchorApp/Config/AppConfig.swift`
- `AnchorShieldExtension/Shared/AppGroupStorage.swift`

