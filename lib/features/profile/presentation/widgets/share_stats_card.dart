import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/theme/app_text_styles.dart';
import '../../../auth/data/models/user_model.dart';
import '../../data/models/profile_stats_model.dart';

enum ShareStatTemplate {
  weeklyWarrior,
  setMachine,
  dailyGrind,
  onFire,
}

extension ShareStatTemplateLabels on ShareStatTemplate {
  String get title {
    return switch (this) {
      ShareStatTemplate.weeklyWarrior => 'Weekly Warrior',
      ShareStatTemplate.setMachine => 'Set Machine',
      ShareStatTemplate.dailyGrind => 'Daily Grind',
      ShareStatTemplate.onFire => 'On Fire',
    };
  }

  String get icon {
    return switch (this) {
      ShareStatTemplate.weeklyWarrior => 'weekly',
      ShareStatTemplate.setMachine => 'sets',
      ShareStatTemplate.dailyGrind => 'today',
      ShareStatTemplate.onFire => 'streak',
    };
  }
}

class ShareStatsCard extends StatelessWidget {
  const ShareStatsCard({
    super.key,
    required this.template,
    required this.stats,
    required this.user,
    this.avatarUrl,
  });

  final ShareStatTemplate template;
  final ProfileStatsModel stats;
  final UserModel user;
  final String? avatarUrl;

  static const _cardWidth = 1080.0;
  static const _cardHeight = 1080.0;
  static const _accentColor = Color(0xFFE07D3B);
  static const _greenColor = Color(0xFF4ADE80);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _cardWidth,
      height: _cardHeight,
      child: Padding(
        padding: const EdgeInsets.all(56),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLogo(),
            const Spacer(),
            _buildStat(context),
            const Spacer(),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SvgPicture.asset(
            'assets/images/logo.svg',
            width: 64,
            height: 64,
          ),
        ),
        const SizedBox(width: 16),
        Text(
          'Get Gains',
          style: const TextStyle(
            fontFamily: AppTextStyles.fontFamilySans,
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildStat(BuildContext context) {
    return switch (template) {
      ShareStatTemplate.weeklyWarrior => _weeklyWarrior(),
      ShareStatTemplate.setMachine => _setMachine(),
      ShareStatTemplate.dailyGrind => _dailyGrind(),
      ShareStatTemplate.onFire => _onFire(),
    };
  }

  Widget _weeklyWarrior() {
    final count = stats.workoutsThisWeek;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$count',
          style: const TextStyle(
            fontFamily: AppTextStyles.fontFamilyMono,
            fontSize: 120,
            fontWeight: FontWeight.w700,
            color: _accentColor,
            height: 1.0,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'workouts completed\nthis week',
          style: TextStyle(
            fontFamily: AppTextStyles.fontFamilySans,
            fontSize: 40,
            fontWeight: FontWeight.w600,
            color: Colors.white,
            height: 1.2,
          ),
        ),
        if (stats.totalMinutesWeek > 0) ...[
          const SizedBox(height: 12),
          Text(
            '${stats.totalMinutesWeek} min of training',
            style: TextStyle(
              fontFamily: AppTextStyles.fontFamilySans,
              fontSize: 24,
              fontWeight: FontWeight.w400,
              color: Colors.white.withValues(alpha: 0.6),
            ),
          ),
        ],
      ],
    );
  }

