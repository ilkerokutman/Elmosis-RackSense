import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rack_sense/app/data/controllers/app_controller.dart';
import 'package:rack_sense/app/data/services/serial_service.dart';
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
                Text('GPIO'),
                Divider(),
                Text('Serial (Loop: ${ac.allowSerialLoop})'),

                Row(
                  children: [
                    TextButton(
                      onPressed: () {
                        ac.addToSerialMessageStack(
                          SerialMessage(device: 0x01, command: 0x65),
                        );
                      },
                      child: Text('Reset'),
                    ),
                    TextButton(
                      onPressed: () {
                        ac.addToSerialMessageStack(
                          SerialMessage(device: 0x01, command: 0x67),
                        );
                      },
                      child: Text('Ac'),
                    ),
                    TextButton(
                      onPressed: () {
                        ac.addToSerialMessageStack(
                          SerialMessage(device: 0x01, command: 0x68),
                        );
                      },
                      child: Text('Kapa'),
                    ),
                  ],
                ),
                Divider(),
              ],
            ),
          ),
        );
      },
    );
  }
}
