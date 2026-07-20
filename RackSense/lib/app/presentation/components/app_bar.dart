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
            // IconButton(
            //   onPressed: () {
            //     Get.toNamed(Routes.sync);
            //   },
            //   icon: Icon(Icons.sync),
            // ),
            // IconButton(
            //   onPressed: () {
            //     Get.toNamed(Routes.settings);
            //   },
            //   icon: Icon(Icons.settings),
            // ),
            // IconButton(
            //   onPressed: () async => await CU.exitAppDialog(context),
            //   icon: Icon(Icons.close),
            // ),
            ac.isOnline
                ? Icon(Icons.lan_outlined, color: Colors.greenAccent)
                : Icon(Icons.wifi_off, color: Colors.grey),
          ],
        );
      },
    );
  }
}
