import 'package:flutter/material.dart';

import '../../app/theme.dart';

/// Icon inside a soft rounded square, used by list rows and quick actions.
class IconTile extends StatelessWidget {
  const IconTile({
    super.key,
    required this.icon,
    this.size = 44,
    this.color = AppColors.primary,
    this.background = AppColors.primarySoft,
    this.radius = AppRadius.sm,
  });

  final IconData icon;
  final double size;
  final Color color;
  final Color background;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Icon(icon, size: size * 0.5, color: color),
    );
  }
}

/// Label/value pair used in detail lists.
class InfoRow extends StatelessWidget {
  const InfoRow({
    super.key,
    required this.label,
    required this.value,
    this.trailing,
  });

  final String label;
  final String value;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Row(
        children: [
          Expanded(child: Text(label, style: AppTextStyles.bodySecondary)),
          if (trailing != null)
            trailing!
          else
            Text(value, style: AppTextStyles.bodyStrong),
        ],
      ),
    );
  }
}
