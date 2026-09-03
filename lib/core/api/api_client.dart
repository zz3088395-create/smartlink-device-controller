import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../storage/token_storage.dart';
import 'api_exception.dart';
import 'api_response.dart';
import 'auth_interceptor.dart';

/// Thin Dio wrapper: base URL, timeouts, token header, envelope unwrapping and
/// error mapping. Repositories only ever see parsed values or [ApiException].
class ApiClient {
  ApiClient({
    required String baseUrl,
    required TokenStorage tokenStorage,
    required VoidCallback onSessionExpired,
    Duration timeout = const Duration(seconds: 10),
  })  : _tokenStorage = tokenStorage,
        _onSessionExpired = onSessionExpired,
        _dio = Dio(
          BaseOptions(
            baseUrl: baseUrl,
            connectTimeout: timeout,
            sendTimeout: timeout,
            receiveTimeout: timeout,
            responseType: ResponseType.json,
            headers: const {'Accept': 'application/json'},
          ),
        ) {
    _dio.interceptors.add(AuthInterceptor(tokenStorage));
  }

  final Dio _dio;
  final TokenStorage _tokenStorage;
  final VoidCallback _onSessionExpired;

  String get baseUrl => _dio.options.baseUrl;

  Future<T> get<T>(
    String path, {
    Map<String, dynamic>? query,
    required JsonParser<T> parse,
  }) {
    return _send(
      () => _dio.get<dynamic>(path, queryParameters: query),
      parse,
    );
  }

  Future<T> post<T>(
    String path, {
    Object? body,
    required JsonParser<T> parse,
  }) {
    return _send(() => _dio.post<dynamic>(path, data: body), parse);
  }

  Future<T> put<T>(
    String path, {
    Object? body,
    required JsonParser<T> parse,
  }) {
    return _send(() => _dio.put<dynamic>(path, data: body), parse);
  }

  Future<T> delete<T>(
    String path, {
    required JsonParser<T> parse,
  }) {
    return _send(() => _dio.delete<dynamic>(path), parse);
  }

  Future<T> _send<T>(
    Future<Response<dynamic>> Function() request,
    JsonParser<T> parse,
  ) async {
    try {
      final response = await request();
      return ApiResponse.unwrap(response.data, parse);
    } on DioException catch (error) {
      _log(error.requestOptions, error);
      throw await _handle(ApiResponse.fromDio(error));
    } on ApiException catch (error) {
      throw await _handle(error);
    }
  }

  /// Debug-only transport diagnostics (the UI only ever shows product copy).
  void _log(RequestOptions options, DioException error) {
    if (!kDebugMode) return;
    debugPrint(
      'API ${options.method} ${options.uri} failed: ${error.type.name}'
      '${error.response == null ? '' : ' HTTP ${error.response!.statusCode}'}'
      '${error.error == null ? '' : ' (${error.error})'}',
    );
  }

  Future<ApiException> _handle(ApiException error) async {
    if (error is SessionExpiredException) {
      await _tokenStorage.clear();
      _onSessionExpired();
    }
    return error;
  }
}
