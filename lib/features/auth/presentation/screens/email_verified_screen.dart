import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../providers/router_provider.dart';

/// Email Verified Screen
///
/// Shown after user verifies their email via the web app deep link.
/// Deep link: getgains://auth/email-verified → Router navigates to /email-verified
/// Displays a success message and a button to navigate to login.
class EmailVerifiedScreen extends ConsumerWidget {
  const EmailVerifiedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Success Icon
              Icon(
                Icons.verified_outlined,
                size: 100,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 32),

              // Title
              Text(
                'Email Verified!',
                style: Theme.of(context).textTheme.headlineLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),

              // Subtitle
              Text(
                'Your email has been successfully verified.\nYou can now log in to your account.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),

              // Login Button
              FilledButton(
                onPressed: () => context.go(AppRoutes.login),
                child: const Text('Log In'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
