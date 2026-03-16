import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/guidance_content.dart';
import '../../data/models/help_content_model.dart';

part 'help_provider.g.dart';

/// Looks up [HelpContentModel] for a given screen by ID.
///
/// Returns `null` if no content is registered for [screenId].
@riverpod
HelpContentModel? helpContent(Ref ref, String screenId) {
  return kHelpContentMap[screenId];
}
