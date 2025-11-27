# App Selection Feature

## Overview
The App Selection feature allows users to select which apps should be blocked during focus sessions using iOS Family Controls framework.

## Components

### Views
- **SelectAppsView**: Main app selection interface
  - Displays selected apps
  - Shows app count badge
  - Provides "Select Apps" button to open picker
  - Clear selection option
  - Error message display

- **FamilyActivityPickerRepresentable**: UIKit wrapper for FamilyActivityPicker
  - Bridges SwiftUI to UIKit Family Controls
  - Handles picker presentation and dismissal

### ViewModels
- **SelectAppsViewModel**: Manages app selection state
  - Stores selected app tokens
  - Updates selection from picker
  - Clears selection
  - Handles errors

## Features
- Select multiple apps to block
- View selected app count
- Clear all selections
- Error handling for permission issues
- Integration with Family Controls framework

## How It Works
1. User taps "Select Apps" → Family Activity Picker opens
2. User selects apps from system picker
3. Picker returns app tokens (privacy-preserving identifiers)
4. Tokens stored in `selectedAppTokens`
5. Tokens used by `ScreenTimeService` to block apps during sessions

## Important Notes
- Uses iOS Family Controls framework (iOS 15+)
- App tokens are privacy-preserving (cannot identify specific apps)
- Requires Screen Time permission
- Tokens persist across app launches
- Tokens are used to configure `FamilyActivityPicker` and `EventStore`

## Dependencies
- `FamilyControls` framework
- `ActivitySelectionService`: App selection persistence
- `ScreenTimeService`: App blocking implementation

