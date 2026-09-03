import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartlink_mobile/core/api/api_exception.dart';
import 'package:smartlink_mobile/core/api/api_response.dart';
import 'package:smartlink_mobile/core/utils/greeting.dart';
import 'package:smartlink_mobile/features/auth/auth_models.dart';
import 'package:smartlink_mobile/features/devices/device_models.dart';

DioException badResponse(int status, Object? body) => DioException(
      requestOptions: RequestOptions(path: '/x'),
      type: DioExceptionType.badResponse,
      response: Response(requestOptions: RequestOptions(path: '/x'), statusCode: status, data: body),
    );

void main() {
  group('ApiResponse.unwrap', () {
    test('returns parsed data on 00000', () {
      final user = ApiResponse.unwrap(
        {'code': '00000', 'msg': 'ok', 'data': {'id': '1000001', 'username': 'demo', 'nickname': 'Mia Carter'}},
        (data) => AppUser.fromJson(ApiResponse.asMap(data)),
      );
      expect(user.id, '1000001');
      expect(user.displayName, 'Mia Carter');
    });

    test('maps business codes to product copy, never raw messages', () {
      expect(
        () => ApiResponse.unwrap({'code': 'A0210', 'msg': '用户名或密码错误'}, ApiResponse.ignore),
        throwsA(isA<BusinessException>()
            .having((e) => e.code, 'code', 'A0210')
            .having((e) => e.message, 'message', 'Incorrect username or password.')),
      );
    });

    test('A0002 and A0230 both mean session expired', () {
      for (final code in ['A0002', 'A0230']) {
        expect(
          () => ApiResponse.unwrap({'code': code}, ApiResponse.ignore),
          throwsA(isA<SessionExpiredException>()),
          reason: code,
        );
      }
    });
  });

  group('ApiResponse.fromDio', () {
    test('HTTP 401 is a session expiry', () {
      expect(ApiResponse.fromDio(badResponse(401, {'code': 'A0002'})), isA<SessionExpiredException>());
    });

    test('HTTP 400 with A0302 is the ownership failure', () {
      final error = ApiResponse.fromDio(badResponse(400, {'code': 'A0302', 'msg': 'x'}));
      expect(error, isA<BusinessException>().having((e) => e.code, 'code', 'A0302'));
    });

    test('HTTP 403 D0001 (banned) ends the session', () {
      expect(ApiResponse.fromDio(badResponse(403, {'code': 'D0001'})), isA<SessionExpiredException>());
    });

    test('timeouts and connection errors are network failures', () {
      for (final type in [
        DioExceptionType.connectionTimeout,
        DioExceptionType.receiveTimeout,
        DioExceptionType.connectionError,
      ]) {
        final error = DioException(requestOptions: RequestOptions(path: '/x'), type: type);
        expect(ApiResponse.fromDio(error), isA<NetworkException>(), reason: type.name);
      }
    });
  });

  group('models', () {
    test('AppDevice parses string ids, enums and timestamps', () {
      final device = AppDevice.fromJson({
        'id': '2000002',
        'deviceName': 'SmartLink Mini',
        'deviceIdentifier': 'SL100-B41E0D77',
        'deviceType': 'SL-100',
        'firmwareVersion': '1.2.4',
        'batteryLevel': 64,
        'status': 'OFFLINE',
        'lastConnectedAt': '2026-09-01 16:34:52',
        'nickname': 'Bedside',
      });
      expect(device.id, '2000002');
      expect(device.status, DeviceStatus.offline);
      expect(device.lastConnectedAt, DateTime(2026, 9, 1, 16, 34, 52));
      expect(device.nicknameOrNull, 'Bedside');
    });

    test('displayName falls back to username', () {
      expect(const AppUser(id: '1', username: 'demo', nickname: '  ').displayName, 'demo');
    });

    test('greeting follows the local hour', () {
      expect(greetingForHour(8), 'Good morning');
      expect(greetingForHour(13), 'Good afternoon');
      expect(greetingForHour(21), 'Good evening');
    });
  });
}
