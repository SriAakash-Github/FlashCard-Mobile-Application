import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import '../controllers/category_controller.dart';
import '../controllers/flashcard_controller.dart';
import 'add_edit_flashcard_screen.dart';
import 'flashcard_list_screen.dart' as flashcard_list;
import 'flashcard_review_screen.dart' as flashcard_review;
import 'category_management_screen.dart' as category_management;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late CategoryController _categoryController;
  late FlashcardController _flashcardController;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _categoryController = CategoryController();
    _flashcardController = FlashcardController();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _loadData();
  }

  @override
  void dispose() {
    _categoryController.dispose();
    _flashcardController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    await _categoryController.loadCategoriesWithCount();
    if (mounted) {
      _animationController.forward();
    }
  }

  Future<void> _refreshData() async {
    await _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flashcards'),
        actions: [
          IconButton(
            icon: const Icon(Icons.category),
            onPressed: () => _navigateToCategories(),
            tooltip: 'Manage Categories',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: AnimatedBuilder(
          animation: _categoryController,
          builder: (context, child) {
            if (_categoryController.isLoading) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            if (_categoryController.error != null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Error loading categories',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _categoryController.error!,
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _refreshData,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            final categoriesWithCount = _categoryController.categoriesWithCount;

            if (categoriesWithCount.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.folder_open,
                      size: 64,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No categories found',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Create your first category to get started',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => _navigateToCategories(),
                      child: const Text('Manage Categories'),
                    ),
                  ],
                ),
              );
            }

            return Column(
              children: [
                // Summary Card with animation
                Container(
                  margin: const EdgeInsets.all(16),
                  child: Card(
                    elevation: 6,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Total Flashcards',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '${_categoryController.totalFlashcardCount}',
                                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                                        color: Theme.of(context).colorScheme.primary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            height: 60,
                            width: 1,
                            color: Colors.grey[300],
                            margin: const EdgeInsets.symmetric(horizontal: 16),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Categories',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '${categoriesWithCount.length}',
                                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                                        color: Theme.of(context).colorScheme.secondary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Categories List with staggered animations
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: categoriesWithCount.length,
                    itemBuilder: (context, index) {
                      final categoryWithCount = categoriesWithCount[index];
                      final category = categoryWithCount.category;
                      final count = categoryWithCount.flashcardCount;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: ListTile(
                          leading: Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: category.colorValue,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text(
                                category.name.isNotEmpty ? category.name[0].toUpperCase() : '?',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                ),
                              ),
                            ),
                          ),
                          title: Text(
                            category.name,
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          subtitle: Text(
                            '$count flashcard${count == 1 ? '' : 's'}',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Colors.grey[600],
                                ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (count > 0)
                                IconButton(
                                  icon: const Icon(Icons.play_arrow_rounded),
                                  onPressed: () => _startReview(category.id),
                                  tooltip: 'Start Review',
                                ),
                              IconButton(
                                icon: const Icon(Icons.list_rounded),
                                onPressed: () => _viewFlashcards(category.id, category.name),
                                tooltip: 'View Flashcards',
                              ),
                            ],
                          ),
                          onTap: () => _viewFlashcards(category.id, category.name),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addFlashcard,
        tooltip: 'Add Flashcard',
        child: const Icon(Icons.add),
      ),
    );
  }

  void _addFlashcard() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const AddEditFlashcardScreen(),
      ),
    ).then((_) => _refreshData());
  }

  void _viewFlashcards(String categoryId, String categoryName) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => flashcard_list.FlashcardListScreen(
          categoryId: categoryId,
          categoryName: categoryName,
        ),
      ),
    ).then((_) => _refreshData());
  }

  void _startReview(String categoryId) async {
    // Load flashcards for the category
    await _flashcardController.loadFlashcardsByCategory(categoryId);
    
    if (!mounted) return;

    if (_flashcardController.flashcards.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No flashcards available for review'),
        ),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => flashcard_review.FlashcardReviewScreen(
          flashcards: _flashcardController.flashcards,
          categoryId: categoryId,
        ),
      ),
    ).then((_) => _refreshData());
  }

  void _navigateToCategories() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const category_management.CategoryManagementScreen(),
      ),
    ).then((_) => _refreshData());
  }
}