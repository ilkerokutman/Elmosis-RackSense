import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rack_sense/app/core/routes/routes.dart';
import 'package:window_manager/window_manager.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            onPressed: () {
              Get.toNamed(Routes.sync);
            },
            icon: Icon(Icons.sync),
          ),
          IconButton(
            onPressed: () {
              Get.toNamed(Routes.settings);
            },
            icon: Icon(Icons.settings),
          ),
          IconButton(
            onPressed: () async {
              await windowManager.close();
            },
            icon: Icon(Icons.close),
          ),
        ],
      ),
      body: Center(child: Text('Hello World!')),
    );
  }
}
