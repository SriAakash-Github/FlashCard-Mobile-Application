import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:flashcards_app/services/database_service.dart';

void main() {
  group('DatabaseService Tests', () {
    late DatabaseService databaseService;

    setUpAll(() {
      // Initialize FFI for testing
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    });

    setUp(() async {
      await DatabaseService.instance.deleteDatabase();
      databaseService = DatabaseService.instance;
    });

    tearDown(() async {
      await databaseService.close();
    });

    test('should create database with correct tables', () async {
      final db = await databaseService.database;
      
      // Check if tables exist
      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table'"
      );
      
      final tableNames = tables.map((table) => table['name']).toList();
      expect(tableNames, contains('categories'));
      expect(tableNames, contains('flashcards'));
    });

    test('should create default category on initialization', () async {
      final categories = await databaseService.query('categories');
      
      expect(categories.length, 1);
      expect(categories.first['id'], 'default-category');
      expect(categories.first['name'], 'General');
    });

    test('should insert data correctly', () async {
      final testData = {
        'id': 'test-id',
        'name': 'Test Category',
        'color': 'ff0000',
        'created_at': DateTime.now().millisecondsSinceEpoch,
      };

      await databaseService.insert('categories', testData);
      
      final result = await databaseService.query(
        'categories',
        where: 'id = ?',
        whereArgs: ['test-id'],
      );

      expect(result.length, 1);
      expect(result.first['name'], 'Test Category');
    });

    test('should update data correctly', () async {
      // Insert test data first
      final testData = {
        'id': 'test-id',
        'name': 'Original Name',
        'color': 'ff0000',
        'created_at': DateTime.now().millisecondsSinceEpoch,
      };
      await databaseService.insert('categories', testData);

      // Update the data
      await databaseService.update(
        'categories',
        {'name': 'Updated Name'},
        where: 'id = ?',
        whereArgs: ['test-id'],
      );

      // Verify update
      final result = await databaseService.query(
        'categories',
        where: 'id = ?',
        whereArgs: ['test-id'],
      );

      expect(result.first['name'], 'Updated Name');
    });

    test('should delete data correctly', () async {
      // Insert test data first
      final testData = {
        'id': 'test-id',
        'name': 'Test Category',
        'color': 'ff0000',
        'created_at': DateTime.now().millisecondsSinceEpoch,
      };
      await databaseService.insert('categories', testData);

      // Delete the data
      await databaseService.delete(
        'categories',
        where: 'id = ?',
        whereArgs: ['test-id'],
      );

      // Verify deletion
      final result = await databaseService.query(
        'categories',
        where: 'id = ?',
        whereArgs: ['test-id'],
      );

      expect(result.length, 0);
    });

    test('should execute raw queries correctly', () async {
      final result = await databaseService.rawQuery(
        'SELECT COUNT(*) as count FROM categories'
      );

      expect(result.length, 1);
      expect(result.first['count'], 1); // Default category
    });

    test('should support transactions', () async {
      await databaseService.transaction((txn) async {
        await txn.insert('categories', {
          'id': 'test-1',
          'name': 'Test 1',
          'color': 'ff0000',
          'created_at': DateTime.now().millisecondsSinceEpoch,
        });

        await txn.insert('categories', {
          'id': 'test-2',
          'name': 'Test 2',
          'color': '00ff00',
          'created_at': DateTime.now().millisecondsSinceEpoch,
        });
      });

      final result = await databaseService.query('categories');
      expect(result.length, 3); // Default + 2 new categories
    });

    test('should support batch operations', () async {
      await databaseService.batch((batch) {
        batch.insert('categories', {
          'id': 'batch-1',
          'name': 'Batch 1',
          'color': 'ff0000',
          'created_at': DateTime.now().millisecondsSinceEpoch,
        });

        batch.insert('categories', {
          'id': 'batch-2',
          'name': 'Batch 2',
          'color': '00ff00',
          'created_at': DateTime.now().millisecondsSinceEpoch,
        });
      });

      final result = await databaseService.query('categories');
      expect(result.length, 3); // Default + 2 batch categories
    });

    test('should get database version correctly', () async {
      final version = await databaseService.getDatabaseVersion();
      expect(version, 1);
    });

    test('should check database existence', () async {
      // Database should exist after first access
      await databaseService.database;
      final exists = await databaseService.databaseExists();
      expect(exists, true);
    });

    test('should close database connection', () async {
      await databaseService.database; // Initialize database
      await databaseService.close();
      
      // Database should be reinitialized on next access
      final db = await databaseService.database;
      expect(db, isNotNull);
    });
  });
}