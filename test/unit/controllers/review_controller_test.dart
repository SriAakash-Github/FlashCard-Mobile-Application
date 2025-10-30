import 'package:flutter_test/flutter_test.dart';
import 'package:flashcards_app/controllers/review_controller.dart';
import 'package:flashcards_app/models/flashcard.dart';

void main() {
  group('ReviewController Tests', () {
    late ReviewController controller;
    late List<Flashcard> testFlashcards;

    setUp(() {
      controller = ReviewController();
      testFlashcards = [
        Flashcard(
          id: '1',
          question: 'Question 1',
          answer: 'Answer 1',
          categoryId: 'category-1',
        ),
        Flashcard(
          id: '2',
          question: 'Question 2',
          answer: 'Answer 2',
          categoryId: 'category-1',
        ),
        Flashcard(
          id: '3',
          question: 'Question 3',
          answer: 'Answer 3',
          categoryId: 'category-1',
        ),
      ];
    });

    test('should initialize with empty state', () {
      expect(controller.flashcards, isEmpty);
      expect(controller.currentIndex, 0);
      expect(controller.isFlipped, false);
      expect(controller.reviewMode, ReviewMode.sequential);
      expect(controller.currentFlashcard, isNull);
      expect(controller.totalCards, 0);
      expect(controller.hasCards, false);
    });

    test('should initialize review session correctly', () {
      controller.initializeReview(testFlashcards, categoryId: 'category-1');

      expect(controller.flashcards.length, 3);
      expect(controller.categoryId, 'category-1');
      expect(controller.currentIndex, 0);
      expect(controller.isFlipped, false);
      expect(controller.totalCards, 3);
      expect(controller.hasCards, true);
      expect(controller.currentFlashcard?.id, '1');
    });

    test('should flip card correctly', () {
      controller.initializeReview(testFlashcards);

      expect(controller.isFlipped, false);

      controller.flipCard();
      expect(controller.isFlipped, true);

      controller.flipCard();
      expect(controller.isFlipped, false);
    });

    test('should show question and answer correctly', () {
      controller.initializeReview(testFlashcards);
      controller.flipCard(); // Start with answer showing

      controller.showQuestion();
      expect(controller.isFlipped, false);

      controller.showAnswer();
      expect(controller.isFlipped, true);
    });

    test('should navigate to next card correctly', () {
      controller.initializeReview(testFlashcards);

      expect(controller.currentIndex, 0);
      expect(controller.canGoNext(), true);

      final result = controller.nextCard();
      expect(result, true);
      expect(controller.currentIndex, 1);
      expect(controller.isFlipped, false);
      expect(controller.currentFlashcard?.id, '2');
    });

    test('should navigate to previous card correctly', () {
      controller.initializeReview(testFlashcards);
      controller.nextCard(); // Go to second card

      expect(controller.currentIndex, 1);
      expect(controller.canGoPrevious(), true);

      final result = controller.previousCard();
      expect(result, true);
      expect(controller.currentIndex, 0);
      expect(controller.isFlipped, false);
      expect(controller.currentFlashcard?.id, '1');
    });

    test('should handle navigation boundaries correctly', () {
      controller.initializeReview(testFlashcards);

      // At first card, can't go previous
      expect(controller.canGoPrevious(), false);
      expect(controller.previousCard(), false);

      // Go to last card
      controller.goToLast();
      expect(controller.canGoNext(), false);
      expect(controller.nextCard(), false);
    });

    test('should go to specific card correctly', () {
      controller.initializeReview(testFlashcards);

      final result = controller.goToCard(2);
      expect(result, true);
      expect(controller.currentIndex, 2);
      expect(controller.currentFlashcard?.id, '3');

      // Invalid index
      final invalidResult = controller.goToCard(5);
      expect(invalidResult, false);
    });

    test('should go to first and last card correctly', () {
      controller.initializeReview(testFlashcards);
      controller.nextCard(); // Move away from first

      controller.goToFirst();
      expect(controller.currentIndex, 0);
      expect(controller.isFlipped, false);

      controller.goToLast();
      expect(controller.currentIndex, 2);
      expect(controller.isFlipped, false);
    });

    test('should calculate progress correctly', () {
      controller.initializeReview(testFlashcards);

      expect(controller.currentPosition, 1);
      expect(controller.progress, closeTo(0.33, 0.01));

      controller.nextCard();
      expect(controller.currentPosition, 2);
      expect(controller.progress, closeTo(0.67, 0.01));

      controller.nextCard();
      expect(controller.currentPosition, 3);
      expect(controller.progress, 1.0);
    });

    test('should track remaining and completed cards', () {
      controller.initializeReview(testFlashcards);

      expect(controller.completedCards, 0);
      expect(controller.remainingCards, 2);

      controller.nextCard();
      expect(controller.completedCards, 1);
      expect(controller.remainingCards, 1);

      controller.nextCard();
      expect(controller.completedCards, 2);
      expect(controller.remainingCards, 0);
    });

    test('should detect review completion', () {
      controller.initializeReview(testFlashcards);

      expect(controller.isReviewComplete, false);

      controller.goToLast();
      expect(controller.isReviewComplete, true);
    });

    test('should restart review correctly', () {
      controller.initializeReview(testFlashcards);
      controller.nextCard();
      controller.flipCard();

      controller.restart();

      expect(controller.currentIndex, 0);
      expect(controller.isFlipped, false);
    });

    test('should set review mode correctly', () {
      controller.initializeReview(testFlashcards);

      expect(controller.reviewMode, ReviewMode.sequential);

      controller.setReviewMode(ReviewMode.random);
      expect(controller.reviewMode, ReviewMode.random);
    });

    test('should update flashcard in session', () {
      controller.initializeReview(testFlashcards);

      final updatedFlashcard = testFlashcards[0].copyWith(
        question: 'Updated Question',
      );

      controller.updateFlashcard(updatedFlashcard);

      expect(controller.currentFlashcard?.question, 'Updated Question');
    });

    test('should remove flashcard from session', () {
      controller.initializeReview(testFlashcards);

      controller.removeFlashcard('2');

      expect(controller.totalCards, 2);
      expect(controller.flashcards.any((f) => f.id == '2'), false);
    });

    test('should add flashcard to session', () {
      controller.initializeReview(testFlashcards, categoryId: 'category-1');

      final newFlashcard = Flashcard(
        id: '4',
        question: 'Question 4',
        answer: 'Answer 4',
        categoryId: 'category-1',
      );

      controller.addFlashcard(newFlashcard);

      expect(controller.totalCards, 4);
      expect(controller.flashcards.any((f) => f.id == '4'), true);
    });

    test('should not add flashcard from different category', () {
      controller.initializeReview(testFlashcards, categoryId: 'category-1');

      final newFlashcard = Flashcard(
        id: '4',
        question: 'Question 4',
        answer: 'Answer 4',
        categoryId: 'category-2',
      );

      controller.addFlashcard(newFlashcard);

      expect(controller.totalCards, 3); // Should not be added
    });

    test('should get review statistics correctly', () {
      controller.initializeReview(testFlashcards, categoryId: 'category-1');
      controller.nextCard();

      final stats = controller.getReviewStats();

      expect(stats['totalCards'], 3);
      expect(stats['currentPosition'], 2);
      expect(stats['completedCards'], 1);
      expect(stats['remainingCards'], 1);
      expect(stats['categoryId'], 'category-1');
    });

    test('should clear session correctly', () {
      controller.initializeReview(testFlashcards, categoryId: 'category-1');

      controller.clear();

      expect(controller.flashcards, isEmpty);
      expect(controller.currentIndex, 0);
      expect(controller.isFlipped, false);
      expect(controller.categoryId, isNull);
    });

    test('should handle empty flashcard list', () {
      controller.initializeReview([]);

      expect(controller.currentFlashcard, isNull);
      expect(controller.totalCards, 0);
      expect(controller.hasCards, false);
      expect(controller.canGoNext(), false);
      expect(controller.canGoPrevious(), false);
    });

    test('should notify listeners on state changes', () {
      bool notified = false;
      controller.addListener(() {
        notified = true;
      });

      controller.initializeReview(testFlashcards);

      expect(notified, true);
    });
  });
}