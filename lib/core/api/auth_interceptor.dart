import 'package:dio/dio.dart';

import '../storage/token_storage.dart';
import 'api_constants.dart';

/// Injects `X-Auth-Token: Bearer <token>` into every request.
///
/// Session expiry is handled by [ApiClient], which sees both the HTTP 401 and
/// the in-body business codes.
class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._tokenStorage);

  final TokenStorage _tokenStorage;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _tokenStorage.read();
    if (token != null && token.isNotEmpty) {
      options.headers[ApiConstants.authHeaderName] =
          '${ApiConstants.authTokenPrefix}$token';
    }
    handler.next(options);
  }
}
