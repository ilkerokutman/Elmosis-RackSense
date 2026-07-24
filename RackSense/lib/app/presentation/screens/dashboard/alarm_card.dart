import 'package:flutter/material.dart';

class AlarmCardWidget extends StatelessWidget {
  const AlarmCardWidget({super.key, required this.label, required this.value});
  final String label;
  final bool value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Card(
      shape: RoundedRectangleBorder(
        side: BorderSide(
          color: value ? scheme.error : scheme.primary,
          width: 2,
        ),
        borderRadius: BorderRadiusGeometry.circular(10),
      ),
      color: value ? scheme.errorContainer : scheme.primaryContainer,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelLarge?.copyWith(
                color: value
                    ? scheme.onErrorContainer
                    : scheme.onPrimaryContainer,
              ),
            ),
            Text(
              value ? 'ALARM' : 'YOK/KAPALI',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: value
                    ? scheme.onErrorContainer
                    : scheme.onPrimaryContainer,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
