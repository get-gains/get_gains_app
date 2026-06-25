import 'models/help_content_model.dart';
import 'models/rpe_scale_model.dart';
import 'models/segment_explanation_model.dart';
import 'models/tour_step_model.dart';

// ============================================================================
// 1. TOUR STEP DEFINITIONS
// ============================================================================

/// Routine Detail spotlight tour (4 steps).
const kRoutineDetailTourSteps = [
  TourStepModel(
    targetKey: 'routine_detail_exercise_card',
    title: 'Your Exercises',
    body:
        'Each card shows an exercise in your routine with the prescribed sets and reps.',
    order: 0,
  ),
  TourStepModel(
    targetKey: 'routine_detail_analyze_form',
    title: 'Analyze Form',
    body:
        "Tap here to see your coach's reference form for this exercise. Study it before recording.",
    order: 1,
  ),
  TourStepModel(
    targetKey: 'routine_detail_prescription',
    title: 'Sets & Reps',
    body:
        'Your coach prescribed this range to match your training goals. Aim for the target reps each set.',
    order: 2,
  ),
  TourStepModel(
    targetKey: 'routine_detail_start_workout',
    title: 'Start Your Workout',
    body:
        "When ready, start your workout here. You'll record each exercise and compare against the coach's form.",
    order: 3,
    requiresScroll: true,
  ),
];

/// Workout Session spotlight tour (4 steps).
const kWorkoutSessionTourSteps = [
  TourStepModel(
    targetKey: 'workout_session_exercise_tabs',
    title: 'Exercise Tabs',
    body: 'Switch between exercises in your workout using these tabs.',
    order: 0,
  ),
  TourStepModel(
    targetKey: 'workout_session_set_input',
    title: 'Logged Sets',
    body: 'Each row shows a logged set with reps, weight, and your form score.',
    order: 1,
  ),
  TourStepModel(
    targetKey: 'workout_session_progress',
    title: 'Workout Progress',
    body: 'Track your overall workout completion as you log sets.',
    order: 2,
  ),
  TourStepModel(
    targetKey: 'workout_session_finish',
    title: 'Continue or Finish',
    body:
        'Continue to your next set, or finish when all exercises are complete.',
    order: 3,
    requiresScroll: true,
  ),
];

/// Home screen spotlight tour (5 steps).
const kHomeTourSteps = [
  TourStepModel(
    targetKey: 'home_todays_focus',
    title: "Today's Focus",
    body: 'Shows your assigned workout for today. Tap to get started.',
    order: 0,
  ),
  TourStepModel(
    targetKey: 'home_weekly_progress',
    title: 'Weekly Progress',
    body: 'Track your training consistency throughout the week.',
    order: 1,
  ),
  TourStepModel(
    targetKey: 'home_quick_action_start',
    title: 'Quick Start',
    body: 'Tap here to jump straight into a workout.',
    order: 2,
  ),
  TourStepModel(
    targetKey: 'home_quick_action_history',
    title: 'Workout History',
    body: 'Review your past workouts and track your improvement over time.',
    order: 3,
  ),
  TourStepModel(
    targetKey: 'home_recent_activity',
    title: 'Recent Activity',
    body: 'Your latest sessions appear here with scores and summaries.',
    order: 4,
    requiresScroll: true,
  ),
];

/// Coach home spotlight tour (5 steps).
const kCoachHomeTourSteps = [
  TourStepModel(
    targetKey: 'coach_pulse',
    title: 'Coach Pulse',
    body:
        'See your client stats at a glance: total clients, those with an assigned program, and those who still need one.',
    order: 0,
  ),
  TourStepModel(
    targetKey: 'coach_tool_routines',
    title: 'Routines',
    body:
        'Create and manage workout routines for your clients. Build day-by-day programs with exercises, sets, and reps.',
    order: 1,
  ),
  TourStepModel(
    targetKey: 'coach_tool_exercises',
    title: 'Exercises',
    body:
        'Browse and manage your custom exercise library. Add exercises with form references for your clients to follow.',
    order: 2,
  ),
  TourStepModel(
    targetKey: 'coach_tool_clients',
    title: 'Clients',
    body:
        'View and manage your client roster. Assign programs, track progress, and review client form submissions.',
    order: 3,
  ),
  TourStepModel(
    targetKey: 'coach_tool_settings',
    title: 'Coach Settings',
    body:
        'Configure your coach profile, manage your subscription, and adjust your coaching preferences.',
    order: 4,
  ),
];

