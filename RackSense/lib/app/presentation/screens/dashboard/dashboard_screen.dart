import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rack_sense/app/core/routes/routes.dart';
import 'package:rack_sense/app/data/controllers/app_controller.dart';
import 'package:rack_sense/app/presentation/components/nav_rail.dart';
import 'package:window_manager/window_manager.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<AppController>(
      builder: (ac) {
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
                  final shouldExit = await showDialog<bool>(
                    context: context,
                    builder: (dialogContext) => AlertDialog(
                      title: const Text('Çıkış'),
                      content: const Text(
                        'RackSense uygulamasını sonlandırmak istediğinizden emin misiniz?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () =>
                              Navigator.of(dialogContext).pop(false),
                          child: const Text('İptal'),
                        ),
                        TextButton(
                          onPressed: () =>
                              Navigator.of(dialogContext).pop(true),
                          child: const Text('Sonlandır'),
                        ),
                      ],
                    ),
                  );
                  if (shouldExit == true) {
                    await windowManager.close();
                  }
                },
                icon: Icon(Icons.close),
              ),
            ],
          ),
          body: Row(
            children: [
              NavRailWidget(selectedIndex: 0),
              VerticalDivider(),
              Expanded(child: Center(child: Text('hello'))),
            ],
          ),
        );
      },
    );
  }
}
