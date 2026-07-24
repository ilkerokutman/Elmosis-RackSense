import 'dart:convert';

import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:rack_sense/app/data/models/app_settings.dart';

class SettingsService extends GetxService {
  static const _storageKey = 'app_settings';

  final GetStorage _storage;
  final Rx<AppSettings> _settings = const AppSettings().obs;

  SettingsService(this._storage);

  AppSettings get settings => _settings.value;
  Rx<AppSettings> get settingsRx => _settings;

  Future<SettingsService> initialize() async {
    final data = _storage.read<String>(_storageKey);
    if (data != null) {
      try {
        _settings.value = AppSettings.fromJson(
          Map<String, dynamic>.from(jsonDecode(data) as Map),
        );
      } catch (_) {
        await save(const AppSettings());
      }
    } else {
      await save(const AppSettings());
    }
    return this;
  }

  Future<void> save(AppSettings value) async {
    _settings.value = value;
    await _storage.write(_storageKey, jsonEncode(value.toJson()));
  }
}
