import 'package:flutter/material.dart';

class TemperatureControlCardWidget extends StatelessWidget {
  const TemperatureControlCardWidget({
    super.key,
    required this.value,
    required this.onDecrease,
    required this.onIncrease,
  });
  final int value;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.max,
          children: [
            Expanded(child: Text('$value°C')),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: onDecrease,
                  icon: const Icon(Icons.remove),
                ),
                SizedBox(
                  width: 96,
                  child: Text(
                    '$value°C',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ),
                IconButton(onPressed: onIncrease, icon: const Icon(Icons.add)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