// ============================================================================
// 2. HELP CONTENT MODELS
// ============================================================================

/// Routine detail help content.
const kRoutineDetailHelp = HelpContentModel(
  id: 'routine_detail',
  title: 'Routine Detail',
  sections: [
    HelpSection(
      heading: 'Exercise Cards',
      body:
          'Each card shows an exercise with its prescribed sets, reps, and rest time. '
          'A green check appears when all sets for that exercise are completed.',
      iconName: 'fitness_center',
    ),
    HelpSection(
      heading: 'Analyze Form',
      body:
          "Tap 'Analyze Form' on any exercise to view your coach's reference form. "
          'Study the movement before recording to improve your score.',
      iconName: 'analytics',
    ),
    HelpSection(
      heading: 'Starting a Workout',
      body:
          "Tap 'Start Workout' to begin. You'll record each exercise one at a time "
          "and compare your form against the coach's reference.",
      iconName: 'play_arrow',
    ),
  ],
);

/// View form help content.
const kViewFormHelp = HelpContentModel(
  id: 'view_form',
  title: 'Reference Form',
  sections: [
    HelpSection(
      heading: 'What is This?',
      body:
          "This is your coach's ideal reference form for the exercise. "
          "Study the movement pattern before recording your own.",
      iconName: 'visibility',
    ),
    HelpSection(
      heading: '2D / 3D Views',
      body:
          'Toggle between 2D skeleton and 3D avatar views to see the form '
          'from different perspectives.',
      iconName: 'threed_rotation',
    ),
    HelpSection(
      heading: "Don't Mirror",
      body:
          "When recording, follow the same direction as the coach — don't mirror "
          'the movement. The comparison works best when directions match.',
      iconName: 'do_not_disturb_on',
    ),
  ],
);

/// Camera angle help content for view form screen.
const kViewFormAngleHelp = HelpContentModel(
  id: 'view_form_angles',
  title: 'Camera Angles',
  sections: [
    HelpSection(
      heading: 'Front',
      body: 'Camera facing directly forward. Best for exercises performed '
          'straight-on like squats and overhead presses.',
      iconName: 'videocam',
    ),
    HelpSection(
      heading: 'Side Left / Side Right',
      body: 'Camera at 90° from the side. Ideal for exercises where '
          'lateral movement matters like lunges and lateral raises.',
      iconName: 'switch_left',
    ),
    HelpSection(
      heading: '45° Left / 45° Right',
      body: 'Camera at a 45° diagonal, facing toward the side of the coach. '
          'Great for most compound lifts where both front and side views are helpful.',
      iconName: 'rotate_right',
    ),
    HelpSection(
      heading: 'Rear',
      body: 'Camera from behind. Useful for exercises where back posture '
          'is the focus, like deadlifts and rows.',
      iconName: 'arrow_back',
    ),
  ],
);

/// Recording help content (pre-brief + info icon).
const kRecordingHelp = HelpContentModel(
  id: 'recording',
  title: 'Recording Your Form',
  sections: [
    HelpSection(
      heading: 'Reference on Screen',
      body:
          "The coach's reference form will be visible on screen during recording. "
          'Use it as a visual guide.',
      iconName: 'visibility',
    ),
    HelpSection(
      heading: 'Follow the Form',
      body:
          'Perform the exercise following the on-screen form. Try to match the '
          "coach's timing and range of motion.",
      iconName: 'fitness_center',
    ),
    HelpSection(
      heading: 'Same Direction',
      body:
          "Do NOT mirror the form — follow the same direction as shown. "
          'This gives the most accurate comparison.',
      iconName: 'do_not_disturb_on',
    ),
    HelpSection(
      heading: 'Automatic Stop',
      body:
          "The recording will automatically stop after the coach's reference completes. ",
      iconName: 'stop',
    ),
  ],
);

