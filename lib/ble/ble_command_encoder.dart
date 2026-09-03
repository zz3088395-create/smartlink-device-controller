import 'dart:typed_data';

import 'ble_models.dart';

/// Encodes the fictional SmartLink demo protocol.
///
/// Every packet is exactly 3 bytes: `[command, channel, value]`.
///
/// | Byte | Meaning                                              |
/// |------|------------------------------------------------------|
/// | 0    | 0x01 START · 0x02 STOP · 0x03 SET_INTENSITY · 0x04 SET_MODE |
/// | 1    | channel: 0 = all, 1-3 = channel A/B/C                |
/// | 2    | intensity 0-100, or mode 1-4 for SET_MODE            |
///
/// The protocol is invented for this portfolio and does not correspond to any
/// real product.
abstract final class BleCommandEncoder {
  static const int packetLength = 3;
  static const int channelAll = 0;
  static const int minChannel = 0;
  static const int maxChannel = 3;
  static const int minIntensity = 0;
  static const int maxIntensity = 100;

  static Uint8List start() => _packet(BleCommand.start, channelAll, 0);

  static Uint8List stop() => _packet(BleCommand.stop, channelAll, 0);

  static Uint8List setIntensity(int channel, int value) {
    _requireChannel(channel);
    _requireIntensity(value);
    return _packet(BleCommand.setIntensity, channel, value);
  }

  static Uint8List setMode(ControlMode mode) =>
      _packet(BleCommand.setMode, channelAll, mode.code);

  /// Inverse of the encoders; throws [FormatException] on malformed input.
  static ({BleCommand command, int channel, int value}) decode(Uint8List packet) {
    if (packet.length != packetLength) {
      throw FormatException('Expected $packetLength bytes, got ${packet.length}');
    }
    final command = BleCommand.fromCode(packet[0]);
    if (command == null) {
      throw FormatException('Unknown command 0x${packet[0].toRadixString(16)}');
    }
    return (command: command, channel: packet[1], value: packet[2]);
  }

  static Uint8List _packet(BleCommand command, int channel, int value) {
    return Uint8List.fromList([command.code, channel & 0xFF, value & 0xFF]);
  }

  static void _requireChannel(int channel) {
    if (channel < minChannel || channel > maxChannel) {
      throw ArgumentError.value(
        channel,
        'channel',
        'must be between $minChannel and $maxChannel',
      );
    }
  }

  static void _requireIntensity(int value) {
    if (value < minIntensity || value > maxIntensity) {
      throw ArgumentError.value(
        value,
        'value',
        'must be between $minIntensity and $maxIntensity',
      );
    }
  }
}
