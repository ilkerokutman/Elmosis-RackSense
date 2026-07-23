import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rack_sense/app/core/constants/serial.dart';
import 'package:rack_sense/app/data/controllers/app_controller.dart';
import 'package:rack_sense/app/data/services/serial_service.dart';
import 'package:rack_sense/app/presentation/components/app_scaffold.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<AppController>(
      builder: (app) {
        return AppScaffold(
          selectedIndex: 5,
          title: 'Ayarlar',
          body: Row(
            children: [
              Expanded(flex: 3, child: Container()),
              Expanded(
                flex: 1,
                child: Column(
                  spacing: 8,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Loop: ${app.allowSerialLoop ? 'ON' : 'OFF'}'),
                        IconButton(
                          onPressed: () {
                            app.turnOnSerialLoop();
                          },
                          icon: Icon(Icons.play_arrow),
                        ),
                        IconButton(
                          onPressed: () {
                            app.turnOffSerialLoop();
                          },
                          icon: Icon(Icons.stop),
                        ),
                        Spacer(),
                        Text('Stack: ${app.messageStack.length}'),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          onPressed: () {
                            app.addToSerialMessageStack(
                              SerialMessage(
                                device: SerialKeys.device1,
                                command: SerialKeys.cmdReset,
                              ),
                            );
                          },
                          icon: Icon(Icons.restart_alt_outlined),
                        ),
                        IconButton(
                          onPressed: () {
                            app.addToSerialMessageStack(
                              SerialMessage(
                                device: SerialKeys.device1,
                                command: SerialKeys.cmdCommTest,
                              ),
                            );
                          },
                          icon: Icon(Icons.text_snippet),
                        ),
                        IconButton(
                          onPressed: () {
                            app.addToSerialMessageStack(
                              SerialMessage(
                                device: SerialKeys.device1,
                                command: SerialKeys.cmdTurnOn,
                              ),
                            );
                          },
                          icon: Icon(Icons.power),
                        ),
                        IconButton(
                          onPressed: () {
                            app.addToSerialMessageStack(
                              SerialMessage(
                                device: SerialKeys.device1,
                                command: SerialKeys.cmdTurnOff,
                              ),
                            );
                          },
                          icon: Icon(Icons.power_off),
                        ),
                      ],
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemBuilder: (context, index) =>
                            Text('${app.messageStack[index]}'),
                        itemCount: app.messageStack.length,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
