class TemperatureSample {
  const TemperatureSample({
    required this.recordedAt,
    required this.temperature,
    required this.targetTemperature,
  });

  final DateTime recordedAt;
  final int temperature;
  final int targetTemperature;
}
