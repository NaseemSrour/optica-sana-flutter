import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path_provider/path_provider.dart';
import 'schema.dart';

class DatabaseHelper {
  static final _databaseName = "OpticaSana.db";
  static final _databaseVersion = 1;

  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  static Database? _database;
  static String? _cachedPath;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<String> get databasePath async {
    if (_cachedPath != null) return _cachedPath!;
    final dir = await getApplicationDocumentsDirectory();
    _cachedPath = join(dir.path, _databaseName);
    return _cachedPath!;
  }

  Future<void> closeDatabase() async {
    await _database?.close();
    _database = null;
  }

  _initDatabase() async {
    final path = await databasePath;
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onOpen: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
  }

  Future _onCreate(Database db, int version) async {
    List<String> statements = schemaSql.split(';');
    for (String statement in statements) {
      if (statement.trim().isNotEmpty) {
        await db.execute(statement);
      }
    }
  }
}
