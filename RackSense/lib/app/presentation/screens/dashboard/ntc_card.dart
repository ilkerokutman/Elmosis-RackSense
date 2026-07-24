import 'package:flutter/material.dart';

class NtcCardWidget extends StatelessWidget {
  const NtcCardWidget({super.key, required this.index, this.value});
  final int index;
  final double? value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('NTC $index'),
          Text(value == null ? '---' : '${value?.toStringAsFixed(0)}'),
        ],
      ),
    );
  }
}
