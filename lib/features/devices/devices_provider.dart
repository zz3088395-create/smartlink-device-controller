import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_provider.dart';
import 'device_models.dart';
import 'device_repository.dart';

/// Devices bound to the signed-in user. Resets when the account changes.
class MyDevicesNotifier extends AsyncNotifier<List<AppDevice>> {
  @override
  Future<List<AppDevice>> build() {
    ref.watch(currentUserIdProvider);
    return ref.watch(deviceRepositoryProvider).list();
  }

  /// Re-fetches while keeping the current list on screen (Riverpod keeps the
  /// previous value during an invalidation-triggered rebuild).
  Future<void> refresh() async {
    ref.invalidateSelf();
    try {
      await future;
    } on Object {
      // The error is already reflected in [state]; callers such as
      // RefreshIndicator only need the future to settle.
    }
  }
}

final myDevicesProvider =
    AsyncNotifierProvider<MyDevicesNotifier, List<AppDevice>>(MyDevicesNotifier.new);

/// The device to feature on the home screen when nothing is connected:
/// online first, then most recently connected.
final featuredDeviceProvider = Provider<AppDevice?>((ref) {
  final devices = ref.watch(myDevicesProvider).value;
  if (devices == null || devices.isEmpty) return null;
  final sorted = List<AppDevice>.of(devices)
    ..sort((a, b) {
      if (a.isOnline != b.isOnline) return a.isOnline ? -1 : 1;
      final at = a.lastConnectedAt?.millisecondsSinceEpoch ?? 0;
      final bt = b.lastConnectedAt?.millisecondsSinceEpoch ?? 0;
      return bt.compareTo(at);
    });
  return sorted.first;
});

/// Single device by id, served from the list when possible.
final deviceByIdProvider = FutureProvider.autoDispose.family<AppDevice, String>(
  (ref, id) async {
    final cached = ref.watch(myDevicesProvider).value;
    for (final device in cached ?? const <AppDevice>[]) {
      if (device.id == id) return device;
    }
    return ref.watch(deviceRepositoryProvider).get(id);
  },
);
