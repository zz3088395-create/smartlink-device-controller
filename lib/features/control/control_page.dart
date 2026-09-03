import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../app/theme.dart';
import '../../ble/ble_models.dart';
import '../../ble/ble_provider.dart';
import '../../core/widgets/widgets.dart';
import '../presets/mode_icons.dart';
import 'ble_session.dart';
import 'ble_session_controller.dart';
import 'channel_slider.dart';

class ControlPage extends ConsumerWidget {
  const ControlPage({super.key});

  static const _channelLabels = ['Channel A', 'Channel B', 'Channel C'];

  Future<void> _disconnect(BuildContext context, WidgetRef ref, String name) async {
    final confirmed = await showConfirmSheet(
      context,
      title: 'Disconnect device?',
      message: 'Disconnect from $name?',
      confirmLabel: 'Disconnect',
      cancelLabel: 'Cancel',
      destructive: true,
      icon: Icons.link_off_rounded,
    );
    if (!confirmed || !context.mounted) return;
    await ref.read(bleSessionProvider.notifier).disconnect();
    if (context.mounted) context.go(AppRoutes.devices);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final flow = ref.watch(bleSessionProvider);
    final live = ref.watch(deviceStateProvider).value;
    final session = flow.session;

    if (flow.phase == ConnectPhase.disconnecting) {
      return Scaffold(
        appBar: AppBar(title: Text(session?.deviceName ?? 'Device Control')),
        body: const LoadingView(label: 'Disconnecting…'),
      );
    }

    if (!flow.hasSession || session == null || live == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Device Control')),
        body: EmptyState(
          icon: Icons.bluetooth_disabled_rounded,
          title: 'No device connected',
          message: flow.message ??
              'Connect to a SmartLink device to access its controls.',
          actionLabel: 'Scan for Devices',
          onAction: () => context.pushReplacement(AppRoutes.scan),
        ),
      );
    }

    final ble = ref.read(bleServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(session.deviceName),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: TextButton.icon(
              onPressed: () => _disconnect(context, ref, session.deviceName),
              style: TextButton.styleFrom(foregroundColor: AppColors.danger),
              icon: const Icon(Icons.link_off_rounded, size: 18),
              label: const Text('Disconnect'),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.page,
          AppSpacing.xs,
          AppSpacing.page,
          AppSpacing.xxxl,
        ),
        children: [
          if (!session.cloudSynced) ...[
            const InfoBanner(
              title: 'Cloud sync unavailable',
              message: 'Device controls are still available.',
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          _StatusCard(session: session, live: live),
          const SizedBox(height: AppSpacing.lg),
          _DeviceVisualCard(live: live),
          const SizedBox(height: AppSpacing.lg),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SectionHeader(title: 'Master Control'),
                _MasterButton(
                  running: live.running,
                  onPressed: () => live.running ? ble.stop() : ble.start(),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SectionHeader(title: 'Channel Control'),
                for (var i = 0; i < BleDeviceState.channelCount; i++) ...[
                  ChannelSlider(
                    label: _channelLabels[i],
                    value: live.channel(i),
                    onChanged: (value) => ble.setIntensity(i + 1, value),
                  ),
                  if (i < BleDeviceState.channelCount - 1)
                    const SizedBox(height: AppSpacing.xs),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.session, required this.live});

  final BleSession session;
  final BleDeviceState live;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.lg,
      ),
      child: Row(
        children: [
          const StatusBadge(label: 'Connected', tone: StatusTone.online),
          const Spacer(),
          BatteryIndicator(level: live.batteryLevel, size: 20),
          const SizedBox(width: AppSpacing.lg),
          SignalIndicator(rssi: live.rssi, showLabel: false, showDbm: true, size: 16),
        ],
      ),
    );
  }
}

class _DeviceVisualCard extends StatelessWidget {
  const _DeviceVisualCard({required this.live});

  final BleDeviceState live;

  @override
  Widget build(BuildContext context) {
    final running = live.running;
    return AppCard(
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.xxl,
        horizontal: AppSpacing.xl,
      ),
      child: Column(
        children: [
          DeviceIllustration(size: 150, active: running, channels: live.channels),
          const SizedBox(height: AppSpacing.xl),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: Text(
              running ? 'Device Active' : 'Device Stopped',
              key: ValueKey(running),
              style: AppTextStyles.title,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          _ModeEntry(mode: live.mode, onTap: () => context.push(AppRoutes.modes)),
        ],
      ),
    );
  }
}

/// Current mode with a chevron into "Control Modes".
class _ModeEntry extends StatelessWidget {
  const _ModeEntry({required this.mode, required this.onTap});

  final ControlMode mode;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.background,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            children: [
              IconTile(icon: mode.icon, size: 36),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(mode.label, style: AppTextStyles.bodyStrong),
                    Text(mode.description, style: AppTextStyles.caption),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textTertiary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MasterButton extends StatelessWidget {
  const _MasterButton({required this.running, required this.onPressed});

  final bool running;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final background = running ? AppColors.dangerSoft : AppColors.primary;
    final foreground = running ? AppColors.danger : AppColors.onPrimary;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
      height: 64,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: Center(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Row(
                key: ValueKey(running),
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    running ? Icons.stop_rounded : Icons.play_arrow_rounded,
                    color: foreground,
                    size: 26,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    running ? 'Stop' : 'Start',
                    style: AppTextStyles.subtitle.copyWith(
                      color: foreground,
                      fontSize: 17,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
