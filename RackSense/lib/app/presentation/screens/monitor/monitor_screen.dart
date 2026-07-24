import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rack_sense/app/data/controllers/app_controller.dart';
import 'package:rack_sense/app/presentation/components/app_scaffold.dart';
import 'package:rack_sense/app/presentation/screens/monitor/widgets/monitor_card_widget.dart';

class MonitorScreen extends StatelessWidget {
  const MonitorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<AppController>(
      builder: (app) {
        return AppScaffold(
          selectedIndex: 1,
          title: 'RackSense: Monitor',
          body: Row(
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
                          title: Text('SICAKLIK GRAFİĞİ'),
                          subtitle: Text('Saat | Gün | Ay'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            spacing: 8,
                            children: [
                              Container(
                                width: 20,
                                height: 4,
                                color: Colors.blue,
                              ),
                              Text('Ortam'),
                              Container(
                                width: 20,
                                height: 4,
                                color: Colors.orange,
                              ),
                              Text('Üfleme '),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              color: Colors.blueGrey.withValues(alpha: 0.3),
                            ),
                            child: Center(child: Text('Veri bekleniyor')),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(
                width: 240,
                child: Card(
                  child: Padding(
                    padding: EdgeInsetsGeometry.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    child: Column(
                      children: [
                        Text(
                          'CANLI ÖZET',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Wrap(
                          children: [
                            MonitorCardWidget(label: 'Ortam', value: '0.0°C'),
                            MonitorCardWidget(label: 'Üfleme', value: '0.0°C'),
                            MonitorCardWidget(label: 'Nem', value: '0%'),
                            MonitorCardWidget(label: 'AQ', value: '0'),
                            MonitorCardWidget(
                              label: 'Günlük Çalışma',
                              value: '00:00:00',
                            ),
                            MonitorCardWidget(
                              label: 'Aktif Klima',
                              value: '0 / 2',
                            ),
                          ],
                        ),
                        ListTile(
                          title: Text(
                            'Son veri',
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                          trailing: Text('08:14:26'),
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
