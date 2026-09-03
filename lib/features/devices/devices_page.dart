import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../app/theme.dart';
import '../../core/api/api_exception.dart';
import '../../core/widgets/widgets.dart';
import 'device_card.dart';
import 'devices_provider.dart';

class DevicesPage extends ConsumerWidget {
  const DevicesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final devices = ref.watch(myDevicesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Devices'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: TextButton.icon(
              onPressed: () => context.push(AppRoutes.scan),
              icon: const Icon(Icons.bluetooth_searching_rounded, size: 18),
              label: const Text('Scan'),
            ),
          ),
        ],
      ),
      body: devices.when(
        loading: () => const LoadingView(),
        error: (error, _) => ErrorView(
          message: error is ApiException
              ? error.message
              : 'We could not load your devices.',
          onRetry: () => ref.invalidate(myDevicesProvider),
        ),
        data: (list) {
          if (list.isEmpty) {
            return EmptyState(
              illustration: const DeviceIllustration(
                size: 110,
                muted: true,
                online: false,
              ),
              title: 'No devices connected',
              message: 'Devices you pair will show up here with their '
                  'battery, firmware and connection status.',
              actionLabel: 'Scan for Devices',
              onAction: () => context.push(AppRoutes.scan),
            );
          }
          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () => ref.read(myDevicesProvider.notifier).refresh(),
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.page,
                AppSpacing.sm,
                AppSpacing.page,
                AppSpacing.xxxl,
              ),
              itemCount: list.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
              itemBuilder: (context, index) {
                final device = list[index];
                return DeviceCard(
                  device: device,
                  onTap: () => context.push(AppRoutes.device(device.id)),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
