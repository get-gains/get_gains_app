import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../widgets/widgets.dart';
import '../../data/models/mission_list_item_model.dart';

/// Native dialog showing partner name, logo, bio, and clickable social links.
class PartnerDetailDialog extends StatelessWidget {
  const PartnerDetailDialog({super.key, required this.partner});

  final MissionPartnerModel partner;

  Future<void> _openLink(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    final canOpen = await canLaunchUrl(uri);
    if (canOpen) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);

    return Dialog(
      backgroundColor: Colors.transparent,
      child: AppCard(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (partner.logoKey.isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: AppImage.network(
                        url: partner.logoKey,
                        width: 64,
                        height: 64,
                        fit: BoxFit.cover,
                      ),
                    )
                  else
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.surface3Dark
                            : AppColors.surface3Light,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.business),
                    ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      partner.name,
                      style: theme.textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                partner.bio,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
              ),
              if (partner.socialLinks.isNotEmpty) ...[
                const SizedBox(height: 20),
                Text(
                  'Social Links',
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: partner.socialLinks.map((link) {
                    return ActionChip(
                      label: Text(
                        _displayHost(link),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      onPressed: () => _openLink(link),
                    );
                  }).toList(),
                ),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: AppButton(
                  onPressed: () => Navigator.of(context).pop(),
                  label: 'Close',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _displayHost(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.host.isEmpty ? url : uri.host;
    } catch (_) {
      return url;
    }
  }
}
