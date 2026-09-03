import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../core/widgets/widgets.dart';
import 'preset_models.dart';

/// Eight-step timeline: each column shows the A/B/C intensities as bars.
class PatternTimeline extends StatelessWidget {
  const PatternTimeline({
    super.key,
    required this.steps,
    required this.selectedIndex,
    required this.onSelect,
    this.playingIndex,
    this.barHeight = 128,
  });

  final List<PatternStep> steps;
  final int selectedIndex;
  final int? playingIndex;
  final ValueChanged<int> onSelect;
  final double barHeight;

  static const List<Color> channelColors = [
    AppColors.primary,
    Color(0xFF8C98FF),
    Color(0xFFC3C9FF),
  ];
  static const List<String> channelLabels = ['A', 'B', 'C'];

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
            child: Row(
              children: [
                for (var i = 0; i < channelLabels.length; i++) ...[
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: channelColors[i],
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text('Channel ${channelLabels[i]}', style: AppTextStyles.caption),
                  const SizedBox(width: AppSpacing.md),
                ],
                const Spacer(),
                Text(
                  '${PatternData.stepMs} ms / step',
                  style: AppTextStyles.overline,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            height: barHeight + 34,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < steps.length; i++)
                  Expanded(
                    child: _StepColumn(
                      index: i,
                      step: steps[i],
                      selected: i == selectedIndex,
                      playing: i == playingIndex,
                      onTap: () => onSelect(i),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StepColumn extends StatelessWidget {
  const _StepColumn({
    required this.index,
    required this.step,
    required this.selected,
    required this.playing,
    required this.onTap,
  });

  final int index;
  final PatternStep step;
  final bool selected;
  final bool playing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final borderColor = playing
        ? AppColors.online
        : selected
            ? AppColors.primary
            : Colors.transparent;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(horizontal: 2),
        padding: const EdgeInsets.fromLTRB(4, 6, 4, 4),
        decoration: BoxDecoration(
          color: selected ? AppColors.primarySoft : AppColors.background,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(color: borderColor, width: 1.5),
        ),
        child: Column(
          children: [
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (var c = 0; c < step.channels.length; c++) ...[
                    if (c > 0) const SizedBox(width: 2),
                    Expanded(
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: AnimatedFractionallySizedBox(
                          duration: const Duration(milliseconds: 220),
                          curve: Curves.easeOut,
                          heightFactor:
                              (step.channels[c] / PatternData.maxIntensity).clamp(0.04, 1.0),
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: PatternTimeline.channelColors[c],
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${index + 1}',
              style: AppTextStyles.caption.copyWith(
                color: selected ? AppColors.primary : AppColors.textTertiary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
