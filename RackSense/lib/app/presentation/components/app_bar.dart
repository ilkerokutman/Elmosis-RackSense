import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rack_sense/app/data/controllers/app_controller.dart';

class AppBarWidget extends StatelessWidget {
  const AppBarWidget({super.key, this.title, this.actions});
  final String? title;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    return GetBuilder<AppController>(
      builder: (ac) {
        return AppBar(
          title: Text(title ?? 'RackSense'),
          actions: [
            ...?actions,

            SizedBox(width: 8),
            Icon(
              Icons.sync_alt,
              color: ac.processingSerialLoop
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.3),
            ),
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
