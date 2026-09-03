import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:smartlink_mobile/ble/ble_models.dart';
import 'package:smartlink_mobile/ble/mock_ble_service.dart';
import 'package:smartlink_mobile/features/presets/pattern_player.dart';
import 'package:smartlink_mobile/features/presets/preset_models.dart';

void main() {
  late MockBleService ble;
  late PatternPlayer player;

  final steps = [
    PatternStep(ms: 10, channels: const [10, 20, 30]),
    PatternStep(ms: 10, channels: const [40, 50, 60]),
    PatternStep(ms: 10, channels: const [70, 80, 90]),
  ];

  setUp(() async {
    ble = MockBleService(
      random: Random(3),
      connectDelay: Duration.zero,
      disconnectDelay: Duration.zero,
      commandLatency: Duration.zero,
      notifyIntervalMin: const Duration(seconds: 10),
      notifyIntervalMax: const Duration(seconds: 10),
    );
    player = PatternPlayer(ble);
    await ble.connect('mock-sl100-mini');
  });

  tearDown(() => ble.dispose());

  test('plays every step in order and reports progress', () async {
    final seen = <int?>[];
    await player.play(steps, onStep: seen.add);

    expect(seen, [0, 1, 2, null]);
    expect(ble.currentDeviceState!.channels, [70, 80, 90]);
    expect(ble.currentDeviceState!.mode, ControlMode.custom);
    expect(player.isPlaying, isFalse);
  });

  test('restores the idle state when the device was not running', () async {
    expect(ble.currentDeviceState!.running, isFalse);
    await player.play(steps);
    expect(ble.currentDeviceState!.running, isFalse, reason: 'stopped after preview');
  });

  test('leaves a running device running', () async {
    await ble.start();
    await player.play(steps);
    expect(ble.currentDeviceState!.running, isTrue);
  });

  test('stop cancels playback before the last step', () async {
    final seen = <int?>[];
    final playing = player.play(
      [for (final s in steps) PatternStep(ms: 40, channels: s.channels)],
      onStep: seen.add,
    );
    await Future<void>.delayed(const Duration(milliseconds: 15));
    player.stop();
    await playing;

    expect(seen, isNot(contains(2)));
    expect(ble.currentDeviceState!.channels, isNot([70, 80, 90]));
  });

  test('rejects an invalid pattern before sending anything', () async {
    await expectLater(
      player.play([PatternStep(channels: const [0, 0, 300])]),
      throwsA(isA<PatternValidationError>()),
    );
    expect(ble.lastCommand, isNull);
  });
}
