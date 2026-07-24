import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rack_sense/app/data/controllers/alarm_controller.dart';
import 'package:rack_sense/app/data/models/alarm_input_config.dart';
import 'package:rack_sense/app/presentation/components/app_scaffold.dart';

class AlarmScreen extends StatelessWidget {
  const AlarmScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<AlarmController>(
      builder: (controller) {
        return AppScaffold(
          selectedIndex: 2,
          title: 'RackSense: Alarms',
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  controller.hasBlockingAlarm
                      ? 'Cabinet shutdown protection is active'
                      : 'Cabinet alarm inputs',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView.separated(
                    itemCount: controller.alarms.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final alarm = controller.alarms[index];
                      final active = alarm.isActive;
                      return Card(
                        color: active
                            ? Theme.of(context).colorScheme.errorContainer
                            : null,
                        child: ListTile(
                          leading: Icon(
                            active
                                ? Icons.warning_rounded
                                : Icons.check_circle_outline,
                            color: active
                                ? Theme.of(context).colorScheme.error
                                : Colors.green,
                          ),
                          title: Text(alarm.config.label),
                          subtitle: Text(
                            '${alarm.config.input.label} • ${_actionLabel(alarm.config.action)}',
                          ),
                          trailing: Text(active ? 'ACTIVE' : 'NORMAL'),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _actionLabel(AlarmAction action) => switch (action) {
    AlarmAction.none => 'No action',
    AlarmAction.soundBuzzer => 'Sound buzzer',
    AlarmAction.turnOffDevices => 'Turn off devices',
  };
}
