import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rack_sense/app/data/controllers/settings_controller.dart';
import 'package:rack_sense/app/data/models/alarm_input_config.dart';
import 'package:rack_sense/app/data/models/mainboard_input.dart';
import 'package:rack_sense/app/presentation/components/app_scaffold.dart';

class SystemSettingsScreen extends StatelessWidget {
  const SystemSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<SettingsController>(
      builder: (controller) {
        final settings = controller.settings;
        return AppScaffold(
          selectedIndex: 5,
          title: 'RackSense: Ayarlar',
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Çalışma Ayarları',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Card(
                  child: Column(
                    children: [
                      _AutoSwitchIntervalTile(controller: controller),
                      SwitchListTile(
                        title: const Text('Koyu tema'),
                        value: settings.isDarkMode,
                        onChanged: controller.updateTheme,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Text('Kamera', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                _CameraStreamUrlCard(
                  initialUrl: settings.cameraStreamUrl,
                  controller: controller,
                ),
                const SizedBox(height: 20),
                Text(
                  'Kabin Alarm Girişleri',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                for (final config in settings.alarmInputs)
                  _AlarmInputCard(config: config, controller: controller),
                const SizedBox(height: 20),
                Text(
                  'Senkronizasyon Varsayılanları',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        title: const Text('Azure eşitleme aralığı'),
                        trailing: Text(
                          '${settings.azureSyncIntervalMinutes} dk.',
                        ),
                      ),
                      ListTile(
                        title: const Text('Toplu işlem boyutu'),
                        trailing: Text('${settings.azureSyncBatchSize} satır'),
                      ),
                      ListTile(
                        title: const Text('Yeniden deneme ilkesi'),
                        trailing: Text(
                          '${settings.syncRetryCount} × ${settings.syncRetryIntervalMinutes} dk.',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _AutoSwitchIntervalTile extends StatelessWidget {
  const _AutoSwitchIntervalTile({required this.controller});

  static const int _minMinutes = 5;
  static const int _maxMinutes = 72 * 60;

  final SettingsController controller;

  @override
  Widget build(BuildContext context) {
    final totalMinutes = controller.settings.autoSwitchIntervalMinutes.clamp(
      _minMinutes,
      _maxMinutes,
    );
    final hour = totalMinutes ~/ 60;
    final minute = totalMinutes % 60;

    return ListTile(
      title: const Text('Otomatik geçiş aralığı'),
      subtitle: Text('$hour sa. $minute dk.'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButton<int>(
            value: hour,
            items: [
              for (var h = 0; h <= 72; h++)
                DropdownMenuItem(value: h, child: Text('$h sa.')),
            ],
            onChanged: (value) {
              if (value == null) return;
              _updateInterval(hour: value, minute: minute);
            },
          ),
          const SizedBox(width: 12),
          DropdownButton<int>(
            value: minute,
            items: [
              for (var m = 0; m < 60; m += 5)
                DropdownMenuItem(value: m, child: Text('$m dk.')),
            ],
            onChanged: (value) {
              if (value == null) return;
              _updateInterval(hour: hour, minute: value);
            },
          ),
        ],
      ),
    );
  }

  void _updateInterval({required int hour, required int minute}) {
    final totalMinutes = (hour * 60 + minute).clamp(_minMinutes, _maxMinutes);
    controller.updateAutoSwitchInterval(totalMinutes);
  }
}

class _CameraStreamUrlCard extends StatefulWidget {
  const _CameraStreamUrlCard({
    required this.initialUrl,
    required this.controller,
  });

  final String initialUrl;
  final SettingsController controller;

  @override
  State<_CameraStreamUrlCard> createState() => _CameraStreamUrlCardState();
}

class _CameraStreamUrlCardState extends State<_CameraStreamUrlCard> {
  late final TextEditingController _urlController;

  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController(text: widget.initialUrl);
  }

  @override
  void didUpdateWidget(covariant _CameraStreamUrlCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialUrl != widget.initialUrl &&
        _urlController.text != widget.initialUrl) {
      _urlController.text = widget.initialUrl;
    }
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.videocam_outlined),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _urlController,
                keyboardType: TextInputType.url,
                decoration: const InputDecoration(
                  labelText: 'Video akış adresi',
                  hintText: 'http://localhost:8080/video_feed',
                ),
                onSubmitted: (_) => _save(context),
              ),
            ),
            const SizedBox(width: 12),
            FilledButton(
              onPressed: () => _save(context),
              child: const Text('Kaydet'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save(BuildContext context) async {
    try {
      await widget.controller.updateCameraStreamUrl(_urlController.text);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Video akış adresi kaydedildi.')),
      );
    } on ArgumentError catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message?.toString() ?? 'Geçersiz adres.')),
      );
    }
  }
}

class _AlarmInputCard extends StatelessWidget {
  const _AlarmInputCard({required this.config, required this.controller});

  final AlarmInputConfig config;
  final SettingsController controller;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              config.displayLabel,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<MainboardInput>(
                    initialValue: config.input,
                    decoration: const InputDecoration(
                      labelText: 'Ana kart girişi',
                    ),
                    items: MainboardInput.values
                        .map(
                          (input) => DropdownMenuItem(
                            value: input,
                            child: Text(
                              '${input.label} (GPIO ${input.gpioPin})',
                            ),
                          ),
                        )
                        .toList(growable: false),
                    onChanged: (input) {
                      if (input != null) {
                        controller.updateAlarmInput(config.key, input: input);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<AlarmAction>(
                    initialValue: config.action,
                    decoration: const InputDecoration(
                      labelText: 'Alarm eylemi',
                    ),
                    items: AlarmAction.values
                        .map(
                          (action) => DropdownMenuItem(
                            value: action,
                            child: Text(_actionLabel(action)),
                          ),
                        )
                        .toList(growable: false),
                    onChanged: (action) {
                      if (action != null) {
                        controller.updateAlarmInput(config.key, action: action);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  children: [
                    const Text('Tersle'),
                    Switch(
                      value: config.isInverted,
                      onChanged: (value) {
                        controller.updateAlarmInput(
                          config.key,
                          isInverted: value,
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _actionLabel(AlarmAction action) => switch (action) {
    AlarmAction.none => 'Eylem yok',
    AlarmAction.soundBuzzer => 'Sesli uyarı ver',
    AlarmAction.turnOffDevices => 'Cihazları kapat',
  };
}
