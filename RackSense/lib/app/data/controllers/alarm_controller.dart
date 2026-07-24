import 'package:get/get.dart';
import 'package:rack_sense/app/data/controllers/app_controller.dart';
import 'package:rack_sense/app/data/controllers/settings_controller.dart';
import 'package:rack_sense/app/data/models/alarm_input_config.dart';
import 'package:rack_sense/app/data/models/alarm_state.dart';

class AlarmController extends GetxController {
  late final AppController _appController;
  late final SettingsController _settingsController;

  final RxMap<String, AlarmState> _alarmStates = <String, AlarmState>{}.obs;

  Map<String, AlarmState> get alarmStates => Map.unmodifiable(_alarmStates);
  List<AlarmState> get alarms => _alarmStates.values.toList(growable: false);
  bool get hasBlockingAlarm => alarms.any(
    (alarm) =>
        alarm.isActive && alarm.config.action == AlarmAction.turnOffDevices,
  );

  @override
  void onInit() {
    super.onInit();
    _appController = Get.find<AppController>();
    _settingsController = Get.find<SettingsController>();
    ever(_appController.inputRevisionRx, (_) => _evaluate());
    ever(_settingsController.settingsRx, (_) => _evaluate());
    _evaluate();
  }

  void _evaluate() {
    for (final config in _settingsController.settings.alarmInputs) {
      final active =
          _appController.inputStatus(config.input) != config.isInverted;
      final previous = _alarmStates[config.key];
      if (previous?.isActive == active) continue;
      _alarmStates[config.key] = AlarmState(
        config: config,
        isActive: active,
        becameActiveAt: active ? DateTime.now() : null,
      );
      if (active) {
        _handleActivation(config);
      }
    }
    _appController.setCabinetShutdownBlocked(hasBlockingAlarm);
    update();
  }

  void _handleActivation(AlarmInputConfig config) {
    switch (config.action) {
      case AlarmAction.none:
        return;
      case AlarmAction.soundBuzzer:
        _appController.soundError();
      case AlarmAction.turnOffDevices:
        _appController.soundError();
        _appController.requestStopAll(force: true);
    }
  }
}
