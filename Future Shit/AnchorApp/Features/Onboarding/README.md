# Onboarding Feature

## Overview
The Onboarding feature provides a first-time user experience that introduces the app's key features and guides users through necessary permission setup.

## Components

### Views
- **OnboardingView**: Main onboarding container
  - Multi-page introduction flow
  - Permission setup step
  - Page navigation with dots indicator

- **OnboardingPermissionStepView**: Permission request interface
  - Screen Time permission setup
  - Guides users through permission flow

### ViewModels
- **OnboardingViewModel**: Manages onboarding flow state
  - Tracks current page
  - Handles page navigation
  - Manages onboarding completion

## Onboarding Pages

1. **Welcome Page**: Introduces Anchor app
   - App icon and branding
   - Welcome message
   - Value proposition

2. **App Blocking Page**: Explains app blocking feature
   - Lock shield icon
   - Focus session explanation
   - Distraction blocking benefits

3. **Friends Accountability Page**: Introduces accountability feature
   - Friends icon
   - Accountability partner concept
   - Unlock request feature

4. **Permission Step**: Screen Time permission setup
   - Guides through permission request
   - Explains why permission is needed

## Flow
1. First app launch → `OnboardingView` displayed
2. User swipes through introduction pages
3. "Get Started" button → Transitions to permission step
4. Permission setup → User grants Screen Time permission
5. Onboarding complete → User proceeds to main app

## Features
- Smooth page transitions
- Visual page indicators
- Permission guidance
- First-time user education

## Dependencies
- `ScreenTimePermissionViewModel`: Permission management
- `AppGroupStorage`: Onboarding completion tracking

