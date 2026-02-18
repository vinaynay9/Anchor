# Anchor V0

Anchor V0 is a SwiftUI iOS app that uses Screen Time controls to lock distracting apps until users complete their daily goals. V0 is intentionally minimal and local‑first. Social accountability features (friends, proofs, unlock requests) are not part of V0 and are archived for future work.

## Current V0 Flow

1. Sign in
2. Set goals with multi‑select categories
3. Choose unlock mode + time/percent rules
4. Select apps/categories and apply presets
5. Home shows locked state, usage summary, and goals
6. Goal completion requires the affirmation phrase
7. Daily reset at midnight (configurable with friction phrase)

## Architecture Notes

- SwiftUI + MVVM
- `ScreenTimeService` handles FamilyControls/ManagedSettings
- `AppGroupStorage` is the source of truth for app ↔ shield state
- Shield extension is lightweight and reads V0 state only

## How To Run

1. Open `Anchor.xcodeproj`
2. Build `AnchorApp`
3. Run on a real device (required for Screen Time)
4. Authorize Screen Time when prompted
5. Select apps/categories and complete onboarding

## Entitlements

- App Group: `group.com.anchor.app`
- Family Controls capability enabled for `AnchorApp` and Shield extension

## Project Structure (V0)

```
Anchor/
├── AnchorApp/
│   ├── Config/
│   ├── Core/
│   │   ├── DesignSystem/
│   │   ├── Services/ (ScreenTimeService + V0 services)
│   │   └── Utilities/
│   └── Features/
│       ├── V0Onboarding/
│       ├── V0Home/
│       └── V0Settings/
├── Shared/
│   ├── Models/ (V0 models)
│   ├── Messaging/ (V0 shield messages)
│   └── Storage/ (AppGroupStorage)
├── AnchorShieldExtension/
└── Future Shit/  # Archived legacy features; not built
```

## Roadmap (V1+)

- Friends / social accountability
- Proofs and unlock requests
- Additional analytics and insights
