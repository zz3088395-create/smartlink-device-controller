import 'dart:async';

import 'package:flutter/foundation.dart';

/// Runs at most one action per [interval]; the latest action queued during
/// the quiet period runs when the period ends. Used to rate-limit slider
/// updates sent to the device.
class Throttler {
  Throttler(this.interval);

  final Duration interval;

  Timer? _timer;
  VoidCallback? _pending;
  DateTime? _lastRun;

  void run(VoidCallback action) {
    final now = DateTime.now();
    final last = _lastRun;
    if (last == null || now.difference(last) >= interval) {
      _lastRun = now;
      action();
      return;
    }
    _pending = action;
    _timer ??= Timer(interval - now.difference(last), _flush);
  }

  void _flush() {
    _timer = null;
    final pending = _pending;
    _pending = null;
    if (pending != null) {
      _lastRun = DateTime.now();
      pending();
    }
  }

  /// Drops any queued action without running it.
  void cancel() {
    _timer?.cancel();
    _timer = null;
    _pending = null;
  }

  void dispose() => cancel();
}
