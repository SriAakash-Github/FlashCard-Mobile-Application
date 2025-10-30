import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import '../models/flashcard.dart';
import '../controllers/flashcard_controller.dart';
import '../controllers/category_controller.dart';

class AddEditFlashcardScreen extends StatefulWidget {
  final Flashcard? flashcard;

  const AddEditFlashcardScreen({super.key, this.flashcard});

  @override
  State<AddEditFlashcardScreen> createState() => _AddEditFlashcardScreenState();
}

class _AddEditFlashcardScreenState extends State<AddEditFlashcardScreen> {
  final _formKey = GlobalKey<FormState>();
  final _questionController = TextEditingController();
  final _answerController = TextEditingController();
  
  late FlashcardController _flashcardController;
  late CategoryController _categoryController;
  
  String? _selectedCategoryId;
  bool _isLoading = false;

  bool get _isEditing => widget.flashcard != null;

  @override
  void initState() {
    super.initState();
    _flashcardController = FlashcardController();
    _categoryController = CategoryController();
    
    if (_isEditing) {
      _questionController.text = widget.flashcard!.question;
      _answerController.text = widget.flashcard!.answer;
      _selectedCategoryId = widget.flashcard!.categoryId;
    }
    
    _loadCategories();
  }

  @override
  void dispose() {
    _questionController.dispose();
    _answerController.dispose();
    _flashcardController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    await _categoryController.loadCategories();
    if (!_isEditing && _categoryController.categories.isNotEmpty) {
      // Set default category if creating new flashcard
      final defaultCategory = _categoryController.defaultCategory;
      if (defaultCategory != null) {
        setState(() {
          _selectedCategoryId = defaultCategory.id;
        });
      }
    }
  }

  Future<void> _saveFlashcard() async {
    if (_selectedCategoryId == null) {
      // Show error if no category is selected
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a category'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) {
      // Show error if form validation fails
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all required fields correctly'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final flashcard = _isEditing
          ? widget.flashcard!.copyWith(
              question: _questionController.text.trim(),
              answer: _answerController.text.trim(),
              categoryId: _selectedCategoryId!,
            )
          : Flashcard(
              question: _questionController.text.trim(),
              answer: _answerController.text.trim(),
              categoryId: _selectedCategoryId!,
            );

      final success = _isEditing
          ? await _flashcardController.updateFlashcard(flashcard)
          : await _flashcardController.addFlashcard(flashcard);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Flashcard saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_flashcardController.error ?? 'Failed to save flashcard'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Flashcard' : 'Add Flashcard'),
        actions: [
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            TextButton(
              onPressed: _saveFlashcard,
              child: Text(
                _isEditing ? 'UPDATE' : 'SAVE',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      body: AnimatedBuilder(
        animation: _categoryController,
        builder: (context, child) {
          if (_categoryController.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (_categoryController.error != null) {
            return FadeInUp(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    Text('Error loading categories: ${_categoryController.error}'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadCategories,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }

          return Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Category Selection with animation
                  FadeInUp(
                    duration: const Duration(milliseconds: 400),
                    child: Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Category',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<String>(
                              value: _selectedCategoryId,
                              decoration: InputDecoration(
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                filled: true,
                                fillColor: Colors.grey[100],
                                hintText: 'Select a category',
                                // Add error styling if no category is selected
                                errorStyle: _selectedCategoryId == null 
                                  ? const TextStyle(color: Colors.red, fontSize: 12) 
                                  : null,
                              ),
                              items: _categoryController.categories.map((category) {
                                return DropdownMenuItem<String>(
                                  value: category.id,
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 24,
                                        height: 24,
                                        decoration: BoxDecoration(
                                          color: category.colorValue,
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Center(
                                          child: Text(
                                            category.name.isNotEmpty 
                                                ? category.name[0].toUpperCase() 
                                                : '?',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Text(category.name),
                                    ],
                                  ),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedCategoryId = value;
                                });
                              },
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please select a category';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Question Field with animation
                  FadeInUp(
                    duration: const Duration(milliseconds: 500),
                    child: Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Question',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _questionController,
                              decoration: InputDecoration(
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                filled: true,
                                fillColor: Colors.grey[100],
                                hintText: 'Enter your question here...',
                              ),
                              maxLines: 3,
                              textCapitalization: TextCapitalization.sentences,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Question cannot be empty';
                                }
                                if (value.trim().length > 500) {
                                  return 'Question must be less than 500 characters';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Answer Field with animation
                  FadeInUp(
                    duration: const Duration(milliseconds: 600),
                    child: Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Answer',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _answerController,
                              decoration: InputDecoration(
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                filled: true,
                                fillColor: Colors.grey[100],
                                hintText: 'Enter your answer here...',
                              ),
                              maxLines: 4,
                              textCapitalization: TextCapitalization.sentences,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Answer cannot be empty';
                                }
                                if (value.trim().length > 1000) {
                                  return 'Answer must be less than 1000 characters';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Save Button with animation
                  FadeInUp(
                    duration: const Duration(milliseconds: 700),
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _saveFlashcard,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(
                              _isEditing ? 'UPDATE FLASHCARD' : 'CREATE FLASHCARD',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}