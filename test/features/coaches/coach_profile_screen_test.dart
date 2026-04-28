import 'package:flutter_test/flutter_test.dart';
import 'package:get_gains_app/features/coaches/presentation/providers/subscribed_coaches_provider.dart';

void main() {
  test('SubscribedCoachesInitial is detectable by type check', () {
    const state = SubscribedCoachesInitial();
    expect(state, isA<SubscribedCoachesInitial>());
  });
}
