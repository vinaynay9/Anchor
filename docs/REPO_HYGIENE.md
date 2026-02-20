# Repo Hygiene (Anchor)

This repo intentionally keeps **only source-of-truth files**. Generated artifacts and caches should never be committed.

## Source of Truth
- `AnchorApp/` — main app source
- `AnchorShieldExtension/` and `AnchorShieldActionExtension/` — extensions
- `Shared/` — shared models/services
- `infra/` — backend infra (SAM)
- `docs/` — documentation
- `.xcodeproj` / `.xcworkspace` — project metadata

## Never Commit (Generated)
- `DerivedData/`
- `Index.noindex/`, `ModuleCache.noindex/`, `SymbolCache.noindex/`, `CompilationCache.noindex/`
- `build/` / `Build/`
- `xcuserdata/`, `*.xcuserstate`
- `.swiftpm/` and `.build/`
- `.DS_Store`, editor swap files

## Local Cleanup (Safe)
From repo root:
```bash
./scripts/clean_local.sh
```

## Optional (Xcode DerivedData)
By default, the script **does not** delete global DerivedData. To do so:
```bash
./scripts/clean_local.sh --deriveddata
```

## Where Things Go
- Core app logic: `AnchorApp/Core/`
- UI feature modules: `AnchorApp/Features/`
- Shared models/services: `Shared/`
- Extensions: `AnchorShieldExtension/`, `AnchorShieldActionExtension/`
- Backend infra: `infra/`
