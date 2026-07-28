class AcUnitState {
  const AcUnitState({
    required this.deviceId,
    this.errorCode = 0,
    this.status = 0,
    this.targetTemperature,
    this.ntc0,
    this.ntc1,
    this.ntc2,
    this.ntc3,
    this.fanLevel,
    this.isRunning = false,
    this.isConnected = false,
    this.nextProbeAt,
    this.lastResponseAt,
    this.lastTurnedOnAt,
    this.lastTurnedOffAt,
    this.failureStartedAt,
    this.communicationFailureStartedAt,
  });

  final int deviceId;
  final int errorCode;
  final int status;
  final int? targetTemperature;
  final int? ntc0;
  final int? ntc1;
  final int? ntc2;
  final int? ntc3;
  final int? fanLevel;
  final bool isRunning;
  final bool isConnected;
  final DateTime? nextProbeAt;
  final DateTime? lastResponseAt;
  final DateTime? lastTurnedOnAt;
  final DateTime? lastTurnedOffAt;
  final DateTime? failureStartedAt;
  final DateTime? communicationFailureStartedAt;

  bool get hasError => errorCode != 0;

  List<int?> get temperatures => [ntc0, ntc1, ntc2, ntc3];

  AcUnitState copyWith({
    int? errorCode,
    int? status,
    int? targetTemperature,
    int? ntc0,
    int? ntc1,
    int? ntc2,
    int? ntc3,
    int? fanLevel,
    bool? isRunning,
    bool? isConnected,
    DateTime? nextProbeAt,
    DateTime? lastResponseAt,
    DateTime? lastTurnedOnAt,
    DateTime? lastTurnedOffAt,
    DateTime? failureStartedAt,
    DateTime? communicationFailureStartedAt,
    bool clearFailureStartedAt = false,
    bool clearCommunicationFailureStartedAt = false,
    bool clearNextProbeAt = false,
  }) {
    return AcUnitState(
      deviceId: deviceId,
      errorCode: errorCode ?? this.errorCode,
      status: status ?? this.status,
      targetTemperature: targetTemperature ?? this.targetTemperature,
      ntc0: ntc0 ?? this.ntc0,
      ntc1: ntc1 ?? this.ntc1,
      ntc2: ntc2 ?? this.ntc2,
      ntc3: ntc3 ?? this.ntc3,
      fanLevel: fanLevel ?? this.fanLevel,
      isRunning: isRunning ?? this.isRunning,
      isConnected: isConnected ?? this.isConnected,
      nextProbeAt: clearNextProbeAt ? null : nextProbeAt ?? this.nextProbeAt,
      lastResponseAt: lastResponseAt ?? this.lastResponseAt,
      lastTurnedOnAt: lastTurnedOnAt ?? this.lastTurnedOnAt,
      lastTurnedOffAt: lastTurnedOffAt ?? this.lastTurnedOffAt,
      failureStartedAt: clearFailureStartedAt
          ? null
          : failureStartedAt ?? this.failureStartedAt,
      communicationFailureStartedAt: clearCommunicationFailureStartedAt
          ? null
          : communicationFailureStartedAt ?? this.communicationFailureStartedAt,
    );
  }
}
