import 'package:flutter/widgets.dart';
import 'package:rack_sense/app/presentation/components/app_scaffold.dart';

class CameraScreen extends StatelessWidget {
  const CameraScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      selectedIndex: 3,
      title: 'Kamera',
      body: Center(child: Text('TODO: Ayarlar sayfasi')),
    );
  }
}
