// End-to-end check of the API layer against a running smartlink-front-web.
//
// Skipped unless the backend URL is supplied:
//
//   flutter test test/integration --dart-define=SMARTLINK_API=http://localhost:8081
//
// Uses the demo seed (docs/API.md): demo/demo123 owns "SmartLink Mini"
// (SL100-B41E0D77); alice/alice123 does not.
import 'package:flutter_test/flutter_test.dart';
import 'package:smartlink_mobile/ble/mock_ble_service.dart';
import 'package:smartlink_mobile/core/api/api_client.dart';
import 'package:smartlink_mobile/core/api/api_exception.dart';
import 'package:smartlink_mobile/core/storage/token_storage.dart';
import 'package:smartlink_mobile/features/auth/auth_repository.dart';
import 'package:smartlink_mobile/features/devices/device_models.dart';
import 'package:smartlink_mobile/features/devices/device_repository.dart';
import 'package:smartlink_mobile/features/history/history_models.dart';
import 'package:smartlink_mobile/features/history/history_repository.dart';
import 'package:smartlink_mobile/ble/ble_models.dart';
import 'package:smartlink_mobile/features/presets/preset_models.dart';
import 'package:smartlink_mobile/features/presets/preset_repository.dart';

const String apiBaseUrl = String.fromEnvironment('SMARTLINK_API');

class InMemoryTokenStorage implements TokenStorage {
  String? _token;

  @override
  Future<String?> read() async => _token;

  @override
  Future<void> write(String token) async => _token = token;

  @override
  Future<void> clear() async => _token = null;
}

void main() {
  final skip = apiBaseUrl.isEmpty ? 'SMARTLINK_API not provided' : false;

  late InMemoryTokenStorage storage;
  late ApiClient client;
  late AuthRepository auth;
  late DeviceRepository devices;
  late HistoryRepository history;
  var sessionExpiredEvents = 0;

  setUp(() {
    storage = InMemoryTokenStorage();
    client = ApiClient(
      baseUrl: apiBaseUrl,
      tokenStorage: storage,
      onSessionExpired: () => sessionExpiredEvents++,
    );
    auth = AuthRepository(client, storage);
    devices = DeviceRepository(client);
    history = HistoryRepository(client);
  });

  test('unauthenticated call is mapped to session expiry (401 A0002)', () async {
    await expectLater(auth.me(), throwsA(isA<SessionExpiredException>()));
    expect(sessionExpiredEvents, 1);
  }, skip: skip);

  test('wrong password is a business error with product copy', () async {
    await expectLater(
      auth.login(username: 'demo', password: 'nope'),
      throwsA(isA<BusinessException>()
          .having((e) => e.code, 'code', 'A0210')
          .having((e) => e.message, 'message', 'Incorrect username or password.')),
    );
  }, skip: skip);

  test('disabled account (bob) is rejected with A0202', () async {
    await expectLater(
      auth.login(username: 'bob', password: 'bob123'),
      throwsA(isA<BusinessException>().having((e) => e.code, 'code', 'A0202')),
    );
  }, skip: skip);

  test('demo: login → me → devices → idempotent bind → status → history', () async {
    final user = await auth.login(username: 'demo', password: 'demo123');
    expect(user.username, 'demo');
    expect(await storage.read(), isNotEmpty);

    final me = await auth.me();
    expect(me.id, user.id);
    expect(me.displayName, isNotEmpty);

    final mine = await devices.list();
    expect(mine, isNotEmpty);

    final mini = MockBleService.simulatedDevices.first;
    final seedMini = mine.firstWhere((d) => d.deviceIdentifier == mini.identifier);

    final bound = await devices.bind(BindDeviceRequest(
      deviceIdentifier: mini.identifier,
      deviceName: mini.name,
      deviceType: mini.model,
      firmwareVersion: mini.firmwareVersion,
    ));
    expect(bound.id, seedMini.id, reason: 'bind is idempotent for the owner');

    await devices.reportStatus(
      bound.id,
      status: DeviceStatus.online,
      batteryLevel: 88,
      firmwareVersion: mini.firmwareVersion,
    );
    final refreshed = await devices.get(bound.id);
    expect(refreshed.status, DeviceStatus.online);
    expect(refreshed.batteryLevel, 88);

    final connectedAt = DateTime.now().subtract(const Duration(minutes: 3));
    await history.report(ReportSessionRequest(
      deviceId: bound.id,
      connectedAt: connectedAt,
      disconnectedAt: DateTime.now(),
      rssi: -58,
      batteryLevel: 87,
    ));
    final page = await history.list(pageSize: 3);
    expect(page.total, greaterThan(0));
    expect(page.list.first.deviceId, bound.id);
    expect(page.list.first.rssi, -58);
    expect(page.list.first.durationSeconds, inInclusiveRange(170, 190));

    await devices.reportStatus(bound.id, status: DeviceStatus.offline, batteryLevel: 87);
  }, skip: skip);

  test('demo: presets — built-in flag, create custom, update, delete', () async {
    await auth.login(username: 'demo', password: 'demo123');
    final presets = PresetRepository(client);

    final initial = await presets.list();
    expect(initial.where((p) => p.builtIn), isNotEmpty, reason: 'seed has system presets');
    expect(initial.where((p) => p.builtIn).map((p) => p.mode),
        containsAll([ControlMode.pulse, ControlMode.wave, ControlMode.rhythm]));

    final steps = [
      PatternStep(channels: const [20, 40, 60]),
      PatternStep(channels: const [40, 70, 90]),
    ];
    final created = await presets.create(
      SavePresetRequest.custom(presetName: 'Smoke Test Pattern', steps: steps),
    );
    expect(created.builtIn, isFalse);
    expect(created.mode, ControlMode.custom);
    expect(created.patternData, PatternData.encode(steps));
    expect(created.steps.map((s) => s.channels), [[20, 40, 60], [40, 70, 90]]);

    final updatedSteps = [PatternStep(channels: const [5, 10, 15])];
    await presets.update(
      created.id,
      SavePresetRequest.custom(presetName: 'Smoke Test Pattern v2', steps: updatedSteps),
    );
    final afterUpdate = (await presets.list()).firstWhere((p) => p.id == created.id);
    expect(afterUpdate.presetName, 'Smoke Test Pattern v2');
    expect(afterUpdate.steps.single.channels, [5, 10, 15]);

    final builtIn = initial.firstWhere((p) => p.builtIn);
    await expectLater(
      presets.update(builtIn.id, SavePresetRequest.custom(presetName: 'x', steps: steps)),
      throwsA(isA<BusinessException>().having((e) => e.code, 'code', 'A0305')),
      reason: 'built-in presets are read-only',
    );

    await presets.delete(created.id);
    expect((await presets.list()).where((p) => p.id == created.id), isEmpty);
  }, skip: skip);

  test('alice: binding demo\'s device fails with A0302', () async {
    await auth.login(username: 'alice', password: 'alice123');
    final mini = MockBleService.simulatedDevices.first;
    await expectLater(
      devices.bind(BindDeviceRequest(
        deviceIdentifier: mini.identifier,
        deviceName: mini.name,
        deviceType: mini.model,
      )),
      throwsA(isA<BusinessException>()
          .having((e) => e.code, 'code', 'A0302')
          .having((e) => e.message, 'message', 'This device is already linked to another account.')),
    );
  }, skip: skip);
}
