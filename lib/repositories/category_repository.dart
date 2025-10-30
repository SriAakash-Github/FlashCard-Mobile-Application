import '../models/category.dart';
import '../services/database_service.dart';

abstract class CategoryRepository {
  Future<List<Category>> getAllCategories();
  Future<Category?> getCategoryById(String id);
  Future<Category?> getCategoryByName(String name);
  Future<void> insertCategory(Category category);
  Future<void> updateCategory(Category category);
  Future<void> deleteCategory(String id);
  Future<int> getCategoryCount();
  Future<bool> categoryExists(String name);
  Future<List<CategoryWithCount>> getCategoriesWithFlashcardCount();
}

class CategoryRepositoryImpl implements CategoryRepository {
  final DatabaseService _databaseService;

  CategoryRepositoryImpl({DatabaseService? databaseService})
      : _databaseService = databaseService ?? DatabaseService.instance;

  @override
  Future<List<Category>> getAllCategories() async {
    try {
      final maps = await _databaseService.query(
        DatabaseService.categoriesTable,
        orderBy: 'name ASC',
      );
      return maps.map((map) => Category.fromMap(map)).toList();
    } catch (e) {
      throw CategoryRepositoryException('Failed to get all categories: $e');
    }
  }

  @override
  Future<Category?> getCategoryById(String id) async {
    try {
      final maps = await _databaseService.query(
        DatabaseService.categoriesTable,
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );
      if (maps.isNotEmpty) {
        return Category.fromMap(maps.first);
      }
      return null;
    } catch (e) {
      throw CategoryRepositoryException('Failed to get category by id: $e');
    }
  }

  @override
  Future<Category?> getCategoryByName(String name) async {
    try {
      final maps = await _databaseService.query(
        DatabaseService.categoriesTable,
        where: 'name = ?',
        whereArgs: [name],
        limit: 1,
      );
      if (maps.isNotEmpty) {
        return Category.fromMap(maps.first);
      }
      return null;
    } catch (e) {
      throw CategoryRepositoryException('Failed to get category by name: $e');
    }
  }

  @override
  Future<void> insertCategory(Category category) async {
    try {
      if (!category.isValid()) {
        throw CategoryRepositoryException('Invalid category data');
      }
      
      // Check if category name already exists
      final existing = await getCategoryByName(category.name);
      if (existing != null) {
        throw CategoryRepositoryException('Category name already exists');
      }

      await _databaseService.insert(
        DatabaseService.categoriesTable,
        category.toMap(),
      );
    } catch (e) {
      if (e is CategoryRepositoryException) rethrow;
      throw CategoryRepositoryException('Failed to insert category: $e');
    }
  }

  @override
  Future<void> updateCategory(Category category) async {
    try {
      if (!category.isValid()) {
        throw CategoryRepositoryException('Invalid category data');
      }

      // Check if new name conflicts with existing category (excluding current)
      final existing = await getCategoryByName(category.name);
      if (existing != null && existing.id != category.id) {
        throw CategoryRepositoryException('Category name already exists');
      }

      final rowsAffected = await _databaseService.update(
        DatabaseService.categoriesTable,
        category.toMap(),
        where: 'id = ?',
        whereArgs: [category.id],
      );
      if (rowsAffected == 0) {
        throw CategoryRepositoryException('Category not found');
      }
    } catch (e) {
      if (e is CategoryRepositoryException) rethrow;
      throw CategoryRepositoryException('Failed to update category: $e');
    }
  }

  @override
  Future<void> deleteCategory(String id) async {
    try {
      // Check if it's the default category
      if (id == 'default-category') {
        throw CategoryRepositoryException('Cannot delete default category');
      }

      // Use transaction to ensure data consistency
      await _databaseService.transaction((txn) async {
        // First, delete all flashcards in this category
        await txn.delete(
          DatabaseService.flashcardsTable,
          where: 'category_id = ?',
          whereArgs: [id],
        );

        // Then delete the category
        final rowsAffected = await txn.delete(
          DatabaseService.categoriesTable,
          where: 'id = ?',
          whereArgs: [id],
        );

        if (rowsAffected == 0) {
          throw CategoryRepositoryException('Category not found');
        }
      });
    } catch (e) {
      if (e is CategoryRepositoryException) rethrow;
      throw CategoryRepositoryException('Failed to delete category: $e');
    }
  }

  @override
  Future<int> getCategoryCount() async {
    try {
      final result = await _databaseService.rawQuery(
        'SELECT COUNT(*) as count FROM ${DatabaseService.categoriesTable}',
      );
      return result.first['count'] as int;
    } catch (e) {
      throw CategoryRepositoryException('Failed to get category count: $e');
    }
  }

  @override
  Future<bool> categoryExists(String name) async {
    try {
      final category = await getCategoryByName(name);
      return category != null;
    } catch (e) {
      throw CategoryRepositoryException('Failed to check category existence: $e');
    }
  }

  @override
  Future<List<CategoryWithCount>> getCategoriesWithFlashcardCount() async {
    try {
      final result = await _databaseService.rawQuery('''
        SELECT 
          c.id,
          c.name,
          c.color,
          c.created_at,
          COUNT(f.id) as flashcard_count
        FROM ${DatabaseService.categoriesTable} c
        LEFT JOIN ${DatabaseService.flashcardsTable} f ON c.id = f.category_id
        GROUP BY c.id, c.name, c.color, c.created_at
        ORDER BY c.name ASC
      ''');

      return result.map((map) {
        final category = Category.fromMap({
          'id': map['id'],
          'name': map['name'],
          'color': map['color'],
          'created_at': map['created_at'],
        });
        final count = map['flashcard_count'] as int;
        return CategoryWithCount(category: category, flashcardCount: count);
      }).toList();
    } catch (e) {
      throw CategoryRepositoryException(
          'Failed to get categories with flashcard count: $e');
    }
  }
}

class CategoryWithCount {
  final Category category;
  final int flashcardCount;

  CategoryWithCount({
    required this.category,
    required this.flashcardCount,
  });

  @override
  String toString() {
    return 'CategoryWithCount(category: ${category.name}, count: $flashcardCount)';
  }
}

class CategoryRepositoryException implements Exception {
  final String message;
  CategoryRepositoryException(this.message);

  @override
  String toString() => 'CategoryRepositoryException: $message';
}