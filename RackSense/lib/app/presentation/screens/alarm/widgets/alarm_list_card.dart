import 'package:flutter/material.dart';

class AlarmListCardWidget extends StatelessWidget {
  const AlarmListCardWidget({
    super.key,
    required this.title,
    required this.items,
    this.icon,
  });
  final String title;
  final List<String> items;
  final Widget? icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsetsGeometry.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          children: [
            ListTile(
              title: Text(title),
              subtitle: Text('${items.length} kayıt'),
              trailing: icon,
            ),
            Expanded(
              child: items.isNotEmpty
                  ? ListView.builder(
                      itemBuilder: (context, index) => Text(items[index]),
                      itemCount: items.length,
                    )
                  : Center(child: Text('Kayıt bulunmuyor')),
            ),
          ],
        ),
      ),
    );
  }
}
