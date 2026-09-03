import '../../core/api/api_response.dart';
import '../../core/utils/date_utils.dart';

/// `AppUserVO` / `AppLoginVO` from the backend.
class AppUser {
  const AppUser({
    required this.id,
    required this.username,
    this.nickname,
    this.email,
    this.lastLoginTime,
    this.createTime,
  });

  final String id;
  final String username;
  final String? nickname;
  final String? email;
  final DateTime? lastLoginTime;
  final DateTime? createTime;

  /// Nickname when present, otherwise the username.
  String get displayName {
    final name = nickname?.trim();
    return (name == null || name.isEmpty) ? username : name;
  }

  factory AppUser.fromJson(JsonMap json) {
    return AppUser(
      id: json['id'].toString(),
      username: json['username']?.toString() ?? '',
      nickname: json['nickname']?.toString(),
      email: json['email']?.toString(),
      lastLoginTime: parseApiDateTime(json['lastLoginTime']),
      createTime: parseApiDateTime(json['createTime']),
    );
  }
}

class LoginResult {
  const LoginResult({
    required this.token,
    required this.userId,
    required this.username,
    this.nickname,
  });

  final String token;
  final String userId;
  final String username;
  final String? nickname;

  factory LoginResult.fromJson(JsonMap json) {
    return LoginResult(
      token: json['token'].toString(),
      userId: json['userId'].toString(),
      username: json['username']?.toString() ?? '',
      nickname: json['nickname']?.toString(),
    );
  }

  AppUser toUser() => AppUser(id: userId, username: username, nickname: nickname);
}
