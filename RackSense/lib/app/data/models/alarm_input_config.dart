import 'package:rack_sense/app/data/models/mainboard_input.dart';

enum AlarmAction { none, soundBuzzer, turnOffDevices }

class AlarmInputConfig {
  const AlarmInputConfig({
    required this.key,
    required this.label,
    required this.input,
    this.action = AlarmAction.none,
    this.isInverted = false,
  });

  final String key;
  final String label;
  final MainboardInput input;
  final AlarmAction action;
  final bool isInverted;

  String get displayLabel => switch (key) {
    'smoke' => 'Duman',
    'water_leak' => 'Su Kaçağı',
    'front_door' => 'Ön Kapı Açık',
    'rear_door' => 'Arka Kapı Açık',
    'service_door' => 'Servis Kapısı Açık',
    _ => label,
  };

  AlarmInputConfig copyWith({
    MainboardInput? input,
    AlarmAction? action,
    bool? isInverted,
  }) {
    return AlarmInputConfig(
      key: key,
      label: label,
      input: input ?? this.input,
      action: action ?? this.action,
      isInverted: isInverted ?? this.isInverted,
    );
  }

  Map<String, Object> toJson() => {
    'key': key,
    'label': label,
    'input': input.name,
    'action': action.name,
    'isInverted': isInverted,
  };

  factory AlarmInputConfig.fromJson(Map<String, dynamic> json) {
    return AlarmInputConfig(
      key: json['key'] as String,
      label: json['label'] as String,
      input: MainboardInput.values.byName(json['input'] as String),
      action: AlarmAction.values.byName(json['action'] as String),
      isInverted: json['isInverted'] as bool? ?? false,
    );
  }
}
