import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:rack_sense/app/presentation/components/app_scaffold.dart';

class CameraScreen extends StatelessWidget {
  const CameraScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      selectedIndex: 3,
      title: 'Kamera ve Güvenlik',
      body: Row(
        spacing: 12,
        children: [
          Expanded(
            child: Card(
              child: Padding(
                padding: EdgeInsetsGeometry.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                child: Column(
                  children: [
                    ListTile(
                      title: Text('CANLI KAMERA'),
                      trailing: Text(
                        'YAPILANDIRILMADI',
                        style: Theme.of(
                          context,
                        ).textTheme.labelSmall?.copyWith(color: Colors.orange),
                      ),
                    ),
                    Expanded(child: Container(color: Colors.deepPurpleAccent)),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(
            width: 180,
            child: Card(
              child: Padding(
                padding: EdgeInsetsGeometry.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                child: Column(children: [Text('Güvenlik')]),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
