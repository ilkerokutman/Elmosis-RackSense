import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:rack_sense/app/core/utils/common_utils.dart';

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
      labelType: NavigationRailLabelType.all,
      leading: CircleAvatar(child: Icon(Icons.ac_unit_outlined)),
      trailing: IconButton(
        onPressed: () async => await CU.exitAppDialog(context),
        icon: Icon(Icons.exit_to_app),
      ),
    );
  }
}
