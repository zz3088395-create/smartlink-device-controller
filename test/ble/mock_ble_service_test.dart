import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:smartlink_mobile/ble/ble_models.dart';
import 'package:smartlink_mobile/ble/mock_ble_service.dart';

MockBleService fastMock() => MockBleService(
      random: Random(7),
      scanSchedule: const [
        Duration(milliseconds: 10),
        Duration(milliseconds: 20),
        Duration(milliseconds: 30),
      ],
      scanDuration: const Duration(milliseconds: 60),
      connectDelay: const Duration(milliseconds: 10),
      disconnectDelay: const Duration(milliseconds: 5),
      commandLatency: Duration.zero,
      notifyIntervalMin: const Duration(milliseconds: 15),
      notifyIntervalMax: const Duration(milliseconds: 15),
    );

Future<void> tick([int ms = 5]) => Future<void>.delayed(Duration(milliseconds: ms));

/// Lets pending stream events reach their listeners.
Future<void> flush() => Future<void>.delayed(Duration.zero);

void main() {
  late MockBleService ble;

  setUp(() => ble = fastMock());
  tearDown(() => ble.dispose());

  group('scan', () {
    test('reports the three simulated devices in order, then stops', () async {
      final snapshots = <List<BleDeviceInfo>>[];
      final sub = ble.scanResults.listen(snapshots.add);
      final scanningStates = <bool>[];
      final scanSub = ble.scanning.listen(scanningStates.add);

      await ble.startScan();
      await tick(100);

      expect(snapshots.last.map((d) => d.name), [
        'SmartLink Mini',
        'SmartLink Hub',
        'SmartLink Demo Device',
      ]);
      expect(snapshots.last.map((d) => d.model), ['SL-100', 'SL-200', 'SL-100']);
      for (final device in snapshots.last) {
        expect(device.rssi, inInclusiveRange(MockBleService.minRssi, MockBleService.maxRssi));
      }
      expect(scanningStates, containsAllInOrder([false, true, false]));
      expect(ble.isScanning, isFalse);

      await sub.cancel();
      await scanSub.cancel();
    });

    test('stopScan cancels pending results', () async {
      await ble.startScan();
      await ble.stopScan();
      await tick(60);
      expect(ble.isScanning, isFalse);
      final results = await ble.scanResults.first;
      expect(results, isEmpty);
    });
  });

  group('connect / disconnect', () {
    test('connect moves connecting → connected and publishes a device state', () async {
      final states = <BleConnectionStatus>[];
      final sub = ble.connectionState.listen((s) => states.add(s.status));

      await ble.connect('mock-sl100-mini');
      await flush();

      expect(states, [
        BleConnectionStatus.disconnected,
        BleConnectionStatus.connecting,
        BleConnectionStatus.connected,
      ]);
      expect(ble.currentConnectionState.device?.name, 'SmartLink Mini');
      final state = ble.currentDeviceState!;
      expect(state.channels, [0, 0, 0]);
      expect(state.running, isFalse);
      expect(state.mode, ControlMode.pulse);
      expect(state.batteryLevel, inInclusiveRange(MockBleService.minBattery, MockBleService.maxBattery));
      expect(state.rssi, inInclusiveRange(MockBleService.minRssi, MockBleService.maxRssi));
      await sub.cancel();
    });

    test('connect rejects unknown devices', () async {
      expect(() => ble.connect('nope'), throwsA(isA<BleException>()));
    });

    test('disconnect clears device state and ends notifications', () async {
      await ble.connect('mock-sl200-hub');
      final states = <BleConnectionStatus>[];
      final sub = ble.connectionState.listen((s) => states.add(s.status));

      await ble.disconnect();
      await flush();

      expect(states.last, BleConnectionStatus.disconnected);
      expect(states, contains(BleConnectionStatus.disconnecting));
      expect(ble.currentDeviceState, isNull);

      await tick(40);
      expect(ble.currentDeviceState, isNull, reason: 'no notification after disconnect');
      await sub.cancel();
    });

    test('commands fail when not connected', () async {
      expect(() => ble.start(), throwsA(isA<BleException>()));
      expect(() => ble.setIntensity(1, 10), throwsA(isA<BleException>()));
    });
  });

  group('commands update the state stream', () {
    setUp(() => ble.connect('mock-sl100-mini'));

    test('setIntensity updates a single channel', () async {
      final updates = <BleDeviceState?>[];
      final sub = ble.deviceState.listen(updates.add);

      await ble.setIntensity(2, 72);
      await flush();

      expect(updates.last!.channels, [0, 72, 0]);
      expect(ble.currentDeviceState!.channels, [0, 72, 0]);
      expect(ble.lastCommand, [0x03, 0x02, 72]);
      await sub.cancel();
    });

    test('setIntensity on channel 0 updates every channel', () async {
      await ble.setIntensity(0, 35);
      expect(ble.currentDeviceState!.channels, [35, 35, 35]);
    });

    test('setIntensity validates the range before touching the device', () async {
      expect(() => ble.setIntensity(1, 140), throwsArgumentError);
      expect(ble.currentDeviceState!.channels, [0, 0, 0]);
    });

    test('start / stop toggle running', () async {
      await ble.start();
      expect(ble.currentDeviceState!.running, isTrue);
      expect(ble.lastCommand, [0x01, 0x00, 0x00]);
      await ble.stop();
      expect(ble.currentDeviceState!.running, isFalse);
      expect(ble.lastCommand, [0x02, 0x00, 0x00]);
    });

    test('setMode changes the mode', () async {
      await ble.setMode(ControlMode.rhythm);
      expect(ble.currentDeviceState!.mode, ControlMode.rhythm);
      expect(ble.lastCommand, [0x04, 0x00, 3]);
    });

    test('a connected device keeps emitting battery / RSSI notifications', () async {
      final updates = <BleDeviceState?>[];
      final sub = ble.deviceState.listen(updates.add);

      await tick(60);

      expect(updates.length, greaterThan(2));
      for (final update in updates.whereType<BleDeviceState>()) {
        expect(update.batteryLevel, inInclusiveRange(5, MockBleService.maxBattery));
        expect(update.rssi, inInclusiveRange(MockBleService.minRssi, MockBleService.maxRssi));
      }
      await sub.cancel();
    });
  });
}
