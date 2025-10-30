import 'package:flutter_test/flutter_test.dart';
import 'package:flashcards_app/controllers/flashcard_controller.dart';
import 'package:flashcards_app/models/flashcard.dart';
import 'package:flashcards_app/repositories/flashcard_repository.dart';

// Mock repository for testing
class MockFlashcardRepository implements FlashcardRepository {
  final List<Flashcard> _flashcards = [];
  bool shouldThrowError = false;

  @override
  Future<List<Flashcard>> getAllFlashcards() async {
    if (shouldThrowError) throw Exception('Mock error');
    return List.from(_flashcards);
  }

  @override
  Future<List<Flashcard>> getFlashcardsByCategory(String categoryId) async {
    if (shouldThrowError) throw Exception('Mock error');
    return _flashcards.where((f) => f.categoryId == categoryId).toList();
  }

  @override
  Future<Flashcard?> getFlashcardById(String id) async {
    if (shouldThrowError) throw Exception('Mock error');
    try {
      return _flashcards.firstWhere((f) => f.id == id);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> insertFlashcard(Flashcard flashcard) async {
    if (shouldThrowError) throw Exception('Mock error');
    _flashcards.add(flashcard);
  }

  @override
  Future<void> updateFlashcard(Flashcard flashcard) async {
    if (shouldThrowError) throw Exception('Mock error');
    final index = _flashcards.indexWhere((f) => f.id == flashcard.id);
    if (index == -1) throw Exception('Flashcard not found');
    _flashcards[index] = flashcard;
  }

  @override
  Future<void> deleteFlashcard(String id) async {
    if (shouldThrowError) throw Exception('Mock error');
    final initialLength = _flashcards.length;
    _flashcards.removeWhere((f) => f.id == id);
    if (_flashcards.length == initialLength) throw Exception('Flashcard not found');
  }

  @override
  Future<void> deleteFlashcardsByCategory(String categoryId) async {
    if (shouldThrowError) throw Exception('Mock error');
    _flashcards.removeWhere((f) => f.categoryId == categoryId);
  }

  @override
  Future<int> getFlashcardCount() async {
    if (shouldThrowError) throw Exception('Mock error');
    return _flashcards.length;
  }

  @override
  Future<int> getFlashcardCountByCategory(String categoryId) async {
    if (shouldThrowError) throw Exception('Mock error');
    return _flashcards.where((f) => f.categoryId == categoryId).length;
  }
}

void main() {
  group('FlashcardController Tests', () {
    late FlashcardController controller;
    late MockFlashcardRepository mockRepository;

    setUp(() {
      mockRepository = MockFlashcardRepository();
      controller = FlashcardController(flashcardRepository: mockRepository);
    });

    test('should initialize with empty state', () {
      expect(controller.flashcards, isEmpty);
      expect(controller.isLoading, false);
      expect(controller.error, isNull);
      expect(controller.currentCategoryId, isNull);
      expect(controller.flashcardCount, 0);
      expect(controller.hasFlashcards, false);
    });

    test('should load all flashcards successfully', () async {
      final flashcard1 = Flashcard(
        question: 'Question 1',
        answer: 'Answer 1',
        categoryId: 'category-1',
      );
      final flashcard2 = Flashcard(
        question: 'Question 2',
        answer: 'Answer 2',
        categoryId: 'category-2',
      );

      mockRepository._flashcards.addAll([flashcard1, flashcard2]);

      await controller.loadAllFlashcards();

      expect(controller.flashcards.length, 2);
      expect(controller.isLoading, false);
      expect(controller.error, isNull);
      expect(controller.currentCategoryId, isNull);
    });

    test('should load flashcards by category', () async {
      final flashcard1 = Flashcard(
        question: 'Question 1',
        answer: 'Answer 1',
        categoryId: 'category-1',
      );
      final flashcard2 = Flashcard(
        question: 'Question 2',
        answer: 'Answer 2',
        categoryId: 'category-2',
      );

      mockRepository._flashcards.addAll([flashcard1, flashcard2]);

      await controller.loadFlashcardsByCategory('category-1');

      expect(controller.flashcards.length, 1);
      expect(controller.flashcards.first.question, 'Question 1');
      expect(controller.currentCategoryId, 'category-1');
    });

    test('should add flashcard successfully', () async {
      final flashcard = Flashcard(
        question: 'New Question',
        answer: 'New Answer',
        categoryId: 'category-1',
      );

      final result = await controller.addFlashcard(flashcard);

      expect(result, true);
      expect(mockRepository._flashcards.length, 1);
      expect(controller.error, isNull);
    });

    test('should update flashcard successfully', () async {
      final flashcard = Flashcard(
        id: 'test-id',
        question: 'Original Question',
        answer: 'Original Answer',
        categoryId: 'category-1',
      );

      mockRepository._flashcards.add(flashcard);
      await controller.loadAllFlashcards();

      final updated = flashcard.copyWith(
        question: 'Updated Question',
        answer: 'Updated Answer',
      );

      final result = await controller.updateFlashcard(updated);

      expect(result, true);
      expect(controller.flashcards.first.question, 'Updated Question');
      expect(controller.error, isNull);
    });

    test('should delete flashcard successfully', () async {
      final flashcard = Flashcard(
        question: 'Test Question',
        answer: 'Test Answer',
        categoryId: 'category-1',
      );

      mockRepository._flashcards.add(flashcard);
      await controller.loadAllFlashcards();

      final result = await controller.deleteFlashcard(flashcard.id);

      expect(result, true);
      expect(controller.flashcards.length, 0);
      expect(controller.error, isNull);
    });

    test('should search flashcards correctly', () async {
      final flashcard1 = Flashcard(
        question: 'What is Flutter?',
        answer: 'UI toolkit',
        categoryId: 'category-1',
      );
      final flashcard2 = Flashcard(
        question: 'What is Dart?',
        answer: 'Programming language',
        categoryId: 'category-1',
      );

      mockRepository._flashcards.addAll([flashcard1, flashcard2]);
      await controller.loadAllFlashcards();

      controller.searchFlashcards('Flutter');

      expect(controller.flashcards.length, 1);
      expect(controller.flashcards.first.question, 'What is Flutter?');
    });

    test('should clear search correctly', () async {
      final flashcard1 = Flashcard(
        question: 'Question 1',
        answer: 'Answer 1',
        categoryId: 'category-1',
      );
      final flashcard2 = Flashcard(
        question: 'Question 2',
        answer: 'Answer 2',
        categoryId: 'category-1',
      );

      mockRepository._flashcards.addAll([flashcard1, flashcard2]);
      await controller.loadAllFlashcards();

      controller.searchFlashcards('Question 1');
      expect(controller.flashcards.length, 1);

      controller.clearSearch();
      expect(controller.flashcards.length, 2);
    });

    test('should validate flashcard correctly', () {
      final validation = controller.validateFlashcard('', '', '');

      expect(validation['question'], 'Question cannot be empty');
      expect(validation['answer'], 'Answer cannot be empty');
      expect(validation['category'], 'Please select a category');

      final validValidation = controller.validateFlashcard(
        'Valid question',
        'Valid answer',
        'category-1',
      );

      expect(validValidation['question'], isNull);
      expect(validValidation['answer'], isNull);
      expect(validValidation['category'], isNull);
    });

    test('should handle errors correctly', () async {
      mockRepository.shouldThrowError = true;

      await controller.loadAllFlashcards();

      expect(controller.error, isNotNull);
      expect(controller.error, contains('Mock error'));
      expect(controller.isLoading, false);
    });

    test('should clear data correctly', () async {
      final flashcard = Flashcard(
        question: 'Test Question',
        answer: 'Test Answer',
        categoryId: 'category-1',
      );

      mockRepository._flashcards.add(flashcard);
      await controller.loadAllFlashcards();

      controller.clear();

      expect(controller.flashcards, isEmpty);
      expect(controller.currentCategoryId, isNull);
      expect(controller.error, isNull);
    });

    test('should notify listeners on state changes', () async {
      bool notified = false;
      controller.addListener(() {
        notified = true;
      });

      await controller.loadAllFlashcards();

      expect(notified, true);
    });
  });
}