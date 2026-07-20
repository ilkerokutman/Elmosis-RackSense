import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:rack_sense/app/core/constants/db.dart';
import 'package:sqflite/sqflite.dart';
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
      } else {
        path = join(await getDatabasesPath(), 'rack_sense.db');
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
    //
  }

  Future<void> _onCreate(Database db, int version) async {
    //
  }
}
