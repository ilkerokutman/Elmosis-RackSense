// ignore_for_file: dead_code

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rack_sense/app/core/constants/serial.dart';
import 'package:rack_sense/app/data/controllers/alarm_controller.dart';
import 'package:rack_sense/app/data/controllers/app_controller.dart';
import 'package:rack_sense/app/data/models/ac_unit_state.dart';
import 'package:rack_sense/app/presentation/components/app_scaffold.dart';
import 'package:rack_sense/app/presentation/screens/dashboard/alarm_card.dart';

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
                      child: Container(
                        color: Colors.orange,
                        // temperature control
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
                            child: Container(
                              color: Colors.purple,
                              //unit A
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: Container(
                              color: Colors.green,
                              //unit B
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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

        return AppScaffold(
          selectedIndex: 0,
          title: 'RackSense: Control',
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _TemperatureControl(
                        value: targetTemperature,
                        onDecrease: () => _changeTemperature(controller, -1),
                        onIncrease: () => _changeTemperature(controller, 1),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'Operating Mode',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              SwitchListTile(
                                contentPadding: EdgeInsets.zero,
                                title: Text(
                                  controller.isAutoMode
                                      ? 'Automatic'
                                      : 'Manual',
                                ),
                                subtitle: Text(
                                  controller.isAutoMode
                                      ? 'Switches units every 4 hours'
                                      : 'User controls the active unit',
                                ),
                                value: controller.isAutoMode,
                                onChanged: controller.setAutoMode,
                              ),
                              Text(
                                'Serial: ${controller.allowSerialLoop ? 'Online' : 'Starting'}',
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: _UnitCard(
                          title: 'Unit A',
                          state: controller.unitFor(SerialKeys.device1),
                          controller: controller,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _UnitCard(
                          title: 'Unit B',
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
        );
      },
    );
  }
}

class _TemperatureControl extends StatelessWidget {
  const _TemperatureControl({
    required this.value,
    required this.onDecrease,
    required this.onIncrease,
  });

  final int value;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              'Target Temperature',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: onDecrease,
                  icon: const Icon(Icons.remove),
                ),
                SizedBox(
                  width: 96,
                  child: Text(
                    '$value°C',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ),
                IconButton(onPressed: onIncrease, icon: const Icon(Icons.add)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _UnitCard extends StatelessWidget {
  const _UnitCard({
    required this.title,
    required this.state,
    required this.controller,
  });

  final String title;
  final AcUnitState state;
  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final canTurnOn = controller.canTurnOn(state.deviceId);
    final canTurnOff = controller.canTurnOff(state.deviceId);
    final isFaulted = state.hasError;
    final statusColor = isFaulted
        ? Theme.of(context).colorScheme.error
        : state.isRunning
        ? Colors.green
        : Theme.of(context).colorScheme.outline;
    final actionLabel = state.isRunning ? 'Turn Off' : 'Turn On';
    final isAllowed = state.isRunning ? canTurnOff : canTurnOn;
    final cooldown = controller.cooldownSecondsRemaining(
      state.deviceId,
      turningOn: !state.isRunning,
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.circle, size: 14, color: statusColor),
                const SizedBox(width: 8),
                Text(title, style: Theme.of(context).textTheme.titleLarge),
                const Spacer(),
                Text(state.isRunning ? 'RUNNING' : 'OFF'),
              ],
            ),
            const Divider(),
            _MetricRow('Set', _temperature(state.targetTemperature)),
            _MetricRow('NTC0', _temperature(state.ntc0)),
            _MetricRow('NTC1', _temperature(state.ntc1)),
            _MetricRow('NTC2', _temperature(state.ntc2)),
            _MetricRow('NTC3', _temperature(state.ntc3)),
            _MetricRow('Fan', state.fanLevel?.toString() ?? '--'),
            _MetricRow(
              'Error',
              '0x${state.errorCode.toRadixString(16).padLeft(2, '0')}',
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: isAllowed
                  ? () {
                      if (state.isRunning) {
                        controller.requestTurnOff(state.deviceId);
                      } else {
                        controller.requestTurnOn(state.deviceId);
                      }
                    }
                  : null,
              child: Text(actionLabel),
            ),
            if (cooldown > 0)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Available in ${cooldown}s',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelMedium,
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _temperature(int? value) => value == null ? '--' : '$value°C';
}

class _MetricRow extends StatelessWidget {
  const _MetricRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [Text(label), Text(value)],
      ),
    );
  }
}
