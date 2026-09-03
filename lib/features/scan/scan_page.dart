import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../app/theme.dart';
import '../../ble/ble_models.dart';
import '../../ble/ble_provider.dart';
import '../../ble/ble_service.dart';
import '../../core/widgets/widgets.dart';
import '../control/ble_session_controller.dart';
import 'radar_indicator.dart';
import 'scan_device_card.dart';

/// Discovers nearby devices and starts the connect flow. Scanning never
/// touches the backend; synchronisation begins only after "Connect".
class ScanPage extends ConsumerStatefulWidget {
  const ScanPage({super.key});

  @override
  ConsumerState<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends ConsumerState<ScanPage> {
  late final BleService _ble;
  bool _navigating = false;

  @override
  void initState() {
    super.initState();
    _ble = ref.read(bleServiceProvider);
    WidgetsBinding.instance.addPostFrameCallback((_) => _startScan());
  }

  @override
  void dispose() {
    _ble.stopScan();
    super.dispose();
  }

  Future<void> _startScan() async {
    ref.read(bleSessionProvider.notifier).dismiss();
    await _ble.startScan();
  }

  Future<void> _connect(BleDeviceInfo device) async {
    await _ble.stopScan();
    await ref.read(bleSessionProvider.notifier).connect(device);
  }

  Future<void> _openControls() async {
    if (_navigating) return;
    _navigating = true;
    // Let the "Connected" state land before moving on.
    await Future<void>.delayed(const Duration(milliseconds: 450));
    if (!mounted) return;
    context.pushReplacement(AppRoutes.control);
  }

  Future<void> _showOwnershipFailure(BleDeviceInfo? device) async {
    await showAppBottomSheet<void>(
      context,
      isDismissible: false,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                color: AppColors.warningSoft,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.link_off_rounded,
                size: 34,
                color: AppColors.warning,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          const Text(
            'Device unavailable',
            style: AppTextStyles.title,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '${device?.name ?? 'This device'} is already linked to another '
            'account. Ask its owner to unlink it before pairing.',
            style: AppTextStyles.bodySecondary,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xxl),
          AppButton(
            label: 'Back to Devices',
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
    if (!mounted) return;
    ref.read(bleSessionProvider.notifier).dismiss();
    context.go(AppRoutes.devices);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(bleSessionProvider, (previous, next) {
      if (previous?.phase == next.phase) return;
      switch (next.phase) {
        case ConnectPhase.ready:
          _openControls();
        case ConnectPhase.ownershipFailed:
          _showOwnershipFailure(next.target);
        case ConnectPhase.failed:
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(next.message ?? 'Connection failed.')),
          );
          ref.read(bleSessionProvider.notifier).dismiss();
        default:
          break;
      }
    });

    final results = ref.watch(scanResultsProvider).value ?? const <BleDeviceInfo>[];
    final scanning = ref.watch(scanningProvider).value ?? false;
    final flow = ref.watch(bleSessionProvider);

    final status = scanning
        ? 'Scanning for devices…'
        : results.isEmpty
            ? 'No devices found'
            : '${results.length} ${results.length == 1 ? 'device' : 'devices'} found';
    final hint = scanning
        ? 'Keep your device nearby and powered on.'
        : results.isEmpty
            ? 'Make sure the device is switched on and within range.'
            : 'Choose a device to connect.';

    return Scaffold(
      appBar: AppBar(title: const Text('Scan for Devices')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.page,
              AppSpacing.sm,
              AppSpacing.page,
              AppSpacing.lg,
            ),
            child: Column(
              children: [
                RadarIndicator(active: scanning),
                const SizedBox(height: AppSpacing.lg),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: Text(
                    status,
                    key: ValueKey(status),
                    style: AppTextStyles.subtitle,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  hint,
                  style: AppTextStyles.caption,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          Expanded(
            child: results.isEmpty && !scanning
                ? EmptyState(
                    icon: Icons.bluetooth_disabled_rounded,
                    title: 'Nothing nearby',
                    message: 'No SmartLink devices were found this time.',
                    actionLabel: 'Scan again',
                    onAction: _startScan,
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.page,
                      0,
                      AppSpacing.page,
                      AppSpacing.xxl,
                    ),
                    itemCount: results.length,
                    separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
                    itemBuilder: (context, index) {
                      final device = results[index];
                      return ScanDeviceCard(
                        key: ValueKey(device.id),
                        device: device,
                        action: _actionFor(device, flow),
                        onConnect: () => _connect(device),
                      );
                    },
                  ),
          ),
          if (!scanning && results.isNotEmpty && !flow.isBusy)
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.page,
                  0,
                  AppSpacing.page,
                  AppSpacing.lg,
                ),
                child: AppButton.secondary(
                  label: 'Scan again',
                  icon: Icons.refresh_rounded,
                  onPressed: _startScan,
                ),
              ),
            ),
        ],
      ),
    );
  }

  ScanCardAction _actionFor(BleDeviceInfo device, ConnectFlowState flow) {
    final isTarget = flow.target?.id == device.id;
    switch (flow.phase) {
      case ConnectPhase.connecting:
        return isTarget ? ScanCardAction.connecting : ScanCardAction.disabled;
      case ConnectPhase.syncing:
      case ConnectPhase.ready:
        return isTarget ? ScanCardAction.connected : ScanCardAction.disabled;
      case ConnectPhase.disconnecting:
        return ScanCardAction.disabled;
      case ConnectPhase.idle:
      case ConnectPhase.ownershipFailed:
      case ConnectPhase.failed:
        return ScanCardAction.connect;
    }
  }
}
