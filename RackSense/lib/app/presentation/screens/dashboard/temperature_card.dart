import 'package:flutter/material.dart';

class TemperatureControlCardWidget extends StatelessWidget {
  const TemperatureControlCardWidget({
    super.key,
    required this.value,
    required this.unitATemperature,
    required this.unitBTemperature,
    required this.onDecrease,
    required this.onIncrease,
  });

  final int value;
  final double? unitATemperature;
  final double? unitBTemperature;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;
  // actual temperatures per unit

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
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: _UnitTemperature(
                      label: 'Klima #1',
                      temperature: unitATemperature,
                    ),
                  ),
                  const VerticalDivider(width: 1),
                  Expanded(
                    child: _UnitTemperature(
                      label: 'Klima #2',
                      temperature: unitBTemperature,
                    ),
                  ),
                ],
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

/// A single unit's actual temperature reading, scaled down to fit
/// alongside its sibling unit so both are visible at the same time.
class _UnitTemperature extends StatelessWidget {
  const _UnitTemperature({required this.label, required this.temperature});

  final String label;
  final double? temperature;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.max,
      children: [
        Text(label, style: Theme.of(context).textTheme.titleMedium),
        Expanded(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  temperature?.toStringAsFixed(0) ?? '--',
                  style: const TextStyle(
                    fontSize: 72,
                    fontWeight: FontWeight.w100,
                  ),
                ),
                const Text(
                  '°C',
                  style: TextStyle(
                    fontSize: 28,
                    height: 1,
                    fontWeight: FontWeight.w100,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
