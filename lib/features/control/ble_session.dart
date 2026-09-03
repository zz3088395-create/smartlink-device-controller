/// One connected session, created only after a successful connect and
/// consumed only by an explicit disconnect (or a link drop reported by the
/// BLE stack). Nothing else - navigation, hot reload, widget disposal - may
/// create or close it.
class BleSession {
  const BleSession({
    required this.deviceIdentifier,
    required this.deviceName,
    required this.deviceModel,
    required this.connectedAt,
    this.backendDeviceId,
    this.firmwareVersion,
    this.lastRssi,
    this.lastBatteryLevel,
    this.cloudSynced = false,
  });

  /// `AppDeviceVO.id` once the backend confirmed ownership; `null` when the
  /// cloud was unreachable during connect.
  final String? backendDeviceId;
  final String deviceIdentifier;
  final String deviceName;
  final String deviceModel;
  final String? firmwareVersion;
  final DateTime connectedAt;
  final int? lastRssi;
  final int? lastBatteryLevel;

  /// `true` when binding + status report succeeded.
  final bool cloudSynced;

  BleSession copyWith({
    int? lastRssi,
    int? lastBatteryLevel,
  }) {
    return BleSession(
      backendDeviceId: backendDeviceId,
      deviceIdentifier: deviceIdentifier,
      deviceName: deviceName,
      deviceModel: deviceModel,
      firmwareVersion: firmwareVersion,
      connectedAt: connectedAt,
      lastRssi: lastRssi ?? this.lastRssi,
      lastBatteryLevel: lastBatteryLevel ?? this.lastBatteryLevel,
      cloudSynced: cloudSynced,
    );
  }
}
