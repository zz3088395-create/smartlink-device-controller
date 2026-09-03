/// Wire-level constants of the SmartLink backend (smartlink-front-web).
///
/// The token header and prefix live here and nowhere else.
abstract final class ApiConstants {
  /// `auth.token.header` in application-dev.yml.
  static const String authHeaderName = 'X-Auth-Token';

  /// `auth.token.prefix` in application-dev.yml (trailing space included).
  static const String authTokenPrefix = 'Bearer ';

  /// `Res.code` for a successful call.
  static const String successCode = '00000';

  /// Any of these means the session is gone: the interceptor answers
  /// HTTP 401 + `A0002`, `FrontAuthUtil` answers HTTP 400 + `A0230`.
  static const Set<String> sessionExpiredCodes = {'A0002', 'A0230'};

  /// HTTP 403 + `D0001`: account banned through the admin console.
  static const String accountBannedCode = 'D0001';

  /// Bean-validation failure.
  static const String validationFailedCode = 'A0102';

  /// Device is bound to another app user.
  static const String deviceBoundToOtherAccountCode = 'A0302';

  /// `yyyy-MM-dd HH:mm:ss`, server local time.
  static const String dateTimeFormat = 'yyyy-MM-dd HH:mm:ss';
}
