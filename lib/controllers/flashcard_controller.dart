import 'package:flutter/foundation.dart';
import '../models/flashcard.dart';
import '../repositories/flashcard_repository.dart';

class FlashcardController extends ChangeNotifier {
  final FlashcardRepository _flashcardRepository;

  FlashcardController({FlashcardRepository? flashcardRepository})
      : _flashcardRepository = flashcardRepository ?? FlashcardRepositoryImpl();

  List<Flashcard> _flashcards = [];
  List<Flashcard> _filteredFlashcards = [];
  bool _isLoading = false;
  String? _error;
  String? _currentCategoryId;

  // Getters
  List<Flashcard> get flashcards => _filteredFlashcards;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get currentCategoryId => _currentCategoryId;
  int get flashcardCount => _filteredFlashcards.length;
  bool get hasFlashcards => _filteredFlashcards.isNotEmpty;

  // Load all flashcards
  Future<void> loadAllFlashcards() async {
    await _performAsyncOperation(() async {
      _flashcards = await _flashcardRepository.getAllFlashcards();
      _filteredFlashcards = List.from(_flashcards);
      _currentCategoryId = null;
    });
  }

  // Load flashcards by category
  Future<void> loadFlashcardsByCategory(String categoryId) async {
    await _performAsyncOperation(() async {
      _flashcards = await _flashcardRepository.getFlashcardsByCategory(categoryId);
      _filteredFlashcards = List.from(_flashcards);
      _currentCategoryId = categoryId;
    });
  }

  // Add new flashcard
  Future<bool> addFlashcard(Flashcard flashcard) async {
    try {
      _setLoading(true);
      _clearError();

      await _flashcardRepository.insertFlashcard(flashcard);
      
      // Refresh the current view
      if (_currentCategoryId != null) {
        await loadFlashcardsByCategory(_currentCategoryId!);
      } else {
        await loadAllFlashcards();
      }
      
      return true;
    } catch (e) {
      _setError('Failed to add flashcard: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Update existing flashcard
  Future<bool> updateFlashcard(Flashcard flashcard) async {
    try {
      _setLoading(true);
      _clearError();

      await _flashcardRepository.updateFlashcard(flashcard);
      
      // Update local list
      final index = _flashcards.indexWhere((f) => f.id == flashcard.id);
      if (index != -1) {
        _flashcards[index] = flashcard;
        _filteredFlashcards = List.from(_flashcards);
        notifyListeners();
      }
      
      return true;
    } catch (e) {
      _setError('Failed to update flashcard: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Delete flashcard
  Future<bool> deleteFlashcard(String flashcardId) async {
    try {
      _setLoading(true);
      _clearError();

      await _flashcardRepository.deleteFlashcard(flashcardId);
      
      // Remove from local lists
      _flashcards.removeWhere((f) => f.id == flashcardId);
      _filteredFlashcards.removeWhere((f) => f.id == flashcardId);
      notifyListeners();
      
      return true;
    } catch (e) {
      _setError('Failed to delete flashcard: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Get flashcard by ID
  Future<Flashcard?> getFlashcardById(String id) async {
    try {
      return await _flashcardRepository.getFlashcardById(id);
    } catch (e) {
      _setError('Failed to get flashcard: ${e.toString()}');
      return null;
    }
  }

  // Search flashcards
  void searchFlashcards(String query) {
    if (query.isEmpty) {
      _filteredFlashcards = List.from(_flashcards);
    } else {
      final lowercaseQuery = query.toLowerCase();
      _filteredFlashcards = _flashcards.where((flashcard) {
        return flashcard.question.toLowerCase().contains(lowercaseQuery) ||
               flashcard.answer.toLowerCase().contains(lowercaseQuery);
      }).toList();
    }
    notifyListeners();
  }

  // Clear search and show all flashcards
  void clearSearch() {
    _filteredFlashcards = List.from(_flashcards);
    notifyListeners();
  }

  // Get flashcard count for category
  Future<int> getFlashcardCountByCategory(String categoryId) async {
    try {
      return await _flashcardRepository.getFlashcardCountByCategory(categoryId);
    } catch (e) {
      _setError('Failed to get flashcard count: ${e.toString()}');
      return 0;
    }
  }

  // Validate flashcard data
  Map<String, String?> validateFlashcard(String question, String answer, String categoryId) {
    final flashcard = Flashcard(
      question: question,
      answer: answer,
      categoryId: categoryId,
    );

    return {
      'question': flashcard.validateQuestion(),
      'answer': flashcard.validateAnswer(),
      'category': categoryId.isEmpty ? 'Please select a category' : null,
    };
  }

  // Clear all data
  void clear() {
    _flashcards.clear();
    _filteredFlashcards.clear();
    _currentCategoryId = null;
    _clearError();
    notifyListeners();
  }

  // Private helper methods
  Future<void> _performAsyncOperation(Future<void> Function() operation) async {
    try {
      _setLoading(true);
      _clearError();
      await operation();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
    }
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    if (_error != null) {
      _error = null;
      notifyListeners();
    }
  }
}