import 'package:flutter/foundation.dart';
import '../models/flashcard.dart';

enum ReviewMode {
  sequential,
  random,
}

class ReviewController extends ChangeNotifier {
  List<Flashcard> _flashcards = [];
  int _currentIndex = 0;
  bool _isFlipped = false;
  ReviewMode _reviewMode = ReviewMode.sequential;
  List<int> _reviewOrder = [];
  String? _categoryId;

  // Getters
  List<Flashcard> get flashcards => _flashcards;
  int get currentIndex => _currentIndex;
  bool get isFlipped => _isFlipped;
  ReviewMode get reviewMode => _reviewMode;
  String? get categoryId => _categoryId;
  
  // Current flashcard
  Flashcard? get currentFlashcard {
    if (_flashcards.isEmpty || _currentIndex < 0 || _currentIndex >= _flashcards.length) {
      return null;
    }
    final actualIndex = _reviewOrder.isNotEmpty ? _reviewOrder[_currentIndex] : _currentIndex;
    return _flashcards[actualIndex];
  }

  // Progress information
  int get totalCards => _flashcards.length;
  int get currentPosition => _currentIndex + 1;
  double get progress => _flashcards.isEmpty ? 0.0 : (currentPosition / totalCards);
  bool get isFirstCard => _currentIndex == 0;
  bool get isLastCard => _currentIndex == _flashcards.length - 1;
  bool get hasCards => _flashcards.isNotEmpty;

  // Initialize review session
  void initializeReview(List<Flashcard> flashcards, {String? categoryId, ReviewMode? mode}) {
    _flashcards = List.from(flashcards);
    _categoryId = categoryId;
    _currentIndex = 0;
    _isFlipped = false;
    _reviewMode = mode ?? ReviewMode.sequential;
    
    _setupReviewOrder();
    notifyListeners();
  }

  // Set up the order of review based on mode
  void _setupReviewOrder() {
    _reviewOrder = List.generate(_flashcards.length, (index) => index);
    
    if (_reviewMode == ReviewMode.random) {
      _reviewOrder.shuffle();
    }
  }

  // Change review mode
  void setReviewMode(ReviewMode mode) {
    if (_reviewMode != mode) {
      _reviewMode = mode;
      _setupReviewOrder();
      notifyListeners();
    }
  }

  // Flip the current card
  void flipCard() {
    _isFlipped = !_isFlipped;
    notifyListeners();
  }

  // Show question side
  void showQuestion() {
    if (_isFlipped) {
      _isFlipped = false;
      notifyListeners();
    }
  }

  // Show answer side
  void showAnswer() {
    if (!_isFlipped) {
      _isFlipped = true;
      notifyListeners();
    }
  }

  // Navigate to next card
  bool nextCard() {
    if (canGoNext()) {
      _currentIndex++;
      _isFlipped = false;
      notifyListeners();
      return true;
    }
    return false;
  }

  // Navigate to previous card
  bool previousCard() {
    if (canGoPrevious()) {
      _currentIndex--;
      _isFlipped = false;
      notifyListeners();
      return true;
    }
    return false;
  }

  // Go to specific card index
  bool goToCard(int index) {
    if (index >= 0 && index < _flashcards.length) {
      _currentIndex = index;
      _isFlipped = false;
      notifyListeners();
      return true;
    }
    return false;
  }

  // Go to first card
  void goToFirst() {
    if (_flashcards.isNotEmpty) {
      _currentIndex = 0;
      _isFlipped = false;
      notifyListeners();
    }
  }

  // Go to last card
  void goToLast() {
    if (_flashcards.isNotEmpty) {
      _currentIndex = _flashcards.length - 1;
      _isFlipped = false;
      notifyListeners();
    }
  }

  // Check if can go to next card
  bool canGoNext() {
    return _currentIndex < _flashcards.length - 1;
  }

  // Check if can go to previous card
  bool canGoPrevious() {
    return _currentIndex > 0;
  }

  // Restart review session
  void restart() {
    _currentIndex = 0;
    _isFlipped = false;
    if (_reviewMode == ReviewMode.random) {
      _setupReviewOrder();
    }
    notifyListeners();
  }

  // Shuffle cards (only in random mode)
  void shuffleCards() {
    if (_reviewMode == ReviewMode.random) {
      _setupReviewOrder();
      notifyListeners();
    }
  }

  // Get remaining cards count
  int get remainingCards => _flashcards.length - _currentIndex - 1;

  // Get completed cards count
  int get completedCards => _currentIndex;

  // Check if review is complete
  bool get isReviewComplete => _currentIndex >= _flashcards.length - 1 && _flashcards.isNotEmpty;

  // Get review statistics
  Map<String, dynamic> getReviewStats() {
    return {
      'totalCards': totalCards,
      'currentPosition': currentPosition,
      'completedCards': completedCards,
      'remainingCards': remainingCards,
      'progress': progress,
      'reviewMode': _reviewMode.toString(),
      'categoryId': _categoryId,
    };
  }

  // Clear review session
  void clear() {
    _flashcards.clear();
    _reviewOrder.clear();
    _currentIndex = 0;
    _isFlipped = false;
    _categoryId = null;
    notifyListeners();
  }

  // Update flashcard in current session (if it was edited)
  void updateFlashcard(Flashcard updatedFlashcard) {
    final index = _flashcards.indexWhere((f) => f.id == updatedFlashcard.id);
    if (index != -1) {
      _flashcards[index] = updatedFlashcard;
      notifyListeners();
    }
  }

  // Remove flashcard from current session (if it was deleted)
  void removeFlashcard(String flashcardId) {
    final index = _flashcards.indexWhere((f) => f.id == flashcardId);
    if (index != -1) {
      _flashcards.removeAt(index);
      
      // Adjust current index if necessary
      if (_currentIndex >= _flashcards.length && _flashcards.isNotEmpty) {
        _currentIndex = _flashcards.length - 1;
      } else if (_flashcards.isEmpty) {
        _currentIndex = 0;
      }
      
      // Rebuild review order
      _setupReviewOrder();
      _isFlipped = false;
      notifyListeners();
    }
  }

  // Add flashcard to current session
  void addFlashcard(Flashcard flashcard) {
    if (_categoryId == null || flashcard.categoryId == _categoryId) {
      _flashcards.add(flashcard);
      _setupReviewOrder();
      notifyListeners();
    }
  }
}