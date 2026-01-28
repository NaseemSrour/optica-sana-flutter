import 'package:optica_sana/db_flutter/models.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../bootstrap.dart';

class ContactLensesTestRepo {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<int> addTest(ContactLensesTest test) async {
    final db = await _dbHelper.database;
    final map = test.toMap();
    map.remove('id');
    return await db.insert('contact_lenses_tests', map);
  }

  Future<ContactLensesTest?> getTest(int testId) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'contact_lenses_tests',
      where: 'id = ?',
      whereArgs: [testId],
    );
    if (maps.isNotEmpty) {
      return ContactLensesTest.fromMap(maps.first);
    }
    return null;
  }

  Future<List<ContactLensesTest>> listTestsForCustomer(int customerId) async {
    if (customerId <= 0) {
      throw ArgumentError("customer_id must be a positive integer");
    }
    final db = await _dbHelper.database;
    final maps = await db.query(
      'contact_lenses_tests',
      where: 'customer_id = ?',
      whereArgs: [customerId],
      orderBy: 'exam_date DESC',
    );
    return maps.map((map) => ContactLensesTest.fromMap(map)).toList();
  }

  Future<bool> updateTest(ContactLensesTest test) async {
    if (test.id == null) {
      throw ArgumentError("Cannot update a test without an ID");
    }
    final db = await _dbHelper.database;
    final result = await db.update(
      'contact_lenses_tests',
      test.toMap(),
      where: 'id = ?',
      whereArgs: [test.id],
    );
    return result > 0;
  }

  Future<bool> deleteTest(int testId) async {
    final db = await _dbHelper.database;
    final result = await db.delete(
      'contact_lenses_tests',
      where: 'id = ?',
      whereArgs: [testId],
    );
    return result > 0;
  }
}
