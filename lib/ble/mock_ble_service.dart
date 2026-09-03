import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'ble_command_encoder.dart';
import 'ble_models.dart';
import 'ble_service.dart';

/// Simulated Bluetooth stack used when no hardware is available.
///
/// Behaviour mirrors what a real peripheral would do: scan results arrive over
/// time, connecting takes a moment, and a connected device pushes battery and
/// RSSI notifications every few seconds. Commands go through
/// [BleCommandEncoder] and mutate the device state that the UI observes, so
/// the app never fakes values locally.
class MockBleService implements BleService {
  MockBleService({
    Random? random,
    this.scanSchedule = const [
      Duration(milliseconds: 1000),
      Duration(milliseconds: 1700),
      Duration(milliseconds: 2400),
    ],
    this.scanDuration = const Duration(milliseconds: 4000),
    this.connectDelay = const Duration(milliseconds: 800),
    this.disconnectDelay = const Duration(milliseconds: 250),
    this.commandLatency = const Duration(milliseconds: 40),
    this.notifyIntervalMin = const Duration(seconds: 3),
    this.notifyIntervalMax = const Duration(seconds: 5),
  })  : assert(scanSchedule.length == simulatedDevices.length),
        _random = random ?? Random();

  /// Fictional peripherals. "SmartLink Mini" advertises the identifier of the
  /// seed device already bound to the demo account, so binding is idempotent
  /// for `demo` and fails with A0302 for anyone else.
  static const List<BleDeviceInfo> simulatedDevices = [
    BleDeviceInfo(
      id: 'mock-sl100-mini',
      name: 'SmartLink Mini',
      model: 'SL-100',
      identifier: 'SL100-B41E0D77',
      rssi: -52,
      firmwareVersion: '1.3.0',
    ),
    BleDeviceInfo(
      id: 'mock-sl200-hub',
      name: 'SmartLink Hub',
      model: 'SL-200',
      identifier: 'SL200-4F8A2C61',
      rssi: -67,
      firmwareVersion: '2.0.1',
    ),
    BleDeviceInfo(
      id: 'mock-sl100-demo',
      name: 'SmartLink Demo Device',
      model: 'SL-100',
      identifier: 'SL100-9D3E7B15',
      rssi: -73,
      firmwareVersion: '1.2.4',
    ),
  ];

  static const int minRssi = -80;
  static const int maxRssi = -45;
  static const int minBattery = 60;
  static const int maxBattery = 100;

  final List<Duration> scanSchedule;
  final Duration scanDuration;
  final Duration connectDelay;
  final Duration disconnectDelay;
  final Duration commandLatency;
  final Duration notifyIntervalMin;
  final Duration notifyIntervalMax;

  final Random _random;

  final _scanResults = _ValueStream<List<BleDeviceInfo>>(const []);
  final _scanning = _ValueStream<bool>(false);
  final _connection = _ValueStream<BleConnectionState>(
    const BleConnectionState.disconnected(),
  );
  final _deviceState = _ValueStream<BleDeviceState?>(null);

  final List<Timer> _scanTimers = [];
  Timer? _notifyTimer;
  int _connectAttempt = 0;
  bool _disposed = false;

  /// Last packet "written" to the device. Exposed for tests and diagnostics.
  Uint8List? lastCommand;

  @override
  Stream<List<BleDeviceInfo>> get scanResults => _scanResults.stream;

  @override
  Stream<bool> get scanning => _scanning.stream;

  @override
  Stream<BleConnectionState> get connectionState => _connection.stream;

  @override
  Stream<BleDeviceState?> get deviceState => _deviceState.stream;

  @override
  BleConnectionState get currentConnectionState => _connection.value;

  @override
  BleDeviceState? get currentDeviceState => _deviceState.value;

  bool get isScanning => _scanning.value;

  @override
  Future<void> startScan() async {
    _ensureAlive();
    await stopScan();
    _scanResults.add(const []);
    _scanning.add(true);
    for (var i = 0; i < simulatedDevices.length; i++) {
      final template = simulatedDevices[i];
      _scanTimers.add(
        Timer(scanSchedule[i], () {
          if (!_scanning.value) return;
          final found = template.copyWith(rssi: _jitterRssi(template.rssi, 3));
          _scanResults.add([..._scanResults.value, found]);
        }),
      );
    }
    _scanTimers.add(Timer(scanDuration, () => _scanning.add(false)));
  }

  @override
  Future<void> stopScan() async {
    for (final timer in _scanTimers) {
      timer.cancel();
    }
    _scanTimers.clear();
    if (_scanning.value) _scanning.add(false);
  }

