import 'package:get/get.dart';
import 'package:rack_sense/app/data/models/alarm_input_config.dart';
import 'package:rack_sense/app/data/models/app_settings.dart';
import 'package:rack_sense/app/data/models/mainboard_input.dart';
import 'package:rack_sense/app/data/services/settings_service.dart';

class SettingsController extends GetxController {
  late final SettingsService _settingsService;

  final Rx<AppSettings> _settings = const AppSettings().obs;

  AppSettings get settings => _settings.value;
  Rx<AppSettings> get settingsRx => _settings;

  @override
  void onInit() {
    super.onInit();
    _settingsService = Get.find<SettingsService>();
    _settings.value = _settingsService.settings;
    ever(_settingsService.settingsRx, (AppSettings value) {
      _settings.value = value;
      update();
    });
  }

  Future<void> updateSettings(AppSettings value) {
    return _settingsService.save(value);
  }

  Future<void> updateAutoSwitchInterval(int minutes) {
    return updateSettings(
      settings.copyWith(autoSwitchIntervalMinutes: minutes),
    );
  }

  Future<void> updateTheme(bool isDarkMode) {
    return updateSettings(settings.copyWith(isDarkMode: isDarkMode));
  }

  Future<void> updateAlarmInput(
    String key, {
    MainboardInput? input,
    AlarmAction? action,
    bool? isInverted,
  }) {
    final inputs = settings.alarmInputs
        .map(
          (item) => item.key == key
              ? item.copyWith(
                  input: input,
                  action: action,
                  isInverted: isInverted,
                )
              : item,
        )
        .toList(growable: false);
    return updateSettings(settings.copyWith(alarmInputs: inputs));
  }
}
