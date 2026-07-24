import 'package:rack_sense/app/data/models/alarm_input_config.dart';
import 'package:rack_sense/app/data/models/mainboard_input.dart';

class AppSettings {
  const AppSettings({
    this.autoSwitchIntervalMinutes = 240,
    this.azureSyncIntervalMinutes = 60,
    this.azureSyncBatchSize = 300,
    this.syncRetryCount = 5,
    this.syncRetryIntervalMinutes = 15,
    this.minimumTemperature = 16,
    this.maximumTemperature = 30,
    this.isDarkMode = true,
    this.alarmInputs = _defaultAlarmInputs,
  });

  static const List<AlarmInputConfig> _defaultAlarmInputs = [
    AlarmInputConfig(
      key: 'smoke',
      label: 'Duman',
      input: MainboardInput.input1,
    ),
    AlarmInputConfig(
      key: 'water_leak',
      label: 'Su Kaçağı',
      input: MainboardInput.input2,
    ),
    AlarmInputConfig(
      key: 'front_door',
      label: 'Ön Kapı',
      input: MainboardInput.input3,
    ),
    AlarmInputConfig(
      key: 'rear_door',
      label: 'Arka Kapı',
      input: MainboardInput.input4,
    ),
    AlarmInputConfig(
      key: 'service_door',
      label: 'Servis Kapısı',
      input: MainboardInput.input5,
    ),
  ];

  final int autoSwitchIntervalMinutes;
  final int azureSyncIntervalMinutes;
  final int azureSyncBatchSize;
  final int syncRetryCount;
  final int syncRetryIntervalMinutes;
  final int minimumTemperature;
  final int maximumTemperature;
  final bool isDarkMode;
  final List<AlarmInputConfig> alarmInputs;

  AppSettings copyWith({
    int? autoSwitchIntervalMinutes,
    int? azureSyncIntervalMinutes,
    int? azureSyncBatchSize,
    int? syncRetryCount,
    int? syncRetryIntervalMinutes,
    int? minimumTemperature,
    int? maximumTemperature,
    bool? isDarkMode,
    List<AlarmInputConfig>? alarmInputs,
  }) {
    return AppSettings(
      autoSwitchIntervalMinutes:
          autoSwitchIntervalMinutes ?? this.autoSwitchIntervalMinutes,
      azureSyncIntervalMinutes:
          azureSyncIntervalMinutes ?? this.azureSyncIntervalMinutes,
      azureSyncBatchSize: azureSyncBatchSize ?? this.azureSyncBatchSize,
      syncRetryCount: syncRetryCount ?? this.syncRetryCount,
      syncRetryIntervalMinutes:
          syncRetryIntervalMinutes ?? this.syncRetryIntervalMinutes,
      minimumTemperature: minimumTemperature ?? this.minimumTemperature,
      maximumTemperature: maximumTemperature ?? this.maximumTemperature,
      isDarkMode: isDarkMode ?? this.isDarkMode,
      alarmInputs: alarmInputs ?? this.alarmInputs,
    );
  }

  Map<String, Object> toJson() => {
    'autoSwitchIntervalMinutes': autoSwitchIntervalMinutes,
    'azureSyncIntervalMinutes': azureSyncIntervalMinutes,
    'azureSyncBatchSize': azureSyncBatchSize,
    'syncRetryCount': syncRetryCount,
    'syncRetryIntervalMinutes': syncRetryIntervalMinutes,
    'minimumTemperature': minimumTemperature,
    'maximumTemperature': maximumTemperature,
    'isDarkMode': isDarkMode,
    'alarmInputs': alarmInputs.map((input) => input.toJson()).toList(),
  };

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    final inputData = json['alarmInputs'] as List<dynamic>?;
    return AppSettings(
      autoSwitchIntervalMinutes:
          json['autoSwitchIntervalMinutes'] as int? ?? 240,
      azureSyncIntervalMinutes: json['azureSyncIntervalMinutes'] as int? ?? 60,
      azureSyncBatchSize: json['azureSyncBatchSize'] as int? ?? 300,
      syncRetryCount: json['syncRetryCount'] as int? ?? 5,
      syncRetryIntervalMinutes: json['syncRetryIntervalMinutes'] as int? ?? 15,
      minimumTemperature: json['minimumTemperature'] as int? ?? 16,
      maximumTemperature: json['maximumTemperature'] as int? ?? 30,
      isDarkMode: json['isDarkMode'] as bool? ?? true,
      alarmInputs: inputData == null
          ? _defaultAlarmInputs
          : inputData
                .map(
                  (value) => AlarmInputConfig.fromJson(
                    Map<String, dynamic>.from(value as Map),
                  ),
                )
                .toList(growable: false),
    );
  }
}
