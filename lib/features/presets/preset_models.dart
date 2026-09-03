import 'dart:convert';

import '../../ble/ble_models.dart';
import '../../core/api/api_response.dart';
import '../../core/utils/date_utils.dart';

/// One entry of `control_preset.pattern_data`: `{"ms":500,"ch":[a,b,c]}`.
class PatternStep {
  PatternStep({this.ms = PatternData.stepMs, required List<int> channels})
      : channels = List.unmodifiable(channels);

  final int ms;

  /// Intensities for channel A, B, C in that order.
  final List<int> channels;

  PatternStep withChannel(int index, int value) {
    final next = List<int>.of(channels);
    next[index] = value;
    return PatternStep(ms: ms, channels: next);
  }

  Map<String, dynamic> toJson() => {'ms': ms, 'ch': channels};

  static PatternStep? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final ch = raw['ch'];
    if (ch is! List) return null;
    final channels = ch.map((v) => v is num ? v.toInt() : int.tryParse('$v') ?? 0).toList();
    final ms = raw['ms'];
    return PatternStep(
      ms: ms is num ? ms.toInt() : PatternData.stepMs,
      channels: channels,
    );
  }
}

class PatternValidationError implements Exception {
  const PatternValidationError(this.message);

  final String message;

  @override
  String toString() => 'PatternValidationError: $message';
}

/// Encoding rules shared by the editor, the player and the API layer.
abstract final class PatternData {
  static const int stepMs = 500;
  static const int stepCount = 8;
  static const int channelCount = BleDeviceState.channelCount;
  static const int minIntensity = 0;
  static const int maxIntensity = 100;

  /// `control_preset.pattern_data` column limit (`@Size(max = 4000)`).
  static const int maxEncodedLength = 4000;

  static Duration totalDuration(List<PatternStep> steps) =>
      Duration(milliseconds: steps.fold(0, (sum, s) => sum + s.ms));

  /// Parses the backend JSON. Malformed input yields an empty list.
  static List<PatternStep> decode(String? json) {
    if (json == null || json.trim().isEmpty) return const [];
    try {
      final raw = jsonDecode(json);
      if (raw is! List) return const [];
      return raw.map(PatternStep.fromJson).whereType<PatternStep>().toList();
    } on FormatException {
      return const [];
    }
  }

  static String encode(List<PatternStep> steps) =>
      jsonEncode(steps.map((s) => s.toJson()).toList());

  /// Throws [PatternValidationError] unless every step has three channels in
  /// 0-100 and the encoded payload fits the backend column.
  static void validate(List<PatternStep> steps) {
    if (steps.isEmpty) {
      throw const PatternValidationError('Add at least one step.');
    }
    for (var i = 0; i < steps.length; i++) {
      final step = steps[i];
      if (step.channels.length != channelCount) {
        throw PatternValidationError('Step ${i + 1} must have $channelCount channels.');
      }
      if (step.ms <= 0) {
        throw PatternValidationError('Step ${i + 1} must last longer than 0 ms.');
      }
      for (final value in step.channels) {
        if (value < minIntensity || value > maxIntensity) {
          throw PatternValidationError(
            'Step ${i + 1}: intensity must be between $minIntensity and $maxIntensity.',
          );
        }
      }
    }
    if (encode(steps).length > maxEncodedLength) {
      throw const PatternValidationError('The pattern is too long to save.');
    }
  }

  /// Exactly [stepCount] steps for the editor: trims extras, pads with the
  /// last step (or silence).
  static List<PatternStep> normalize(List<PatternStep> steps, {int count = stepCount}) {
    final result = steps.take(count).map((s) {
      final ch = List<int>.generate(
        channelCount,
        (i) => i < s.channels.length
            ? s.channels[i].clamp(minIntensity, maxIntensity)
            : 0,
      );
      return PatternStep(ms: s.ms > 0 ? s.ms : stepMs, channels: ch);
    }).toList();
    while (result.length < count) {
      result.add(PatternStep(channels: List.filled(channelCount, 0)));
    }
    return result;
  }

  /// Starting point for a new pattern: a gentle ramp that reads well in the
  /// timeline without being a real-world profile.
  static List<PatternStep> starter() => [
        PatternStep(channels: const [20, 40, 60]),
        PatternStep(channels: const [40, 70, 90]),
        PatternStep(channels: const [60, 55, 70]),
        PatternStep(channels: const [80, 40, 50]),
        PatternStep(channels: const [60, 55, 70]),
        PatternStep(channels: const [40, 70, 90]),
        PatternStep(channels: const [20, 40, 60]),
        PatternStep(channels: const [10, 20, 30]),
      ];
}

/// `ControlPresetDO` as returned by `/app/presets`.
class ControlPreset {
  const ControlPreset({
    required this.id,
    required this.presetName,
    required this.mode,
    required this.channel1,
    required this.channel2,
    required this.channel3,
    this.userId,
    this.patternData,
    this.createTime,
    this.updateTime,
  });

  final String id;

  /// `null` for system presets.
  final String? userId;
  final String presetName;
  final ControlMode mode;
  final int channel1;
  final int channel2;
  final int channel3;
  final String? patternData;
  final DateTime? createTime;
  final DateTime? updateTime;

  bool get builtIn => userId == null;
  bool get isCustom => mode == ControlMode.custom;
  List<int> get channels => [channel1, channel2, channel3];
  List<PatternStep> get steps => PatternData.decode(patternData);

  factory ControlPreset.fromJson(JsonMap json) {
    return ControlPreset(
      id: json['id'].toString(),
      userId: json['userId']?.toString(),
      presetName: json['presetName']?.toString() ?? 'Preset',
      mode: ControlMode.fromApi(json['mode']?.toString()),
      channel1: _toInt(json['channel1']) ?? 0,
      channel2: _toInt(json['channel2']) ?? 0,
      channel3: _toInt(json['channel3']) ?? 0,
      patternData: json['patternData']?.toString(),
      createTime: parseApiDateTime(json['createTime']),
      updateTime: parseApiDateTime(json['updateTime']),
    );
  }
}

/// `AppSavePresetReqDTO`
class SavePresetRequest {
  const SavePresetRequest({
    required this.presetName,
    required this.mode,
    required this.channel1,
    required this.channel2,
    required this.channel3,
    this.patternData,
  });

  /// Custom preset from editor steps. `channel1-3` mirror the first step so
  /// the admin console shows meaningful base values.
  factory SavePresetRequest.custom({
    required String presetName,
    required List<PatternStep> steps,
  }) {
    PatternData.validate(steps);
    final first = steps.first.channels;
    return SavePresetRequest(
      presetName: presetName,
      mode: ControlMode.custom,
      channel1: first[0],
      channel2: first[1],
      channel3: first[2],
      patternData: PatternData.encode(steps),
    );
  }

  final String presetName;
  final ControlMode mode;
  final int channel1;
  final int channel2;
  final int channel3;
  final String? patternData;

  JsonMap toJson() => {
        'presetName': presetName,
        'mode': mode.apiValue,
        'channel1': channel1,
        'channel2': channel2,
        'channel3': channel3,
        'patternData': ?patternData,
      };
}

int? _toInt(Object? value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString());
}
