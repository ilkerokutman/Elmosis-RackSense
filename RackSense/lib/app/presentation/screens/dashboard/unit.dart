import 'package:flutter/material.dart';
import 'package:rack_sense/app/data/controllers/app_controller.dart';
import 'package:rack_sense/app/data/models/ac_unit_state.dart';
import 'package:rack_sense/app/presentation/screens/dashboard/ntc_card.dart';

class UnitWidget extends StatelessWidget {
  const UnitWidget({
    super.key,
    required this.unitId,
    required this.state,
    required this.controller,
  });
  final int unitId;
  final AcUnitState state;
  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final canTurnOn = controller.canTurnOn(state.deviceId);
    final canTurnOff = controller.canTurnOff(state.deviceId);
    final isFaulted = state.hasError;
    final statusBgColor = isFaulted
        ? Theme.of(context).colorScheme.errorContainer
        : state.isRunning
        ? Theme.of(context).colorScheme.primaryContainer
        : Theme.of(context).colorScheme.outline;
    final statusColor = isFaulted
        ? Theme.of(context).colorScheme.onErrorContainer
        : state.isRunning
        ? Theme.of(context).colorScheme.onPrimary
        : Theme.of(context).colorScheme.primary;
    final actionLabel = state.communicationFailureStartedAt != null
        ? 'Haberleşme hatası'
        : state.isRunning
        ? 'Çalışıyor'
        : 'Bekliyor';
    final isAllowed = state.isRunning ? canTurnOff : canTurnOn;
    final cooldown = controller.cooldownSecondsRemaining(
      state.deviceId,
      turningOn: !state.isRunning,
    );
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadiusGeometry.circular(8),
      ),
      margin: EdgeInsets.all(2),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          children: [
            ListTile(
              dense: true,
              title: Text('Klima #$unitId'),
              subtitle: Text(actionLabel),
              trailing: cooldown > 0
                  ? SizedBox(
                      width: 32,
                      height: 32,
                      child: CircularProgressIndicator(
                        value: 1 - (cooldown / 15),
                      ),
                    )
                  : IconButton(
                      onPressed: isAllowed
                          ? () {
                              if (state.isRunning) {
                                controller.requestTurnOff(state.deviceId);
                              } else {
                                controller.requestTurnOn(state.deviceId);
                              }
                            }
                          : null,
                      icon: Icon(Icons.power_settings_new, color: statusColor),
                      color: statusBgColor,
                    ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: NtcCardWidget(
                    label: 'NTC 1',
                    value: state.ntc0 == null ? '-' : '${state.ntc0}°',
                  ),
                ),
                Expanded(
                  child: NtcCardWidget(
                    label: 'NTC 2',
                    value: state.ntc1 == null ? '-' : '${state.ntc1}°',
                  ),
                ),
                Expanded(
                  child: NtcCardWidget(
                    label: 'NTC 3',
                    value: state.ntc2 == null ? '-' : '${state.ntc2}°',
                  ),
                ),
                Expanded(
                  child: NtcCardWidget(
                    label: 'NTC 4',
                    value: state.ntc3 == null ? '-' : '${state.ntc3}°',
                  ),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: NtcCardWidget(
                    label: 'SET',
                    value: state.targetTemperature == null
                        ? '-'
                        : '${state.targetTemperature}°',
                  ),
                ),
                Expanded(
                  child: NtcCardWidget(
                    label: 'FAN',
                    value: state.fanLevel == null ? '-' : '${state.fanLevel}',
                  ),
                ),
                Expanded(
                  child: NtcCardWidget(
                    label: 'DURUM',
                    value: state.isRunning ? 'ON' : 'OFF',
                  ),
                ),
                Expanded(
                  child: NtcCardWidget(
                    label: 'HATA',
                    value: state.errorCode == 0x00
                        ? '-'
                        : state.errorCode.toString(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
