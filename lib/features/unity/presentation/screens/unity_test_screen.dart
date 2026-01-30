import 'package:flutter/material.dart';
import 'package:flutter_embed_unity/flutter_embed_unity.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../providers/router_provider.dart';
import '../../data/unity_message_contract.dart';

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
  final TextEditingController _sendController = TextEditingController();
  final FocusNode _sendFocusNode = FocusNode();
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
                  ? EmbedUnity(onMessageFromUnity: _onMessageFromUnity)
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
                // Send custom message to Unity
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _sendController,
                        focusNode: _sendFocusNode,
                        enabled: _isUnityLoaded,
                        decoration: InputDecoration(
                          hintText: 'Type message for Unity...',
                          border: const OutlineInputBorder(),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        onSubmitted: (_) => _sendCustomMessage(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      onPressed: _isUnityLoaded ? _sendCustomMessage : null,
                      icon: const Icon(Icons.send),
                      tooltip: 'Send to Unity',
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Test Buttons
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.tonalIcon(
                        onPressed: _isUnityLoaded ? _sendRotationSpeed : null,
                        icon: const Icon(Icons.rotate_right, size: 20),
                        label: const Text('Set rotation 50'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.outlined(
                      onPressed: _isUnityLoaded ? () => pauseUnity() : null,
                      icon: const Icon(Icons.pause),
                      tooltip: 'Pause Unity',
                    ),
                    IconButton.outlined(
                      onPressed: _isUnityLoaded ? () => resumeUnity() : null,
                      icon: const Icon(Icons.play_arrow),
                      tooltip: 'Resume Unity',
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
  void dispose() {
    _sendController.dispose();
    _sendFocusNode.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // Fallback: enable UI after 3s if Unity never sends scene_loaded
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && !_isUnityLoaded) {
        setState(() => _isUnityLoaded = true);
      }
    });
  }

  void _onMessageFromUnity(String message) {
    if (!mounted) return;
    setState(() {
      if (message == UnityMessageContract.unityEventSceneLoaded) {
        _isUnityLoaded = true;
        _messagesFromUnity.insert(0, '[Scene ready]');
      } else {
        _messagesFromUnity.insert(0, message);
      }
      if (_messagesFromUnity.length > 20) {
        _messagesFromUnity.removeLast();
      }
    });
  }

  void _sendCustomMessage() {
    final text = _sendController.text.trim();
    if (text.isEmpty || !_isUnityLoaded) return;
    sendToUnity(
      UnityMessageContract.gameObjectName,
      UnityMessageContract.methodOnMessageFromFlutter,
      text,
    );
    _sendController.clear();
    _sendFocusNode.requestFocus();
  }

  void _sendRotationSpeed() {
    if (!_isUnityLoaded) return;
    sendToUnity(
      UnityMessageContract.gameObjectName,
      UnityMessageContract.methodSetRotationSpeed,
      '50',
    );
  }
}
