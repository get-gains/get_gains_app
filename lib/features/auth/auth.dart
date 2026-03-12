/// Auth Feature
///
/// Complete authentication feature including:
/// - Data layer (models, repository)
/// - Services (Google Sign-In, user preferences)
/// - Presentation (providers, screens)
///
/// Usage:
/// ```dart
/// import 'package:get_gains_app/features/auth/auth.dart';
///
/// // Access repository
/// final authRepo = ref.read(authRepositoryProvider);
///
/// // Access registration state
/// final registerState = ref.watch(registerProvider);
/// ```
library;

export 'data/data.dart';
export 'presentation/presentation.dart';
export 'services/services.dart';
