import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../features/auth/services/user_preferences_service.dart';
import '../../../../providers/router_provider.dart';
import '../../../../widgets/app_button.dart';

class LandingScreen extends ConsumerWidget {
  const LandingScreen({super.key});

  static const String subtitle = 'Train safer, grow greater';
  static const String learnMoreUrl = 'https://get-gains.vercel.app';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Opacity(
            opacity: 0.5,
            child: SvgPicture.asset(
              'assets/images/landing_page.svg',
              fit: BoxFit.cover,
            ),
          ),
          Container(
            color:
                (isDark ? AppColors.backgroundDark : AppColors.backgroundLight)
                    .withOpacity(0.75),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                children: [
                  const Spacer(flex: 2),
                  SvgPicture.asset('assets/images/logo.svg', width: 200),
                  const SizedBox(height: 16),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 18,
                      color: isDark
                          ? AppColors.mutedForegroundDark
                          : AppColors.mutedForegroundLight,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const Spacer(flex: 2),
                  AppButton.primary(
                    label: 'Get Started',
                    size: AppButtonSize.lg,
                    isFullWidth: true,
                    onPressed: () {
                      ref
                          .read(userPreferencesServiceProvider)
                          .setHasSeenLanding();
                      context.go(AppRoutes.login);
                    },
                  ),
                  const SizedBox(height: 12),
                  AppButton.ghost(
                    label: 'Learn More',
                    size: AppButtonSize.md,
                    isFullWidth: true,
                    onPressed: () => launchUrl(
                      Uri.parse(learnMoreUrl),
                      mode: LaunchMode.externalApplication,
                    ),
                  ),
                  const SizedBox(height: 48),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
