import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_client.dart';
import '../../core/api/api_providers.dart';
import '../../core/api/api_response.dart';
import 'history_models.dart';

/// `/app/history`
class HistoryRepository {
  HistoryRepository(this._client);

  final ApiClient _client;

  /// `GET /app/history?deviceId=&pageNum=&pageSize=` — newest first.
  Future<PageData<ConnectionRecord>> list({
    String? deviceId,
    int pageNum = 1,
    int pageSize = 20,
  }) {
    return _client.get(
      '/app/history',
      query: {
        'deviceId': ?deviceId,
        'pageNum': pageNum,
        'pageSize': pageSize,
      },
      parse: (data) => PageData.fromJson(data, ConnectionRecord.fromJson),
    );
  }

  /// `POST /app/history`
  Future<void> report(ReportSessionRequest request) {
    return _client.post(
      '/app/history',
      body: request.toJson(),
      parse: ApiResponse.ignore,
    );
  }
}

final historyRepositoryProvider = Provider<HistoryRepository>(
  (ref) => HistoryRepository(ref.watch(apiClientProvider)),
);
