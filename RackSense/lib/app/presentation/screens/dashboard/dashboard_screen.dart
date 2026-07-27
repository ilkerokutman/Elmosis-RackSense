// ignore_for_file: dead_code

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rack_sense/app/core/constants/serial.dart';
import 'package:rack_sense/app/data/controllers/alarm_controller.dart';
import 'package:rack_sense/app/data/controllers/app_controller.dart';
import 'package:rack_sense/app/presentation/components/app_scaffold.dart';
import 'package:rack_sense/app/presentation/screens/dashboard/alarm_card.dart';
import 'package:rack_sense/app/presentation/screens/dashboard/serial_queue_status.dart';
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
          title: 'RackSense: Kontrol',
          actions: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Manuel',
                  style: TextStyle(
                    color: controller.isAutoMode
                        ? Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.3)
                        : Theme.of(context).colorScheme.primary,
                  ),
                ),
                Switch(
                  value: controller.isAutoMode,
                  onChanged: (v) =>
                      controller.setAutoMode(!controller.isAutoMode),
                ),
                Text(
                  'Otomatik',
                  style: TextStyle(
                    color: !controller.isAutoMode
                        ? Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.3)
                        : Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
          ],
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
                      child: Column(
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          SerialQueueStatusWidget(
                            controller: controller,
                            pendingTemperature: _pendingTemperature,
                          ),
                          Expanded(
                            child: TemperatureControlCardWidget(
                              value: targetTemperature,
                              actualTemperature: controller.rackTemperature,
                              onDecrease: () =>
                                  _changeTemperature(controller, -1),
                              onIncrease: () =>
                                  _changeTemperature(controller, 1),
                            ),
                          ),
                        ],
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
