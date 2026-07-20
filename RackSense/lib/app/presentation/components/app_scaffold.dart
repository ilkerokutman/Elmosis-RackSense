import 'package:flutter/material.dart';
import 'package:rack_sense/app/presentation/components/app_bar.dart';
import 'package:rack_sense/app/presentation/components/nav_rail.dart';

class AppScaffold extends StatelessWidget {
  const AppScaffold({
    super.key,
    required this.selectedIndex,
    required this.body,
  });
  final int selectedIndex;
  final Widget body;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          NavRailWidget(selectedIndex: selectedIndex),
          VerticalDivider(),
          Expanded(
            child: Column(
              children: [
                AppBarWidget(),
                Divider(),
                Expanded(child: body),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
