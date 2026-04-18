# Guidance & Onboarding

> **Status**: ✅ Complete  
> **Last Updated**: April 19, 2026  
> **Covers**: Spotlight tours, contextual help sheets, info icons, tour orchestration

---

## Overview

The Guidance feature provides first-time-user onboarding via spotlight coach-mark tours and per-screen contextual help accessible through info icons. Tour completion is persisted in Hive so each tour runs only once.

---

## Architecture

```
lib/features/guidance/
├── guidance.dart                              # Feature barrel export
├── data/
│   ├── data.dart
│   ├── guidance_content.dart                  # Static content: tour steps, help text, RPE scale, segment explanations
│   ├── guidance_repository.dart               # Hive-backed tour-completion flags
│   └── models/
│       ├── help_content_model.dart            # HelpContentModel (title, sections)
│       ├── rpe_scale_model.dart               # RPE scale reference data
│       ├── segment_explanation_model.dart     # Per-segment score explanation
│       └── tour_step_model.dart               # TourStepModel (target key, title, description)
└── presentation/
    ├── presentation.dart
    ├── providers/
    │   ├── help_provider.dart                 # Content provider for contextual help sheets
    │   └── tour_provider.dart                 # TourNotifier (start, advance, complete, reset)
    └── widgets/
        ├── contextual_help_sheet.dart         # Bottom sheet with help sections
        ├── info_icon_button.dart              # Tappable ℹ️ icon that opens help sheet
        ├── spotlight_overlay.dart             # Dimmed overlay with cutout around target
        ├── tour_orchestrator.dart             # Widget that wraps screen and drives tour flow
        ├── tour_tooltip.dart                  # Tooltip bubble for each tour step
        └── widgets.dart
```

---

## Features

| Feature              | Description                                                           | Status      |
|----------------------|-----------------------------------------------------------------------|-------------|
| Spotlight Tours      | Step-by-step coach-mark overlays highlighting UI elements             | ✅ Complete |
| Tour Persistence     | Completed tours stored in Hive; not shown again on subsequent visits  | ✅ Complete |
| Contextual Help      | Per-screen help sheet with explanations for metrics and components    | ✅ Complete |
| Info Icon Buttons    | `InfoIconButton` widget placed in app bars / cards                    | ✅ Complete |
| RPE Scale Reference  | Rate of Perceived Exertion scale shown in set-logging help            | ✅ Complete |
| Segment Explanations | Body-segment score explanations shown in form results help            | ✅ Complete |

---

## Guided Screens

| Screen ID          | Constant                     |
|--------------------|------------------------------|
| `home`             | `GuidanceRepository.kHome`             |
| `routine_detail`   | `GuidanceRepository.kRoutineDetail`    |
| `view_form`        | `GuidanceRepository.kViewForm`         |
| `recording`        | `GuidanceRepository.kRecording`        |
| `results`          | `GuidanceRepository.kResults`          |
| `workout_session`  | `GuidanceRepository.kWorkoutSession`   |
| `set_logger`       | `GuidanceRepository.kSetLogger`        |

---

## Usage

```dart
// Wrap a screen to enable tours
TourOrchestrator(
  screenId: GuidanceRepository.kRoutineDetail,
  steps: kRoutineDetailTourSteps,
  child: RoutineDetailScreen(),
)

// Add a help icon in an AppBar action
InfoIconButton(screenId: GuidanceRepository.kRoutineDetail)

// Manually start a tour
ref.read(tourProvider.notifier).startTour(
  GuidanceRepository.kHome,
  kHomeTourSteps,
);

// Reset all tours (dev/testing)
ref.read(guidanceRepositoryProvider).resetAll();
```

---

## No Routes

The guidance feature has no dedicated routes. All guidance is surfaced inline via `TourOrchestrator` and `InfoIconButton` widgets embedded in existing screens.
