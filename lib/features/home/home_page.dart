import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../app/theme.dart';
import '../../ble/ble_models.dart';
import '../../ble/ble_provider.dart';
import '../../core/utils/date_utils.dart';
import '../../core/utils/greeting.dart';
import '../../core/widgets/widgets.dart';
import '../auth/auth_provider.dart';
import '../control/ble_session_controller.dart';
import '../devices/device_models.dart';
import '../devices/devices_provider.dart';
import '../history/activity_row.dart';
import '../history/history_provider.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).value;
    final name = user?.displayName ?? '';

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () => Future.wait([
            ref.read(myDevicesProvider.notifier).refresh(),
            ref.refresh(recentActivityProvider.future),
          ]),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.page,
              AppSpacing.lg,
              AppSpacing.page,
              AppSpacing.xxxl,
            ),
            children: [
              _HomeHeader(
                greeting: greetingNow(),
                name: name,
                onAvatarTap: () => context.go(AppRoutes.settings),
              ),
              const SizedBox(height: AppSpacing.xxl),
              const _DeviceHeroCard(),
              const SizedBox(height: AppSpacing.xxl),
              const SectionHeader(title: 'Quick Actions'),
              const _QuickActions(),
              const SizedBox(height: AppSpacing.xxl),
              SectionHeader(
                title: 'Recent Activity',
                actionLabel: 'See all',
                onAction: () => context.go(AppRoutes.activity),
              ),
              const _RecentActivity(),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({
    required this.greeting,
    required this.name,
    required this.onAvatarTap,
  });

  final String greeting;
  final String name;
  final VoidCallback onAvatarTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$greeting,',
                style: AppTextStyles.bodySecondary.copyWith(fontSize: 15),
              ),
              const SizedBox(height: 2),
              Text(
                name,
                style: AppTextStyles.display,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        GestureDetector(
          onTap: onAvatarTap,
          child: Container(
            width: 46,
            height: 46,
            decoration: const BoxDecoration(
              color: AppColors.primarySoft,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              initialsOf(name),
              style: AppTextStyles.bodyStrong.copyWith(color: AppColors.primary),
            ),
          ),
        ),
      ],
    );
  }
}

/// Live device when connected, otherwise the featured bound device, otherwise
/// a prompt to scan.
class _DeviceHeroCard extends ConsumerWidget {
  const _DeviceHeroCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final flow = ref.watch(bleSessionProvider);
    final live = ref.watch(deviceStateProvider).value;

    if (flow.hasSession && live != null) {
      return _LiveDeviceCard(session: flow, live: live);
    }

    final devices = ref.watch(myDevicesProvider);
    final featured = ref.watch(featuredDeviceProvider);
    if (devices.isLoading && featured == null) {
      return const AppCard(
        child: SizedBox(height: 168, child: LoadingView()),
      );
    }
    if (featured == null) return const _NoDeviceCard();
    return _FeaturedDeviceCard(device: featured);
  }
}

class _LiveDeviceCard extends StatelessWidget {
  const _LiveDeviceCard({required this.session, required this.live});

  final ConnectFlowState session;
  final BleDeviceState live;

  @override
  Widget build(BuildContext context) {
    final info = session.session!;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(info.deviceName, style: AppTextStyles.title),
                    const SizedBox(height: 2),
                    Text(info.deviceModel, style: AppTextStyles.caption),
                    const SizedBox(height: AppSpacing.md),
                    StatusBadge(
                      label: live.running ? 'Connected · Active' : 'Connected',
                      tone: StatusTone.online,
                    ),
                  ],
                ),
              ),
              DeviceIllustration(
                size: 96,
                active: live.running,
                channels: live.channels,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: _MetricTile(
                  label: 'Battery',
                  child: BatteryIndicator(
                    level: live.batteryLevel,
                    size: 20,
                    textStyle: AppTextStyles.bodyStrong,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _MetricTile(
                  label: 'Signal',
                  child: SignalIndicator(rssi: live.rssi, size: 16),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          AppButton(
            label: 'Open Controls',
            icon: Icons.tune_rounded,
            onPressed: () => context.push(AppRoutes.control),
          ),
        ],
      ),
    );
  }
}

class _FeaturedDeviceCard extends StatelessWidget {
  const _FeaturedDeviceCard({required this.device});

