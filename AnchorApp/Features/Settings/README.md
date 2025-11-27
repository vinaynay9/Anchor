# Settings Feature

## Overview
The Settings feature provides app configuration, user preferences, and account management options.

## Components

### Views
- **SettingsView**: Main settings interface
  - Account section (profile, display name)
  - Notifications section (session reminders, unlock alerts)
  - Privacy section (clear data, export logs)
  - About section (version, privacy policy, terms)

- **NotificationSettingsView**: Detailed notification preferences
- **ScreenTimePermissionView**: Screen Time permission management
- **SettingsRowView**: Reusable settings row component

### ViewModels
- **SettingsViewModel**: Manages settings state and actions
  - Handles profile editing
  - Manages notification preferences
  - Handles data export and clearing
  - Opens external links (privacy policy, terms)

- **ScreenTimePermissionViewModel**: Manages Screen Time permissions
  - Checks permission status
  - Guides users through permission setup

## Features
- Edit user profile and display name
- Configure notification preferences
- Manage Screen Time permissions
- Clear local data
- Export activity logs
- Access privacy policy and terms
- View app version

## Sections

### Account
- Edit Profile
- Change Display Name

### Notifications
- Session Reminders toggle
- Unlock Request Alerts toggle

### Privacy
- Clear Local Data (with confirmation)
- Export Activity Log

### About
- App Version
- Privacy Policy link
- Terms link

## Dependencies
- `UserService`: User profile management
- `NotificationService`: Notification preferences
- `ScreenTimeService`: Permission management

