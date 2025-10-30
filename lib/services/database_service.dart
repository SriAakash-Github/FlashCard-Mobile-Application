import 'dart:async';
import 'dart:typed_data';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseService {
  static Database? _database;
  static const String _databaseName = 'flashcards.db';
  static const int _databaseVersion = 1;

  // Table names
  static const String categoriesTable = 'categories';
  static const String flashcardsTable = 'flashcards';

  // Singleton pattern
  DatabaseService._privateConstructor();
  static final DatabaseService instance = DatabaseService._privateConstructor();

  // Get database instance
  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  // Initialize database
  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), _databaseName);
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  // Create database tables
  Future<void> _onCreate(Database db, int version) async {
    await _createCategoriesTable(db);
    await _createFlashcardsTable(db);
    await _insertDefaultCategory(db);
  }

  // Handle database upgrades
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Handle future database migrations here
    if (oldVersion < newVersion) {
      // Add migration logic for future versions
    }
  }

  // Create categories table
  Future<void> _createCategoriesTable(Database db) async {
    await db.execute('''
      CREATE TABLE $categoriesTable (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL UNIQUE,
        color TEXT NOT NULL,
        created_at INTEGER NOT NULL
      )
    ''');
  }

  // Create flashcards table
  Future<void> _createFlashcardsTable(Database db) async {
    await db.execute('''
      CREATE TABLE $flashcardsTable (
        id TEXT PRIMARY KEY,
        question TEXT NOT NULL,
        answer TEXT NOT NULL,
        category_id TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        FOREIGN KEY (category_id) REFERENCES $categoriesTable (id) ON DELETE CASCADE
      )
    ''');

    // Create index for better query performance
    await db.execute('''
      CREATE INDEX idx_flashcards_category_id ON $flashcardsTable (category_id)
    ''');
  }

  // Insert default category
  Future<void> _insertDefaultCategory(Database db) async {
    await db.insert(categoriesTable, {
      'id': 'default-category',
      'name': 'General',
      'color': '2196f3', // Blue color
      'created_at': DateTime.now().millisecondsSinceEpoch,
    });
  }

  // Generic query method
  Future<List<Map<String, dynamic>>> query(
    String table, {
    bool? distinct,
    List<String>? columns,
    String? where,
    List<Object?>? whereArgs,
    String? groupBy,
    String? having,
    String? orderBy,
    int? limit,
    int? offset,
  }) async {
    final db = await database;
    return await db.query(
      table,
      distinct: distinct,
      columns: columns,
      where: where,
      whereArgs: whereArgs,
      groupBy: groupBy,
      having: having,
      orderBy: orderBy,
      limit: limit,
      offset: offset,
    );
  }

  // Generic insert method
  Future<int> insert(String table, Map<String, dynamic> values) async {
    final db = await database;
    return await db.insert(table, values);
  }

  // Generic update method
  Future<int> update(
    String table,
    Map<String, dynamic> values, {
    String? where,
    List<Object?>? whereArgs,
  }) async {
    final db = await database;
    return await db.update(table, values, where: where, whereArgs: whereArgs);
  }

  // Generic delete method
  Future<int> delete(
    String table, {
    String? where,
    List<Object?>? whereArgs,
  }) async {
    final db = await database;
    return await db.delete(table, where: where, whereArgs: whereArgs);
  }

  // Execute raw SQL
  Future<List<Map<String, dynamic>>> rawQuery(
    String sql, [
    List<Object?>? arguments,
  ]) async {
    final db = await database;
    return await db.rawQuery(sql, arguments);
  }

  // Execute raw SQL without return
  Future<void> execute(String sql, [List<Object?>? arguments]) async {
    final db = await database;
    await db.execute(sql, arguments);
  }

  // Transaction support
  Future<T> transaction<T>(Future<T> Function(Transaction txn) action) async {
    final db = await database;
    return await db.transaction(action);
  }

  // Batch operations
  Future<List<Object?>> batch(Function(Batch batch) operations) async {
    final db = await database;
    final batch = db.batch();
    operations(batch);
    return await batch.commit();
  }

  // Get database path (useful for debugging)
  Future<String> getDatabasePath() async {
    return join(await getDatabasesPath(), _databaseName);
  }

  // Close database connection
  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }

  // Delete database (useful for testing)
  Future<void> deleteDatabase() async {
    String path = await getDatabasePath();
    await databaseFactory.deleteDatabase(path);
    _database = null;
  }

  // Check if database exists
  Future<bool> databaseExists() async {
    String path = await getDatabasePath();
    return await databaseFactory.databaseExists(path);
  }

  // Get database version
  Future<int> getDatabaseVersion() async {
    final db = await database;
    return await db.getVersion();
  }

  // Backup database (returns database file content)
  Future<Uint8List?> backupDatabase() async {
    try {
      String path = await getDatabasePath();
      final file = await databaseFactory.readDatabaseBytes(path);
      return file;
    } catch (e) {
      return null;
    }
  }

  // Restore database from backup
  Future<bool> restoreDatabase(Uint8List backupData) async {
    try {
      await close();
      String path = await getDatabasePath();
      await databaseFactory.writeDatabaseBytes(path, backupData);
      _database = null; // Force reinitialization
      return true;
    } catch (e) {
      return false;
    }
  }
}