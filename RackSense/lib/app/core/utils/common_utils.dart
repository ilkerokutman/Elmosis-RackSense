import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:window_manager/window_manager.dart';

class CU {
  static Future<void> wait(int milliseconds) async {
    return await Future.delayed(Duration(milliseconds: milliseconds));
  }

  static Future<void> microWait() async {
    return await Future.delayed(Duration(microseconds: 100));
  }

  static Future<void> exitAppDialog(BuildContext context) async {
    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Çıkış'),
        content: const Text(
          'RackSense uygulamasını sonlandırmak istediğinizden emin misiniz?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Sonlandır'),
          ),
        ],
      ),
    );
    if (shouldExit == true) {
      await windowManager.close();
    }
  }
}
