/// User-presentable failures. Raw transport errors never leave the API layer.
sealed class ApiException implements Exception {
  const ApiException(this.message);

  /// Copy that is safe to show in the UI.
  final String message;

  @override
  String toString() => '$runtimeType: $message';
}

/// The backend could not be reached (offline, DNS, timeout, refused).
class NetworkException extends ApiException {
  const NetworkException([
    super.message = 'Unable to reach the SmartLink cloud. '
        'Check your connection and try again.',
  ]);
}

/// The token is missing, expired or revoked. The caller must sign in again.
class SessionExpiredException extends ApiException {
  const SessionExpiredException([
    super.message = 'Your session has expired. Please sign in again.',
  ]);
}

/// The backend rejected the request with a business code (HTTP 400).
class BusinessException extends ApiException {
  const BusinessException(this.code, super.message);

  final String code;

  @override
  String toString() => 'BusinessException($code): $message';
}

/// 5xx, malformed payload or anything else we cannot explain to the user.
class ServerException extends ApiException {
  const ServerException([
    super.message = 'Something went wrong on our side. Please try again.',
  ]);
}

/// Maps backend business codes (docs/API.md) to product copy.
abstract final class ApiErrorMessages {
  static String forCode(String code) {
    return switch (code) {
      'A0102' => 'Some fields are invalid. Please check and try again.',
      'A0202' => 'This account has been disabled.',
      'A0210' => 'Incorrect username or password.',
      'A0301' => 'This device is already linked to your account.',
      'A0302' => 'This device is already linked to another account.',
      'A0303' => 'This device is not linked to your account.',
      'A0304' => 'A device with this identifier already exists.',
      'A0305' => 'This preset is not in your library.',
      'A0306' => 'Custom presets need at least one pattern step.',
      'A0307' => 'Disconnect time cannot be earlier than connect time.',
      'A0308' => 'This device is not linked to any account.',
      'A0309' => 'The device is being registered. Please try again.',
      'D0001' => 'Your account has been disabled.',
      _ => 'The request could not be completed. Please try again.',
    };
  }
}
