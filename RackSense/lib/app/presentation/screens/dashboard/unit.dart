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
                  child: NtcCardWidget(index: 1, value: state.ntc0?.toDouble()),
                ),
                Expanded(
                  child: NtcCardWidget(index: 2, value: state.ntc1?.toDouble()),
                ),
                Expanded(
                  child: NtcCardWidget(index: 2, value: state.ntc2?.toDouble()),
                ),
                Expanded(
                  child: NtcCardWidget(index: 3, value: state.ntc3?.toDouble()),
                ),
              ],
            ),
            Text('other values'),
          ],
        ),
      ),
    );
  }
}
