import 'ble_models.dart';

/// Transport-agnostic contract for talking to a SmartLink device.
///
/// The UI depends on this interface only. Phase 4 binds it to
/// `MockBleService`; Phase 5 adds a `RealBleService` without touching pages.
abstract class BleService {
  /// Devices discovered by the current scan, newest last.
  Stream<List<BleDeviceInfo>> get scanResults;

  /// Whether a scan is in progress.
  Stream<bool> get scanning;

  Stream<BleConnectionState> get connectionState;

  /// `null` while no device is connected.
  Stream<BleDeviceState?> get deviceState;

  BleConnectionState get currentConnectionState;

  BleDeviceState? get currentDeviceState;

  Future<void> startScan();

  Future<void> stopScan();

  /// Completes once the link is established; throws [BleException] otherwise.
  Future<void> connect(String deviceId);

  Future<void> disconnect();

  /// [channel] 0 = all, 1-3 = A/B/C; [value] 0-100.
  Future<void> setIntensity(int channel, int value);

  Future<void> start();

  Future<void> stop();

  Future<void> setMode(ControlMode mode);

  Future<void> dispose();
}
