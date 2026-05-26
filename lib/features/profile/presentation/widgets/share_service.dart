import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/models/profile_stats_model.dart';
import '../../../auth/data/models/user_model.dart';
import 'share_stats_card.dart';

class ShareCardPreview extends StatelessWidget {
  const ShareCardPreview({
    super.key,
    required this.template,
    required this.stats,
    required this.user,
    required this.repaintKey,
    this.avatarUrl,
  });

  final ShareStatTemplate template;
  final ProfileStatsModel stats;
  final UserModel user;
  final GlobalKey repaintKey;
  final String? avatarUrl;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(template.title),
        actions: [
          _ShareButton(
            onPressed: () => _share(context),
            icon: Icons.share,
            label: 'Share',
          ),
          const SizedBox(width: 8),
          _ShareButton(
            onPressed: () => _saveToGallery(context),
            icon: Icons.save_alt,
            label: 'Save',
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: RepaintBoundary(
            key: repaintKey,
            child: ShareStatsCard(
              template: template,
              stats: stats,
              user: user,
              avatarUrl: avatarUrl,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _share(BuildContext context) async {
    final bytes = await _captureImage();
    if (bytes == null) return;

    final dir = await getTemporaryDirectory();
    final file = File(
      '${dir.path}/getgains_${template.title.toLowerCase().replaceAll(' ', '_')}.png',
    );
    await file.writeAsBytes(bytes);

    await Share.shareXFiles(
      [XFile(file.path)],
      subject: 'My ${template.title} stat from Get Gains',
    );
  }

  Future<void> _saveToGallery(BuildContext context) async {
    final bytes = await _captureImage();
    if (bytes == null) return;

    final dir = await getTemporaryDirectory();
    final file = File(
      '${dir.path}/getgains_${template.title.toLowerCase().replaceAll(' ', '_')}.png',
    );
    await file.writeAsBytes(bytes);

    try {
      await Gal.putImage(file.path);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Saved to gallery!')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: $e')),
        );
      }
    }
  }

  Future<Uint8List?> _captureImage() async {
    final boundary =
        repaintKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) return null;

    final image = await boundary.toImage(pixelRatio: 2.0);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) return null;

    return byteData.buffer.asUint8List();
  }
}

class _ShareButton extends StatelessWidget {
  const _ShareButton({
    required this.onPressed,
    required this.icon,
    required this.label,
  });

  final VoidCallback onPressed;
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 20),
      label: Text(label),
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primaryDark,
      ),
    );
  }
}
