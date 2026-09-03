import 'package:flutter/material.dart';

import '../../app/theme.dart';
import 'status_badge.dart';

/// Inline, non-blocking notice ("Cloud sync unavailable", login errors...).
class InfoBanner extends StatelessWidget {
  const InfoBanner({
    super.key,
    required this.title,
    this.message,
    this.tone = StatusTone.warning,
    this.icon,
    this.onDismiss,
  });

  final String title;
  final String? message;
  final StatusTone tone;
  final IconData? icon;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    final resolvedIcon = icon ??
        switch (tone) {
          StatusTone.danger => Icons.error_outline_rounded,
          StatusTone.warning => Icons.cloud_off_rounded,
          StatusTone.online => Icons.check_circle_outline_rounded,
          _ => Icons.info_outline_rounded,
        };
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: tone.softColor,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Icon(resolvedIcon, size: 20, color: tone.color),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.bodyStrong.copyWith(
                    color: tone == StatusTone.neutral
                        ? AppColors.textPrimary
                        : tone.color,
                  ),
                ),
                if (message != null) ...[
                  const SizedBox(height: 2),
                  Text(message!, style: AppTextStyles.caption),
                ],
              ],
            ),
          ),
          if (onDismiss != null)
            GestureDetector(
              onTap: onDismiss,
              child: const Padding(
                padding: EdgeInsets.only(left: AppSpacing.sm),
                child: Icon(Icons.close_rounded, size: 18, color: AppColors.textTertiary),
              ),
            ),
        ],
      ),
    );
  }
}
