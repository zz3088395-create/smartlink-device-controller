import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_config.dart';
import '../storage/app_prefs.dart';
import '../storage/token_storage.dart';
import 'api_client.dart';
import 'session_events.dart';

final tokenStorageProvider = Provider<TokenStorage>((ref) => TokenStorage());

final appPrefsProvider = Provider<AppPrefs>((ref) => AppPrefs());

final sessionEventsProvider = Provider<SessionEvents>((ref) {
  final events = SessionEvents();
  ref.onDispose(events.dispose);
  return events;
});

final apiClientProvider = Provider<ApiClient>((ref) {
  final events = ref.watch(sessionEventsProvider);
  return ApiClient(
    baseUrl: AppConfig.apiBaseUrl,
    timeout: AppConfig.apiTimeout,
    tokenStorage: ref.watch(tokenStorageProvider),
    onSessionExpired: events.notifyExpired,
  );
});
