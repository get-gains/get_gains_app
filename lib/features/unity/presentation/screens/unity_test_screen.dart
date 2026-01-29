import 'package:flutter/material.dart';
import 'package:flutter_embed_unity/flutter_embed_unity.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../providers/router_provider.dart';

/// Unity Test Screen
///
/// Screen for testing Unity integration. Displays the Unity widget
/// and provides controls to send/receive messages from Unity.
class UnityTestScreen extends StatefulWidget {
  const UnityTestScreen({super.key});

  @override
  State<UnityTestScreen> createState() => _UnityTestScreenState();
}

class _UnityTestScreenState extends State<UnityTestScreen> {
  final List<String> _messagesFromUnity = [];
  bool _isUnityLoaded = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.backgroundDark
          : AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Unity Test'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(AppRoutes.home),
        ),
      ),
      body: Column(
        children: [
          // Unity Widget
          Expanded(
            flex: 3,
            child: Container(
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.surface1Dark
                    : AppColors.surface1Light,
                border: Border.all(
                  color: isDark ? AppColors.borderDark : AppColors.borderLight,
                ),
              ),
              child: _isUnityLoaded
                  ? EmbedUnity(
                      onMessageFromUnity: (String message) {
                        setState(() {
                          _messagesFromUnity.insert(0, message);
                          // Keep only last 10 messages
                          if (_messagesFromUnity.length > 10) {
                            _messagesFromUnity.removeLast();
                          }
                        });
                      },
                    )
                  : Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const CircularProgressIndicator(),
                          const SizedBox(height: 16),
                          Text(
                            'Loading Unity...',
                            style: TextStyle(
                              color: isDark
                                  ? AppColors.mutedForegroundDark
                                  : AppColors.mutedForegroundLight,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'This may take a few seconds',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? AppColors.mutedForegroundDark
                                  : AppColors.mutedForegroundLight,
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ),

          // Controls Panel
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surface1Dark : AppColors.surface1Light,
              border: Border(
                top: BorderSide(
                  color: isDark ? AppColors.borderDark : AppColors.borderLight,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Test Buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isUnityLoaded
                            ? () {
                                sendToUnity(
                                  'FlutterLogo', // Game object name
                                  'SetRotationSpeed', // Function name
                                  '50', // Message
                                );
                              }
                            : null,
                        icon: const Icon(Icons.send),
                        label: const Text('Send Test Message'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: _isUnityLoaded
                          ? () {
                              pauseUnity();
                            }
                          : null,
                      icon: const Icon(Icons.pause),
                      label: const Text('Pause'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: _isUnityLoaded
                          ? () {
                              resumeUnity();
                            }
                          : null,
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Resume'),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Messages from Unity
                Text(
                  'Messages from Unity:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: isDark
                        ? AppColors.foregroundDark
                        : AppColors.foregroundLight,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 100,
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.backgroundDark
                        : AppColors.backgroundLight,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isDark
                          ? AppColors.borderDark
                          : AppColors.borderLight,
                    ),
                  ),
                  child: _messagesFromUnity.isEmpty
                      ? Center(
                          child: Text(
                            'No messages yet',
                            style: TextStyle(
                              color: isDark
                                  ? AppColors.mutedForegroundDark
                                  : AppColors.mutedForegroundLight,
                            ),
                          ),
                        )
                      : ListView.builder(
                          reverse: false,
                          itemCount: _messagesFromUnity.length,
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              child: Text(
                                _messagesFromUnity[index],
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark
                                      ? AppColors.foregroundDark
                                      : AppColors.foregroundLight,
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    // Set Unity as loaded after a delay (in real app, wait for scene_loaded message)
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _isUnityLoaded = true;
        });
      }
    });
  }
}
