import 'dart:io';

import 'package:flutter/services.dart';
import 'package:rack_sense/app/core/constants/db.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class DatabaseService {
  static Database? _database;
  static bool _initialized = false;

  static void initializeFfi() {
    if (_initialized) return;
    if (Platform.isLinux) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
    _initialized = true;
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    initializeFfi();

    String path;
    if (Platform.isLinux) {
      const dataDir = DbConstants.dbPath;
      final dir = Directory(dataDir);
      if (!dir.existsSync()) {
        dir.createSync(recursive: true);
      }
      path = '$dataDir/${DbConstants.dbFile}';

      final dbFile = File(path);
      if (dbFile.existsSync()) {
        try {
          await Process.run('chmod', ['666', path]);
        } catch (e) {
          print('unable to chmod: ${e.toString()}');
        }
      }

      return openDatabase(
        path,
        version: DbConstants.dbVersion,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
        readOnly: false,
        singleInstance: true,
      );
    } else {
      throw PlatformException(code: "Linux is required");
    }
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _createOperationalTables(db);
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    await _createOperationalTables(db);
  }

  Future<void> _createOperationalTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS telemetry_records (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        source_type TEXT NOT NULL,
        source_id TEXT NOT NULL,
        metric TEXT NOT NULL,
        previous_value TEXT,
        new_value TEXT NOT NULL,
        occurred_at TEXT NOT NULL,
        sync_status TEXT NOT NULL,
        retry_count INTEGER NOT NULL DEFAULT 0
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS runtime_events (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        device_id INTEGER NOT NULL,
        event_type TEXT NOT NULL,
        reason TEXT NOT NULL,
        occurred_at TEXT NOT NULL,
        sync_status TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE INDEX IF NOT EXISTS telemetry_records_occurred_at_idx
      ON telemetry_records (occurred_at)
    ''');
    await db.execute('''
      CREATE INDEX IF NOT EXISTS runtime_events_device_id_idx
      ON runtime_events (device_id, occurred_at)
    ''');
  }
}
