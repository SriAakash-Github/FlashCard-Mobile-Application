import 'package:flutter/foundation.dart';
import '../models/category.dart' as model;
import '../repositories/category_repository.dart';

class CategoryController extends ChangeNotifier {
  final CategoryRepository _categoryRepository;

  CategoryController({CategoryRepository? categoryRepository})
      : _categoryRepository = categoryRepository ?? CategoryRepositoryImpl();

  List<model.Category> _categories = [];
  List<CategoryWithCount> _categoriesWithCount = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  List<model.Category> get categories => _categories;
  List<CategoryWithCount> get categoriesWithCount => _categoriesWithCount;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get categoryCount => _categories.length;
  bool get hasCategories => _categories.isNotEmpty;

  // Load all categories
  Future<void> loadCategories() async {
    await _performAsyncOperation(() async {
      _categories = await _categoryRepository.getAllCategories();
    });
  }

  // Load categories with flashcard counts
  Future<void> loadCategoriesWithCount() async {
    await _performAsyncOperation(() async {
      _categoriesWithCount = await _categoryRepository.getCategoriesWithFlashcardCount();
      _categories = _categoriesWithCount.map((c) => c.category).toList();
    });
  }

  // Add new category
  Future<bool> addCategory(model.Category category) async {
    try {
      _setLoading(true);
      _clearError();

      await _categoryRepository.insertCategory(category);
      await loadCategoriesWithCount(); // Refresh the list
      
      return true;
    } catch (e) {
      _setError('Failed to add category: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Update existing category
  Future<bool> updateCategory(model.Category category) async {
    try {
      _setLoading(true);
      _clearError();

      await _categoryRepository.updateCategory(category);
      
      // Update local lists
      final index = _categories.indexWhere((c) => c.id == category.id);
      if (index != -1) {
        _categories[index] = category;
        
        // Update categories with count list
        final countIndex = _categoriesWithCount.indexWhere((c) => c.category.id == category.id);
        if (countIndex != -1) {
          _categoriesWithCount[countIndex] = CategoryWithCount(
            category: category,
            flashcardCount: _categoriesWithCount[countIndex].flashcardCount,
          );
        }
        
        notifyListeners();
      }
      
      return true;
    } catch (e) {
      _setError('Failed to update category: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Delete category
  Future<bool> deleteCategory(String categoryId) async {
    try {
      _setLoading(true);
      _clearError();

      await _categoryRepository.deleteCategory(categoryId);
      
      // Remove from local lists
      _categories.removeWhere((c) => c.id == categoryId);
      _categoriesWithCount.removeWhere((c) => c.category.id == categoryId);
      notifyListeners();
      
      return true;
    } catch (e) {
      _setError('Failed to delete category: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Get category by ID
  Future<model.Category?> getCategoryById(String id) async {
    try {
      return await _categoryRepository.getCategoryById(id);
    } catch (e) {
      _setError('Failed to get category: ${e.toString()}');
      return null;
    }
  }

  // Get category by name
  Future<model.Category?> getCategoryByName(String name) async {
    try {
      return await _categoryRepository.getCategoryByName(name);
    } catch (e) {
      _setError('Failed to get category: ${e.toString()}');
      return null;
    }
  }

  // Check if category name exists
  Future<bool> categoryNameExists(String name, {String? excludeId}) async {
    try {
      final category = await _categoryRepository.getCategoryByName(name);
      if (category == null) return false;
      if (excludeId != null && category.id == excludeId) return false;
      return true;
    } catch (e) {
      _setError('Failed to check category name: ${e.toString()}');
      return false;
    }
  }

  // Validate category data
  Map<String, String?> validateCategory(String name, {String? excludeId}) {
    final category = model.Category(name: name);
    
    return {
      'name': category.validateName(),
    };
  }

  // Validate category name uniqueness
  Future<String?> validateCategoryNameUniqueness(String name, {String? excludeId}) async {
    if (await categoryNameExists(name, excludeId: excludeId)) {
      return 'Category name already exists';
    }
    return null;
  }

  // Get default category
  model.Category? get defaultCategory {
    try {
      return _categories.firstWhere((c) => c.id == 'default-category');
    } catch (e) {
      return null;
    }
  }

  // Get category with count by ID
  CategoryWithCount? getCategoryWithCountById(String id) {
    try {
      return _categoriesWithCount.firstWhere((c) => c.category.id == id);
    } catch (e) {
      return null;
    }
  }

  // Get total flashcard count across all categories
  int get totalFlashcardCount {
    return _categoriesWithCount.fold(0, (sum, category) => sum + category.flashcardCount);
  }

  // Get categories sorted by name
  List<model.Category> get categoriesSortedByName {
    final sorted = List<model.Category>.from(_categories);
    sorted.sort((a, b) => a.name.compareTo(b.name));
    return sorted;
  }

  // Get categories sorted by flashcard count (descending)
  List<CategoryWithCount> get categoriesSortedByCount {
    final sorted = List<CategoryWithCount>.from(_categoriesWithCount);
    sorted.sort((a, b) => b.flashcardCount.compareTo(a.flashcardCount));
    return sorted;
  }

  // Clear all data
  void clear() {
    _categories.clear();
    _categoriesWithCount.clear();
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