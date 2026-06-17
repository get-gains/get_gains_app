// lib/features/home/presentation/widgets/coach_pulse_block.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../providers/router_provider.dart';
import '../../../../widgets/widgets.dart';
import '../providers/coach_pulse_provider.dart';

/// Hero block for coaches: shows client count and assignment stats with a
/// primary CTA to navigate to the Coach Hub.
///
/// When [isDeactivated] is true, shows a deactivation notice instead.
class CoachPulseBlock extends ConsumerWidget {
  const CoachPulseBlock({super.key, this.isDeactivated = false});

  final bool isDeactivated;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pulseAsync = ref.watch(coachPulseProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: AppCard.gradient(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.coach, AppColors.coachMuted],
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.sports, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Coach Pulse',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (isDeactivated)
              const _DeactivatedNotice()
            else
              pulseAsync.when(
                data: (stats) => Row(
                  children: [
                    _StatTile(
                      label: 'Clients',
                      value: '${stats.totalClients}',
                    ),
                    const SizedBox(width: 12),
                    _StatTile(
                      label: 'With Program',
                      value: '${stats.clientsAssigned}',
                    ),
                    const SizedBox(width: 12),
                    _StatTile(
                      label: 'Need Program',
                      value: '${stats.clientsUnassigned}',
                      highlight: stats.clientsUnassigned > 0,
                    ),
                  ],
                ),
                loading: () => const SizedBox(
                  height: 40,
                  child: Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                ),
                error: (_, __) => const Text(
                  'Could not load coach stats',
                  style: TextStyle(color: Colors.white70),
                ),
              ),
            if (!isDeactivated) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white54),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () => context.push(AppRoutes.coachHub),
                  child: const Text('Open Coach Hub'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  final String label;
  final String value;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: highlight ? 0.25 : 0.15),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}

class _DeactivatedNotice extends StatelessWidget {
  const _DeactivatedNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Column(
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.white70, size: 28),
          SizedBox(height: 8),
          Text(
            'Your coach account has been deactivated.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Contact support for assistance.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
