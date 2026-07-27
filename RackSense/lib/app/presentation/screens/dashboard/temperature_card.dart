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
            Expanded(
              child: Center(
                child: Text(
                  '$value°C', // TODO: this shall be the actual average environment temperature
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineLarge,
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
