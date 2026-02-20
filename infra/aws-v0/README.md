# Anchor V0 Analytics (SAM)

## Anchor V0 Analytics — Current DynamoDB Schema (Implemented)

This reflects the **currently deployed** analytics backend in `infra/aws-v0` and the data the app sends today.
All timestamps are stored as **ISO-8601 strings**.

### 1) `anchor_v0_users`
**Key schema**
- PK: `user_id` (string UUID)

**Purpose**
- Stores per-user profile fields and lifetime aggregates.

**Fields (current)**
- `user_id` (string)
- `timezone` (string)
- `display_name` (string)
- `birth_month` (number/int)
- `birth_day` (number/int)
- `created_at` (string, ISO)
- `last_active_at` (string, ISO)
- `lifetime_goals_completed` (number)
- `lifetime_social_minutes` (number)
- `lifetime_sessions` (number)
- `lifetime_shield_hits` (number)

---

### 2) `anchor_v0_daily_metrics`
**Key schema**
- PK: `user_id` (string)
- SK: `date` (string `YYYY-MM-DD`)

**Purpose**
- One row per user per day. Flattened metrics (no nested map).

**Fields (current)**
- `user_id` (string)
- `date` (string, `YYYY-MM-DD`)
- `timezone` (string)
- `daily_reset_session_start_time` (number)
- `daily_session_start_time` (string, optional `HH:MM:SS`)
- `social_minutes` (number)
- `video_game_minutes` (number)
- `streaming_minutes` (number)
- `shopping_minutes` (number)
- `news_minutes` (number)
- `sports_minutes` (number)
- `goals_completed` (number)
- `shield_hits` (number)
- `session_count` (number)
- `session_total_minutes` (number)
- `created_at` (string, ISO)
- `updated_at` (string, ISO)

---

### 3) `anchor_v0_weekly_metrics`
**Key schema**
- PK: `user_id` (string)
- SK: `week_start` (string `YYYY-MM-DD`)

**Purpose**
- Weekly rollup aggregates (Monday week start).

**Fields (current)**
- `user_id` (string)
- `week_start` (string, Monday `YYYY-MM-DD`)
- `total_social_minutes` (number)
- `total_video_game_minutes` (number)
- `total_streaming_minutes` (number)
- `total_shopping_minutes` (number)
- `total_news_minutes` (number)
- `total_sports_minutes` (number)
- `total_goals_completed` (number)
- `total_shield_hits` (number)
- `total_sessions` (number)
- `total_session_minutes` (number)
- `goal_completion_rate` (number)
- `created_at` (string, ISO)

**Week start convention**
- `week_start` is **Monday** in UTC.
- Rollup range is **Mon–Sun** inclusive (`week_start`..`week_start + 6 days`).
- Manual rollup invocations use **STRICT** validation: if `week_start` is not a Monday UTC date, the lambda returns `400 bad_request` and performs no writes.

---

### 4) `anchor_v0_global_metrics`
**Key schema**
- PK: `metric_name` (string)
- SK: `period` (string `YYYY-MM-DD`)

**Purpose**
- Global weekly aggregates written by rollup.

**Fields (current)**
- `metric_name` (string)
- `period` (string, Monday `YYYY-MM-DD`)
- `value` (number)
- `updated_at` (string, ISO)

---

## Notes on GlobalMetricsTable Changes

CloudFormation cannot replace a **custom-named** DynamoDB table when the key schema changes.
If the stack update fails due to this, you must do a one-time manual deletion of the existing
`anchor_v0_global_metrics` table (only if you are okay with losing that legacy data), then re-deploy.

---

## Verification (CLI)

### Describe table key schema
```bash
aws dynamodb describe-table --profile anchor --region us-east-1 --table-name anchor_v0_users --query 'Table.KeySchema'
aws dynamodb describe-table --profile anchor --region us-east-1 --table-name anchor_v0_daily_metrics --query 'Table.KeySchema'
aws dynamodb describe-table --profile anchor --region us-east-1 --table-name anchor_v0_weekly_metrics --query 'Table.KeySchema'
aws dynamodb describe-table --profile anchor --region us-east-1 --table-name anchor_v0_global_metrics --query 'Table.KeySchema'
```

### Get-item examples (empty result is normal if item not present)
```bash
aws dynamodb get-item --profile anchor --region us-east-1 --table-name anchor_v0_users \
  --key '{"user_id":{"S":"example-user-id"}}'

aws dynamodb get-item --profile anchor --region us-east-1 --table-name anchor_v0_daily_metrics \
  --key '{"user_id":{"S":"example-user-id"},"date":{"S":"2026-02-20"}}'

aws dynamodb get-item --profile anchor --region us-east-1 --table-name anchor_v0_weekly_metrics \
  --key '{"user_id":{"S":"example-user-id"},"week_start":{"S":"2026-02-16"}}'

aws dynamodb get-item --profile anchor --region us-east-1 --table-name anchor_v0_global_metrics \
  --key '{"metric_name":{"S":"active_users"},"period":{"S":"2026-02-16"}}'

### Manual rollup examples (STRICT mode)
```bash
# Valid Monday
aws lambda invoke --profile anchor --region us-east-1 \
  --function-name "$ROLLUP_FN" \
  --cli-binary-format raw-in-base64-out \
  --payload '{"user_id":"example-user-id","week_start":"2026-02-16"}' /tmp/rollup_ok.json

# Invalid (not Monday) -> 400 bad_request, no writes
aws lambda invoke --profile anchor --region us-east-1 \
  --function-name "$ROLLUP_FN" \
  --cli-binary-format raw-in-base64-out \
  --payload '{"user_id":"example-user-id","week_start":"2026-02-18"}' /tmp/rollup_bad.json
```
```
