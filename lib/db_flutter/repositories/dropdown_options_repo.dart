import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:optica_sana/db_flutter/bootstrap.dart';

class DropdownOptionsRepo {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<List<String>> getOptions(String fieldKey) async {
    final db = await _dbHelper.database;
    final rows = await db.query(
      'dropdown_options',
      columns: ['value'],
      where: 'field_key = ?',
      whereArgs: [fieldKey],
      orderBy: 'sort_order ASC, value ASC',
    );
    return rows.map((r) => r['value'] as String).toList();
  }

  Future<void> addOption(String fieldKey, String value) async {
    final db = await _dbHelper.database;
    final maxOrder = await db.rawQuery(
      'SELECT COALESCE(MAX(sort_order), 0) + 1 AS next FROM dropdown_options WHERE field_key = ?',
      [fieldKey],
    );
    final sortOrder = maxOrder.first['next'] as int;
    await db.insert(
      'dropdown_options',
      {'field_key': fieldKey, 'value': value, 'sort_order': sortOrder},
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  Future<void> deleteOption(String fieldKey, String value) async {
    final db = await _dbHelper.database;
    await db.delete(
      'dropdown_options',
      where: 'field_key = ? AND value = ?',
      whereArgs: [fieldKey, value],
    );
  }

  Future<Map<String, List<String>>> getAllOptions() async {
    final db = await _dbHelper.database;
    final rows = await db.query(
      'dropdown_options',
      orderBy: 'field_key ASC, sort_order ASC, value ASC',
    );
    final result = <String, List<String>>{};
    for (final row in rows) {
      final key = row['field_key'] as String;
      final value = row['value'] as String;
      result.putIfAbsent(key, () => []).add(value);
    }
    return result;
  }
}
