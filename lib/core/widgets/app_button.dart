import 'package:flutter/material.dart';

import '../../app/theme.dart';

enum AppButtonVariant { primary, secondary, danger }

/// Full-width action button with a built-in loading state.
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.loading = false,
    this.variant = AppButtonVariant.primary,
    this.height = 52,
  });

  const AppButton.secondary({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.loading = false,
    this.height = 52,
  }) : variant = AppButtonVariant.secondary;

  const AppButton.danger({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.loading = false,
    this.height = 52,
  }) : variant = AppButtonVariant.danger;

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool loading;
  final AppButtonVariant variant;
  final double height;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !loading;
    final foreground = switch (variant) {
      AppButtonVariant.primary => AppColors.onPrimary,
      AppButtonVariant.secondary => AppColors.textPrimary,
      AppButtonVariant.danger => AppColors.danger,
    };

    final child = AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: loading
          ? SizedBox(
              key: const ValueKey('loading'),
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.4,
                color: foreground,
              ),
            )
          : Row(
              key: const ValueKey('label'),
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 20),
                  const SizedBox(width: AppSpacing.sm),
                ],
                Text(label),
              ],
            ),
    );

    final size = Size.fromHeight(height);
    return switch (variant) {
      AppButtonVariant.primary => ElevatedButton(
          onPressed: enabled ? onPressed : null,
          style: ElevatedButton.styleFrom(minimumSize: size),
          child: child,
        ),
      AppButtonVariant.secondary => OutlinedButton(
          onPressed: enabled ? onPressed : null,
          style: OutlinedButton.styleFrom(minimumSize: size),
          child: child,
        ),
      AppButtonVariant.danger => OutlinedButton(
          onPressed: enabled ? onPressed : null,
          style: OutlinedButton.styleFrom(
            minimumSize: size,
            foregroundColor: AppColors.danger,
            backgroundColor: AppColors.dangerSoft,
            side: BorderSide.none,
          ),
          child: child,
        ),
    };
  }
}
