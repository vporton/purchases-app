import 'dart:io';

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

/// Let's use FOREIGN KEY constraints
Future onConfigure(Database db) async {
  await db.execute('PRAGMA foreign_keys = ON');
}

void _migrateInitial(Batch batch) {
  batch.execute('''CREATE TABLE Place (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    google_id TEXT NOT NULL,
    name TEXT NOT NULL,
    description TEXT NOT NULL,
    lat REAL NOT NULL,
    lng REAL NOT NULL
)''');
  batch.execute('CREATE INDEX idx_place_google_id ON Place (google_id)');
  batch.execute('''CREATE TABLE Category (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    description TEXT NOT NULL,
)''');
  batch.execute('''CREATE TABLE Product (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    price REAL NOT NULL,
    name TEXT NOT NULL,
    description TEXT NOT NULL,
)''');
  batch.execute('CREATE INDEX idx_product_price ON Product (price)');
  batch.execute('''CREATE TABLE CategoryRel (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    super INTEGER NOT NULL REFERENCES Category(id) ON UPDATE CASCADE,
    sub INTEGER NOT NULL REFERENCES Category(id) ON UPDATE CASCADE    
)''');
  batch.execute('''CREATE TABLE ProductCategory (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    category INTEGER NOT NULL REFERENCES Category(id) ON UPDATE CASCADE,
    product INTEGER NOT NULL REFERENCES Product(id) ON UPDATE CASCADE    
)''');
}

var _migrations = [
  _migrateInitial,
];

Future<Database> openDatabase(DatabaseFactory factory, path) async {
  var databasesPath = await getDatabasesPath();
  var path = join(databasesPath, 'purchases.db');

  // Make sure the directory exists
  try {
    await Directory(databasesPath).create(recursive: true);
  } catch (_) {}

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
