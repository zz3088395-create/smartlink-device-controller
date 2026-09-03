import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;

enum AppEnvironment { development }

/// Single source of truth for environment-dependent values.
///
/// Nothing outside this file may mention a host name or a port. Override the
/// backend at build time with `--dart-define=API_BASE_URL=http://host:port`.
abstract final class AppConfig {
  static const AppEnvironment environment = AppEnvironment.development;

  static const String appName = 'SmartLink';
  static const String appTagline = 'Control your connected devices';
  static const String appVersion = '1.0.0';

  static const String _apiBaseUrlOverride = String.fromEnvironment('API_BASE_URL');

  /// `smartlink-front-web` listens on 8081 with context path `/`
  /// (see docs/LOCAL_RUN.md).
  static const int _devBackendPort = 8081;

  static String get apiBaseUrl {
    if (_apiBaseUrlOverride.isNotEmpty) return _apiBaseUrlOverride;
    if (!kIsWeb && Platform.isAndroid) {
      // Android emulator reaches the host machine through 10.0.2.2.
      return 'http://10.0.2.2:$_devBackendPort';
    }
    // iOS simulator / desktop. Physical devices pass --dart-define=API_BASE_URL.
    return 'http://localhost:$_devBackendPort';
  }

  static bool get isApiBaseUrlOverridden => _apiBaseUrlOverride.isNotEmpty;

  static const Duration apiTimeout = Duration(seconds: 10);

  /// Phase 4 ships with the simulated Bluetooth stack. Phase 5 swaps in the
  /// real implementation behind the same [BleService] interface.
  static const bool useMockBle = true;

  /// Demo credentials published in docs/API.md. Only used by the
  /// "Use demo account" shortcut on the login screen.
  static const String demoUsername = 'demo';
  static const String demoPassword = 'demo123';
}
