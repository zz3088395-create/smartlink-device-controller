import '../../core/api/api_response.dart';
import '../../core/utils/date_utils.dart';

/// `DeviceStatusEnum` on the backend.
enum DeviceStatus {
  online('ONLINE', 'Online'),
  offline('OFFLINE', 'Offline');

  const DeviceStatus(this.apiValue, this.label);

  final String apiValue;
  final String label;

  static DeviceStatus fromApi(String? value) =>
      value == DeviceStatus.online.apiValue ? DeviceStatus.online : DeviceStatus.offline;
}

/// `AppDeviceVO`: a device bound to the signed-in user.
class AppDevice {
  const AppDevice({
    required this.id,
    required this.deviceName,
    required this.deviceIdentifier,
    required this.deviceType,
    required this.status,
    this.firmwareVersion,
    this.batteryLevel,
    this.lastConnectedAt,
    this.nickname,
    this.bindTime,
  });

  final String id;
  final String deviceName;
  final String deviceIdentifier;
  final String deviceType;
  final DeviceStatus status;
  final String? firmwareVersion;
  final int? batteryLevel;
  final DateTime? lastConnectedAt;

  /// Alias chosen by the user ("Bedside"), optional.
  final String? nickname;
  final DateTime? bindTime;

  bool get isOnline => status == DeviceStatus.online;

  String? get nicknameOrNull {
    final value = nickname?.trim();
    return (value == null || value.isEmpty) ? null : value;
  }

  factory AppDevice.fromJson(JsonMap json) {
    return AppDevice(
      id: json['id'].toString(),
      deviceName: json['deviceName']?.toString() ?? 'Unknown device',
      deviceIdentifier: json['deviceIdentifier']?.toString() ?? '',
      deviceType: json['deviceType']?.toString() ?? '',
      status: DeviceStatus.fromApi(json['status']?.toString()),
      firmwareVersion: json['firmwareVersion']?.toString(),
      batteryLevel: _toInt(json['batteryLevel']),
      lastConnectedAt: parseApiDateTime(json['lastConnectedAt']),
      nickname: json['nickname']?.toString(),
      bindTime: parseApiDateTime(json['bindTime']),
    );
  }
}

/// `AppBindDeviceReqDTO`
class BindDeviceRequest {
  const BindDeviceRequest({
    required this.deviceIdentifier,
    required this.deviceName,
    required this.deviceType,
    this.firmwareVersion,
    this.nickname,
  });

  final String deviceIdentifier;
  final String deviceName;
  final String deviceType;
  final String? firmwareVersion;
  final String? nickname;

  JsonMap toJson() => {
        'deviceIdentifier': deviceIdentifier,
        'deviceName': deviceName,
        'deviceType': deviceType,
        if (firmwareVersion != null) 'firmwareVersion': firmwareVersion,
        if (nickname != null) 'nickname': nickname,
      };
}

int? _toInt(Object? value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString());
}
