import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/theme.dart';

/// Concentric rings with a slowly rotating sweep while scanning.
class RadarIndicator extends StatefulWidget {
  const RadarIndicator({super.key, required this.active, this.size = 168});

  final bool active;
  final double size;

  @override
  State<RadarIndicator> createState() => _RadarIndicatorState();
}

class _RadarIndicatorState extends State<RadarIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  );

  @override
  void initState() {
    super.initState();
    if (widget.active) _controller.repeat();
  }

  @override
  void didUpdateWidget(RadarIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.active && _controller.isAnimating) {
      _controller.animateTo(1, duration: const Duration(milliseconds: 600));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) => CustomPaint(
          painter: _RadarPainter(
            progress: _controller.value,
            active: widget.active,
          ),
          child: child,
        ),
        child: Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: widget.size * 0.3,
            height: widget.size * 0.3,
            decoration: BoxDecoration(
              color: widget.active ? AppColors.primary : AppColors.primarySoft,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.bluetooth_rounded,
              size: widget.size * 0.15,
              color: widget.active ? AppColors.onPrimary : AppColors.primary,
            ),
          ),
        ),
      ),
    );
  }
}

class _RadarPainter extends CustomPainter {
  const _RadarPainter({required this.progress, required this.active});

  final double progress;
  final bool active;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2;
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = AppColors.border;
    for (final factor in [0.45, 0.72, 1.0]) {
      canvas.drawCircle(center, radius * factor, ring);
    }

    if (!active) return;
    final angle = progress * 2 * math.pi;
    final sweep = Paint()
      ..shader = SweepGradient(
        startAngle: 0,
        endAngle: math.pi / 2,
        colors: [
          AppColors.primary.withValues(alpha: 0),
          AppColors.primary.withValues(alpha: 0.22),
        ],
        transform: GradientRotation(angle - math.pi / 2),
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      angle - math.pi / 2,
      math.pi / 2,
      true,
      sweep,
    );
    final needle = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.6)
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      center,
      center + Offset(math.cos(angle), math.sin(angle)) * radius,
      needle,
    );
  }

  @override
  bool shouldRepaint(_RadarPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.active != active;
}
