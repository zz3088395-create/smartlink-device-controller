import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_provider.dart';
import 'preset_models.dart';
import 'preset_repository.dart';

/// Built-in + personal presets. Mutations re-fetch so ids and timestamps
/// always come from the backend.
class PresetsNotifier extends AsyncNotifier<List<ControlPreset>> {
  @override
  Future<List<ControlPreset>> build() {
    ref.watch(currentUserIdProvider);
    return ref.watch(presetRepositoryProvider).list();
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
    try {
      await future;
    } on Object {
      // Reflected in [state]; callers only await settlement.
    }
  }

  Future<ControlPreset> create(SavePresetRequest request) async {
    final created = await ref.read(presetRepositoryProvider).create(request);
    await refresh();
    return created;
  }

  Future<void> updatePreset(String id, SavePresetRequest request) async {
    await ref.read(presetRepositoryProvider).update(id, request);
    await refresh();
  }

  Future<void> delete(String id) async {
    await ref.read(presetRepositoryProvider).delete(id);
    await refresh();
  }
}

final presetsProvider =
    AsyncNotifierProvider<PresetsNotifier, List<ControlPreset>>(PresetsNotifier.new);

/// Preset by id from the loaded list (`null` while loading or unknown).
final presetByIdProvider = Provider.family<ControlPreset?, String>((ref, id) {
  final presets = ref.watch(presetsProvider).value;
  if (presets == null) return null;
  for (final preset in presets) {
    if (preset.id == id) return preset;
  }
  return null;
});
