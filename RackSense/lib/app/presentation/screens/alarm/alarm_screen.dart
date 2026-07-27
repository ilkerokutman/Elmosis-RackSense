import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rack_sense/app/data/controllers/alarm_controller.dart';
import 'package:rack_sense/app/data/controllers/app_controller.dart';
import 'package:rack_sense/app/presentation/components/app_scaffold.dart';
import 'package:rack_sense/app/presentation/screens/alarm/widgets/alarm_status_grid.dart';

class AlarmScreen extends StatelessWidget {
  const AlarmScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<AlarmController>(
      builder: (controller) {
        return AppScaffold(
          selectedIndex: 2,
          title: 'RackSense: Alarms',
          body: GetBuilder<AppController>(
            builder: (appController) => AlarmStatusGrid(
              alarms: controller.alarms,
              units: appController.units.values.toList(growable: false),
            ),
          ),
        );
      },
    );
  }
}
