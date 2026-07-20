import 'package:flutter/widgets.dart';
import 'package:rack_sense/app/presentation/components/app_scaffold.dart';

class AlarmScreen extends StatelessWidget {
  const AlarmScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      selectedIndex: 2,
      title: 'Alarm',
      body: Center(child: Text('TODO:  Alarm sayfasi')),
    );
  }
}
