import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_client.dart';
import '../../core/api/api_providers.dart';
import '../../core/api/api_response.dart';
import 'device_models.dart';

/// `/app/devices/*`
class DeviceRepository {
  DeviceRepository(this._client);

  final ApiClient _client;

  /// `GET /app/devices`
  Future<List<AppDevice>> list() {
    return _client.get(
      '/app/devices',
      parse: (data) => ApiResponse.asMapList(data).map(AppDevice.fromJson).toList(),
    );
  }

  /// `GET /app/devices/{id}`
  Future<AppDevice> get(String id) {
    return _client.get(
      '/app/devices/$id',
      parse: (data) => AppDevice.fromJson(ApiResponse.asMap(data)),
    );
  }

  /// `POST /app/devices` — idempotent for a device already bound to the
  /// caller; `A0302` when it belongs to someone else.
  Future<AppDevice> bind(BindDeviceRequest request) {
    return _client.post(
      '/app/devices',
      body: request.toJson(),
      parse: (data) => AppDevice.fromJson(ApiResponse.asMap(data)),
    );
  }

  /// `PUT /app/devices/{id}` — empty nickname clears it.
  Future<void> rename(String id, String? nickname) {
    return _client.put(
      '/app/devices/$id',
      body: {'nickname': nickname ?? ''},
      parse: ApiResponse.ignore,
    );
  }

  /// `PUT /app/devices/{id}/status`
  Future<void> reportStatus(
    String id, {
    required DeviceStatus status,
    int? batteryLevel,
    String? firmwareVersion,
  }) {
    return _client.put(
      '/app/devices/$id/status',
      body: {
        'status': status.apiValue,
        'batteryLevel': ?batteryLevel,
        'firmwareVersion': ?firmwareVersion,
      },
      parse: ApiResponse.ignore,
    );
  }

  /// `DELETE /app/devices/{id}`
  Future<void> unbind(String id) {
    return _client.delete('/app/devices/$id', parse: ApiResponse.ignore);
  }
}

final deviceRepositoryProvider = Provider<DeviceRepository>(
  (ref) => DeviceRepository(ref.watch(apiClientProvider)),
);
