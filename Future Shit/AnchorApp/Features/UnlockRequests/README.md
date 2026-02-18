# Unlock Requests Feature

## Overview
The Unlock Requests feature allows users to request temporary access to blocked apps from their accountability partners during an active session.

## Components

### Views
- **UnlockRequestView** (User): Interface for users to create unlock requests
  - Text editor for entering unlock reason
  - Character limit (200 characters)
  - Send request functionality

- **UnlockRequestDetailView**: View for reviewing incoming unlock requests
  - Shows request details and reason
  - Allows approving or denying requests

### ViewModels
- **UnlockRequestViewModel**: Manages unlock request creation
  - Validates request input
  - Sends requests to accountability partners
  - Handles request state

- **UnlockRequestsViewModel**: Manages incoming unlock requests
  - Loads pending requests
  - Handles approve/deny actions

## Features
- Create unlock requests with reason
- Send requests to accountability partners
- Review incoming unlock requests
- Approve or deny unlock requests
- Temporary app access when approved

## Flow
1. User needs app access during session → Opens `UnlockRequestView`
2. User enters reason → Sends request to accountability partner
3. Partner receives notification → Reviews request in `UnlockRequestDetailView`
4. Partner approves/denies → User receives response
5. If approved → Temporary unlock granted

## Dependencies
- `UnlockRequestService`: Core unlock request management
- `NotificationService`: Request notifications
- `SessionService`: Session state management

