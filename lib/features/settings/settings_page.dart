import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../core/config/app_config.dart';
import '../../core/utils/greeting.dart';
import '../../core/widgets/widgets.dart';
import '../auth/auth_provider.dart';
import '../control/ble_session_controller.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showConfirmSheet(
      context,
      title: 'Log out?',
      message: 'You can sign back in with your username and password.',
      confirmLabel: 'Logout',
      destructive: true,
      icon: Icons.logout_rounded,
    );
    if (!confirmed) return;
    if (ref.read(bleSessionProvider).hasSession) {
      await ref.read(bleSessionProvider.notifier).disconnect();
    }
    await ref.read(authProvider.notifier).logout();
  }

  Future<void> _about(BuildContext context) {
    return showAppBottomSheet<void>(
      context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SmartLinkLogo(size: 64),
          const SizedBox(height: AppSpacing.lg),
          Text(AppConfig.appName, style: AppTextStyles.title),
          const SizedBox(height: AppSpacing.xs),
          Text('Version ${AppConfig.appVersion}', style: AppTextStyles.caption),
          const SizedBox(height: AppSpacing.lg),
          const Text(
            'A generic controller for Bluetooth and IoT smart devices: '
            'scan, connect, control channels in real time and save your own '
            'patterns to the cloud.',
            style: AppTextStyles.bodySecondary,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xxl),
          AppButton.secondary(
            label: 'Close',
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).value;
    final name = user?.displayName ?? '';

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.page,
          AppSpacing.xs,
          AppSpacing.page,
          AppSpacing.xxxl,
        ),
        children: [
          const SectionHeader(title: 'Profile'),
          AppCard(
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: const BoxDecoration(
                    color: AppColors.primarySoft,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    initialsOf(name),
                    style: AppTextStyles.subtitle.copyWith(color: AppColors.primary),
                  ),
                ),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: AppTextStyles.subtitle),
                      const SizedBox(height: 2),
                      Text(
                        user?.email ?? '@${user?.username ?? ''}',
                        style: AppTextStyles.caption,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
          const SectionHeader(title: 'App Settings'),
          AppCard(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xl,
              vertical: AppSpacing.xs,
            ),
            child: Column(
              children: [
                InfoRow(
                  label: 'Demo Bluetooth Mode',
                  value: '',
                  trailing: StatusBadge(
                    label: AppConfig.useMockBle ? 'Enabled' : 'Off',
                    tone: AppConfig.useMockBle ? StatusTone.online : StatusTone.offline,
                  ),
                ),
                const Divider(),
                const InfoRow(label: 'API Environment', value: 'Development'),
                const Divider(),
                InkWell(
                  onTap: () => _about(context),
                  child: const InfoRow(
                    label: 'About ${AppConfig.appName}',
                    value: '',
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Version ${AppConfig.appVersion}', style: AppTextStyles.bodyStrong),
                        SizedBox(width: AppSpacing.xs),
                        Icon(Icons.chevron_right_rounded, size: 20, color: AppColors.textTertiary),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
          AppButton.danger(
            label: 'Logout',
            icon: Icons.logout_rounded,
            onPressed: () => _logout(context, ref),
          ),
        ],
      ),
    );
  }
}
