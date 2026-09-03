import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../core/utils/date_utils.dart';
import '../../core/widgets/widgets.dart';
import 'history_models.dart';

/// One connection session in a list: device, time, duration, battery, signal.
class ActivityRow extends StatelessWidget {
  const ActivityRow({super.key, required this.record});

  final ConnectionRecord record;

  @override
  Widget build(BuildContext context) {
    final subtitle = [
      formatSessionTime(record.connectedAt),
      record.isOpen ? 'Active' : formatDurationSeconds(record.durationSeconds),
    ].join(' · ');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Row(
        children: [
          IconTile(
            icon: record.isOpen
                ? Icons.bluetooth_connected_rounded
                : Icons.bluetooth_rounded,
            size: 40,
            color: record.isOpen ? AppColors.online : AppColors.primary,
            background: record.isOpen ? AppColors.onlineSoft : AppColors.primarySoft,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record.deviceName,
                  style: AppTextStyles.bodyStrong,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(subtitle, style: AppTextStyles.caption),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              BatteryIndicator(level: record.batteryLevel, size: 16),
              const SizedBox(height: 4),
              SignalIndicator(rssi: record.rssi, size: 12),
            ],
          ),
        ],
      ),
    );
  }
}
