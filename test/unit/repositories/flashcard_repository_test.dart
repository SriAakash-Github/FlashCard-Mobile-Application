import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:flashcards_app/models/flashcard.dart';
import 'package:flashcards_app/models/category.dart';
import 'package:flashcards_app/repositories/flashcard_repository.dart';
import 'package:flashcards_app/repositories/category_repository.dart';
import 'package:flashcards_app/services/database_service.dart';

void main() {
  group('FlashcardRepository Tests', () {
    late FlashcardRepository flashcardRepository;
    late CategoryRepository categoryRepository;
    late DatabaseService databaseService;

    setUpAll(() {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    });

    setUp(() async {
      // Create a fresh database service for each test
      await DatabaseService.instance.deleteDatabase();
      databaseService = DatabaseService.instance;
      flashcardRepository = FlashcardRepositoryImpl(databaseService: databaseService);
      categoryRepository = CategoryRepositoryImpl(databaseService: databaseService);
      
      // Ensure database is initialized
      await databaseService.database;
    });

    tearDown(() async {
      await databaseService.close();
    });

    test('should insert and retrieve flashcard', () async {
      final flashcard = Flashcard(
        question: 'What is Flutter?',
        answer: 'A UI toolkit',
        categoryId: 'default-category',
      );

      await flashcardRepository.insertFlashcard(flashcard);
      final retrieved = await flashcardRepository.getFlashcardById(flashcard.id);

      expect(retrieved, isNotNull);
      expect(retrieved!.question, flashcard.question);
      expect(retrieved.answer, flashcard.answer);
      expect(retrieved.categoryId, flashcard.categoryId);
    });

    test('should get all flashcards', () async {
      final flashcard1 = Flashcard(
        question: 'Question 1',
        answer: 'Answer 1',
        categoryId: 'default-category',
      );
      final flashcard2 = Flashcard(
        question: 'Question 2',
        answer: 'Answer 2',
        categoryId: 'default-category',
      );

      await flashcardRepository.insertFlashcard(flashcard1);
      await flashcardRepository.insertFlashcard(flashcard2);

      final flashcards = await flashcardRepository.getAllFlashcards();
      expect(flashcards.length, 2);
    });

    test('should get flashcards by category', () async {
      // Create a test category
      final testCategory = Category(name: 'Test Category');
      await categoryRepository.insertCategory(testCategory);

      final flashcard1 = Flashcard(
        question: 'Question 1',
        answer: 'Answer 1',
        categoryId: 'default-category',
      );
      final flashcard2 = Flashcard(
        question: 'Question 2',
        answer: 'Answer 2',
        categoryId: testCategory.id,
      );

      await flashcardRepository.insertFlashcard(flashcard1);
      await flashcardRepository.insertFlashcard(flashcard2);

      final defaultFlashcards = await flashcardRepository
          .getFlashcardsByCategory('default-category');
      final testFlashcards = await flashcardRepository
          .getFlashcardsByCategory(testCategory.id);

      expect(defaultFlashcards.length, 1);
      expect(testFlashcards.length, 1);
      expect(testFlashcards.first.question, 'Question 2');
    });

    test('should update flashcard', () async {
      final flashcard = Flashcard(
        question: 'Original Question',
        answer: 'Original Answer',
        categoryId: 'default-category',
      );

      await flashcardRepository.insertFlashcard(flashcard);

      final updated = flashcard.copyWith(
        question: 'Updated Question',
        answer: 'Updated Answer',
      );

      await flashcardRepository.updateFlashcard(updated);
      final retrieved = await flashcardRepository.getFlashcardById(flashcard.id);

      expect(retrieved!.question, 'Updated Question');
      expect(retrieved.answer, 'Updated Answer');
    });

    test('should delete flashcard', () async {
      final flashcard = Flashcard(
        question: 'Test Question',
        answer: 'Test Answer',
        categoryId: 'default-category',
      );

      await flashcardRepository.insertFlashcard(flashcard);
      await flashcardRepository.deleteFlashcard(flashcard.id);

      final retrieved = await flashcardRepository.getFlashcardById(flashcard.id);
      expect(retrieved, isNull);
    });

    test('should get flashcard count', () async {
      final flashcard1 = Flashcard(
        question: 'Question 1',
        answer: 'Answer 1',
        categoryId: 'default-category',
      );
      final flashcard2 = Flashcard(
        question: 'Question 2',
        answer: 'Answer 2',
        categoryId: 'default-category',
      );

      await flashcardRepository.insertFlashcard(flashcard1);
      await flashcardRepository.insertFlashcard(flashcard2);

      final count = await flashcardRepository.getFlashcardCount();
      expect(count, 2);
    });

    test('should get flashcard count by category', () async {
      final testCategory = Category(name: 'Test Category');
      await categoryRepository.insertCategory(testCategory);

      final flashcard1 = Flashcard(
        question: 'Question 1',
        answer: 'Answer 1',
        categoryId: 'default-category',
      );
      final flashcard2 = Flashcard(
        question: 'Question 2',
        answer: 'Answer 2',
        categoryId: testCategory.id,
      );

      await flashcardRepository.insertFlashcard(flashcard1);
      await flashcardRepository.insertFlashcard(flashcard2);

      final defaultCount = await flashcardRepository
          .getFlashcardCountByCategory('default-category');
      final testCount = await flashcardRepository
          .getFlashcardCountByCategory(testCategory.id);

      expect(defaultCount, 1);
      expect(testCount, 1);
    });

    test('should delete flashcards by category', () async {
      final testCategory = Category(name: 'Test Category');
      await categoryRepository.insertCategory(testCategory);

      final flashcard1 = Flashcard(
        question: 'Question 1',
        answer: 'Answer 1',
        categoryId: testCategory.id,
      );
      final flashcard2 = Flashcard(
        question: 'Question 2',
        answer: 'Answer 2',
        categoryId: testCategory.id,
      );

      await flashcardRepository.insertFlashcard(flashcard1);
      await flashcardRepository.insertFlashcard(flashcard2);

      await flashcardRepository.deleteFlashcardsByCategory(testCategory.id);

      final flashcards = await flashcardRepository
          .getFlashcardsByCategory(testCategory.id);
      expect(flashcards.length, 0);
    });

    test('should throw exception for invalid flashcard', () async {
      final invalidFlashcard = Flashcard(
        question: '',
        answer: '',
        categoryId: '',
      );

      expect(
        () => flashcardRepository.insertFlashcard(invalidFlashcard),
        throwsA(isA<FlashcardRepositoryException>()),
      );
    });

    test('should throw exception when updating non-existent flashcard', () async {
      final flashcard = Flashcard(
        id: 'non-existent-id',
        question: 'Test Question',
        answer: 'Test Answer',
        categoryId: 'default-category',
      );

      expect(
        () => flashcardRepository.updateFlashcard(flashcard),
        throwsA(isA<FlashcardRepositoryException>()),
      );
    });

    test('should throw exception when deleting non-existent flashcard', () async {
      expect(
        () => flashcardRepository.deleteFlashcard('non-existent-id'),
        throwsA(isA<FlashcardRepositoryException>()),
      );
    });
  });
}