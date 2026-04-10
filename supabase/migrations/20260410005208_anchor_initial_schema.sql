-- ============================================================
-- Anchor — Initial Schema
-- Generated from SUPABASE_SETUP.md
-- ============================================================


-- ────────────────────────────────────────────
-- USERS
-- ────────────────────────────────────────────
create table if not exists public.users (
    id              uuid primary key references auth.users(id) on delete cascade,
    email           text,
    display_name    text,
    created_at      timestamptz not null default now(),
    updated_at      timestamptz not null default now()
);

alter table public.users enable row level security;

create policy "Users can read their own row"
    on public.users for select
    using (auth.uid() = id);

create policy "Users can update their own row"
    on public.users for update
    using (auth.uid() = id);

create policy "Users can insert their own row"
    on public.users for insert
    with check (auth.uid() = id);

create policy "Users can delete their own row"
    on public.users for delete
    using (auth.uid() = id);


-- ────────────────────────────────────────────
-- HABITS (Goals)
-- ────────────────────────────────────────────
create table if not exists public.habits (
    id          uuid primary key default gen_random_uuid(),
    user_id     uuid not null references public.users(id) on delete cascade,
    title       text not null,
    category    text not null default 'other',
    is_active   boolean not null default true,
    created_at  timestamptz not null default now(),
    updated_at  timestamptz not null default now()
);

alter table public.habits enable row level security;

create policy "Users manage their own habits"
    on public.habits for all
    using (auth.uid() = user_id)
    with check (auth.uid() = user_id);


-- ────────────────────────────────────────────
-- BLOCKING PREFERENCES
-- ────────────────────────────────────────────
create table if not exists public.blocking_preferences (
    user_id         uuid primary key references public.users(id) on delete cascade,
    schedule_json   text,
    policy_json     text,
    updated_at      timestamptz not null default now()
);

alter table public.blocking_preferences enable row level security;

create policy "Users manage their own blocking prefs"
    on public.blocking_preferences for all
    using (auth.uid() = user_id)
    with check (auth.uid() = user_id);


-- ────────────────────────────────────────────
-- REWARD RULES
-- ────────────────────────────────────────────
create table if not exists public.reward_rules (
    user_id     uuid primary key references public.users(id) on delete cascade,
    rules_json  text,
    updated_at  timestamptz not null default now()
);

alter table public.reward_rules enable row level security;

create policy "Users manage their own reward rules"
    on public.reward_rules for all
    using (auth.uid() = user_id)
    with check (auth.uid() = user_id);


-- ────────────────────────────────────────────
-- EVENTS
-- ────────────────────────────────────────────
create table if not exists public.events (
    id              bigserial primary key,
    user_id         uuid not null references public.users(id) on delete cascade,
    category        text not null,
    occurred_at     timestamptz not null default now(),
    payload         jsonb
);

alter table public.events enable row level security;

create policy "Users manage their own events"
    on public.events for all
    using (auth.uid() = user_id)
    with check (auth.uid() = user_id);


-- ────────────────────────────────────────────
-- EMERGENCY UNLOCKS
-- ────────────────────────────────────────────
create table if not exists public.emergency_unlocks (
    id              bigserial primary key,
    user_id         uuid not null references public.users(id) on delete cascade,
    reason          text,
    outcome         text not null default 'pending',
    requested_at    timestamptz not null default now()
);

alter table public.emergency_unlocks enable row level security;

create policy "Users manage their own emergency unlocks"
    on public.emergency_unlocks for all
    using (auth.uid() = user_id)
    with check (auth.uid() = user_id);


-- ────────────────────────────────────────────
-- ERRORS
-- ────────────────────────────────────────────
create table if not exists public.errors (
    id              bigserial primary key,
    user_id         uuid references public.users(id) on delete set null,
    message         text not null,
    stack_trace     text,
    context         text,
    occurred_at     timestamptz not null default now()
);

alter table public.errors enable row level security;

create policy "Users can insert their own errors"
    on public.errors for insert
    with check (auth.uid() = user_id or user_id is null);

create policy "Users can read their own errors"
    on public.errors for select
    using (auth.uid() = user_id);


-- ────────────────────────────────────────────
-- DAILY AGGREGATES
-- ────────────────────────────────────────────
create table if not exists public.daily_aggregates (
    user_id                     uuid not null references public.users(id) on delete cascade,
    date                        date not null,
    locked_seconds              int not null default 0,
    goals_completed             int not null default 0,
    goals_total                 int not null default 0,
    shield_hits                 int not null default 0,
    shield_hits_by_category     jsonb,
    primary key (user_id, date)
);

alter table public.daily_aggregates enable row level security;

create policy "Users manage their own daily aggregates"
    on public.daily_aggregates for all
    using (auth.uid() = user_id)
    with check (auth.uid() = user_id);


-- ────────────────────────────────────────────
-- WEEKLY AGGREGATES
-- ────────────────────────────────────────────
create table if not exists public.weekly_aggregates (
    user_id                 uuid not null references public.users(id) on delete cascade,
    week_start              date not null,
    total_locked_seconds    int not null default 0,
    total_goals_completed   int not null default 0,
    total_shield_hits       int not null default 0,
    days_complete           int not null default 0,
    primary key (user_id, week_start)
);

alter table public.weekly_aggregates enable row level security;

create policy "Users manage their own weekly aggregates"
    on public.weekly_aggregates for all
    using (auth.uid() = user_id)
    with check (auth.uid() = user_id);


-- ────────────────────────────────────────────
-- MONTHLY AGGREGATES
-- ────────────────────────────────────────────
create table if not exists public.monthly_aggregates (
    user_id                 uuid not null references public.users(id) on delete cascade,
    month                   text not null,
    total_locked_seconds    int not null default 0,
    total_goals_completed   int not null default 0,
    total_shield_hits       int not null default 0,
    days_complete           int not null default 0,
    primary key (user_id, month)
);

alter table public.monthly_aggregates enable row level security;

create policy "Users manage their own monthly aggregates"
    on public.monthly_aggregates for all
    using (auth.uid() = user_id)
    with check (auth.uid() = user_id);
