# Auth Feature

## Overview
The Auth feature handles user authentication, sign-in, and initial username setup for new users.

## Components

### Views
- **AuthRootView**: Root authentication view that manages the authentication flow
  - Shows `SignInOptionsView` when user is not authenticated
  - Shows `UsernameSetupView` for new users who need to set up their username
  - Transitions to main app once authenticated and username is set

- **SignInOptionsView**: Displays sign-in options for users
- **UsernameSetupView**: Allows new users to set up their username

### ViewModels
- **AuthViewModel**: Manages authentication state and user data
  - Tracks current user
  - Handles username setup requirement
  - Manages authentication flow

## Flow
1. User opens app → `AuthRootView` checks authentication status
2. If not authenticated → Shows `SignInOptionsView`
3. After sign-in → Checks if username is set
4. If username not set → Shows `UsernameSetupView`
5. Once authenticated and username set → Proceeds to main app

## Dependencies
- `AuthService`: Core authentication service
- `UserService`: User data management

