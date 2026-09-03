import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_client.dart';
import '../../core/api/api_providers.dart';
import '../../core/api/api_response.dart';
import 'preset_models.dart';

/// `/app/presets/*`
class PresetRepository {
  PresetRepository(this._client);

  final ApiClient _client;

  /// `GET /app/presets` — built-in presets plus the caller's own.
  Future<List<ControlPreset>> list() {
    return _client.get(
      '/app/presets',
      parse: (data) => ApiResponse.asMapList(data).map(ControlPreset.fromJson).toList(),
    );
  }

  /// `POST /app/presets`
  Future<ControlPreset> create(SavePresetRequest request) {
    return _client.post(
      '/app/presets',
      body: request.toJson(),
      parse: (data) => ControlPreset.fromJson(ApiResponse.asMap(data)),
    );
  }

  /// `PUT /app/presets/{id}` — own presets only (`A0305` otherwise).
  Future<void> update(String id, SavePresetRequest request) {
    return _client.put(
      '/app/presets/$id',
      body: request.toJson(),
      parse: ApiResponse.ignore,
    );
  }

  /// `DELETE /app/presets/{id}`
  Future<void> delete(String id) {
    return _client.delete('/app/presets/$id', parse: ApiResponse.ignore);
  }
}

final presetRepositoryProvider = Provider<PresetRepository>(
  (ref) => PresetRepository(ref.watch(apiClientProvider)),
);
