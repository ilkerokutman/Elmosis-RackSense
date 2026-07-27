import 'package:flutter/material.dart';

class NtcCardWidget extends StatelessWidget {
  const NtcCardWidget({
    super.key,
    required this.label,
    this.value,
    this.foregroundColor,
    this.backgroundColor,
    this.borderColor,
  });

  final String label;
  final String? value;
  final Color? foregroundColor;
  final Color? backgroundColor;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Card(
      margin: EdgeInsets.all(2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadiusGeometry.circular(8),
        side: BorderSide(color: borderColor ?? scheme.secondaryContainer),
      ),
      color: backgroundColor,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Opacity(
              opacity: 0.7,
              child: Text(
                label,
                textAlign: TextAlign.start,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: foregroundColor,
                ),
              ),
            ),
            Text(
              value == null ? '---' : '$value',
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: foregroundColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
