import 'package:optica_sana/db_flutter/models.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../bootstrap.dart';

class GlassesRepo {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<GlassesTest> addTest(GlassesTest test) async {
    final db = await _dbHelper.database;
    final id = await db.insert('glasses_tests', test.toMap());
    test.id = id;
    return test;
  }

  Future<GlassesTest?> getTest(int testId) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'glasses_tests',
      where: 'id = ?',
      whereArgs: [testId],
    );
    if (maps.isNotEmpty) {
      return GlassesTest.fromMap(maps.first);
    }
    return null;
  }

  Future<List<GlassesTest>> listTestsForCustomer(int customerId) async {
    if (customerId <= 0) {
      throw ArgumentError("customer_id must be a positive integer");
    }
    final db = await _dbHelper.database;
    final maps = await db.query(
      'glasses_tests',
      where: 'customer_id = ?',
      whereArgs: [customerId],
      orderBy: 'exam_date DESC',
    );
    return maps.map((map) => GlassesTest.fromMap(map)).toList();
  }

  Future<bool> updateTest(GlassesTest test) async {
    final db = await _dbHelper.database;
    final result = await db.update(
      'glasses_tests',
      test.toMap(),
      where: 'id = ?',
      whereArgs: [test.id],
    );
    return result > 0;
  }

  Future<bool> deleteTest(int testId) async {
    final db = await _dbHelper.database;
    final result = await db.delete(
      'glasses_tests',
      where: 'id = ?',
      whereArgs: [testId],
    );
    return result > 0;
  }
}
