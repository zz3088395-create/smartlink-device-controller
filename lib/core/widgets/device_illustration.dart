import 'package:flutter/material.dart';

import '../../app/theme.dart';

/// Abstract hardware silhouette: a rounded slab with a status LED and three
/// channel bars. It is intentionally generic and resembles no real product.
///
/// When [channels] is given the bars reflect the live intensities, which makes
/// the illustration double as a state indicator on the control screen.
class DeviceIllustration extends StatelessWidget {
  const DeviceIllustration({
    super.key,
    this.size = 120,
    this.active = false,
    this.online = true,
    this.channels,
    this.muted = false,
  });

  final double size;
  final bool active;
  final bool online;
  final List<int>? channels;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final width = size * 0.62;
    final height = size;
    final body = muted ? AppColors.deviceBodyMuted : AppColors.deviceBody;
    final ledColor = !online
        ? AppColors.offline
        : active
            ? AppColors.online
            : AppColors.textTertiary;
    final values = channels ?? const [0, 0, 0];

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOut,
            width: active ? size : size * 0.8,
            height: active ? size : size * 0.8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: active
                  ? AppColors.primary.withValues(alpha: 0.10)
                  : Colors.transparent,
            ),
          ),
          Container(
            width: width,
            height: height * 0.82,
            decoration: BoxDecoration(
              color: body,
              borderRadius: BorderRadius.circular(size * 0.14),
              boxShadow: muted ? null : AppShadows.card,
            ),
            padding: EdgeInsets.all(size * 0.09),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: size * 0.07,
                  height: size * 0.07,
                  decoration: BoxDecoration(
                    color: ledColor,
                    shape: BoxShape.circle,
                    boxShadow: active
                        ? [
                            BoxShadow(
                              color: ledColor.withValues(alpha: 0.6),
                              blurRadius: size * 0.06,
                            ),
                          ]
                        : null,
                  ),
                ),
                const Spacer(),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: List.generate(3, (i) {
                    final level = (values[i].clamp(0, 100)) / 100;
                    final minHeight = size * 0.06;
                    final maxHeight = size * 0.34;
                    return Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(right: i == 2 ? 0 : size * 0.04),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeOut,
                          height: minHeight + (maxHeight - minHeight) * level,
                          decoration: BoxDecoration(
                            color: active && level > 0
                                ? AppColors.primary
                                : (muted
                                    ? AppColors.surface
                                    : AppColors.textSecondary.withValues(alpha: 0.5)),
                            borderRadius: BorderRadius.circular(size * 0.02),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
