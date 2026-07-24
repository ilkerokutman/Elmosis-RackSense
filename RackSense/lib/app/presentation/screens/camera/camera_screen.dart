import 'package:flutter/material.dart';
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
                                    'Kamera bağlantısı algılanamadı',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
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
                      horizontal: 8,
                      vertical: 12,
                    ),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Text('Güvenlik'),
                        ),

                        ListView.builder(
                          itemBuilder: (context, index) => ListTile(
                            title: Text(
                              'NA',
                              // app.securitySwitchList[index].title,
                              style: Theme.of(context).textTheme.labelMedium,
                            ),
                            trailing:
                                // app.securitySwitchList[index].status == true
                                // ? Icon(
                                //     Icons.warning_rounded,
                                //     color: Colors.redAccent,
                                //   )
                                // :
                                Icon(
                                  Icons.check_circle,
                                  color: Colors.lightGreen,
                                ),
                          ),
                          shrinkWrap: true,
                          itemCount: 0, // app.securitySwitchList.length,
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
