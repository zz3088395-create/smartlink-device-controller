import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../core/utils/date_utils.dart';
import '../../core/widgets/widgets.dart';
import 'device_models.dart';

/// Row in "My Devices".
class DeviceCard extends StatelessWidget {
  const DeviceCard({super.key, required this.device, this.onTap});

  final AppDevice device;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final meta = [
      device.deviceType,
      if (device.firmwareVersion != null) 'Firmware ${device.firmwareVersion}',
    ].join(' · ');

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              IconTile(
                icon: Icons.memory_rounded,
                size: 48,
                color: device.isOnline ? AppColors.primary : AppColors.textSecondary,
                background:
                    device.isOnline ? AppColors.primarySoft : AppColors.surfaceMuted,
                radius: AppRadius.md,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      device.deviceName,
                      style: AppTextStyles.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(meta, style: AppTextStyles.caption),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              StatusBadge(
                label: device.status.label,
                tone: device.isOnline ? StatusTone.online : StatusTone.offline,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          const Divider(),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              BatteryIndicator(level: device.batteryLevel),
              const SizedBox(width: AppSpacing.lg),
              const Icon(
                Icons.schedule_rounded,
                size: 16,
                color: AppColors.textTertiary,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  'Last connected ${formatRelative(device.lastConnectedAt).toLowerCase()}',
                  style: AppTextStyles.caption,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: AppColors.textTertiary,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
