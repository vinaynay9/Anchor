# Sessions Feature

## Overview
The Sessions feature manages focus sessions where users block distracting apps and stay accountable with friends.

## Components

### Views
- **SessionHomeView**: Main sessions view
  - Shows active session summary if one exists
  - Displays call-to-action to start new session when none active
  - Shows session duration, end time, and accountability partner info

- **SessionSetupView**: Session creation and configuration
  - Allows selecting apps to block
  - Sets session duration
  - Selects accountability partners

- **ActiveSessionView**: View for active session management
  - Shows current session status
  - Displays time remaining
  - Provides session controls

- **CreateSessionView**: Alternative session creation interface
- **ActivityPickerView**: UI for selecting activities/apps

### ViewModels
- **SessionViewModel**: Manages session state and operations
  - Creates and manages active sessions
  - Loads session data
  - Handles session lifecycle

- **CreateSessionViewModel**: Handles session creation logic
- **ActiveSessionMockViewModel**: Mock view model for testing

## Features
- Create focus sessions with custom duration
- Select apps to block during session
- Add accountability partners
- Track active session status
- View session history

## Dependencies
- `SessionService`: Core session management
- `ScreenTimeService`: App blocking functionality
- `FriendService`: Accountability partner management
- `ActivitySelectionService`: App selection management

