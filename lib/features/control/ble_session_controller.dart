import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../ble/ble_models.dart';
import '../../ble/ble_provider.dart';
import '../../ble/ble_service.dart';
import '../../core/api/api_constants.dart';
import '../../core/api/api_exception.dart';
import '../devices/device_models.dart';
import '../devices/device_repository.dart';
import '../devices/devices_provider.dart';
import '../history/history_models.dart';
import '../history/history_provider.dart';
import '../history/history_repository.dart';
import 'ble_session.dart';

enum ConnectPhase {
  idle,

  /// BLE link being established.
  connecting,

  /// Link up; confirming ownership with the backend.
  syncing,

  /// Session active, controls available.
  ready,

  /// Explicit disconnect in progress.
  disconnecting,

  /// Backend answered A0302: the device belongs to another account.
  ownershipFailed,

  /// BLE connect failed.
  failed,
}

class ConnectFlowState {
  const ConnectFlowState({
    this.phase = ConnectPhase.idle,
    this.target,
    this.session,
    this.message,
  });

  final ConnectPhase phase;

  /// Device being connected / connected to.
  final BleDeviceInfo? target;
  final BleSession? session;

  /// Copy for the failure states.
  final String? message;

  bool get isBusy =>
      phase == ConnectPhase.connecting ||
      phase == ConnectPhase.syncing ||
      phase == ConnectPhase.disconnecting;

  bool get hasSession => phase == ConnectPhase.ready && session != null;

  ConnectFlowState copyWith({
    ConnectPhase? phase,
    BleDeviceInfo? target,
    BleSession? session,
    String? message,
  }) {
    return ConnectFlowState(
      phase: phase ?? this.phase,
      target: target ?? this.target,
      session: session ?? this.session,
      message: message ?? this.message,
    );
  }
}

/// Orchestrates "tap Connect" end to end:
///
/// 1. `BleService.connect`
/// 2. `POST /app/devices` (ownership) → A0302 disconnects and fails
/// 3. `PUT /app/devices/{id}/status ONLINE` (best effort)
/// 4. session created → control screen
///
/// Cloud failures other than A0302 never break the Bluetooth demo: the
/// session opens with `cloudSynced = false` and the UI shows a banner.
class BleSessionController extends Notifier<ConnectFlowState> {
  @override
  ConnectFlowState build() {
    ref.listen(deviceStateProvider, (_, next) {
      final device = next.value;
      final session = state.session;
      if (device == null || session == null) return;
      state = state.copyWith(
        session: session.copyWith(
          lastRssi: device.rssi,
          lastBatteryLevel: device.batteryLevel,
        ),
      );
    });
    ref.listen(connectionStateProvider, (_, next) {
      final link = next.value;
      if (link == null) return;
      // Link dropped underneath an active session (real hardware, Phase 5).
      if (link.isDisconnected && state.phase == ConnectPhase.ready) {
        final session = state.session;
        state = ConnectFlowState(
          message: link.error ?? 'The device disconnected.',
        );
        if (session != null) unawaited(_closeSession(session));
      }
    });
    return const ConnectFlowState();
  }

  BleService get _ble => ref.read(bleServiceProvider);

  Future<void> connect(BleDeviceInfo device) async {
    if (state.isBusy) return;
    state = ConnectFlowState(phase: ConnectPhase.connecting, target: device);

    try {
      await _ble.connect(device.id);
    } on BleException catch (error) {
      debugPrint('BLE connect failed: ${error.message}');
      state = ConnectFlowState(
        phase: ConnectPhase.failed,
        target: device,
        message: 'Could not connect to ${device.name}. '
            'Move closer to the device and try again.',
      );
      return;
    }

    state = state.copyWith(phase: ConnectPhase.syncing);

    String? backendDeviceId;
    var cloudSynced = false;
    try {
      final bound = await ref.read(deviceRepositoryProvider).bind(
            BindDeviceRequest(
              deviceIdentifier: device.identifier,
              deviceName: device.name,
              deviceType: device.model,
              firmwareVersion: device.firmwareVersion,
            ),
          );
      backendDeviceId = bound.id;
      cloudSynced = true;
    } on BusinessException catch (error) {
      if (error.code == ApiConstants.deviceBoundToOtherAccountCode) {
        await _ble.disconnect();
        state = ConnectFlowState(
          phase: ConnectPhase.ownershipFailed,
          target: device,
          message: error.message,
        );
        return;
      }
      debugPrint('Bind rejected (${error.code}): ${error.message}');
    } on SessionExpiredException {
      // The router is already sending the user to the login screen.
      await _ble.disconnect();
      state = const ConnectFlowState();
      return;
    } on ApiException catch (error) {
      debugPrint('Cloud unavailable during connect: ${error.message}');
    }

    final live = _ble.currentDeviceState;
    final session = BleSession(
      backendDeviceId: backendDeviceId,
      deviceIdentifier: device.identifier,
      deviceName: device.name,
      deviceModel: device.model,
      firmwareVersion: device.firmwareVersion,
      connectedAt: DateTime.now(),
      lastRssi: live?.rssi ?? device.rssi,
      lastBatteryLevel: live?.batteryLevel,
      cloudSynced: cloudSynced,
    );
    state = ConnectFlowState(
      phase: ConnectPhase.ready,
      target: device,
      session: session,
    );

    if (backendDeviceId != null) {
      ref.invalidate(myDevicesProvider);
      unawaited(_reportStatus(
        backendDeviceId,
        DeviceStatus.online,
        batteryLevel: live?.batteryLevel,
        firmwareVersion: device.firmwareVersion,
      ));
    }
  }

  /// Tears down the link immediately; cloud bookkeeping happens afterwards
  /// and never delays the UI.
  Future<void> disconnect() async {
    final session = state.session;
    state = state.copyWith(phase: ConnectPhase.disconnecting);
    await _ble.disconnect();
    state = const ConnectFlowState();
    if (session != null) unawaited(_closeSession(session));
  }

  /// Clears a failure banner / sheet.
  void dismiss() {
    if (!state.isBusy && state.phase != ConnectPhase.ready) {
      state = const ConnectFlowState();
    }
  }

  Future<void> _closeSession(BleSession session) async {
    final deviceId = session.backendDeviceId;
    if (deviceId != null) {
      await _reportStatus(
        deviceId,
        DeviceStatus.offline,
        batteryLevel: session.lastBatteryLevel,
      );
      try {
        await ref.read(historyRepositoryProvider).report(
              ReportSessionRequest(
                deviceId: deviceId,
                connectedAt: session.connectedAt,
                disconnectedAt: DateTime.now(),
                rssi: session.lastRssi,
                batteryLevel: session.lastBatteryLevel,
              ),
            );
      } on ApiException catch (error) {
        debugPrint('History report skipped: ${error.message}');
      }
    }
    ref.invalidate(myDevicesProvider);
    ref.invalidate(recentActivityProvider);
  }

  Future<void> _reportStatus(
    String deviceId,
    DeviceStatus status, {
    int? batteryLevel,
    String? firmwareVersion,
  }) async {
    try {
      await ref.read(deviceRepositoryProvider).reportStatus(
            deviceId,
            status: status,
            batteryLevel: batteryLevel,
            firmwareVersion: firmwareVersion,
          );
    } on ApiException catch (error) {
      debugPrint('Status report skipped: ${error.message}');
    }
  }
}

final bleSessionProvider =
    NotifierProvider<BleSessionController, ConnectFlowState>(BleSessionController.new);
