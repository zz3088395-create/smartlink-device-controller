import 'package:flutter/material.dart';

import '../../app/theme.dart';

/// Battery icon + animated percentage. Colour only changes under 20 %.
class BatteryIndicator extends StatelessWidget {
  const BatteryIndicator({
    super.key,
    required this.level,
    this.size = 18,
    this.textStyle,
  });

  final int? level;
  final double size;
  final TextStyle? textStyle;

  static Color colorFor(int? level) {
    if (level == null) return AppColors.textTertiary;
    if (level < 10) return AppColors.danger;
    if (level < 20) return AppColors.warning;
    return AppColors.online;
  }

  static IconData iconFor(int? level) {
    if (level == null) return Icons.battery_unknown_rounded;
    if (level >= 95) return Icons.battery_full_rounded;
    if (level >= 80) return Icons.battery_6_bar_rounded;
    if (level >= 65) return Icons.battery_5_bar_rounded;
    if (level >= 50) return Icons.battery_4_bar_rounded;
    if (level >= 35) return Icons.battery_3_bar_rounded;
    if (level >= 20) return Icons.battery_2_bar_rounded;
    if (level >= 10) return Icons.battery_1_bar_rounded;
    return Icons.battery_0_bar_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final style = textStyle ??
        AppTextStyles.caption.copyWith(color: AppColors.textSecondary);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(iconFor(level), size: size, color: colorFor(level)),
        const SizedBox(width: 4),
        if (level == null)
          Text('—', style: style)
        else
          TweenAnimationBuilder<double>(
            tween: Tween(end: level!.toDouble()),
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOutCubic,
            builder: (context, value, _) => Text('${value.round()}%', style: style),
          ),
      ],
    );
  }
}
