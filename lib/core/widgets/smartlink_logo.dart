import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/theme.dart';

/// Original geometric mark: a rounded square holding a node with two
/// broadcast arcs. Drawn with primitives so it scales to any size.
class SmartLinkLogo extends StatelessWidget {
  const SmartLinkLogo({
    super.key,
    this.size = 64,
    this.background = AppColors.primary,
    this.foreground = AppColors.onPrimary,
  });

  final double size;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _LogoPainter(background: background, foreground: foreground),
      ),
    );
  }
}

class _LogoPainter extends CustomPainter {
  const _LogoPainter({required this.background, required this.foreground});

  final Color background;
  final Color foreground;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    final rect = Offset.zero & Size(s, s);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(s * 0.28)),
      Paint()..color = background,
    );

    final node = Offset(s * 0.36, s * 0.64);
    final stroke = Paint()
      ..color = foreground
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.075
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(node, s * 0.075, Paint()..color = foreground);
    const startAngle = -math.pi * 0.47;
    const sweep = math.pi * 0.42;
    for (final radius in [s * 0.21, s * 0.34]) {
      canvas.drawArc(
        Rect.fromCircle(center: node, radius: radius),
        startAngle,
        sweep,
        false,
        stroke,
      );
    }
  }

  @override
  bool shouldRepaint(_LogoPainter oldDelegate) =>
      oldDelegate.background != background || oldDelegate.foreground != foreground;
}