  final AppDevice device;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(device.deviceName, style: AppTextStyles.title),
                    const SizedBox(height: 2),
                    Text(
                      [device.deviceType, if (device.nicknameOrNull != null) device.nicknameOrNull!]
                          .join(' · '),
                      style: AppTextStyles.caption,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    StatusBadge(
                      label: device.status.label,
                      tone: device.isOnline ? StatusTone.online : StatusTone.offline,
                    ),
                  ],
                ),
              ),
              DeviceIllustration(size: 96, online: device.isOnline),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: _MetricTile(
                  label: 'Battery',
                  child: BatteryIndicator(
                    level: device.batteryLevel,
                    size: 20,
                    textStyle: AppTextStyles.bodyStrong,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _MetricTile(
                  label: 'Last connected',
                  child: Text(
                    formatRelative(device.lastConnectedAt),
                    style: AppTextStyles.bodyStrong,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          AppButton(
            label: 'Connect',
            icon: Icons.bluetooth_searching_rounded,
            onPressed: () => context.push(AppRoutes.scan),
          ),
        ],
      ),
    );
  }
}

class _NoDeviceCard extends StatelessWidget {
  const _NoDeviceCard();

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('No device connected', style: AppTextStyles.title),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Scan for a nearby SmartLink device to get started.',
                      style: AppTextStyles.bodySecondary,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              const DeviceIllustration(size: 88, muted: true, online: false),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          AppButton(
            label: 'Scan for Devices',
            icon: Icons.bluetooth_searching_rounded,
            onPressed: () => context.push(AppRoutes.scan),
          ),
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.caption),
          const SizedBox(height: 6),
          child,
        ],
      ),
    );
  }
}

class _QuickActions extends ConsumerWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final featured = ref.watch(featuredDeviceProvider);
    return Row(
      children: [
        _QuickAction(
          icon: Icons.bluetooth_searching_rounded,
          label: 'Scan Device',
          onTap: () => context.push(AppRoutes.scan),
        ),
        const SizedBox(width: AppSpacing.md),
        _QuickAction(
          icon: Icons.auto_awesome_motion_outlined,
          label: 'Presets',
          onTap: () => context.push(AppRoutes.modes),
        ),
        const SizedBox(width: AppSpacing.md),
        _QuickAction(
          icon: Icons.timeline_rounded,
          label: 'Activity',
          onTap: () => context.go(AppRoutes.activity),
        ),
        const SizedBox(width: AppSpacing.md),
        _QuickAction(
          icon: Icons.info_outline_rounded,
          label: 'Device Info',
          onTap: () => featured == null
              ? context.go(AppRoutes.devices)
              : context.push(AppRoutes.device(featured.id)),
        ),
      ],
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: AppCard(
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.lg,
          horizontal: AppSpacing.xs,
        ),
        radius: AppRadius.md,
        onTap: onTap,
        child: Column(
          children: [
            IconTile(icon: icon, size: 40),
            const SizedBox(height: AppSpacing.sm),
            Text(
              label,
              style: AppTextStyles.caption.copyWith(color: AppColors.textPrimary),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentActivity extends ConsumerWidget {
  const _RecentActivity();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recent = ref.watch(recentActivityProvider);
    return recent.when(
      loading: () => const AppCard(
        child: SizedBox(height: 120, child: LoadingView()),
      ),
      error: (_, _) => AppCard(
        child: Row(
          children: [
            const Icon(Icons.cloud_off_rounded, color: AppColors.textTertiary),
            const SizedBox(width: AppSpacing.md),
            const Expanded(
              child: Text('Activity is unavailable right now.', style: AppTextStyles.bodySecondary),
            ),
            TextButton(
              onPressed: () => ref.invalidate(recentActivityProvider),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
      data: (records) {
        if (records.isEmpty) {
          return const AppCard(
            child: Row(
              children: [
                IconTile(
                  icon: Icons.history_rounded,
                  color: AppColors.textSecondary,
                  background: AppColors.surfaceMuted,
                ),
                SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    'No sessions yet. Connect a device to see its activity here.',
                    style: AppTextStyles.bodySecondary,
                  ),
                ),
              ],
            ),
          );
        }
        return AppCard(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.xs,
          ),
          child: Column(
            children: [
              for (var i = 0; i < records.length; i++) ...[
                if (i > 0) const Divider(),
                ActivityRow(record: records[i]),
              ],
            ],
          ),
        );
      },
    );
  }
}
