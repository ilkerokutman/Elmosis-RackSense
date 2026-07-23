import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

class CU {
  static Future<void> wait(int milliseconds) async {
    return await Future.delayed(Duration(milliseconds: milliseconds));
  }

  /// Precise synchronous busy wait.
  ///
  /// Use this only for very short, timing-critical pauses. Unlike [wait], it
  /// does not yield to the event loop, so it is not affected by timer
  /// granularity on the Raspberry Pi (~10 ms ticks) that was causing the
  /// RS-485 TX enable to stay high too long.
  static void busyWait(int milliseconds) =>
      busyWaitMicroseconds(milliseconds * 1000);

  /// Microsecond-precision synchronous busy wait.
  static void busyWaitMicroseconds(int microseconds) {
    final sw = Stopwatch()..start();
    while (sw.elapsedMicroseconds < microseconds) {}
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
