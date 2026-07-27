import 'dart:async';

import 'package:get/get.dart';
import 'package:rack_sense/app/data/controllers/settings_controller.dart';
import 'package:rack_sense/app/data/repositories/telemetry_repository.dart';
import 'package:rack_sense/app/data/services/database_service.dart';

class SyncController extends GetxController {
  late final SettingsController _settingsController;
  late final TelemetryRepository _telemetryRepository;
  Timer? _countdownTimer;

  DateTime? _lastSyncAt;
  late DateTime _nextSyncAt;
  int _unsentDataCount = 0;
  int _failedDataCount = 0;
  bool _isRefreshing = false;

  DateTime? get lastSyncAt => _lastSyncAt;
  DateTime get nextSyncAt => _nextSyncAt;
  int get unsentDataCount => _unsentDataCount;
  int get failedDataCount => _failedDataCount;
  bool get isRefreshing => _isRefreshing;

  @override
  void onInit() {
    super.onInit();
    _settingsController = Get.find<SettingsController>();
    _telemetryRepository = TelemetryRepository(Get.find<DatabaseService>());
    _scheduleNextSync();
    ever(_settingsController.settingsRx, (_) => _scheduleNextSync());
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      update();
    });
    refreshStatus();
  }

  Future<void> refreshStatus() async {
    _isRefreshing = true;
    update();
    try {
      _unsentDataCount = await _telemetryRepository.pendingSyncCount();
      _failedDataCount = await _telemetryRepository.failedSyncCount();
    } finally {
      _isRefreshing = false;
      update();
    }
  }

  Future<void> prepareSyncNow() => refreshStatus();

  Future<void> prepareRetryNow() => refreshStatus();

  void _scheduleNextSync() {
    _nextSyncAt = DateTime.now().add(
      Duration(minutes: _settingsController.settings.azureSyncIntervalMinutes),
    );
    update();
  }

  @override
  void onClose() {
    _countdownTimer?.cancel();
    super.onClose();
  }
}
