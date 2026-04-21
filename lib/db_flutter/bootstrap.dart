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
    await db.execute(dropdownOptionsSql);
    List<String> statements = schemaSql.split(';');
    for (String statement in statements) {
      if (statement.trim().isNotEmpty) {
        await db.execute(statement);
      }
    }
    await _seedDropdownOptions(db);
  }

  Future<void> _seedDropdownOptions(Database db) async {
    const seeds = [
      ('sex', 'M', 1),
      ('sex', 'F', 2),
      ('r_base', 'UP', 1),
      ('r_base', 'DOWN', 2),
      ('r_base', 'IN', 3),
      ('r_base', 'OUT', 4),
      ('l_base', 'UP', 1),
      ('l_base', 'DOWN', 2),
      ('l_base', 'IN', 3),
      ('l_base', 'OUT', 4),
      ('dominant_eye', 'right', 1),
      ('dominant_eye', 'left', 2),
      ('glasses_role', 'רחוק', 1),
      ('glasses_role', 'קרוב', 2),
      ('glasses_role', 'ביניים / מחשב', 3),
      ('glasses_role', 'Multi focal', 4),
      ('glasses_role', 'Bi-focal', 5),
      ('glasses_role', 'אופטי שמש', 6),
      ('glasses_role', 'משקפי מגן', 7),
      ('lenses_material', 'CR1.5', 1),
      ('segment_diameter', '28', 1),
      ('lenses_manufacturer', 'Tommy Hilfiger', 1),
      ('lenses_manufacturer', 'RayBan', 2),
      ('lenses_coated', 'DVP', 1),
      ('lenses_coated', 'MVP', 2),
    ];
    for (final (fieldKey, value, sortOrder) in seeds) {
      await db.insert('dropdown_options', {
        'field_key': fieldKey,
        'value': value,
        'sort_order': sortOrder,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
    }
  }
}
