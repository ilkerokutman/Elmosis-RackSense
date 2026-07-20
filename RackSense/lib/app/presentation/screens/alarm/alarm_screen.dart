import 'package:flutter/material.dart';
import 'package:rack_sense/app/presentation/components/app_scaffold.dart';
import 'package:rack_sense/app/presentation/screens/alarm/widgets/alarm_list_card.dart';

class AlarmScreen extends StatelessWidget {
  const AlarmScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      selectedIndex: 2,
      title: 'Alarm Yönetimi',
      body: Row(
        spacing: 12,
        children: [
          Expanded(
            child: AlarmListCardWidget(title: 'AKTİF ALARMLAR', items: []),
          ),
          Expanded(
            child: AlarmListCardWidget(title: 'ALARM GEÇMİŞİ', items: []),
          ),
        ],
      ),
    );
  }
}
