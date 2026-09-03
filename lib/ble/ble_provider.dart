import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/config/app_config.dart';
import 'ble_models.dart';
import 'ble_service.dart';
import 'mock_ble_service.dart';

/// Composition root for the Bluetooth stack. This is the only file allowed to
/// import a concrete [BleService]; pages import `ble_service.dart` only.
final bleServiceProvider = Provider<BleService>((ref) {
  // Phase 5: `AppConfig.useMockBle ? MockBleService() : RealBleService()`.
  assert(AppConfig.useMockBle, 'Only the mock stack exists in Phase 4');
  final service = MockBleService();
  ref.onDispose(service.dispose);
  return service;
});

final scanResultsProvider = StreamProvider<List<BleDeviceInfo>>(
  (ref) => ref.watch(bleServiceProvider).scanResults,
);

final scanningProvider = StreamProvider<bool>(
  (ref) => ref.watch(bleServiceProvider).scanning,
);

final connectionStateProvider = StreamProvider<BleConnectionState>(
  (ref) => ref.watch(bleServiceProvider).connectionState,
);

final deviceStateProvider = StreamProvider<BleDeviceState?>(
  (ref) => ref.watch(bleServiceProvider).deviceState,
);
