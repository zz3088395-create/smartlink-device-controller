import 'package:intl/intl.dart';

import '../api/api_constants.dart';

final DateFormat _apiFormat = DateFormat(ApiConstants.dateTimeFormat);
final DateFormat _timeFormat = DateFormat('HH:mm');
final DateFormat _dayFormat = DateFormat('EEE, d MMM');
final DateFormat _dateFormat = DateFormat('d MMM yyyy');

/// Parses `yyyy-MM-dd HH:mm:ss` (server local time) into a local [DateTime].
DateTime? parseApiDateTime(Object? value) {
  if (value == null) return null;
  final text = value.toString().trim();
  if (text.isEmpty) return null;
  try {
    return _apiFormat.parseStrict(text);
  } on FormatException {
    return DateTime.tryParse(text);
  }
}

String toApiDateTime(DateTime value) => _apiFormat.format(value);

String formatTime(DateTime value) => _timeFormat.format(value);

String formatDate(DateTime value) => _dateFormat.format(value);

/// "Just now", "5 min ago", "2 h ago", "Yesterday", "3 days ago", "12 Aug 2026".
String formatRelative(DateTime? value, {DateTime? now}) {
  if (value == null) return 'Never';
  final reference = now ?? DateTime.now();
  final diff = reference.difference(value);
  if (diff.isNegative) return 'Just now';
  if (diff.inMinutes < 1) return 'Just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
  if (diff.inHours < 24) return '${diff.inHours} h ago';
  final days = _daysBetween(value, reference);
  if (days == 1) return 'Yesterday';
  if (days < 7) return '$days days ago';
  return formatDate(value);
}

/// "Today, 14:32", "Yesterday, 09:10", "Mon, 2 Sep · 14:32".
String formatSessionTime(DateTime value, {DateTime? now}) {
  final reference = now ?? DateTime.now();
  final days = _daysBetween(value, reference);
  final time = formatTime(value);
  if (days == 0) return 'Today, $time';
  if (days == 1) return 'Yesterday, $time';
  return '${_dayFormat.format(value)} · $time';
}

/// "45 s", "18 min", "1 h 12 min".
String formatDurationSeconds(int? seconds) {
  if (seconds == null || seconds < 0) return '—';
  if (seconds < 60) return '$seconds s';
  final minutes = seconds ~/ 60;
  if (minutes < 60) return '$minutes min';
  final hours = minutes ~/ 60;
  final rest = minutes % 60;
  return rest == 0 ? '$hours h' : '$hours h $rest min';
}

/// "3h 42m" style used by summary tiles.
String formatDurationCompact(int seconds) {
  if (seconds < 60) return '${seconds}s';
  final minutes = seconds ~/ 60;
  if (minutes < 60) return '${minutes}m';
  final hours = minutes ~/ 60;
  final rest = minutes % 60;
  return rest == 0 ? '${hours}h' : '${hours}h ${rest}m';
}

int _daysBetween(DateTime from, DateTime to) {
  final a = DateTime(from.year, from.month, from.day);
  final b = DateTime(to.year, to.month, to.day);
  return b.difference(a).inDays;
}
