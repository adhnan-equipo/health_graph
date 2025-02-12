class O2SaturationData {
  final DateTime date;
  final int o2Value; // Percentage value (0-100)
  final int? pulseRate; // Optional pulse rate in BPM

  O2SaturationData({
    required this.date,
    required this.o2Value,
    this.pulseRate,
  });
}
