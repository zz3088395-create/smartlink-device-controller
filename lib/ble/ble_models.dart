/// Data types shared by every [BleService] implementation and the UI.
library;

/// Operating modes understood by the device. [code] is the byte sent on the
/// wire, [apiValue] the string stored by the backend (`ControlModeEnum`).
enum ControlMode {
  pulse(1, 'PULSE', 'Pulse', 'Steady repeating intensity'),
  wave(2, 'WAVE', 'Wave', 'Smooth rise and fall'),
  rhythm(3, 'RHYTHM', 'Rhythm', 'Dynamic alternating pattern'),
  custom(4, 'CUSTOM', 'Custom', 'Create your own sequence');

  const ControlMode(this.code, this.apiValue, this.label, this.description);

  final int code;
  final String apiValue;
  final String label;
  final String description;

  static ControlMode? fromCode(int code) {
    for (final mode in values) {
      if (mode.code == code) return mode;
    }
    return null;
  }

  static ControlMode fromApi(String? value) {
    for (final mode in values) {
      if (mode.apiValue == value) return mode;
    }
    return ControlMode.pulse;
  }
}

/// Commands of the fictional 3-byte SmartLink demo protocol.
enum BleCommand {
  start(0x01),
  stop(0x02),
  setIntensity(0x03),
  setMode(0x04);

  const BleCommand(this.code);

  final int code;

  static BleCommand? fromCode(int code) {
    for (final command in values) {
      if (command.code == code) return command;
    }
    return null;
  }
}

/// A device seen while scanning.
class BleDeviceInfo {
  const BleDeviceInfo({
    required this.id,
    required this.name,
    required this.model,
    required this.identifier,
    required this.rssi,
    this.firmwareVersion,
  });

  /// Transport-level id (peripheral id / MAC). Only meaningful to the service.
  final String id;

  /// Advertised name, e.g. "SmartLink Mini".
  final String name;

  /// Product model, e.g. "SL-100".
  final String model;

  /// Stable device identifier reported to the backend, e.g. "SL100-B41E0D77".
  final String identifier;

  final int rssi;
  final String? firmwareVersion;

  BleDeviceInfo copyWith({int? rssi}) {
    return BleDeviceInfo(
      id: id,
      name: name,
      model: model,
      identifier: identifier,
      rssi: rssi ?? this.rssi,
      firmwareVersion: firmwareVersion,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is BleDeviceInfo &&
      other.id == id &&
      other.rssi == rssi &&
      other.identifier == identifier;

  @override
  int get hashCode => Object.hash(id, rssi, identifier);
}

enum BleConnectionStatus { disconnected, connecting, connected, disconnecting }

class BleConnectionState {
  const BleConnectionState({
    required this.status,
    this.device,
    this.error,
  });

  const BleConnectionState.disconnected([this.error])
      : status = BleConnectionStatus.disconnected,
        device = null;

  final BleConnectionStatus status;

  /// The peer for any status other than [BleConnectionStatus.disconnected].
  final BleDeviceInfo? device;

  /// Human readable reason for the last drop, if any.
  final String? error;

  bool get isConnected => status == BleConnectionStatus.connected;
  bool get isDisconnected => status == BleConnectionStatus.disconnected;
}

/// Live state reported by a connected device.
class BleDeviceState {
  BleDeviceState({
    required List<int> channels,
    required this.mode,
    required this.running,
    required this.batteryLevel,
    required this.rssi,
  })  : assert(channels.length == channelCount, 'Exactly 3 channels'),
        channels = List.unmodifiable(channels);

  static const int channelCount = 3;

  /// Intensity per channel (A, B, C), 0-100.
  final List<int> channels;
  final ControlMode mode;
  final bool running;
  final int batteryLevel;
  final int rssi;

  int channel(int index) => channels[index];

  BleDeviceState copyWith({
    List<int>? channels,
    ControlMode? mode,
    bool? running,
    int? batteryLevel,
    int? rssi,
  }) {
    return BleDeviceState(
      channels: channels ?? this.channels,
      mode: mode ?? this.mode,
      running: running ?? this.running,
      batteryLevel: batteryLevel ?? this.batteryLevel,
      rssi: rssi ?? this.rssi,
    );
  }
}

/// Failure raised by a [BleService] operation.
class BleException implements Exception {
  const BleException(this.message);

  final String message;

  @override
  String toString() => 'BleException: $message';
}
