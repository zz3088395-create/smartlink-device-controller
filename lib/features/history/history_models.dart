import '../../core/api/api_response.dart';
import '../../core/utils/date_utils.dart';

/// `ConnectionHistoryVO`
class ConnectionRecord {
  const ConnectionRecord({
    required this.id,
    required this.deviceId,
    required this.deviceName,
    required this.deviceIdentifier,
    required this.deviceType,
    required this.connectedAt,
    this.disconnectedAt,
    this.durationSeconds,
    this.rssi,
    this.batteryLevel,
  });

  final String id;
  final String deviceId;
  final String deviceName;
  final String deviceIdentifier;
  final String deviceType;
  final DateTime connectedAt;
  final DateTime? disconnectedAt;
  final int? durationSeconds;
  final int? rssi;
  final int? batteryLevel;

  bool get isOpen => disconnectedAt == null;

  factory ConnectionRecord.fromJson(JsonMap json) {
    return ConnectionRecord(
      id: json['id'].toString(),
      deviceId: json['deviceId'].toString(),
      deviceName: json['deviceName']?.toString() ?? 'Unknown device',
      deviceIdentifier: json['deviceIdentifier']?.toString() ?? '',
      deviceType: json['deviceType']?.toString() ?? '',
      connectedAt: parseApiDateTime(json['connectedAt']) ?? DateTime.now(),
      disconnectedAt: parseApiDateTime(json['disconnectedAt']),
      durationSeconds: _toInt(json['durationSeconds']),
      rssi: _toInt(json['rssi']),
      batteryLevel: _toInt(json['batteryLevel']),
    );
  }
}

/// `AppReportConnectionReqDTO`
class ReportSessionRequest {
  const ReportSessionRequest({
    required this.deviceId,
    required this.connectedAt,
    this.disconnectedAt,
    this.rssi,
    this.batteryLevel,
  });

  final String deviceId;
  final DateTime connectedAt;
  final DateTime? disconnectedAt;
  final int? rssi;
  final int? batteryLevel;

  JsonMap toJson() => {
        'deviceId': deviceId,
        'connectedAt': toApiDateTime(connectedAt),
        if (disconnectedAt != null) 'disconnectedAt': toApiDateTime(disconnectedAt!),
        if (rssi != null) 'rssi': rssi,
        if (batteryLevel != null) 'batteryLevel': batteryLevel,
      };
}

int? _toInt(Object? value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString());
}
