/// Time-of-day greeting for the home header.
String greetingForHour(int hour) {
  if (hour < 12) return 'Good morning';
  if (hour < 18) return 'Good afternoon';
  return 'Good evening';
}

String greetingNow({DateTime? now}) => greetingForHour((now ?? DateTime.now()).hour);

/// "Mia Carter" -> "MC", "demo" -> "D".
String initialsOf(String name) {
  final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
  final letters = parts.take(2).map((p) => p[0].toUpperCase()).join();
  return letters.isEmpty ? '?' : letters;
}
