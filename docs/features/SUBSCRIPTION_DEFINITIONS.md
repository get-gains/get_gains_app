# Feature: Subscription Definitions

**Spec**: `/specs/001-subscription-definitions/spec.md`
**Status**: Complete

## Overview

Differentiates standalone workout tracking from coach program subscription access. Separates statistics and session history by workout source (standalone vs. coach-assigned), replaces raw 403 error messages with contextual upgrade prompts, and refines the frontend experience so non-subscribed users see a complete, usable app.

## User Stories

1. **US1 (P1 MVP)**: Standalone workout stats separated from coach stats
2. **US2 (P2)**: Graceful subscription prompts for coach features
3. **US3 (P2)**: Session history distinguishes workout source
4. **US4 (P3)**: Hide or gate coach-only UI elements

## Key Files

### Models & Data

- `lib/features/workout/data/models/unified_weekly_stats_model.dart` — Unified stats freezed model (`UnifiedWeeklyStats`, `SourceStats`)
- `lib/features/workout/data/models/unified_session_summary_model.dart` — Unified session history model (`UnifiedSessionSummary`, `UnifiedSessionHistoryResponse`)
- `lib/features/subscription/presentation/models/subscription_feature.dart` — `SubscriptionFeature` enum with benefit descriptions and analytics keys

### Providers

- `lib/features/home/presentation/providers/home_providers.dart` — Unified stats provider (`unifiedWeeklyStatsProvider`), `activeTodayProvider` with standalone fallback, `homeStatusProvider`

### UI Screens

- `lib/features/workout/presentation/screens/progress_screen.dart` — Source-aware progress UI with per-source breakdowns
- `lib/features/workout/presentation/screens/workout_history_screen.dart` — Unified session history with source badges and filter tabs (All/Coach/Solo)
- `lib/features/home/presentation/screens/home_screen.dart` — Unified home screen with loading skeletons, "Start a Program" CTA, and max 1 prominent upgrade CTA

### Widgets

- `lib/features/home/presentation/widgets/weekly_progress_card.dart` — Unified weekly progress card
- `lib/features/subscription/presentation/widgets/upgrade_prompt.dart` — Contextual upgrade prompt with compact mode, PAST_DUE billing CTA, PENDING informational
- `lib/features/subscription/presentation/providers/subscription_guard.dart` — `SubscriptionGatedWidget` with proactive cached subscription check and loading skeleton
- `lib/widgets/source_badge.dart` — Source badge widget (Coach/Solo pill)

### Repository

- `lib/features/workout/data/workout_repository.dart` — `getUnifiedWeeklyStats()` and `getSessionHistory()` methods

## Implementation Notes

- Source is derived from `WorkoutSession.assignedProgramId`: null = standalone, set = coach
- Unified stats endpoint: `GET /api/stats/weekly` (replaces separate endpoints)
- Unified session history: `GET /api/sessions/history` with `?source=` filter
- `SubscriptionFeature` enum centralizes upgrade prompt copy and analytics keys
- Stats use `attachSubscription` (non-blocking) — free users see standalone only, subscribed see both
- `SubscriptionGatedWidget` proactively checks cached subscription state — no API call or error flash
- PAST_DUE shows billing resolution CTA with deep link to Play Store / App Store
- PENDING shows informational message with no action required
- Max 1 prominent (non-compact) upgrade CTA per screen; subsequent sections use compact mode
- Loading skeletons shown while subscription status resolves (no premature hide/show)
- Home screen: standalone today's workout for free users (priority); "Start a Program" CTA when no programs
- Subscription expiry gracefully transitions coach sections to free user experience via Riverpod state
- Routine list screen uses compact upgrade prompt for non-subscribed users
- Historical coach sessions always accessible (read-only, no subscription gating per FR-014)
