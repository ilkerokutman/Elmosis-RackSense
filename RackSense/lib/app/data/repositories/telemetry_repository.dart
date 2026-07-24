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
}
