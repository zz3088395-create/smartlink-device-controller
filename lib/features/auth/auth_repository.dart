import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_client.dart';
import '../../core/api/api_providers.dart';
import '../../core/api/api_response.dart';
import '../../core/storage/token_storage.dart';
import 'auth_models.dart';

/// `/app/auth/*` plus token persistence.
class AuthRepository {
  AuthRepository(this._client, this._tokenStorage);

  final ApiClient _client;
  final TokenStorage _tokenStorage;

  Future<bool> hasToken() async {
    final token = await _tokenStorage.read();
    return token != null && token.isNotEmpty;
  }

  /// `POST /app/auth/login` — stores the token on success.
  Future<AppUser> login({
    required String username,
    required String password,
  }) async {
    final result = await _client.post(
      '/app/auth/login',
      body: {'username': username, 'password': password},
      parse: (data) => LoginResult.fromJson(ApiResponse.asMap(data)),
    );
    await _tokenStorage.write(result.token);
    return result.toUser();
  }

  /// `GET /app/auth/me`
  Future<AppUser> me() {
    return _client.get(
      '/app/auth/me',
      parse: (data) => AppUser.fromJson(ApiResponse.asMap(data)),
    );
  }

  Future<void> logout() => _tokenStorage.clear();
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    ref.watch(apiClientProvider),
    ref.watch(tokenStorageProvider),
  );
});
