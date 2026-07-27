import 'package:flutter/material.dart';
import 'package:rack_sense/app/presentation/components/app_scaffold.dart';

class SyncScreen extends StatelessWidget {
  const SyncScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      selectedIndex: 4,
      title: 'Senkronizasyon',
      body: Center(child: Text('Yakında: Azure eşitleme ve geçmiş')),
    );
  }
}
