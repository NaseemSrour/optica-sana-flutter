import 'package:optica_sana/db_flutter/models.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:optica_sana/db_flutter/bootstrap.dart';

class CustomerRepo {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<Customer> addCustomer(Customer newCustomer) async {
    final db = await _dbHelper.database;
    final id = await db.insert('customers', newCustomer.toMap());
    newCustomer.id = id;
    return newCustomer;
  }

  Future<Customer?> getCustomer(int customerId) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'customers',
      where: 'id = ?',
      whereArgs: [customerId],
    );
    if (maps.isNotEmpty) {
      return Customer.fromMap(maps.first);
    }
    return null;
  }

  Future<Customer?> getCustomerBySSN(int customerSSN) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'customers',
      where: 'ssn = ?',
      whereArgs: [customerSSN],
    );
    if (maps.isNotEmpty) {
      return Customer.fromMap(maps.first);
    }
    return null;
  }

  Future<List<Customer>> listCustomers() async {
    final db = await _dbHelper.database;
    final maps = await db.query('customers', orderBy: 'id');
    return maps.map((map) => Customer.fromMap(map)).toList();
  }

  Future<List<Customer>> searchByName(String query) async {
    final db = await _dbHelper.database;
    final words = query.trim().split(' ').where((w) => w.isNotEmpty).toList();
    if (words.isEmpty) {
      return [];
    }

    final conditions = words
        .map((_) => '(fname LIKE ? OR lname LIKE ?)')
        .join(' AND ');
    final params = words.expand((w) => ['%$w%', '%$w%']).toList();

    final sql = 'SELECT * FROM customers WHERE $conditions';
    final maps = await db.rawQuery(sql, params);
    return maps.map((map) => Customer.fromMap(map)).toList();
  }

  Future<List<Customer>> searchByNameOrSsn(String query) async {
    final db = await _dbHelper.database;
    final words = query.trim().split(' ').where((w) => w.isNotEmpty).toList();
    if (words.isEmpty) {
      return [];
    }

    final conditions = words
        .map((_) => '(fname LIKE ? OR lname LIKE ? OR ssn LIKE ?)')
        .join(' AND ');
    final params = words.expand((w) => ['%$w%', '%$w%', '%$w%']).toList();

    final sql = 'SELECT * FROM customers WHERE $conditions';
    final maps = await db.rawQuery(sql, params);
    return maps.map((map) => Customer.fromMap(map)).toList();
  }

  Future<bool> updateCustomer(Customer customer) async {
    final db = await _dbHelper.database;
    final result = await db.update(
      'customers',
      customer.toMap(),
      where: 'id = ?',
      whereArgs: [customer.id],
    );
    return result > 0;
  }

  Future<bool> deleteCustomer(int customerId) async {
    final db = await _dbHelper.database;
    final result = await db.delete(
      'customers',
      where: 'id = ?',
      whereArgs: [customerId],
    );
    return result > 0;
  }
}
