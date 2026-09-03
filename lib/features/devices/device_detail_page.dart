import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../app/theme.dart';
import '../../core/api/api_exception.dart';
import '../../core/utils/date_utils.dart';
import '../../core/widgets/widgets.dart';
import 'device_models.dart';
import 'devices_provider.dart';

class DeviceDetailPage extends ConsumerWidget {
  const DeviceDetailPage({super.key, required this.deviceId});

  final String deviceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final device = ref.watch(deviceByIdProvider(deviceId));

    return Scaffold(
      appBar: AppBar(title: const Text('Device Info')),
      body: device.when(
        loading: () => const LoadingView(),
        error: (error, _) => ErrorView(
          message: error is ApiException
              ? error.message
              : 'We could not load this device.',
          onRetry: () => ref.invalidate(deviceByIdProvider(deviceId)),
        ),
        data: (device) => _DeviceDetail(device: device),
      ),
    );
  }
}

class _DeviceDetail extends StatelessWidget {
  const _DeviceDetail({required this.device});

  final AppDevice device;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.page,
        AppSpacing.sm,
        AppSpacing.page,
        AppSpacing.xxxl,
      ),
      children: [
        AppCard(
          child: Column(
            children: [
              DeviceIllustration(size: 120, online: device.isOnline),
              const SizedBox(height: AppSpacing.lg),
              Text(device.deviceName, style: AppTextStyles.title),
              if (device.nicknameOrNull != null) ...[
                const SizedBox(height: 2),
                Text('“${device.nicknameOrNull}”', style: AppTextStyles.bodySecondary),
              ],
              const SizedBox(height: AppSpacing.md),
              StatusBadge(
                label: device.status.label,
                tone: device.isOnline ? StatusTone.online : StatusTone.offline,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        AppCard(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.sm,
          ),
          child: Column(
            children: [
              InfoRow(label: 'Model', value: device.deviceType),
              const Divider(),
              InfoRow(label: 'Identifier', value: device.deviceIdentifier),
              const Divider(),
              InfoRow(label: 'Firmware', value: device.firmwareVersion ?? '—'),
              const Divider(),
              InfoRow(
                label: 'Battery',
                value: '',
                trailing: BatteryIndicator(
                  level: device.batteryLevel,
                  textStyle: AppTextStyles.bodyStrong,
                ),
              ),
              const Divider(),
              InfoRow(
                label: 'Last connected',
                value: formatRelative(device.lastConnectedAt),
              ),
              const Divider(),
              InfoRow(
                label: 'Added',
                value: device.bindTime == null ? '—' : formatDate(device.bindTime!),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xxl),
        AppButton(
          label: 'Connect',
          icon: Icons.bluetooth_searching_rounded,
          onPressed: () => context.push(AppRoutes.scan),
        ),
      ],
    );
  }
}
