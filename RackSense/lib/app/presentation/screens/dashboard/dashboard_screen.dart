import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rack_sense/app/data/controllers/app_controller.dart';
import 'package:rack_sense/app/presentation/components/app_bar.dart';
import 'package:rack_sense/app/presentation/components/nav_rail.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<AppController>(
      builder: (ac) {
        return Scaffold(
          body: Row(
            children: [
              NavRailWidget(selectedIndex: 0),
              VerticalDivider(),
              Expanded(
                child: Column(
                  children: [
                    AppBarWidget(),
                    Expanded(child: Center(child: Text('hello'))),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
