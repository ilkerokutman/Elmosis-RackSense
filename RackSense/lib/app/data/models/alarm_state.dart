import 'package:rack_sense/app/data/models/alarm_input_config.dart';

class AlarmState {
  const AlarmState({
    required this.config,
    this.isActive = false,
    this.becameActiveAt,
  });

  final AlarmInputConfig config;
  final bool isActive;
  final DateTime? becameActiveAt;

  AlarmState copyWith({bool? isActive, DateTime? becameActiveAt}) {
    return AlarmState(
      config: config,
      isActive: isActive ?? this.isActive,
      becameActiveAt: becameActiveAt ?? this.becameActiveAt,
    );
  }
}
