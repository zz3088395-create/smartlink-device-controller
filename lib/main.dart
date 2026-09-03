import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    ProviderScope(
      // Riverpod 3 retries failed providers with back-off by default. Network
      // failures are surfaced to the user with explicit retry buttons instead.
      retry: (_, _) => null,
      child: const SmartLinkApp(),
    ),
  );
}
