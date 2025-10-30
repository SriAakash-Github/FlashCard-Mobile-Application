import 'package:flutter_test/flutter_test.dart';
import 'package:flashcards_app/models/flashcard.dart';

void main() {
  group('Flashcard Model Tests', () {
    test('should create flashcard with required fields', () {
      final flashcard = Flashcard(
        question: 'What is Flutter?',
        answer: 'A UI toolkit for building apps',
        categoryId: 'category-1',
      );

      expect(flashcard.question, 'What is Flutter?');
      expect(flashcard.answer, 'A UI toolkit for building apps');
      expect(flashcard.categoryId, 'category-1');
      expect(flashcard.id, isNotEmpty);
      expect(flashcard.createdAt, isA<DateTime>());
      expect(flashcard.updatedAt, isA<DateTime>());
    });

    test('should create flashcard with custom id and dates', () {
      final createdAt = DateTime(2023, 1, 1);
      final updatedAt = DateTime(2023, 1, 2);
      
      final flashcard = Flashcard(
        id: 'custom-id',
        question: 'Test question',
        answer: 'Test answer',
        categoryId: 'category-1',
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

      expect(flashcard.id, 'custom-id');
      expect(flashcard.createdAt, createdAt);
      expect(flashcard.updatedAt, updatedAt);
    });

    test('should copy flashcard with updated fields', () {
      final original = Flashcard(
        question: 'Original question',
        answer: 'Original answer',
        categoryId: 'category-1',
      );

      // Add a small delay to ensure different timestamps
      Future.delayed(const Duration(milliseconds: 1));

      final updated = original.copyWith(
        question: 'Updated question',
        answer: 'Updated answer',
      );

      expect(updated.id, original.id);
      expect(updated.question, 'Updated question');
      expect(updated.answer, 'Updated answer');
      expect(updated.categoryId, original.categoryId);
      expect(updated.createdAt, original.createdAt);
      expect(updated.updatedAt.isAfter(original.updatedAt) || 
             updated.updatedAt.isAtSameMomentAs(original.updatedAt), true);
    });

    test('should convert to and from map correctly', () {
      final flashcard = Flashcard(
        id: 'test-id',
        question: 'Test question',
        answer: 'Test answer',
        categoryId: 'category-1',
        createdAt: DateTime(2023, 1, 1),
        updatedAt: DateTime(2023, 1, 2),
      );

      final map = flashcard.toMap();
      final fromMap = Flashcard.fromMap(map);

      expect(fromMap.id, flashcard.id);
      expect(fromMap.question, flashcard.question);
      expect(fromMap.answer, flashcard.answer);
      expect(fromMap.categoryId, flashcard.categoryId);
      expect(fromMap.createdAt, flashcard.createdAt);
      expect(fromMap.updatedAt, flashcard.updatedAt);
    });

    test('should validate correctly', () {
      final validFlashcard = Flashcard(
        question: 'Valid question',
        answer: 'Valid answer',
        categoryId: 'category-1',
      );

      final invalidFlashcard = Flashcard(
        question: '',
        answer: '',
        categoryId: '',
      );

      expect(validFlashcard.isValid(), true);
      expect(invalidFlashcard.isValid(), false);
    });

    test('should validate question field', () {
      final flashcard = Flashcard(
        question: '',
        answer: 'Valid answer',
        categoryId: 'category-1',
      );

      expect(flashcard.validateQuestion(), 'Question cannot be empty');

      final longQuestion = 'a' * 501;
      final flashcardLong = flashcard.copyWith(question: longQuestion);
      expect(flashcardLong.validateQuestion(), 'Question must be less than 500 characters');

      final validFlashcard = flashcard.copyWith(question: 'Valid question');
      expect(validFlashcard.validateQuestion(), null);
    });

    test('should validate answer field', () {
      final flashcard = Flashcard(
        question: 'Valid question',
        answer: '',
        categoryId: 'category-1',
      );

      expect(flashcard.validateAnswer(), 'Answer cannot be empty');

      final longAnswer = 'a' * 1001;
      final flashcardLong = flashcard.copyWith(answer: longAnswer);
      expect(flashcardLong.validateAnswer(), 'Answer must be less than 1000 characters');

      final validFlashcard = flashcard.copyWith(answer: 'Valid answer');
      expect(validFlashcard.validateAnswer(), null);
    });

    test('should implement equality correctly', () {
      final flashcard1 = Flashcard(
        id: 'same-id',
        question: 'Question 1',
        answer: 'Answer 1',
        categoryId: 'category-1',
      );

      final flashcard2 = Flashcard(
        id: 'same-id',
        question: 'Question 2',
        answer: 'Answer 2',
        categoryId: 'category-2',
      );

      final flashcard3 = Flashcard(
        id: 'different-id',
        question: 'Question 1',
        answer: 'Answer 1',
        categoryId: 'category-1',
      );

      expect(flashcard1, flashcard2); // Same ID
      expect(flashcard1, isNot(flashcard3)); // Different ID
    });
  });
}