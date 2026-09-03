/// Plain dBm bucketing commonly used to describe BLE link quality.
///
/// It is a readability aid, not a measurement: the raw dBm value is always
/// available next to it. Thresholds match the admin console.
enum SignalQuality {
  excellent('Excellent', 'Strong signal', 4),
  good('Good', 'Good signal', 3),
  fair('Fair', 'Fair signal', 2),
  weak('Weak', 'Weak signal', 1);

  const SignalQuality(this.label, this.description, this.bars);

  final String label;
  final String description;
  final int bars;

  static SignalQuality fromRssi(int rssi) {
    if (rssi >= -55) return SignalQuality.excellent;
    if (rssi >= -65) return SignalQuality.good;
    if (rssi >= -75) return SignalQuality.fair;
    return SignalQuality.weak;
  }
}
