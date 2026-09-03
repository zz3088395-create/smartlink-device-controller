import 'package:flutter/material.dart';

import '../../app/theme.dart';

/// Semantic colour of a status pill. Only these tones carry colour in the app.
enum StatusTone { online, offline, warning, danger, primary, neutral }

extension StatusToneColors on StatusTone {
  Color get color => switch (this) {
        StatusTone.online => AppColors.online,
        StatusTone.offline => AppColors.offline,
        StatusTone.warning => AppColors.warning,
        StatusTone.danger => AppColors.danger,
        StatusTone.primary => AppColors.primary,
        StatusTone.neutral => AppColors.textSecondary,
      };

  Color get softColor => switch (this) {
        StatusTone.online => AppColors.onlineSoft,
        StatusTone.offline => AppColors.offlineSoft,
        StatusTone.warning => AppColors.warningSoft,
        StatusTone.danger => AppColors.dangerSoft,
        StatusTone.primary => AppColors.primarySoft,
        StatusTone.neutral => AppColors.surfaceMuted,
      };
}

/// Pill with a coloured dot: "Online", "Connected", "Offline"...
class StatusBadge extends StatelessWidget {
  const StatusBadge({
    super.key,
    required this.label,
    required this.tone,
    this.showDot = true,
    this.compact = false,
  });

  final String label;
  final StatusTone tone;
  final bool showDot;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: EdgeInsets.symmetric(
        horizontal: compact ? AppSpacing.sm : AppSpacing.md,
        vertical: compact ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: tone.softColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showDot) ...[
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: 7,
              height: 7,
              decoration: BoxDecoration(color: tone.color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: tone == StatusTone.offline || tone == StatusTone.neutral
                  ? AppColors.textSecondary
                  : tone.color,
              fontWeight: FontWeight.w600,
              fontSize: compact ? 11 : 12,
            ),
          ),
        ],
      ),
    );
  }
}
