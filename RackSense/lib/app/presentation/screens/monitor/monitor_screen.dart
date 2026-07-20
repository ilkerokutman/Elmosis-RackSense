import 'package:flutter/widgets.dart';
import 'package:rack_sense/app/presentation/components/app_scaffold.dart';

class MonitorScreen extends StatelessWidget {
  const MonitorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      selectedIndex: 1,
      title: 'RackSense: Monitor',
      body: Center(child: Text('TODO: Monitor sayfasi')),
    );
  }
}
