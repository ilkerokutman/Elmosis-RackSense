import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class NavRailWidget extends StatelessWidget {
  const NavRailWidget({super.key, required this.selectedIndex});
  final int selectedIndex;

  @override
  Widget build(BuildContext context) {
    return NavigationRail(
      destinations: [
        NavigationRailDestination(
          icon: Icon(Icons.dashboard),
          label: Text('Kontrol'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.area_chart_sharp),
          label: Text('İzleme'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.warning_rounded),
          label: Text('Alarm'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.videocam_off_outlined),
          label: Text('Kamera'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.sync_alt),
          label: Text('Senkron'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.settings),
          label: Text('Ayarlar'),
        ),
      ],
      selectedIndex: selectedIndex,
    );
  }
}
