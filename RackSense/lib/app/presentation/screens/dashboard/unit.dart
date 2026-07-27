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
    final isDisconnected = !state.isConnected;
    final isFaulted = state.hasError || isDisconnected;
    final isOff = !state.isRunning;
    final scheme = Theme.of(context).colorScheme;
    final backgroundColor = isFaulted
        ? scheme.errorContainer
        : isOff
        ? scheme.surfaceContainerLow
        : scheme.primaryContainer;
    final borderColor = isFaulted
        ? scheme.error
        : isOff
        ? scheme.outlineVariant
        : scheme.primary;
    final foregroundColor = isFaulted
        ? scheme.onErrorContainer
        : isOff
        ? scheme.onSurfaceVariant
        : scheme.onPrimaryContainer;
    final statusColor = isFaulted
        ? scheme.error
        : isOff
        ? scheme.onSurfaceVariant
        : scheme.primary;
    NtcCardWidget ntc({required String label, String? value}) => NtcCardWidget(
      label: label,
      value: value,
      foregroundColor: foregroundColor,
      backgroundColor: backgroundColor,
      borderColor: borderColor,
    );
    final actionLabel = isDisconnected
        ? 'Bağlı değil'
        : state.communicationFailureStartedAt != null
        ? 'Haberleşme hatası'
        : state.isRunning
        ? 'Çalışıyor'
        : 'Bekliyor';
    final isAllowed =
        !isDisconnected && (state.isRunning ? canTurnOff : canTurnOn);
    final cooldown = controller.cooldownSecondsRemaining(
      state.deviceId,
      turningOn: !state.isRunning,
    );
    return Opacity(
      opacity: isOff && !isFaulted ? 0.72 : 1,
      child: Card(
        color: backgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadiusGeometry.circular(8),
          side: BorderSide(color: borderColor, width: isFaulted ? 2 : 1),
        ),
        margin: EdgeInsets.all(2),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Column(
            children: [
              ListTile(
                dense: true,
                title: Text(
                  'Klima #$unitId',
                  style: TextStyle(color: foregroundColor),
                ),
                subtitle: Text(
                  actionLabel,
                  style: TextStyle(color: foregroundColor),
                ),
                trailing: cooldown > 0
                    ? SizedBox(
                        width: 22,
                        height: 22,
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
                        icon: Icon(
                          Icons.power_settings_new,
                          color: statusColor,
                        ),
                      ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: ntc(
                      label: 'NTC 0',
                      value: state.ntc0 == null ? '-' : '${state.ntc0}°',
                    ),
                  ),
                  Expanded(
                    child: ntc(
                      label: 'NTC 1',
                      value: state.ntc1 == null ? '-' : '${state.ntc1}°',
                    ),
                  ),
                  Expanded(
                    child: ntc(
                      label: 'NTC 2',
                      value: state.ntc2 == null ? '-' : '${state.ntc2}°',
                    ),
                  ),
                  Expanded(
                    child: ntc(
                      label: 'NTC 3',
                      value: state.ntc3 == null ? '-' : '${state.ntc3}°',
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: ntc(
                      label: 'SET',
                      value: state.targetTemperature == null
                          ? '-'
                          : '${state.targetTemperature}°',
                    ),
                  ),
                  Expanded(
                    child: ntc(
                      label: 'FAN',
                      value: state.fanLevel == null ? '-' : '${state.fanLevel}',
                    ),
                  ),
                  Expanded(
                    child: ntc(
                      label: 'DURUM',
                      value: state.isRunning ? 'ON' : 'OFF',
                    ),
                  ),
                  Expanded(
                    child: ntc(
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
      ),
    );
  }
}
