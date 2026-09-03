import 'history_models.dart';

/// Local roll-up of connection sessions; no backend endpoint involved.
class ActivitySummary {
  const ActivitySummary({
    required this.sessions,
    required this.totalSeconds,
  });

  static const ActivitySummary empty = ActivitySummary(sessions: 0, totalSeconds: 0);

  final int sessions;
  final int totalSeconds;

  int get averageSeconds => sessions == 0 ? 0 : totalSeconds ~/ sessions;

  /// Sessions that started within the last seven days (today included).
  /// Open sessions count from their start until [now].
  static ActivitySummary lastSevenDays(
    Iterable<ConnectionRecord> records, {
    DateTime? now,
  }) {
    final reference = now ?? DateTime.now();
    final today = DateTime(reference.year, reference.month, reference.day);
    final from = today.subtract(const Duration(days: 6));

    var sessions = 0;
    var seconds = 0;
    for (final record in records) {
      if (record.connectedAt.isBefore(from)) continue;
      sessions++;
      final duration = record.durationSeconds ??
          (record.disconnectedAt == null
              ? reference.difference(record.connectedAt).inSeconds
              : record.disconnectedAt!.difference(record.connectedAt).inSeconds);
      seconds += duration < 0 ? 0 : duration;
    }
    return ActivitySummary(sessions: sessions, totalSeconds: seconds);
  }
}
