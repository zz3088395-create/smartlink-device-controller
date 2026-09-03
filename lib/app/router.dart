import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/activity/activity_page.dart';
import '../features/auth/auth_provider.dart';
import '../features/auth/login_page.dart';
import '../features/auth/splash_page.dart';
import '../features/control/control_page.dart';
import '../features/devices/device_detail_page.dart';
import '../features/devices/devices_page.dart';
import '../features/home/home_page.dart';
import '../features/presets/modes_page.dart';
import '../features/presets/pattern_editor_page.dart';
import '../features/scan/scan_page.dart';
import '../features/settings/settings_page.dart';
import '../features/shell/app_shell.dart';

abstract final class AppRoutes {
  static const String splash = '/splash';
  static const String login = '/login';
  static const String home = '/home';
  static const String devices = '/devices';
  static const String activity = '/activity';
  static const String settings = '/settings';
  static const String scan = '/scan';
  static const String control = '/control';
  static const String modes = '/modes';
  static const String patternEditor = '/pattern-editor';

  static String device(String id) => '/device/$id';

  static String patternEditorFor(String presetId) =>
      Uri(path: patternEditor, queryParameters: {'presetId': presetId}).toString();
}

final rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier<int>(0);
  ref.onDispose(refresh.dispose);
  ref.listen(authProvider, (_, _) => refresh.value++);

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: AppRoutes.splash,
    refreshListenable: refresh,
    redirect: (context, state) {
      final auth = ref.read(authProvider);
      final location = state.matchedLocation;
      final onSplash = location == AppRoutes.splash;
      final onLogin = location == AppRoutes.login;

      if (auth.isLoading) return onSplash ? null : AppRoutes.splash;
      final signedIn = auth.value != null;
      if (!signedIn) return onLogin ? null : AppRoutes.login;
      if (onLogin || onSplash) return AppRoutes.home;
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginPage(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AppShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.home,
                builder: (context, state) => const HomePage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.devices,
                builder: (context, state) => const DevicesPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.activity,
                builder: (context, state) => const ActivityPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.settings,
                builder: (context, state) => const SettingsPage(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.scan,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const ScanPage(),
      ),
      GoRoute(
        path: AppRoutes.control,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const ControlPage(),
      ),
      GoRoute(
        path: '/device/:id',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) =>
            DeviceDetailPage(deviceId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: AppRoutes.modes,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const ModesPage(),
      ),
      GoRoute(
        path: AppRoutes.patternEditor,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => PatternEditorPage(
          presetId: state.uri.queryParameters['presetId'],
        ),
      ),
    ],
  );
});
