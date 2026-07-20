import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:rack_sense/app/data/controllers/app_controller.dart';
import 'package:rack_sense/app/presentation/components/app_scaffold.dart';

class CameraScreen extends StatelessWidget {
  const CameraScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<AppController>(
      builder: (app) {
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
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(color: Colors.orange),
                          ),
                        ),
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.deepPurpleAccent.withValues(
                                alpha: 0.3,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                spacing: 12,
                                children: [
                                  Icon(Icons.emergency_recording_outlined),
                                  Text(
                                    'Kamera bağlantısı yok',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    'Veri adaptöründen kamera adresi verilebilir.',
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
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
                    child: Column(
                      children: [
                        Text('Güvenlik'),

                        ListView.builder(
                          itemBuilder: (context, index) => ListTile(
                            title: Text(app.securitySwitchList[index].title),
                            trailing: Text(
                              app.securitySwitchList[index].status == true
                                  ? 'AÇIK'
                                  : 'KAPALI',
                            ),
                          ),
                          shrinkWrap: true,
                          itemCount: app.securitySwitchList.length,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
