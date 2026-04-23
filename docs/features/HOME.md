# Home Feature Documentation

> Created: February 18, 2026
> Updated: April 16, 2026 - unified home status and weekday-aware today display
> Status: Production wired

---

## Overview

Home is the authenticated dashboard. It combines workout readiness, subscription/coach gating, today's routine context, weekly progress, and recent activity in one screen.

The current implementation is driven by unified APIs:

- GET /api/today for coach + standalone today state
- GET /api/stats/weekly for unified weekly totals
- GET /api/workout/sessions for recent activity (with local DB fallback)

---

## Screen Structure

Primary screen: HomeScreen in lib/features/home/presentation/screens/home_screen.dart.

Top-to-bottom sections:

| Section | Behavior |
| --- | --- |
| App Bar | Greeting, profile avatar sheet, coin balance, notifications TODO |
| Quick Actions | Start Workout, History, Shop, Wardrobe, Leaderboard, Progress, and Coach Tools for coaches |
| Home Status CTA | Shows Find Coach, Upgrade, or Waiting for Program depending on status |
| Today's Focus | Shows routine card, rest day card, or Start a Program CTA |
| This Week | Uses real unified weekly stats |
| Recent Activity | Uses real recent sessions; empty state when none |
| Bottom Nav | Home, Workouts, Progress, Profile |

---

## Provider Wiring

Core providers from lib/features/home/presentation/providers/home_providers.dart:

| Provider | Return type | Source | Purpose |
| --- | --- | --- | --- |
| isCoachProvider | Future<bool> | GET /auth/me | Toggle coach-only UI |
| todayStatusProvider | Future<TodayStatusModel> | GET /api/today | Unified subscription + coach + standalone state |
| homeStatusProvider | Future<HomeStatus> | derived from todayStatusProvider | Home CTA decision |
| activeTodayProvider | Future<TodayRoutineModel> | derived from todayStatusProvider | Coach-first today routine with standalone fallback |
| unifiedWeeklyStatsProvider | Future<UnifiedWeeklyStats> | GET /api/stats/weekly | Weekly completed workouts, minutes, streak |
| recentActivityProvider | Future<List<WorkoutSessionSummary>> | GET /api/workout/sessions | Recent sessions, with local DB fallback when remote unavailable |

Legacy provider note:

- weeklyStatsProvider still exists as deprecated fallback; home UI now watches unifiedWeeklyStatsProvider.

---

## HomeStatus Enum

| Value | Meaning |
| --- | --- |
| noCoach | User has no subscribed coach |
| noSubscription | User has coach but no active subscription |
| waitingForProgram | Subscribed coach flow exists but no coach program today |
| restDay | Coach program exists and today is a rest day |
| hasRoutine | Coach program has an assigned routine today |

---

## Today's Focus Behavior

Home uses activeTodayProvider and renders:

1. Rest day card when isRestDay is true
2. Routine card when hasRoutine is true
3. Start a Program CTA when neither coach nor standalone has an active routine

Routine subtitle now uses weekday label formatting based on dayOfWeek (for example Monday), not numeric day labels.

completedToday is respected:

- true -> start button disabled
- false -> start button routes to workouts

---

## Refresh Behavior

Pull-to-refresh invalidates and re-fetches:

- isCoachProvider
- todayStatusProvider
- activeTodayProvider
- homeStatusProvider
- unifiedWeeklyStatsProvider
- recentActivityProvider

---

## Navigation Map

| Action | Destination |
| --- | --- |
| Start Workout | AppRoutes.routines |
| History quick action | AppRoutes.workoutHistory |
| Shop | AppRoutes.shop |
| Wardrobe | AppRoutes.inventory |
| Leaderboard | AppRoutes.leaderboard |
| Progress quick action / bottom nav | AppRoutes.progress |
| Coach Tools | AppRoutes.coachHub |
| Today's Focus See All | AppRoutes.routines |
| Profile tab | AppRoutes.profile |

---

## Remaining TODOs

| Location | TODO |
| --- | --- |
| home_screen.dart | Notifications route still TODO |
| home_screen.dart | Weekly goal currently fixed at 4; make user-configurable |

---

Last updated: April 16, 2026
