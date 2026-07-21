import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rack_sense/app/data/controllers/app_controller.dart';
import 'package:rack_sense/app/presentation/components/app_scaffold.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<AppController>(
      builder: (ac) {
        return AppScaffold(
          selectedIndex: 0,
          title: 'RackSense: Kontrol',
          body: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              spacing: 8,
              children: [
                Text('Dashboard'),
                Text('gpio: ${ac.isGpioReady}'),
                Text('acunit: ${ac.acUnitList.length}'),
                SwitchListTile(
                  title: Text('Allow serial loop'),
                  value: ac.allowSerialLoop,
                  onChanged: (val) {
                    ac.toggleSerialLoop();
                  },
                ),
                Row(
                  children: [
                    ElevatedButton(
                      onPressed: ac.sendSerialTestSignal,
                      child: Text('serial test'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        ac.serialCommand(command: 0x65);
                      },
                      child: Text('reboot d'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        ac.serialCommand(command: 0x67);
                      },
                      child: Text('on d'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        ac.serialCommand(command: 0x68);
                      },
                      child: Text('off d'),
                    ),
                    ElevatedButton(onPressed: ac.buzzBeep, child: Text('beep')),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
