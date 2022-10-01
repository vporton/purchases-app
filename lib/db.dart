import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

/// Let's use FOREIGN KEY constraints
Future onConfigure(Database db) async {
  await db.execute('PRAGMA foreign_keys = ON');
}

void _migrateInitial(Batch batch) {
  batch.execute('''CREATE TABLE Place (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    google_id TEXT NOT NULL,
    name TEXT NOT NULL,
    description TEXT NOT NULL,
    icon_url TEXT NOT NULL,
    lat REAL NOT NULL,
    lng REAL NOT NULL
)''');
  batch.execute('CREATE INDEX idx_place_updated ON Place (updated)');
  batch.execute('CREATE UNIQUE INDEX idx_place_google_id ON Place (google_id)');
  batch.execute('''CREATE TABLE Category (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    description TEXT NOT NULL
)''');
  batch.execute('''CREATE TABLE Product (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    shop INTEGER NOT NULL REFERENCES Place(id) ON DELETE CASCADE,
    category INTEGER NOT NULL REFERENCES Category(id) ON DELETE CASCADE,
    price REAL NOT NULL
)''');
  batch.execute('CREATE UNIQUE INDEX idx_product_uniq ON Product (shop, category)');
  batch.execute('CREATE INDEX idx_product_price ON Product (price)');
  batch.execute('''CREATE TABLE CategoryRel (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    super INTEGER NOT NULL REFERENCES Category(id) ON DELETE CASCADE,
    sub INTEGER NOT NULL REFERENCES Category(id) ON DELETE CASCADE    
)''');
  batch.execute('''CREATE TABLE Global (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    installation BLOB
)''');
  var uuid = const Uuid();
  var buffer = List<int>.filled(16, 0);
  batch.insert('Global', {'installation': Uint8List.fromList(uuid.v4buffer(buffer))});
}

var _migrations = [
  _migrateInitial,
];

Future<Database> myOpenDatabase() async {
  var databasesPath = await getDatabasesPath();
  var path = join(databasesPath, 'products.db');
  debugPrint("Database path: $path");

  // Make sure the directory exists
  try {
    await Directory(databasesPath).create(recursive: true);
  } catch (e) {
    debugPrint("Error creating database path: ${e.toString()}");
  }

  return await databaseFactory.openDatabase(path,
      options: OpenDatabaseOptions(
          version: 2,
          onConfigure: onConfigure,
          onCreate: (db, version) async {
            var batch = db.batch();
            for (final change in _migrations) {
              change(batch);
            }
            await batch.commit();
          },
          onUpgrade: (db, oldVersion, newVersion) async {
            var batch = db.batch();
            _migrations[oldVersion](batch);
            await batch.commit();
          },
          onDowngrade: onDatabaseDowngradeDelete));
}
