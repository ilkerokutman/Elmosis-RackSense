import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rack_sense/app/data/controllers/app_controller.dart';

/// Tick stream that fires every second. Used to refresh the auto-switch
/// countdown without calling [AppController.update] every second.
final _oneSecond = Stream.periodic(
  const Duration(seconds: 1),
).asBroadcastStream();

class AppBarWidget extends StatelessWidget {
  const AppBarWidget({super.key, this.title, this.titleWidget, this.actions});
  final String? title;
  final Widget? titleWidget;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    return GetBuilder<AppController>(
      builder: (ac) {
        return AppBar(
          title: titleWidget ?? Text(title ?? 'RackSense'),
          actions: [
            ...?actions,

            if (ac.isAutoMode && ac.nextAutoSwitchAt != null)
              _AutoSwitchCountdown(nextAutoSwitchAt: ac.nextAutoSwitchAt!),

            SizedBox(width: 8),

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

class _AutoSwitchCountdown extends StatelessWidget {
  const _AutoSwitchCountdown({required this.nextAutoSwitchAt});

  final DateTime nextAutoSwitchAt;

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.titleMedium;
    return StreamBuilder(
      stream: _oneSecond,
      builder: (_, _) {
        final remaining = nextAutoSwitchAt.difference(DateTime.now());
        final display = remaining.isNegative ? const Duration() : remaining;
        return SizedBox(
          width: 88,
          child: Center(
            child: Text(
              _format(display),
              style: textStyle,
              textAlign: TextAlign.center,
            ),
          ),
        );
      },
    );
  }

  String _format(Duration duration) {
    final hours = duration.inHours.toString().padLeft(2, '0');
    final minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }
}
