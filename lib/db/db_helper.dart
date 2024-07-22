import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:todo/models/task.dart';

class DBHelper {
  static Database? _db;
  static const int _version = 1;
  static const String _tableName = 'tasks';

  static Future<void> initDb() async {
    if (_db != null) {
      debugPrint('Database already initialized');
      return;
    }
    try {
      String path = '${await getDatabasesPath()}task.db';
      debugPrint('Database path: $path');
      _db = await openDatabase(path, version: _version,
          onCreate: (Database db, int version) async {
        debugPrint('Creating database');

        // When creating the db, create the table
        return db.execute(
            'CREATE TABLE $_tableName (id INTEGER PRIMARY KEY AUTOINCREMENT, '
            'title STRING, note TEXT, date STRING, '
            'startTime STRING, endTime STRING, '
            'remind INTEGER, repeat STRING, '
            'color INTEGER, '
            'isCompleted INTEGER)');
      });
      debugPrint('Database created');
    } catch (e) {
      debugPrint('Error initializing database: $e');
    }
  }

  static Future<void> _ensureDbInitialized() async {
    if (_db == null) {
      await initDb();
    }
  }

  static Future<int> insert(Task? task) async {
    await _ensureDbInitialized();
    debugPrint('Inserting...');
    try {
      return await _db!.insert(_tableName, task!.toJson());
    } catch (e) {
      debugPrint('Error inserting task: $e');
      return -1; // Returning -1 to indicate an error
    }
  }

  static Future<int> delete(Task task) async {
    await _ensureDbInitialized();
    debugPrint('Deleting...');
    return await _db!.delete(_tableName, where: 'id = ?', whereArgs: [task.id]);
  }
  static Future<int> deleteAll() async {
    await _ensureDbInitialized();
    debugPrint('Deleting All...');
    return await _db!.delete(_tableName,);
  }

  static Future<List<Map<String, dynamic>>> query() async {
    await _ensureDbInitialized();
    debugPrint('Querying...');
    try {
      final result = await _db!.query(_tableName);
      debugPrint('Query result: $result');
      return result;
    } catch (e) {
      debugPrint('Error querying tasks: $e');
      return [];
    }
  }

  static Future<int> update(int id) async {
    await _ensureDbInitialized();
    debugPrint('Updating...');
    return await _db!.rawUpdate('''
    UPDATE $_tableName
    SET isCompleted = ?
    WHERE id = ?
''', [1, id]);
  }
}
