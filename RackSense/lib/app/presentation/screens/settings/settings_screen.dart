import 'package:flutter/material.dart';
import 'package:rack_sense/app/presentation/components/app_scaffold.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      selectedIndex: 5,
      title: 'Ayarlar',
      body: Center(child: Text('TODO: Ayarlar sayfasi')),
    );
  }
}
