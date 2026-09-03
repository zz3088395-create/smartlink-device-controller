import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../ble/ble_models.dart';
import '../../core/utils/signal_quality.dart';
import '../../core/widgets/widgets.dart';

enum ScanCardAction { connect, connecting, connected, disabled }

/// Discovered device with its connect button.
class ScanDeviceCard extends StatelessWidget {
  const ScanDeviceCard({
    super.key,
    required this.device,
    required this.action,
    required this.onConnect,
  });

  final BleDeviceInfo device;
  final ScanCardAction action;
  final VoidCallback onConnect;

  @override
  Widget build(BuildContext context) {
    final quality = SignalQuality.fromRssi(device.rssi);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeOutCubic,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(offset: Offset(0, 14 * (1 - t)), child: child),
      ),
      child: AppCard(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          children: [
            const IconTile(icon: Icons.memory_rounded, size: 48, radius: AppRadius.md),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    device.name,
                    style: AppTextStyles.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${device.model} · ${quality.description}',
                    style: AppTextStyles.caption,
                  ),
                  const SizedBox(height: 6),
                  SignalIndicator(rssi: device.rssi, showLabel: false, showDbm: true),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            _ConnectButton(action: action, onPressed: onConnect),
          ],
        ),
      ),
    );
  }
}

class _ConnectButton extends StatelessWidget {
  const _ConnectButton({required this.action, required this.onPressed});

  final ScanCardAction action;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final (label, background, foreground, icon) = switch (action) {
      ScanCardAction.connect => (
          'Connect',
          AppColors.primary,
          AppColors.onPrimary,
          null,
        ),
      ScanCardAction.connecting => (
          'Connecting…',
          AppColors.primarySoft,
          AppColors.primary,
          null,
        ),
      ScanCardAction.connected => (
          'Connected',
          AppColors.onlineSoft,
          AppColors.online,
          Icons.check_rounded,
        ),
      ScanCardAction.disabled => (
          'Connect',
          AppColors.surfaceMuted,
          AppColors.textTertiary,
          null,
        ),
    };

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
      height: 38,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: action == ScanCardAction.connect ? onPressed : null,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (action == ScanCardAction.connecting) ...[
                  SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: foreground,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                ] else if (icon != null) ...[
                  Icon(icon, size: 16, color: foreground),
                  const SizedBox(width: AppSpacing.xs),
                ],
                Text(
                  label,
                  style: AppTextStyles.caption.copyWith(
                    color: foreground,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