  @override
  Future<void> connect(String deviceId) async {
    _ensureAlive();
    final current = _connection.value;
    if (current.isConnected && current.device?.id == deviceId) return;
    if (!current.isDisconnected) await disconnect();

    final template = _findDevice(deviceId);
    final advertised = _scanResults.value
        .where((d) => d.id == deviceId)
        .cast<BleDeviceInfo?>()
        .firstWhere((_) => true, orElse: () => null);
    final device = advertised ?? template;

    final attempt = ++_connectAttempt;
    _connection.add(
      BleConnectionState(status: BleConnectionStatus.connecting, device: device),
    );
    await Future<void>.delayed(connectDelay);
    if (_disposed || attempt != _connectAttempt) {
      throw const BleException('Connection cancelled');
    }

    _deviceState.add(
      BleDeviceState(
        channels: const [0, 0, 0],
        mode: ControlMode.pulse,
        running: false,
        batteryLevel: minBattery + _random.nextInt(maxBattery - minBattery + 1),
        rssi: _jitterRssi(device.rssi, 2),
      ),
    );
    _connection.add(
      BleConnectionState(status: BleConnectionStatus.connected, device: device),
    );
    _scheduleNotification();
  }

  @override
  Future<void> disconnect() async {
    _notifyTimer?.cancel();
    _notifyTimer = null;
    _connectAttempt++;
    final current = _connection.value;
    if (current.isDisconnected) return;
    _connection.add(
      BleConnectionState(
        status: BleConnectionStatus.disconnecting,
        device: current.device,
      ),
    );
    await Future<void>.delayed(disconnectDelay);
    _deviceState.add(null);
    _connection.add(const BleConnectionState.disconnected());
  }

  @override
  Future<void> setIntensity(int channel, int value) async {
    final packet = BleCommandEncoder.setIntensity(channel, value);
    final state = await _write(packet);
    final channels = List<int>.of(state.channels);
    if (channel == BleCommandEncoder.channelAll) {
      for (var i = 0; i < channels.length; i++) {
        channels[i] = value;
      }
    } else {
      channels[channel - 1] = value;
    }
    _deviceState.add(state.copyWith(channels: channels));
  }

  @override
  Future<void> start() async {
    final state = await _write(BleCommandEncoder.start());
    _deviceState.add(state.copyWith(running: true));
  }

  @override
  Future<void> stop() async {
    final state = await _write(BleCommandEncoder.stop());
    _deviceState.add(state.copyWith(running: false));
  }

  @override
  Future<void> setMode(ControlMode mode) async {
    final state = await _write(BleCommandEncoder.setMode(mode));
    _deviceState.add(state.copyWith(mode: mode));
  }

  @override
  Future<void> dispose() async {
    _disposed = true;
    await stopScan();
    _notifyTimer?.cancel();
    await Future.wait([
      _scanResults.close(),
      _scanning.close(),
      _connection.close(),
      _deviceState.close(),
    ]);
  }

  // ---------------------------------------------------------------------------

  /// Simulates writing [packet] to the control characteristic and returns the
  /// state the command applies to.
  Future<BleDeviceState> _write(Uint8List packet) async {
    _ensureAlive();
    final state = _deviceState.value;
    if (state == null || !_connection.value.isConnected) {
      throw const BleException('No device connected');
    }
    lastCommand = packet;
    if (commandLatency > Duration.zero) {
      await Future<void>.delayed(commandLatency);
    }
    final latest = _deviceState.value;
    if (latest == null) throw const BleException('Device disconnected');
    return latest;
  }

  void _scheduleNotification() {
    _notifyTimer?.cancel();
    final spread = notifyIntervalMax.inMilliseconds - notifyIntervalMin.inMilliseconds;
    final wait = notifyIntervalMin +
        Duration(milliseconds: spread <= 0 ? 0 : _random.nextInt(spread + 1));
    _notifyTimer = Timer(wait, () {
      final state = _deviceState.value;
      if (state == null || !_connection.value.isConnected) return;
      final base = _connection.value.device?.rssi ?? state.rssi;
      var battery = state.batteryLevel;
      if (_random.nextInt(100) < 35 && battery > 5) battery -= 1;
      _deviceState.add(
        state.copyWith(rssi: _jitterRssi(base, 4), batteryLevel: battery),
      );
      _scheduleNotification();
    });
  }

  int _jitterRssi(int base, int amplitude) {
    final jitter = _random.nextInt(amplitude * 2 + 1) - amplitude;
    return (base + jitter).clamp(minRssi, maxRssi);
  }

  BleDeviceInfo _findDevice(String deviceId) {
    for (final device in simulatedDevices) {
      if (device.id == deviceId) return device;
    }
    throw BleException('Unknown device $deviceId');
  }

  void _ensureAlive() {
    if (_disposed) throw const BleException('Service disposed');
  }
}

/// Broadcast stream that replays its latest value to new listeners.
///
/// [value] is updated synchronously; stream listeners are notified on the
/// next event-loop turn, as with any Dart stream.
class _ValueStream<T> {
  _ValueStream(this._value);

  T _value;
  final StreamController<T> _controller = StreamController<T>.broadcast();

  T get value => _value;

  Stream<T> get stream {
    return Stream<T>.multi((listener) {
      listener.add(_value);
      final subscription = _controller.stream.listen(
        listener.add,
        onError: listener.addError,
        onDone: listener.close,
      );
      listener.onCancel = subscription.cancel;
    });
  }

  void add(T value) {
    _value = value;
    if (!_controller.isClosed) _controller.add(value);
  }

  Future<void> close() => _controller.close();
}
