## Anchor Behavioral Analytics (Internal Only)

Purpose
- Measure product impact and behavioral outcomes without surveillance.
- Provide founders with aggregate, privacy-safe signals.

What We Track
- shield_hit: shield encounters, impulse recovery, app token hash.
- app_opened: app opens with anchored/free state and shield-to-open latency.
- pledge_completed: pledge completion with optional completion latency.
- emergency_unanchor_used: emergency usage frequency and duration.
- proof_submitted: proof submissions.
- profile_viewed: friends tab views (proxy for social surface exposure).
- anchor_state_changed: anchored/free transitions.

What We Do NOT Track
- Raw keystrokes, browsing logs, or content.
- Full blocked app lists or un-hashed app identifiers.
- Message or proof contents.
- Cross-app reconstruction of user activity.

Storage & Privacy
- Events stored locally in App Group container as JSONL.
- Hashing of app tokens with a per-install salt to avoid raw identifiers.
- No external analytics SDKs or network export.
- Log rotation keeps recent data only (default 14 days, size capped per file).
- Schema versioning included for safe evolution.
- Records include build type and a daily correlation ID (dayId) for aggregate analysis.

Build Gating
- Analytics is disabled by default in Release builds.
- Compile-time flag `ANALYTICS_ENABLED` can override in internal builds.

Future Export
- AnalyticsStorage can be extended to upload batches.
- AnalyticsServiceProtocol is stable for backend export.
- AnalyticsExportServiceProtocol provides a stubbed export pathway.

Notes
- Some metrics (challenge/invite flows) are defined but not instrumented until those flows exist.
