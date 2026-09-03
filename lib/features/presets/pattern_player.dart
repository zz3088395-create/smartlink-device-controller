import 'dart:async';

import '../../ble/ble_models.dart';
import '../../ble/ble_service.dart';
import 'preset_models.dart';

/// Plays a pattern on the connected device, one step at a time.
///
/// For every step the three channel intensities are written through
/// [BleService.setIntensity], then the player waits `step.ms` before moving
/// on. The device is switched to [ControlMode.custom] and started for the
/// duration of the preview; if it was idle before, it is stopped again at the
/// end. [stop] cancels immediately.
class PatternPlayer {
  PatternPlayer(this._ble);

  final BleService _ble;

  int _generation = 0;
  int? _currentStep;

  bool get isPlaying => _currentStep != null;
  int? get currentStep => _currentStep;

  /// Completes when the pattern finished or was stopped. [onStep] receives
  /// the index being played and `null` when playback ends.
  Future<void> play(
    List<PatternStep> steps, {
    void Function(int? index)? onStep,
  }) async {
    PatternData.validate(steps);
    final generation = ++_generation;
    final wasRunning = _ble.currentDeviceState?.running ?? false;

    try {
      await _ble.setMode(ControlMode.custom);
      if (!wasRunning) await _ble.start();

      for (var i = 0; i < steps.length; i++) {
        if (generation != _generation) return;
        _currentStep = i;
        onStep?.call(i);
        final step = steps[i];
        for (var ch = 0; ch < step.channels.length; ch++) {
          if (generation != _generation) return;
          // Channels are 1-based on the wire (0 = all).
          await _ble.setIntensity(ch + 1, step.channels[ch]);
        }
        await Future<void>.delayed(Duration(milliseconds: step.ms));
      }

      if (generation == _generation && !wasRunning) {
        await _ble.stop();
      }
    } on BleException {
      // Link dropped mid-preview; the control screen reflects the new state.
    } finally {
      if (generation == _generation) {
        _currentStep = null;
        onStep?.call(null);
      }
    }
  }

  /// Cancels the current preview. Safe to call when idle.
  void stop() {
    _generation++;
    _currentStep = null;
  }
}
