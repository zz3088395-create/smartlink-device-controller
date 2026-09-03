import 'package:flutter_test/flutter_test.dart';
import 'package:smartlink_mobile/features/history/activity_summary.dart';
import 'package:smartlink_mobile/features/history/history_models.dart';

ConnectionRecord record({
  required DateTime connectedAt,
  int? durationSeconds,
  DateTime? disconnectedAt,
}) {
  return ConnectionRecord(
    id: connectedAt.millisecondsSinceEpoch.toString(),
    deviceId: '2000001',
    deviceName: 'Home Controller',
    deviceIdentifier: 'SL100-7A3F91C2',
    deviceType: 'SL-100',
    connectedAt: connectedAt,
    disconnectedAt: disconnectedAt,
    durationSeconds: durationSeconds,
  );
}

void main() {
  final now = DateTime(2026, 9, 3, 15, 0);

  test('counts only sessions from the last seven days', () {
    final summary = ActivitySummary.lastSevenDays([
      record(connectedAt: now.subtract(const Duration(hours: 1)), durationSeconds: 1080),
      record(connectedAt: now.subtract(const Duration(days: 6, hours: 2)), durationSeconds: 600),
      record(connectedAt: now.subtract(const Duration(days: 7, hours: 1)), durationSeconds: 999),
      record(connectedAt: now.subtract(const Duration(days: 20)), durationSeconds: 999),
    ], now: now);

    expect(summary.sessions, 2);
    expect(summary.totalSeconds, 1680);
    expect(summary.averageSeconds, 840);
  });

  test('open sessions count until now, ignoring negative spans', () {
    final summary = ActivitySummary.lastSevenDays([
      record(connectedAt: now.subtract(const Duration(minutes: 5))),
      record(connectedAt: now.add(const Duration(minutes: 5))),
    ], now: now);

    expect(summary.sessions, 2);
    expect(summary.totalSeconds, 300);
  });

  test('empty input yields zeros', () {
    final summary = ActivitySummary.lastSevenDays(const [], now: now);
    expect(summary.sessions, 0);
    expect(summary.totalSeconds, 0);
    expect(summary.averageSeconds, 0);
  });
}
