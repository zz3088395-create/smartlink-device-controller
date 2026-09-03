import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../core/utils/throttle.dart';

/// Labelled 0-100 slider. Local drag position is shown immediately; the
/// device receives at most one command per [throttle] interval and always the
/// final value on release.
class ChannelSlider extends StatefulWidget {
  const ChannelSlider({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.enabled = true,
    this.throttle = const Duration(milliseconds: 80),
  });

  final String label;
  final int value;
  final ValueChanged<int> onChanged;
  final bool enabled;
  final Duration throttle;

  @override
  State<ChannelSlider> createState() => _ChannelSliderState();
}

class _ChannelSliderState extends State<ChannelSlider> {
  late final Throttler _throttler = Throttler(widget.throttle);
  double? _dragValue;

  @override
  void dispose() {
    _throttler.dispose();
    super.dispose();
  }

  void _onChanged(double value) {
    setState(() => _dragValue = value);
    _throttler.run(() => widget.onChanged(value.round()));
  }

  void _onChangeEnd(double value) {
    _throttler.cancel();
    widget.onChanged(value.round());
    setState(() => _dragValue = null);
  }

  @override
  Widget build(BuildContext context) {
    final shown = _dragValue ?? widget.value.toDouble();
    return Row(
      children: [
        SizedBox(
          width: 84,
          child: Text(widget.label, style: AppTextStyles.bodyStrong),
        ),
        Expanded(
          child: Slider(
            value: shown.clamp(0, 100),
            min: 0,
            max: 100,
            onChanged: widget.enabled ? _onChanged : null,
            onChangeEnd: widget.enabled ? _onChangeEnd : null,
          ),
        ),
        SizedBox(
          width: 44,
          child: Text(
            '${shown.round()}%',
            textAlign: TextAlign.right,
            style: AppTextStyles.bodyStrong.copyWith(
              fontFeatures: const [FontFeature.tabularFigures()],
              color: widget.enabled ? AppColors.textPrimary : AppColors.textTertiary,
            ),
          ),
        ),
      ],
    );
  }
}