  Widget _setMachine() {
    final count = stats.setsToday;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$count',
          style: const TextStyle(
            fontFamily: AppTextStyles.fontFamilyMono,
            fontSize: 120,
            fontWeight: FontWeight.w700,
            color: _accentColor,
            height: 1.0,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'sets completed\ntoday',
          style: TextStyle(
            fontFamily: AppTextStyles.fontFamilySans,
            fontSize: 40,
            fontWeight: FontWeight.w600,
            color: Colors.white,
            height: 1.2,
          ),
        ),
        if (stats.workoutsThisWeek > 0) ...[
          const SizedBox(height: 12),
          Text(
            '${stats.workoutsThisWeek} workouts this week',
            style: TextStyle(
              fontFamily: AppTextStyles.fontFamilySans,
              fontSize: 24,
              fontWeight: FontWeight.w400,
              color: Colors.white.withValues(alpha: 0.6),
            ),
          ),
        ],
      ],
    );
  }

  Widget _dailyGrind() {
    final completed = stats.completedToday;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          completed ? 'Done!' : 'Not yet',
          style: TextStyle(
            fontFamily: AppTextStyles.fontFamilySans,
            fontSize: 80,
            fontWeight: FontWeight.w700,
            color: completed ? _greenColor : _accentColor,
            height: 1.0,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          completed ? 'Workout completed\ntoday' : 'Today\'s workout\nstill waiting',
          style: const TextStyle(
            fontFamily: AppTextStyles.fontFamilySans,
            fontSize: 40,
            fontWeight: FontWeight.w600,
            color: Colors.white,
            height: 1.2,
          ),
        ),
        if (completed && stats.setsToday > 0) ...[
          const SizedBox(height: 12),
          Text(
            '${stats.setsToday} sets crushed',
            style: TextStyle(
              fontFamily: AppTextStyles.fontFamilySans,
              fontSize: 24,
              fontWeight: FontWeight.w400,
              color: Colors.white.withValues(alpha: 0.6),
            ),
          ),
        ],
      ],
    );
  }

  Widget _onFire() {
    final streak = stats.streakDays;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$streak',
          style: const TextStyle(
            fontFamily: AppTextStyles.fontFamilyMono,
            fontSize: 120,
            fontWeight: FontWeight.w700,
            color: _accentColor,
            height: 1.0,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          streak == 1 ? 'day streak' : 'day streak',
          style: const TextStyle(
            fontFamily: AppTextStyles.fontFamilySans,
            fontSize: 40,
            fontWeight: FontWeight.w600,
            color: Colors.white,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'and counting!',
          style: TextStyle(
            fontFamily: AppTextStyles.fontFamilySans,
            fontSize: 32,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        if (stats.allTimeWorkouts > 0) ...[
          const SizedBox(height: 16),
          Text(
            '${stats.allTimeWorkouts} all-time workouts',
            style: TextStyle(
              fontFamily: AppTextStyles.fontFamilySans,
              fontSize: 24,
              fontWeight: FontWeight.w400,
              color: Colors.white.withValues(alpha: 0.6),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildFooter() {
    return Row(
      children: [
        _buildMiniAvatar(),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                user.name,
                style: const TextStyle(
                  fontFamily: AppTextStyles.fontFamilySans,
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              const Text(
                '#GetGains',
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamilySans,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: _accentColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMiniAvatar() {
    final initials = user.name.isNotEmpty
        ? user.name
            .split(' ')
            .where((s) => s.isNotEmpty)
            .map((s) => s[0].toUpperCase())
            .take(2)
            .join()
        : '?';

    return Container(
      width: 72,
      height: 72,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Color(0xFF363636),
      ),
      clipBehavior: Clip.antiAlias,
      alignment: Alignment.center,
      child: avatarUrl != null && avatarUrl!.isNotEmpty
          ? Image.network(
              avatarUrl!,
              width: 72,
              height: 72,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Text(
                initials,
                style: const TextStyle(
                  fontFamily: AppTextStyles.fontFamilySans,
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                  color: _accentColor,
                ),
              ),
            )
          : Text(
              initials,
              style: const TextStyle(
                fontFamily: AppTextStyles.fontFamilySans,
                fontSize: 28,
                fontWeight: FontWeight.w600,
                color: _accentColor,
              ),
            ),
    );
  }
}

class ShareCardCapture {
  final GlobalKey _repaintKey = GlobalKey();

  GlobalKey get repaintKey => _repaintKey;

  Future<Uint8List> capture(ShareStatsCard card) async {
    final boundary =
        _repaintKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) {
      throw Exception('RepaintBoundary not found');
    }

    final image = await boundary.toImage(pixelRatio: 2.0);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) {
      throw Exception('Failed to convert image to bytes');
    }

    return byteData.buffer.asUint8List();
  }
}
