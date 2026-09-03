import 'package:flutter_test/flutter_test.dart';
import 'package:smartlink_mobile/ble/ble_command_encoder.dart';
import 'package:smartlink_mobile/ble/ble_models.dart';

void main() {
  group('BleCommandEncoder', () {
    test('every packet is exactly 3 bytes', () {
      expect(BleCommandEncoder.start(), hasLength(3));
      expect(BleCommandEncoder.stop(), hasLength(3));
      expect(BleCommandEncoder.setIntensity(1, 50), hasLength(3));
      expect(BleCommandEncoder.setMode(ControlMode.wave), hasLength(3));
    });

    test('START and STOP address all channels with value 0', () {
      expect(BleCommandEncoder.start(), [0x01, 0x00, 0x00]);
      expect(BleCommandEncoder.stop(), [0x02, 0x00, 0x00]);
    });

    test('SET_INTENSITY carries channel and value', () {
      expect(BleCommandEncoder.setIntensity(2, 72), [0x03, 0x02, 72]);
      expect(BleCommandEncoder.setIntensity(0, 100), [0x03, 0x00, 100]);
      expect(BleCommandEncoder.setIntensity(3, 0), [0x03, 0x03, 0]);
    });

    test('SET_MODE maps modes to 1..4', () {
      expect(BleCommandEncoder.setMode(ControlMode.pulse), [0x04, 0x00, 1]);
      expect(BleCommandEncoder.setMode(ControlMode.wave), [0x04, 0x00, 2]);
      expect(BleCommandEncoder.setMode(ControlMode.rhythm), [0x04, 0x00, 3]);
      expect(BleCommandEncoder.setMode(ControlMode.custom), [0x04, 0x00, 4]);
    });

    test('rejects intensity outside 0-100', () {
      expect(() => BleCommandEncoder.setIntensity(1, -1), throwsArgumentError);
      expect(() => BleCommandEncoder.setIntensity(1, 101), throwsArgumentError);
    });

    test('rejects channel outside 0-3', () {
      expect(() => BleCommandEncoder.setIntensity(-1, 10), throwsArgumentError);
      expect(() => BleCommandEncoder.setIntensity(4, 10), throwsArgumentError);
    });

    test('decode round-trips an encoded packet', () {
      final decoded = BleCommandEncoder.decode(BleCommandEncoder.setIntensity(3, 45));
      expect(decoded.command, BleCommand.setIntensity);
      expect(decoded.channel, 3);
      expect(decoded.value, 45);
      expect(ControlMode.fromCode(BleCommandEncoder.decode(BleCommandEncoder.setMode(ControlMode.rhythm)).value), ControlMode.rhythm);
    });

    test('decode rejects malformed packets', () {
      expect(() => BleCommandEncoder.decode(BleCommandEncoder.start().sublist(0, 2)), throwsFormatException);
      expect(() => BleCommandEncoder.decode(Uint8ListFixture.of([0x09, 0, 0])), throwsFormatException);
    });
  });
}

// Tiny helper so the test reads naturally without importing dart:typed_data
// everywhere.
abstract final class Uint8ListFixture {
  static dynamic of(List<int> bytes) => BleCommandEncoder.start()..setAll(0, bytes);
}
