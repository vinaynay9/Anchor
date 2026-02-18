# Proofs Feature

## Overview
The Proofs feature allows users to capture and view photo proofs during focus sessions, providing visual accountability evidence.

## Components

### Views
- **ProofGalleryView**: Displays all proofs for a session
  - Grid layout of proof thumbnails
  - Shows loading and empty states
  - Navigates to proof details

- **ProofCaptureView**: Camera interface for capturing proofs
  - Live camera preview
  - Photo capture functionality
  - Retake and use photo options

- **ProofUploadView**: Handles proof upload after capture
  - Uploads captured image to server
  - Shows upload progress
  - Associates proof with session

- **CaptureProofView**: Alternative proof capture interface

### ViewModels
- **ProofViewModel**: Manages proof data and operations
  - Loads proofs for sessions
  - Handles proof retrieval
  - Manages proof state

- **ProofCaptureViewModel**: Handles proof capture logic
  - Manages camera state
  - Processes captured images
  - Handles photo upload

## Features
- Capture photos during sessions
- Upload proofs to server
- View proof gallery per session
- Display proof thumbnails
- Associate proofs with specific sessions

## Flow
1. During active session → User opens proof capture
2. Camera interface → User captures photo
3. Review captured image → User confirms or retakes
4. Upload proof → Image uploaded and associated with session
5. View in gallery → Proof appears in session's proof gallery

## Dependencies
- `ProofService`: Core proof management and upload
- `SessionService`: Session association
- Camera permissions and UIKit integration

