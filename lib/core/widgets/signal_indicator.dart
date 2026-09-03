import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../utils/signal_quality.dart';

/// Four signal bars derived from RSSI plus an optional label / dBm readout.
class SignalIndicator extends StatelessWidget {
  const SignalIndicator({
    super.key,
    required this.rssi,
    this.showLabel = true,
    this.showDbm = false,
    this.size = 14,
  });

  final int? rssi;
  final bool showLabel;
  final bool showDbm;
  final double size;

  @override
  Widget build(BuildContext context) {
    final quality = rssi == null ? null : SignalQuality.fromRssi(rssi!);
    final activeBars = quality?.bars ?? 0;
    final color = switch (quality) {
      null => AppColors.textTertiary,
      SignalQuality.weak => AppColors.danger,
      SignalQuality.fair => AppColors.warning,
      _ => AppColors.online,
    };

    final bars = Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(4, (i) {
        final active = i < activeBars;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: EdgeInsets.only(right: i == 3 ? 0 : 2),
          width: size * 0.22,
          height: size * (0.4 + 0.2 * i),
          decoration: BoxDecoration(
            color: active ? color : AppColors.border,
            borderRadius: BorderRadius.circular(2),
          ),
        );
      }),
    );

    if (!showLabel && !showDbm) return bars;

    final text = [
      if (showLabel) quality?.label ?? 'No signal',
      if (showDbm && rssi != null) '$rssi dBm',
    ].join(' · ');

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        bars,
        const SizedBox(width: 6),
        Text(
          text,
          style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}
