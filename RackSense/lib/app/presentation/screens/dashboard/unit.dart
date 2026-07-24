import 'package:flutter/material.dart';
import 'package:rack_sense/app/data/models/ac_unit_state.dart';
import 'package:rack_sense/app/presentation/screens/dashboard/ntc_card.dart';

class UnitWidget extends StatelessWidget {
  const UnitWidget({super.key, required this.unitId, required this.state});
  final int unitId;
  final AcUnitState state;

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadiusGeometry.circular(10),
      ),
      margin: EdgeInsets.all(2),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          children: [
            ListTile(
              title: Text('Klima #$unitId'),
              subtitle: Text('status text here'),
              trailing: IconButton(
                onPressed: () {},
                icon: Icon(Icons.power_settings_new),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: NtcCardWidget(label: 'NTC 1', value: '${state.ntc0}°'),
                ),
                Expanded(
                  child: NtcCardWidget(label: 'NTC 2', value: '${state.ntc1}°'),
                ),
                Expanded(
                  child: NtcCardWidget(label: 'NTC 3', value: '${state.ntc2}°'),
                ),
                Expanded(
                  child: NtcCardWidget(label: 'NTC 4', value: '${state.ntc3}°'),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: NtcCardWidget(
                    label: 'SET',
                    value: '${state.targetTemperature}°',
                  ),
                ),
                Expanded(
                  child: NtcCardWidget(
                    label: 'FAN',
                    value: '${state.fanLevel}',
                  ),
                ),
                Expanded(
                  child: NtcCardWidget(
                    label: 'DURUM',
                    value: state.isRunning ? 'OK' : 'ZZ',
                  ),
                ),
                Expanded(
                  child: NtcCardWidget(
                    label: 'HATA',
                    value: state.errorCode == 0x00
                        ? '---'
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
