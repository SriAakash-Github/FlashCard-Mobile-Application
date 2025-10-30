import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:flashcards_app/models/category.dart';
import 'package:flashcards_app/models/flashcard.dart';
import 'package:flashcards_app/repositories/category_repository.dart';
import 'package:flashcards_app/repositories/flashcard_repository.dart';
import 'package:flashcards_app/services/database_service.dart';

void main() {
  group('CategoryRepository Tests', () {
    late CategoryRepository categoryRepository;
    late FlashcardRepository flashcardRepository;
    late DatabaseService databaseService;

    setUpAll(() {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    });

    setUp(() async {
      // Create a fresh database service for each test
      await DatabaseService.instance.deleteDatabase();
      databaseService = DatabaseService.instance;
      categoryRepository = CategoryRepositoryImpl(databaseService: databaseService);
      flashcardRepository = FlashcardRepositoryImpl(databaseService: databaseService);
      
      // Ensure database is initialized
      await databaseService.database;
    });

    tearDown(() async {
      await databaseService.close();
    });

    test('should have default category after initialization', () async {
      final categories = await categoryRepository.getAllCategories();
      expect(categories.length, 1);
      expect(categories.first.name, 'General');
      expect(categories.first.id, 'default-category');
    });

    test('should insert and retrieve category', () async {
      final category = Category(name: 'Math');

      await categoryRepository.insertCategory(category);
      final retrieved = await categoryRepository.getCategoryById(category.id);

      expect(retrieved, isNotNull);
      expect(retrieved!.name, category.name);
      expect(retrieved.id, category.id);
    });

    test('should get all categories', () async {
      final category1 = Category(name: 'Math');
      final category2 = Category(name: 'Science');

      await categoryRepository.insertCategory(category1);
      await categoryRepository.insertCategory(category2);

      final categories = await categoryRepository.getAllCategories();
      expect(categories.length, 3); // Including default category
      
      final names = categories.map((c) => c.name).toList();
      expect(names, contains('Math'));
      expect(names, contains('Science'));
      expect(names, contains('General'));
    });

    test('should get category by name', () async {
      final category = Category(name: 'History');
      await categoryRepository.insertCategory(category);

      final retrieved = await categoryRepository.getCategoryByName('History');
      expect(retrieved, isNotNull);
      expect(retrieved!.name, 'History');
    });

    test('should update category', () async {
      final category = Category(name: 'Original Name');
      await categoryRepository.insertCategory(category);

      final updated = category.copyWith(name: 'Updated Name');
      await categoryRepository.updateCategory(updated);

      final retrieved = await categoryRepository.getCategoryById(category.id);
      expect(retrieved!.name, 'Updated Name');
    });

    test('should delete category and its flashcards', () async {
      final category = Category(name: 'Test Category');
      await categoryRepository.insertCategory(category);

      // Add flashcards to the category
      final flashcard1 = Flashcard(
        question: 'Question 1',
        answer: 'Answer 1',
        categoryId: category.id,
      );
      final flashcard2 = Flashcard(
        question: 'Question 2',
        answer: 'Answer 2',
        categoryId: category.id,
      );

      await flashcardRepository.insertFlashcard(flashcard1);
      await flashcardRepository.insertFlashcard(flashcard2);

      // Delete category
      await categoryRepository.deleteCategory(category.id);

      // Verify category is deleted
      final retrievedCategory = await categoryRepository.getCategoryById(category.id);
      expect(retrievedCategory, isNull);

      // Verify flashcards are also deleted
      final flashcards = await flashcardRepository.getFlashcardsByCategory(category.id);
      expect(flashcards.length, 0);
    });

    test('should not allow deleting default category', () async {
      expect(
        () => categoryRepository.deleteCategory('default-category'),
        throwsA(isA<CategoryRepositoryException>()),
      );
    });

    test('should get category count', () async {
      final category1 = Category(name: 'Math');
      final category2 = Category(name: 'Science');

      await categoryRepository.insertCategory(category1);
      await categoryRepository.insertCategory(category2);

      final count = await categoryRepository.getCategoryCount();
      expect(count, 3); // Including default category
    });

    test('should check if category exists', () async {
      final category = Category(name: 'Physics');
      await categoryRepository.insertCategory(category);

      final exists = await categoryRepository.categoryExists('Physics');
      final notExists = await categoryRepository.categoryExists('Chemistry');

      expect(exists, true);
      expect(notExists, false);
    });

    test('should get categories with flashcard count', () async {
      final mathCategory = Category(name: 'Math');
      final scienceCategory = Category(name: 'Science');

      await categoryRepository.insertCategory(mathCategory);
      await categoryRepository.insertCategory(scienceCategory);

      // Add flashcards
      await flashcardRepository.insertFlashcard(Flashcard(
        question: 'Math Q1',
        answer: 'Math A1',
        categoryId: mathCategory.id,
      ));
      await flashcardRepository.insertFlashcard(Flashcard(
        question: 'Math Q2',
        answer: 'Math A2',
        categoryId: mathCategory.id,
      ));
      await flashcardRepository.insertFlashcard(Flashcard(
        question: 'Science Q1',
        answer: 'Science A1',
        categoryId: scienceCategory.id,
      ));

      final categoriesWithCount = await categoryRepository.getCategoriesWithFlashcardCount();
      expect(categoriesWithCount.length, 3); // Including default category

      final mathWithCount = categoriesWithCount.firstWhere(
        (c) => c.category.name == 'Math',
      );
      final scienceWithCount = categoriesWithCount.firstWhere(
        (c) => c.category.name == 'Science',
      );
      final generalWithCount = categoriesWithCount.firstWhere(
        (c) => c.category.name == 'General',
      );

      expect(mathWithCount.flashcardCount, 2);
      expect(scienceWithCount.flashcardCount, 1);
      expect(generalWithCount.flashcardCount, 0);
    });

    test('should not allow duplicate category names', () async {
      final category1 = Category(name: 'Duplicate');
      final category2 = Category(name: 'Duplicate');

      await categoryRepository.insertCategory(category1);

      expect(
        () => categoryRepository.insertCategory(category2),
        throwsA(isA<CategoryRepositoryException>()),
      );
    });

    test('should not allow updating to existing category name', () async {
      final category1 = Category(name: 'Category 1');
      final category2 = Category(name: 'Category 2');

      await categoryRepository.insertCategory(category1);
      await categoryRepository.insertCategory(category2);

      final updated = category2.copyWith(name: 'Category 1');

      expect(
        () => categoryRepository.updateCategory(updated),
        throwsA(isA<CategoryRepositoryException>()),
      );
    });

    test('should throw exception for invalid category', () async {
      final invalidCategory = Category(name: '');

      expect(
        () => categoryRepository.insertCategory(invalidCategory),
        throwsA(isA<CategoryRepositoryException>()),
      );
    });

    test('should throw exception when updating non-existent category', () async {
      final category = Category(
        id: 'non-existent-id',
        name: 'Test Category',
      );

      expect(
        () => categoryRepository.updateCategory(category),
        throwsA(isA<CategoryRepositoryException>()),
      );
    });

    test('should throw exception when deleting non-existent category', () async {
      expect(
        () => categoryRepository.deleteCategory('non-existent-id'),
        throwsA(isA<CategoryRepositoryException>()),
      );
    });
  });
}