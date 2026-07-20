class AcUnit {
  final int id;
  final int status;
  final double roomTemperature;
  final double blowTemperature;
  final double targetTemperature;
  final DateTime? lastStartTime;
  final int runtimeInMinutes;
  AcUnit({
    required this.id,
    this.status = 0,
    required this.roomTemperature,
    required this.blowTemperature,
    required this.targetTemperature,
    this.lastStartTime,
    this.runtimeInMinutes = 0,
  });
}
