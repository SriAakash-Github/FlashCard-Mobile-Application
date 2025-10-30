import '../models/flashcard.dart';
import '../services/database_service.dart';

abstract class FlashcardRepository {
  Future<List<Flashcard>> getAllFlashcards();
  Future<List<Flashcard>> getFlashcardsByCategory(String categoryId);
  Future<Flashcard?> getFlashcardById(String id);
  Future<void> insertFlashcard(Flashcard flashcard);
  Future<void> updateFlashcard(Flashcard flashcard);
  Future<void> deleteFlashcard(String id);
  Future<void> deleteFlashcardsByCategory(String categoryId);
  Future<int> getFlashcardCount();
  Future<int> getFlashcardCountByCategory(String categoryId);
}

class FlashcardRepositoryImpl implements FlashcardRepository {
  final DatabaseService _databaseService;

  FlashcardRepositoryImpl({DatabaseService? databaseService})
      : _databaseService = databaseService ?? DatabaseService.instance;

  @override
  Future<List<Flashcard>> getAllFlashcards() async {
    try {
      final maps = await _databaseService.query(
        DatabaseService.flashcardsTable,
        orderBy: 'created_at DESC',
      );
      return maps.map((map) => Flashcard.fromMap(map)).toList();
    } catch (e) {
      throw FlashcardRepositoryException('Failed to get all flashcards: $e');
    }
  }

  @override
  Future<List<Flashcard>> getFlashcardsByCategory(String categoryId) async {
    try {
      final maps = await _databaseService.query(
        DatabaseService.flashcardsTable,
        where: 'category_id = ?',
        whereArgs: [categoryId],
        orderBy: 'created_at DESC',
      );
      return maps.map((map) => Flashcard.fromMap(map)).toList();
    } catch (e) {
      throw FlashcardRepositoryException(
          'Failed to get flashcards by category: $e');
    }
  }

  @override
  Future<Flashcard?> getFlashcardById(String id) async {
    try {
      final maps = await _databaseService.query(
        DatabaseService.flashcardsTable,
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );
      if (maps.isNotEmpty) {
        return Flashcard.fromMap(maps.first);
      }
      return null;
    } catch (e) {
      throw FlashcardRepositoryException('Failed to get flashcard by id: $e');
    }
  }

  @override
  Future<void> insertFlashcard(Flashcard flashcard) async {
    try {
      if (!flashcard.isValid()) {
        throw FlashcardRepositoryException('Invalid flashcard data');
      }
      await _databaseService.insert(
        DatabaseService.flashcardsTable,
        flashcard.toMap(),
      );
    } catch (e) {
      if (e is FlashcardRepositoryException) rethrow;
      throw FlashcardRepositoryException('Failed to insert flashcard: $e');
    }
  }

  @override
  Future<void> updateFlashcard(Flashcard flashcard) async {
    try {
      if (!flashcard.isValid()) {
        throw FlashcardRepositoryException('Invalid flashcard data');
      }
      final rowsAffected = await _databaseService.update(
        DatabaseService.flashcardsTable,
        flashcard.toMap(),
        where: 'id = ?',
        whereArgs: [flashcard.id],
      );
      if (rowsAffected == 0) {
        throw FlashcardRepositoryException('Flashcard not found');
      }
    } catch (e) {
      if (e is FlashcardRepositoryException) rethrow;
      throw FlashcardRepositoryException('Failed to update flashcard: $e');
    }
  }

  @override
  Future<void> deleteFlashcard(String id) async {
    try {
      final rowsAffected = await _databaseService.delete(
        DatabaseService.flashcardsTable,
        where: 'id = ?',
        whereArgs: [id],
      );
      if (rowsAffected == 0) {
        throw FlashcardRepositoryException('Flashcard not found');
      }
    } catch (e) {
      if (e is FlashcardRepositoryException) rethrow;
      throw FlashcardRepositoryException('Failed to delete flashcard: $e');
    }
  }

  @override
  Future<void> deleteFlashcardsByCategory(String categoryId) async {
    try {
      await _databaseService.delete(
        DatabaseService.flashcardsTable,
        where: 'category_id = ?',
        whereArgs: [categoryId],
      );
    } catch (e) {
      throw FlashcardRepositoryException(
          'Failed to delete flashcards by category: $e');
    }
  }

  @override
  Future<int> getFlashcardCount() async {
    try {
      final result = await _databaseService.rawQuery(
        'SELECT COUNT(*) as count FROM ${DatabaseService.flashcardsTable}',
      );
      return result.first['count'] as int;
    } catch (e) {
      throw FlashcardRepositoryException('Failed to get flashcard count: $e');
    }
  }

  @override
  Future<int> getFlashcardCountByCategory(String categoryId) async {
    try {
      final result = await _databaseService.rawQuery(
        'SELECT COUNT(*) as count FROM ${DatabaseService.flashcardsTable} WHERE category_id = ?',
        [categoryId],
      );
      return result.first['count'] as int;
    } catch (e) {
      throw FlashcardRepositoryException(
          'Failed to get flashcard count by category: $e');
    }
  }
}

class FlashcardRepositoryException implements Exception {
  final String message;
  FlashcardRepositoryException(this.message);

  @override
  String toString() => 'FlashcardRepositoryException: $message';
}