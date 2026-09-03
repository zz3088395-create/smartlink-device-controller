import 'dart:io';

import 'package:dio/dio.dart';

import 'api_constants.dart';
import 'api_exception.dart';

typedef JsonMap = Map<String, dynamic>;
typedef JsonParser<T> = T Function(Object? data);

/// Pure functions that turn the backend envelope `{code, msg, data}` and
/// transport failures into either a parsed value or an [ApiException].
abstract final class ApiResponse {
  /// Unwraps `Res<T>` and hands `data` to [parse].
  static T unwrap<T>(Object? raw, JsonParser<T> parse) {
    if (raw is! Map) throw const ServerException();
    final code = raw['code']?.toString();
    if (code == ApiConstants.successCode) {
      return parse(raw['data']);
    }
    throw failureForCode(code);
  }

  /// Exception for a non-success envelope.
  static ApiException failureForCode(String? code) {
    if (code == null || code.isEmpty) return const ServerException();
    if (ApiConstants.sessionExpiredCodes.contains(code)) {
      return const SessionExpiredException();
    }
    if (code == ApiConstants.accountBannedCode) {
      return SessionExpiredException(ApiErrorMessages.forCode(code));
    }
    return BusinessException(code, ApiErrorMessages.forCode(code));
  }

  /// Translates a [DioException] into an [ApiException].
  static ApiException fromDio(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.transformTimeout:
      case DioExceptionType.connectionError:
        return const NetworkException();
      case DioExceptionType.cancel:
        return const NetworkException('The request was cancelled.');
      case DioExceptionType.badCertificate:
        return const NetworkException('The server certificate is not trusted.');
      case DioExceptionType.badResponse:
        return _fromResponse(error.response);
      case DioExceptionType.unknown:
        if (error.error is SocketException || error.error is HttpException) {
          return const NetworkException();
        }
        return const ServerException();
    }
  }

  static ApiException _fromResponse(Response<dynamic>? response) {
    if (response == null) return const ServerException();
    final status = response.statusCode ?? 0;
    if (status == HttpStatus.unauthorized) {
      return const SessionExpiredException();
    }
    final body = response.data;
    if (body is Map && body['code'] != null) {
      return failureForCode(body['code'].toString());
    }
    if (status == HttpStatus.forbidden) {
      return SessionExpiredException(
        ApiErrorMessages.forCode(ApiConstants.accountBannedCode),
      );
    }
    return const ServerException();
  }

  // Parsers for the common envelope shapes.

  static JsonMap asMap(Object? data) {
    if (data is Map) return Map<String, dynamic>.from(data);
    throw const ServerException();
  }

  static List<JsonMap> asMapList(Object? data) {
    if (data == null) return const [];
    if (data is List) {
      return data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    }
    throw const ServerException();
  }

  static void ignore(Object? _) {}
}

/// `PageData<T>` from smartlink-core.
class PageData<T> {
  const PageData({required this.total, required this.list});

  final int total;
  final List<T> list;

  static PageData<T> fromJson<T>(
    Object? data,
    T Function(JsonMap json) itemParser,
  ) {
    final map = ApiResponse.asMap(data);
    final rawList = map['list'];
    final items = rawList is List
        ? rawList
            .map((e) => itemParser(Map<String, dynamic>.from(e as Map)))
            .toList()
        : <T>[];
    return PageData(total: _toInt(map['total']) ?? items.length, list: items);
  }
}

int? _toInt(Object? value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString());
}
