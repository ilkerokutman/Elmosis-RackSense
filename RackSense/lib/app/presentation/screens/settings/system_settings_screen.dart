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
          title: 'RackSense: Settings',
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Operation',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        title: const Text('Auto-switch interval'),
                        subtitle: Text(
                          '${settings.autoSwitchIntervalMinutes} minutes',
                        ),
                        trailing: SizedBox(
                          width: 280,
                          child: Slider(
                            min: 30,
                            max: 720,
                            divisions: 23,
                            value: settings.autoSwitchIntervalMinutes
                                .clamp(30, 720)
                                .toDouble(),
                            label: '${settings.autoSwitchIntervalMinutes} min',
                            onChanged: (value) {
                              controller.updateAutoSwitchInterval(
                                value.round(),
                              );
                            },
                          ),
                        ),
                      ),
                      SwitchListTile(
                        title: const Text('Dark theme'),
                        value: settings.isDarkMode,
                        onChanged: controller.updateTheme,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Cabinet Alarm Inputs',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                for (final config in settings.alarmInputs)
                  _AlarmInputCard(config: config, controller: controller),
                const SizedBox(height: 20),
                Text(
                  'Sync Defaults',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        title: const Text('Azure sync interval'),
                        trailing: Text(
                          '${settings.azureSyncIntervalMinutes} min',
                        ),
                      ),
                      ListTile(
                        title: const Text('Batch size'),
                        trailing: Text('${settings.azureSyncBatchSize} rows'),
                      ),
                      ListTile(
                        title: const Text('Retry policy'),
                        trailing: Text(
                          '${settings.syncRetryCount} × ${settings.syncRetryIntervalMinutes} min',
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
            Text(config.label, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<MainboardInput>(
                    initialValue: config.input,
                    decoration: const InputDecoration(
                      labelText: 'Mainboard input',
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
                      labelText: 'Alarm action',
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
                    const Text('Invert'),
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
    AlarmAction.none => 'Do nothing',
    AlarmAction.soundBuzzer => 'Sound buzzer',
    AlarmAction.turnOffDevices => 'Turn off devices',
  };
}
