import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:get_gains_app/services/api/api_client.dart';
import '../../data/repositories/coach_invite_repository.dart';

part 'coach_invite_provider.g.dart';

/// Provider for the coach invite repository.
@Riverpod(keepAlive: true)
CoachInviteRepository coachInviteRepository(Ref ref) {
  final apiClient = ref.watch(apiClientProvider);
  return CoachInviteRepository(apiClient: apiClient);
}
