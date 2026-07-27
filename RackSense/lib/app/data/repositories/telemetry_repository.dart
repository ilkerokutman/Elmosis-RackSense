import 'package:rack_sense/app/data/models/temperature_sample.dart';
import 'package:rack_sense/app/data/services/database_service.dart';

class TelemetryRepository {
  TelemetryRepository(this._databaseService);

  final DatabaseService _databaseService;

  Future<void> recordChange({
    required String sourceType,
    required String sourceId,
    required String metric,
    required String newValue,
    String? previousValue,
    DateTime? occurredAt,
  }) async {
    final database = await _databaseService.database;
    await database.insert('telemetry_records', {
      'source_type': sourceType,
      'source_id': sourceId,
      'metric': metric,
      'previous_value': previousValue,
      'new_value': newValue,
      'occurred_at': (occurredAt ?? DateTime.now()).toIso8601String(),
      'sync_status': 'pending',
      'retry_count': 0,
    });
  }

  Future<void> recordTemperatureSample({
    required int deviceId,
    required int temperature,
    required int targetTemperature,
    DateTime? occurredAt,
  }) async {
    await recordChange(
      sourceType: 'unit',
      sourceId: deviceId.toString(),
      metric: 'temperature_sample',
      newValue: '$temperature,$targetTemperature',
      occurredAt: occurredAt,
    );
  }

  Future<List<TemperatureSample>> temperatureHistory({
    required DateTime from,
  }) async {
    final database = await _databaseService.database;
    final records = await database.query(
      'telemetry_records',
      where: 'source_type = ? AND metric = ? AND occurred_at >= ?',
      whereArgs: ['unit', 'temperature_sample', from.toIso8601String()],
      orderBy: 'occurred_at ASC',
    );
    return records
        .map((record) {
          final values = (record['new_value']! as String).split(',');
          if (values.length != 2) return null;
          final temperature = int.tryParse(values[0]);
          final targetTemperature = int.tryParse(values[1]);
          if (temperature == null || targetTemperature == null) return null;
          return TemperatureSample(
            recordedAt: DateTime.parse(record['occurred_at']! as String),
            temperature: temperature,
            targetTemperature: targetTemperature,
          );
        })
        .whereType<TemperatureSample>()
        .toList(growable: false);
  }

  Future<void> recordRuntimeEvent({
    required int deviceId,
    required String eventType,
    required String reason,
    DateTime? occurredAt,
  }) async {
    final database = await _databaseService.database;
    await database.insert('runtime_events', {
      'device_id': deviceId,
      'event_type': eventType,
      'reason': reason,
      'occurred_at': (occurredAt ?? DateTime.now()).toIso8601String(),
      'sync_status': 'pending',
    });
  }

  Future<Duration> runtimeForToday() {
    final now = DateTime.now();
    return _runtimeSince(DateTime(now.year, now.month, now.day), now);
  }

  Future<Duration> runtimeForDevice(int deviceId) async {
    final database = await _databaseService.database;
    final events = await database.query(
      'runtime_events',
      where: 'device_id = ?',
      whereArgs: [deviceId],
      orderBy: 'occurred_at ASC',
    );
    DateTime? startedAt;
    var total = Duration.zero;
    for (final event in events) {
      final occurredAt = DateTime.parse(event['occurred_at']! as String);
      if (event['event_type'] == 'turned_on') {
        startedAt ??= occurredAt;
      } else if (event['event_type'] == 'turned_off' && startedAt != null) {
        total += occurredAt.difference(startedAt);
        startedAt = null;
      }
    }
    if (startedAt != null) {
      total += DateTime.now().difference(startedAt);
    }
    return total;
  }

  Future<Duration> _runtimeSince(DateTime from, DateTime until) async {
    final database = await _databaseService.database;
    final events = await database.query(
      'runtime_events',
      orderBy: 'occurred_at ASC',
    );
    final startedAtByDevice = <int, DateTime>{};
    var total = Duration.zero;

    for (final event in events) {
      final deviceId = event['device_id']! as int;
      final occurredAt = DateTime.parse(event['occurred_at']! as String);
      if (event['event_type'] == 'turned_on') {
        startedAtByDevice[deviceId] ??= occurredAt;
        continue;
      }
      final startedAt = startedAtByDevice.remove(deviceId);
      if (event['event_type'] == 'turned_off' && startedAt != null) {
        total += _overlap(startedAt, occurredAt, from, until);
      }
    }

    for (final startedAt in startedAtByDevice.values) {
      total += _overlap(startedAt, until, from, until);
    }
    return total;
  }

  Duration _overlap(
    DateTime startedAt,
    DateTime endedAt,
    DateTime from,
    DateTime until,
  ) {
    final start = startedAt.isBefore(from) ? from : startedAt;
    final end = endedAt.isAfter(until) ? until : endedAt;
    return end.isAfter(start) ? end.difference(start) : Duration.zero;
  }
}
