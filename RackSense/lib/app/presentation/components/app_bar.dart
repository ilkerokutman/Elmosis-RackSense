import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rack_sense/app/data/controllers/app_controller.dart';

class AppBarWidget extends StatelessWidget {
  const AppBarWidget({super.key, this.title});
  final String? title;

  @override
  Widget build(BuildContext context) {
    return GetBuilder<AppController>(
      builder: (ac) {
        return AppBar(
          title: Text(title ?? 'RackSense'),
          actions: [
            ac.isOnline
                ? Icon(Icons.lan_outlined, color: Colors.greenAccent)
                : Icon(Icons.wifi_off, color: Colors.grey),
            SizedBox(width: 12),
          ],
        );
      },
    );
  }
}
