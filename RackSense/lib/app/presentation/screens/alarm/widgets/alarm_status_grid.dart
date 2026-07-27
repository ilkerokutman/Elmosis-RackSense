import 'package:flutter/material.dart';
import 'package:rack_sense/app/data/models/ac_unit_state.dart';
import 'package:rack_sense/app/data/models/alarm_state.dart';

class AlarmStatusGrid extends StatelessWidget {
  const AlarmStatusGrid({super.key, required this.alarms, required this.units});

  final List<AlarmState> alarms;
  final List<AcUnitState> units;

  @override
  Widget build(BuildContext context) {
    final items = [
      ...alarms.map(
        (alarm) => _AlarmGridItem(
          label: alarm.config.label,
          detail: alarm.isActive ? 'ALARM' : 'Normal',
          isActive: alarm.isActive,
          icon: _iconFor(alarm.config.key),
        ),
      ),
      ...units.map(
        (unit) => _AlarmGridItem(
          label: 'Klima #${unit.deviceId}',
          detail: !unit.isConnected
              ? 'Bağlı değil'
              : unit.hasError
              ? 'Hata ${unit.errorCode}'
              : 'Normal',
          isActive: unit.hasError,
          isUnavailable: !unit.isConnected,
          icon: Icons.ac_unit,
        ),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = (constraints.maxWidth ~/ 220).clamp(2, 4);
        return GridView.builder(
          padding: const EdgeInsets.all(12),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 1.45,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) => _AlarmGridCard(item: items[index]),
        );
      },
    );
  }

  IconData _iconFor(String key) => switch (key) {
    'smoke' => Icons.smoking_rooms_outlined,
    'water_leak' => Icons.water_drop_outlined,
    'front_door' ||
    'rear_door' ||
    'service_door' => Icons.door_front_door_outlined,
    _ => Icons.warning_amber_rounded,
  };
}

class _AlarmGridCard extends StatelessWidget {
  const _AlarmGridCard({required this.item});

  final _AlarmGridItem item;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final backgroundColor = item.isActive
        ? scheme.errorContainer
        : scheme.surfaceContainerLow;
    final foregroundColor = item.isActive
        ? scheme.onErrorContainer
        : scheme.onSurfaceVariant;
    final accentColor = item.isActive
        ? scheme.error
        : item.isUnavailable
        ? scheme.outline
        : scheme.primary;

    return Opacity(
      opacity: item.isUnavailable ? 0.55 : 1,
      child: Card(
        color: backgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: accentColor, width: item.isActive ? 2 : 1),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(item.icon, color: accentColor, size: 30),
              const Spacer(),
              Text(
                item.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(color: foregroundColor),
              ),
              const SizedBox(height: 4),
              Text(
                item.detail,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: accentColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AlarmGridItem {
  const _AlarmGridItem({
    required this.label,
    required this.detail,
    required this.isActive,
    this.isUnavailable = false,
    required this.icon,
  });

  final String label;
  final String detail;
  final bool isActive;
  final bool isUnavailable;
  final IconData icon;
}