/// Results help content.
const kResultsHelp = HelpContentModel(
  id: 'results',
  title: 'Understanding Your Results',
  sections: [
    HelpSection(
      heading: 'Overall Score',
      body:
          'Your overall form similarity score compared to the coach. '
          'Higher is better: 90%+ Excellent, 75-89% Great, 60-74% Good, '
          '45-59% Fair, 30-44% Needs Work.',
      iconName: 'score',
    ),
    HelpSection(
      heading: 'Segment Breakdown',
      body:
          'See how each body part scored individually. Tap the info icon '
          'next to any segment to learn what it measures.',
      iconName: 'analytics',
    ),
    HelpSection(
      heading: 'AI Form Suggestions',
      body:
          'These suggestions are generated by comparing your motion frame-by-frame '
          "against the coach's reference. Focus on the top suggestion for the biggest improvement.",
      iconName: 'auto_awesome',
    ),
  ],
);

/// Workout session help content.
const kWorkoutSessionHelp = HelpContentModel(
  id: 'workout_session',
  title: 'Workout Session',
  sections: [
    HelpSection(
      heading: 'Exercise Tabs',
      body:
          'Switch between exercises using the tabs at the top. '
          'Each tab shows how many sets are completed.',
      iconName: 'fitness_center',
    ),
    HelpSection(
      heading: 'Logged Sets',
      body:
          'Each row shows a completed set with reps, weight, and your form score. '
          'Sets are logged after each recording.',
      iconName: 'check_circle',
    ),
    HelpSection(
      heading: 'Progress',
      body:
          'The progress bar tracks your overall workout completion across all exercises.',
      iconName: 'trending_up',
    ),
    HelpSection(
      heading: 'Finishing',
      body:
          "Tap 'Continue Workout' to record your next set, or 'Finish Workout' "
          'when all exercises are complete to earn your reward.',
      iconName: 'star',
    ),
  ],
);

/// Home screen help content.
const kHomeHelp = HelpContentModel(
  id: 'home',
  title: 'Your Dashboard',
  sections: [
    HelpSection(
      heading: "Today's Focus",
      body:
          "Shows your assigned workout for today based on your coach's program. "
          'Tap to view the routine and get started.',
      iconName: 'dashboard',
    ),
    HelpSection(
      heading: 'Weekly Progress',
      body:
          'Tracks how many workouts you have completed this week. '
          'Stay consistent to build your streak.',
      iconName: 'trending_up',
    ),
    HelpSection(
      heading: 'Quick Actions',
      body:
          'Start a workout, review history, or access other features quickly.',
      iconName: 'speed',
    ),
    HelpSection(
      heading: 'Recent Activity',
      body:
          'Your latest workout sessions with scores and summaries. '
          'Tap any session to review details.',
      iconName: 'history',
    ),
  ],
);

// ============================================================================
// 3. SEGMENT EXPLANATIONS
// ============================================================================

