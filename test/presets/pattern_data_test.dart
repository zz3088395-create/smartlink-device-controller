import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:smartlink_mobile/ble/ble_models.dart';
import 'package:smartlink_mobile/features/presets/preset_models.dart';

void main() {
  const seedJson =
      '[{"ms":500,"ch":[20,20,20]},{"ms":500,"ch":[40,30,20]},{"ms":800,"ch":[60,45,30]}]';

  group('PatternData', () {
    test('decodes the backend seed format', () {
      final steps = PatternData.decode(seedJson);
      expect(steps, hasLength(3));
      expect(steps[1].ms, 500);
      expect(steps[1].channels, [40, 30, 20]);
      expect(steps[2].ms, 800);
    });

    test('encode produces the exact backend shape', () {
      final steps = [
        PatternStep(channels: const [20, 40, 60]),
        PatternStep(channels: const [40, 70, 90]),
      ];
      expect(
        PatternData.encode(steps),
        '[{"ms":500,"ch":[20,40,60]},{"ms":500,"ch":[40,70,90]}]',
      );
      expect(jsonDecode(PatternData.encode(steps)), isA<List<dynamic>>());
    });

    test('malformed input decodes to an empty list', () {
      expect(PatternData.decode(null), isEmpty);
      expect(PatternData.decode(''), isEmpty);
      expect(PatternData.decode('not json'), isEmpty);
      expect(PatternData.decode('{"ms":500}'), isEmpty);
    });

    test('validate rejects out-of-range intensities', () {
      expect(
        () => PatternData.validate([PatternStep(channels: const [0, 101, 50])]),
        throwsA(isA<PatternValidationError>()),
      );
      expect(
        () => PatternData.validate([PatternStep(channels: const [-1, 0, 0])]),
        throwsA(isA<PatternValidationError>()),
      );
      expect(
        () => PatternData.validate([PatternStep(channels: const [10, 20])]),
        throwsA(isA<PatternValidationError>()),
      );
      expect(() => PatternData.validate(const []), throwsA(isA<PatternValidationError>()));
    });

    test('validate accepts the starter and an 8-step pattern', () {
      expect(() => PatternData.validate(PatternData.starter()), returnsNormally);
      expect(PatternData.starter(), hasLength(PatternData.stepCount));
    });

    test('normalize pads to 8 steps and clamps values', () {
      final normalized = PatternData.normalize([
        PatternStep(channels: const [120, -5, 50]),
      ]);
      expect(normalized, hasLength(8));
      expect(normalized.first.channels, [100, 0, 50]);
      expect(normalized.last.channels, [0, 0, 0]);
    });

    test('normalize trims longer patterns', () {
      final normalized = PatternData.normalize(
        List.generate(12, (i) => PatternStep(channels: [i, i, i])),
      );
      expect(normalized, hasLength(8));
      expect(normalized.last.channels, [7, 7, 7]);
    });

    test('totalDuration sums step lengths', () {
      expect(PatternData.totalDuration(PatternData.starter()).inMilliseconds, 4000);
    });
  });

  group('SavePresetRequest.custom', () {
    test('mirrors the first step into channel1-3 and encodes patternData', () {
      final request = SavePresetRequest.custom(
        presetName: 'Evening Ramp',
        steps: [
          PatternStep(channels: const [20, 40, 60]),
          PatternStep(channels: const [40, 70, 90]),
        ],
      );
      final json = request.toJson();
      expect(json['mode'], 'CUSTOM');
      expect(json['channel1'], 20);
      expect(json['channel2'], 40);
      expect(json['channel3'], 60);
      expect(json['patternData'], '[{"ms":500,"ch":[20,40,60]},{"ms":500,"ch":[40,70,90]}]');
    });

    test('refuses invalid steps before touching the network', () {
      expect(
        () => SavePresetRequest.custom(
          presetName: 'Bad',
          steps: [PatternStep(channels: const [0, 0, 200])],
        ),
        throwsA(isA<PatternValidationError>()),
      );
    });
  });

  group('ControlPreset', () {
    test('built-in when userId is null, parses pattern steps', () {
      final preset = ControlPreset.fromJson({
        'id': '4000004',
        'userId': null,
        'presetName': 'Evening Ramp',
        'mode': 'CUSTOM',
        'channel1': 20,
        'channel2': 20,
        'channel3': 20,
        'patternData': seedJson,
      });
      expect(preset.builtIn, isTrue);
      expect(preset.mode, ControlMode.custom);
      expect(preset.steps, hasLength(3));

      final mine = ControlPreset.fromJson({
        'id': '4000005',
        'userId': '1000002',
        'presetName': 'Focus Steady',
        'mode': 'CUSTOM',
        'channel1': 35,
        'channel2': 35,
        'channel3': 35,
      });
      expect(mine.builtIn, isFalse);
      expect(mine.steps, isEmpty);
    });
  });
}
