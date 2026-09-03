import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../app/theme.dart';
import '../../ble/ble_models.dart';
import '../../ble/ble_provider.dart';
import '../../ble/ble_service.dart';
import '../../core/api/api_exception.dart';
import '../../core/widgets/widgets.dart';
import '../control/ble_session_controller.dart';
import 'mode_icons.dart';
import 'preset_models.dart';
import 'presets_provider.dart';

/// "Control Modes": the four device modes plus built-in and personal presets
/// from `GET /app/presets`.
class ModesPage extends ConsumerWidget {
  const ModesPage({super.key});

  void _notify(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _selectMode(
    BuildContext context,
    WidgetRef ref,
    ControlMode mode,
    bool connected,
  ) async {
    if (mode == ControlMode.custom) {
      context.push(AppRoutes.patternEditor);
      return;
    }
    if (!connected) {
      _notify(context, 'Connect a device to apply a mode.');
      return;
    }
    try {
      await ref.read(bleServiceProvider).setMode(mode);
    } on BleException {
      if (context.mounted) _notify(context, 'The device did not accept the mode.');
    }
  }

  Future<void> _applyPreset(
    BuildContext context,
    WidgetRef ref,
    ControlPreset preset,
    bool connected,
  ) async {
    if (preset.isCustom) {
      context.push(AppRoutes.patternEditorFor(preset.id));
      return;
    }
    if (!connected) {
      _notify(context, 'Connect a device to apply a preset.');
      return;
    }
    final BleService ble = ref.read(bleServiceProvider);
    try {
      await ble.setMode(preset.mode);
      for (var i = 0; i < preset.channels.length; i++) {
        await ble.setIntensity(i + 1, preset.channels[i]);
      }
      if (context.mounted) _notify(context, '“${preset.presetName}” applied.');
    } on BleException {
      if (context.mounted) _notify(context, 'The device did not accept the preset.');
    }
  }

  Future<void> _presetActions(
    BuildContext context,
    WidgetRef ref,
    ControlPreset preset,
  ) async {
    final action = await showAppBottomSheet<String>(
      context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(preset.presetName, style: AppTextStyles.title, textAlign: TextAlign.center),
          const SizedBox(height: AppSpacing.xl),
          if (preset.isCustom) ...[
            AppButton.secondary(
              label: 'Edit pattern',
              icon: Icons.edit_outlined,
              onPressed: () => Navigator.of(context).pop('edit'),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          AppButton.danger(
            label: 'Delete preset',
            icon: Icons.delete_outline_rounded,
            onPressed: () => Navigator.of(context).pop('delete'),
          ),
        ],
      ),
    );
    if (!context.mounted || action == null) return;
    if (action == 'edit') {
      context.push(AppRoutes.patternEditorFor(preset.id));
      return;
    }
    final confirmed = await showConfirmSheet(
      context,
      title: 'Delete preset?',
      message: '“${preset.presetName}” will be removed from your library.',
      confirmLabel: 'Delete',
      destructive: true,
      icon: Icons.delete_outline_rounded,
    );
    if (!confirmed || !context.mounted) return;
    try {
      await ref.read(presetsProvider.notifier).delete(preset.id);
      if (context.mounted) _notify(context, 'Preset deleted.');
    } on ApiException catch (error) {
      if (context.mounted) _notify(context, error.message);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final live = ref.watch(deviceStateProvider).value;
    final connected = ref.watch(bleSessionProvider).hasSession && live != null;
    final presets = ref.watch(presetsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Control Modes')),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () => ref.read(presetsProvider.notifier).refresh(),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.page,
            AppSpacing.xs,
            AppSpacing.page,
            AppSpacing.xxxl,
          ),
          children: [
            if (!connected) ...[
              const InfoBanner(
                tone: StatusTone.neutral,
                icon: Icons.bluetooth_rounded,
                title: 'No device connected',
                message: 'Modes and presets apply once a device is connected.',
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
            const SectionHeader(title: 'Modes'),
            _ModeGrid(
              selected: connected ? live.mode : null,
              onSelect: (mode) => _selectMode(context, ref, mode, connected),
            ),
            const SizedBox(height: AppSpacing.xxl),
            SectionHeader(
              title: 'Presets',
              actionLabel: 'New custom',
              onAction: () => context.push(AppRoutes.patternEditor),
            ),
            presets.when(
              loading: () => const AppCard(
                child: SizedBox(height: 120, child: LoadingView()),
              ),
              error: (error, _) => AppCard(
                child: ErrorView(
                  title: 'Presets unavailable',
                  message: error is ApiException
                      ? error.message
                      : 'We could not load your presets.',
                  onRetry: () => ref.invalidate(presetsProvider),
                ),
              ),
              data: (list) => _PresetList(
                presets: list,
                onTap: (preset) => _applyPreset(context, ref, preset, connected),
                onMore: (preset) => _presetActions(context, ref, preset),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModeGrid extends StatelessWidget {
  const _ModeGrid({required this.selected, required this.onSelect});

  final ControlMode? selected;
  final ValueChanged<ControlMode> onSelect;

  @override
  Widget build(BuildContext context) {
    Widget card(ControlMode mode) => Expanded(
          child: _ModeCard(
            mode: mode,
            selected: selected == mode,
            onTap: () => onSelect(mode),
          ),
        );
    return Column(
      children: [
        Row(
          children: [
            card(ControlMode.pulse),
            const SizedBox(width: AppSpacing.md),
            card(ControlMode.wave),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            card(ControlMode.rhythm),
            const SizedBox(width: AppSpacing.md),
            card(ControlMode.custom),
          ],
        ),
      ],
    );
  }
}

class _ModeCard extends StatelessWidget {
  const _ModeCard({
    required this.mode,
    required this.selected,
    required this.onTap,
  });

  final ControlMode mode;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.lg),
      borderColor: selected ? AppColors.primary : AppColors.border,
      child: SizedBox(
        height: 118,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconTile(
                  icon: mode.icon,
                  size: 40,
                  color: selected ? AppColors.onPrimary : AppColors.primary,
                  background: selected ? AppColors.primary : AppColors.primarySoft,
                ),
                const Spacer(),
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: selected ? 1 : 0,
                  child: const Icon(
                    Icons.check_circle_rounded,
                    color: AppColors.primary,
                    size: 22,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Text(mode.label, style: AppTextStyles.subtitle),
            const SizedBox(height: 2),
            Text(
              mode.description,
              style: AppTextStyles.caption,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _PresetList extends StatelessWidget {
  const _PresetList({
    required this.presets,
    required this.onTap,
    required this.onMore,
  });

  final List<ControlPreset> presets;
  final ValueChanged<ControlPreset> onTap;
  final ValueChanged<ControlPreset> onMore;

  @override
  Widget build(BuildContext context) {
    if (presets.isEmpty) {
      return const AppCard(
        child: Text(
          'No presets yet. Create a custom pattern to save your first one.',
          style: AppTextStyles.bodySecondary,
        ),
      );
    }
    final sorted = List<ControlPreset>.of(presets)
      ..sort((a, b) {
        if (a.builtIn != b.builtIn) return a.builtIn ? -1 : 1;
        return a.presetName.toLowerCase().compareTo(b.presetName.toLowerCase());
      });
    return AppCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xs,
      ),
      child: Column(
        children: [
          for (var i = 0; i < sorted.length; i++) ...[
            if (i > 0) const Divider(),
            _PresetRow(
              preset: sorted[i],
              onTap: () => onTap(sorted[i]),
              onMore: sorted[i].builtIn ? null : () => onMore(sorted[i]),
            ),
          ],
        ],
      ),
    );
  }
}

class _PresetRow extends StatelessWidget {
  const _PresetRow({
    required this.preset,
    required this.onTap,
    this.onMore,
  });

  final ControlPreset preset;
  final VoidCallback onTap;
  final VoidCallback? onMore;

  @override
  Widget build(BuildContext context) {
    final String detail;
    if (preset.isCustom) {
      final steps = preset.steps;
      final total = PatternData.totalDuration(steps);
      detail = '${preset.mode.label} · ${steps.length} steps · '
          '${(total.inMilliseconds / 1000).toStringAsFixed(1)} s';
    } else {
      detail = '${preset.mode.label} · A ${preset.channel1} · '
          'B ${preset.channel2} · C ${preset.channel3}';
    }

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: Row(
          children: [
            IconTile(
              icon: preset.mode.icon,
              size: 40,
              color: preset.builtIn ? AppColors.textSecondary : AppColors.primary,
              background: preset.builtIn ? AppColors.surfaceMuted : AppColors.primarySoft,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          preset.presetName,
                          style: AppTextStyles.bodyStrong,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (preset.builtIn) ...[
                        const SizedBox(width: AppSpacing.sm),
                        const StatusBadge(
                          label: 'Built-in',
                          tone: StatusTone.neutral,
                          showDot: false,
                          compact: true,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(detail, style: AppTextStyles.caption),
                ],
              ),
            ),
            if (onMore != null)
              IconButton(
                onPressed: onMore,
                visualDensity: VisualDensity.compact,
                icon: const Icon(
                  Icons.more_horiz_rounded,
                  color: AppColors.textTertiary,
                ),
              )
            else
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textTertiary,
              ),
          ],
        ),
      ),
    );
  }
}
