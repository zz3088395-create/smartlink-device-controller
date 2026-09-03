import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_exception.dart';
import '../../core/api/api_providers.dart';
import 'auth_models.dart';
import 'auth_repository.dart';

/// Session owner.
///
/// * loading  → app is bootstrapping (splash)
/// * `null`   → signed out
/// * [AppUser] → signed in
class AuthNotifier extends AsyncNotifier<AppUser?> {
  @override
  Future<AppUser?> build() async {
    final subscription = ref
        .watch(sessionEventsProvider)
        .expired
        .listen((_) => onSessionExpired());
    ref.onDispose(subscription.cancel);

    final repository = ref.watch(authRepositoryProvider);
    if (!await repository.hasToken()) return null;
    try {
      return await repository.me();
    } on SessionExpiredException {
      return null;
    } on ApiException {
      // Backend unreachable at launch: fall back to the login screen rather
      // than blocking on a spinner. The stored token is left untouched.
      return null;
    }
  }

  /// Throws [ApiException] so the login screen can show product copy.
  Future<void> login({required String username, required String password}) async {
    final repository = ref.read(authRepositoryProvider);
    final user = await repository.login(username: username, password: password);
    state = AsyncData(user);
    await ref.read(appPrefsProvider).writeLastUsername(username);
    // Fill in profile fields (email, timestamps) without blocking navigation.
    _refreshProfileQuietly();
  }

  Future<void> logout() async {
    await ref.read(authRepositoryProvider).logout();
    state = const AsyncData(null);
  }

  void onSessionExpired() {
    if (state.value != null) state = const AsyncData(null);
  }

  Future<void> _refreshProfileQuietly() async {
    try {
      final user = await ref.read(authRepositoryProvider).me();
      if (state.value != null) state = AsyncData(user);
    } on ApiException {
      // Keep the login payload; nothing user-facing depends on it.
    }
  }
}

final authProvider = AsyncNotifierProvider<AuthNotifier, AppUser?>(AuthNotifier.new);

/// Id of the signed-in user, or `null`. Data providers watch this so their
/// caches reset whenever the account changes.
final currentUserIdProvider = Provider<String?>(
  (ref) => ref.watch(authProvider.select((auth) => auth.value?.id)),
);
