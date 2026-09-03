import 'package:flutter/material.dart';

import '../../app/theme.dart';
import 'app_button.dart';

/// Modal sheet with the app's rounded top, safe-area padding and consistent
/// horizontal margins.
Future<T?> showAppBottomSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  bool isDismissible = true,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isDismissible: isDismissible,
    enableDrag: isDismissible,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) => Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.page,
        right: AppSpacing.page,
        bottom: MediaQuery.paddingOf(context).bottom + AppSpacing.xl,
      ),
      child: builder(context),
    ),
  );
}

/// Yes/no confirmation. Resolves to `true` when the primary action is chosen.
Future<bool> showConfirmSheet(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Confirm',
  String cancelLabel = 'Cancel',
  bool destructive = false,
  IconData? icon,
}) async {
  final result = await showAppBottomSheet<bool>(
    context,
    builder: (context) => Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (icon != null) ...[
          Center(
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: destructive ? AppColors.dangerSoft : AppColors.primarySoft,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 30,
                color: destructive ? AppColors.danger : AppColors.primary,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
        Text(title, style: AppTextStyles.title, textAlign: TextAlign.center),
        const SizedBox(height: AppSpacing.sm),
        Text(
          message,
          style: AppTextStyles.bodySecondary,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.xxl),
        if (destructive)
          AppButton.danger(
            label: confirmLabel,
            onPressed: () => Navigator.of(context).pop(true),
          )
        else
          AppButton(
            label: confirmLabel,
            onPressed: () => Navigator.of(context).pop(true),
          ),
        const SizedBox(height: AppSpacing.sm),
        AppButton.secondary(
          label: cancelLabel,
          onPressed: () => Navigator.of(context).pop(false),
        ),
      ],
    ),
  );
  return result ?? false;
}