/// Body segment explanations keyed by [BodySegment.name].
const kSegmentExplanations = <String, SegmentExplanationModel>{
  'HEAD_NECK': SegmentExplanationModel(
    segmentName: 'HEAD_NECK',
    displayName: 'Head & Neck',
    description:
        'Measures head position and neck alignment relative to the reference.',
    improvementTip: 'Keep your gaze forward and chin neutral.',
  ),
  'LEFT_ARM': SegmentExplanationModel(
    segmentName: 'LEFT_ARM',
    displayName: 'Left Arm',
    description:
        'Measures elbow angle, wrist position, and arm path through the movement.',
    improvementTip: "Focus on matching the arm path shown by the coach.",
  ),
  'RIGHT_ARM': SegmentExplanationModel(
    segmentName: 'RIGHT_ARM',
    displayName: 'Right Arm',
    description:
        'Measures elbow angle, wrist position, and arm path through the movement.',
    improvementTip: "Focus on matching the arm path shown by the coach.",
  ),
  'TORSO': SegmentExplanationModel(
    segmentName: 'TORSO',
    displayName: 'Torso',
    description: 'Measures spine angle, hip hinge depth, and trunk rotation.',
    improvementTip: 'Maintain your core bracing throughout the movement.',
  ),
  'LEFT_LEG': SegmentExplanationModel(
    segmentName: 'LEFT_LEG',
    displayName: 'Left Leg',
    description: 'Measures knee tracking, hip angle, and foot positioning.',
    improvementTip: 'Keep your knee aligned with your toes.',
  ),
  'RIGHT_LEG': SegmentExplanationModel(
    segmentName: 'RIGHT_LEG',
    displayName: 'Right Leg',
    description: 'Measures knee tracking, hip angle, and foot positioning.',
    improvementTip: 'Keep your knee aligned with your toes.',
  ),
  'FULL_BODY': SegmentExplanationModel(
    segmentName: 'FULL_BODY',
    displayName: 'Full Body',
    description: 'Overall coordination score across all segments.',
    improvementTip: 'Focus on smooth, controlled movement matching the tempo.',
  ),
};

// ============================================================================
// 4. RPE SCALE
// ============================================================================

/// Key RPE levels for the info sheet.
const kRpeScaleEntries = [
  RpeScaleModel(
    level: 1,
    label: 'Very Light',
    description: 'Almost no effort, like a warm-up',
  ),
  RpeScaleModel(
    level: 3,
    label: 'Light',
    description: 'Easy effort, could do many more reps',
  ),
  RpeScaleModel(
    level: 5,
    label: 'Moderate',
    description: 'Noticeable effort, several reps left in the tank',
  ),
  RpeScaleModel(
    level: 6,
    label: 'Moderate-Hard',
    description: 'Starting to work, about 4 reps left',
  ),
  RpeScaleModel(
    level: 7,
    label: 'Hard',
    description: 'Challenging, about 3 reps left',
  ),
  RpeScaleModel(
    level: 8,
    label: 'Very Hard',
    description: 'Tough, only 2 reps left in reserve',
  ),
  RpeScaleModel(
    level: 9,
    label: 'Near Max',
    description: 'Extremely hard, only 1 rep left',
  ),
  RpeScaleModel(
    level: 10,
    label: 'Maximal',
    description: 'All-out effort, could not do another rep',
  ),
];

// ============================================================================
// 5. SCORE GRADING SCALE
// ============================================================================

/// Score ranges and their grade labels.
///
/// Each entry is (minPercent, maxPercent, label).
const kScoreGrades = [
  (90, 100, 'Excellent'),
  (75, 89, 'Great'),
  (60, 74, 'Good'),
  (45, 59, 'Fair'),
  (30, 44, 'Needs Work'),
  (0, 29, 'Keep Practicing'),
];

/// Returns the grade label for a given score (0.0–1.0).
String scoreGradeLabel(double score) {
  final percent = (score * 100).round();
  for (final (min, max, label) in kScoreGrades) {
    if (percent >= min && percent <= max) return label;
  }
  return 'Keep Practicing';
}

// ============================================================================
// 6. CONTENT LOOKUP MAP
// ============================================================================

/// Screen ID → HelpContentModel lookup map.
const kHelpContentMap = <String, HelpContentModel>{
  'home': kHomeHelp,
  'routine_detail': kRoutineDetailHelp,
  'view_form': kViewFormHelp,
  'recording': kRecordingHelp,
  'results': kResultsHelp,
  'workout_session': kWorkoutSessionHelp,
};
