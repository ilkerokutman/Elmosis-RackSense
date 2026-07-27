// ignore_for_file: dead_code

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rack_sense/app/core/constants/serial.dart';
import 'package:rack_sense/app/data/controllers/alarm_controller.dart';
import 'package:rack_sense/app/data/controllers/app_controller.dart';
import 'package:rack_sense/app/presentation/components/app_scaffold.dart';
import 'package:rack_sense/app/presentation/screens/dashboard/alarm_card.dart';
import 'package:rack_sense/app/presentation/screens/dashboard/temperature_card.dart';
import 'package:rack_sense/app/presentation/screens/dashboard/unit.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Timer? _temperatureDebounce;
  int? _pendingTemperature;

  @override
  void dispose() {
    _temperatureDebounce?.cancel();
    super.dispose();
  }

  void _changeTemperature(AppController controller, int delta) {
    final value =
        (_pendingTemperature ?? controller.desiredTemperature) + delta;
    if (value < 16 || value > 30) return;
    setState(() => _pendingTemperature = value);
    _temperatureDebounce?.cancel();
    _temperatureDebounce = Timer(const Duration(milliseconds: 500), () {
      controller.setDesiredTemperature(value);
      if (mounted) setState(() => _pendingTemperature = null);
    });
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<AppController>(
      builder: (controller) {
        final targetTemperature =
            _pendingTemperature ?? controller.desiredTemperature;

        final alarmController = Get.find<AlarmController>();

        return AppScaffold(
          selectedIndex: 0,
          title: 'RackSense: Control',

          body: Column(
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Row(
                  mainAxisSize: MainAxisSize.max,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      flex: 6,
                      child: TemperatureControlCardWidget(
                        //actualTemperature
                        value: targetTemperature,
                        onDecrease: () => _changeTemperature(controller, -1),
                        onIncrease: () => _changeTemperature(controller, 1),
                      ),
                    ),
                    Expanded(
                      flex: 4,
                      child: Column(
                        mainAxisSize: MainAxisSize.max,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            flex: 1,
                            child: UnitWidget(
                              unitId: SerialKeys.device1,
                              state: controller.unitFor(SerialKeys.device1),
                              controller: controller,
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: UnitWidget(
                              unitId: SerialKeys.device2,
                              state: controller.unitFor(SerialKeys.device2),
                              controller: controller,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: alarmController.alarms
                      .map(
                        (e) => Expanded(
                          child: AlarmCardWidget(
                            label: e.config.label,
                            value: e.isActive,
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
