import 'package:flutter/material.dart';

class TemperatureControlCardWidget extends StatelessWidget {
  const TemperatureControlCardWidget({
    super.key,
    required this.value,
    required this.actualTemperature,
    required this.onDecrease,
    required this.onIncrease,
  });

  final int value;
  final double? actualTemperature;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;
  // actual temperature

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.max,
          children: [
            Text('Sıcaklık Kontrol'),
            Expanded(
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      actualTemperature?.toStringAsFixed(0) ?? '--',
                      style: const TextStyle(
                        fontSize: 122,
                        fontWeight: FontWeight.w100,
                      ),
                    ),
                    const Text(
                      '°C',
                      style: TextStyle(
                        fontSize: 48,
                        height: 1,
                        fontWeight: FontWeight.w100,
                      ),
                    ),
                  ],
                ),
              ),
            ),
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
                    '$value°C', // this is the target set value
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
