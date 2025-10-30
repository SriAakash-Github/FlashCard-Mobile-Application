import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import '../models/flashcard.dart';
import '../controllers/flashcard_controller.dart';
import 'add_edit_flashcard_screen.dart' as add_edit;
import 'flashcard_review_screen.dart' as review;

class FlashcardListScreen extends StatefulWidget {
  final String categoryId;
  final String categoryName;

  const FlashcardListScreen({
    super.key,
    required this.categoryId,
    required this.categoryName,
  });

  @override
  State<FlashcardListScreen> createState() => _FlashcardListScreenState();
}

class _FlashcardListScreenState extends State<FlashcardListScreen> {
  late FlashcardController _flashcardController;
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _flashcardController = FlashcardController();
    _loadFlashcards();
  }

  @override
  void dispose() {
    _flashcardController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadFlashcards() async {
    await _flashcardController.loadFlashcardsByCategory(widget.categoryId);
  }

  Future<void> _refreshFlashcards() async {
    await _loadFlashcards();
  }

  void _startSearch() {
    setState(() {
      _isSearching = true;
    });
  }

  void _stopSearch() {
    setState(() {
      _isSearching = false;
      _searchController.clear();
    });
    _flashcardController.clearSearch();
  }

  void _onSearchChanged(String query) {
    _flashcardController.searchFlashcards(query);
  }

  void _addFlashcard() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const add_edit.AddEditFlashcardScreen(),
      ),
    ).then((result) {
      if (result == true) {
        _refreshFlashcards();
      }
    });
  }

  void _editFlashcard(Flashcard flashcard) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => add_edit.AddEditFlashcardScreen(flashcard: flashcard),
      ),
    ).then((result) {
      if (result == true) {
        _refreshFlashcards();
      }
    });
  }

  void _deleteFlashcard(Flashcard flashcard) {
    showDialog(
      context: context,
      builder: (context) => ZoomIn(
        child: AlertDialog(
          title: const Text('Delete Flashcard'),
          content: const Text('Are you sure you want to delete this flashcard? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                final success = await _flashcardController.deleteFlashcard(flashcard.id);
                if (success && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Flashcard deleted'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } else if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(_flashcardController.error ?? 'Failed to delete flashcard'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        ),
      ),
    );
  }

  void _showFlashcardOptions(Flashcard flashcard) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
              margin: const EdgeInsets.only(bottom: 16),
            ),
            FadeInUp(
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.edit, color: Colors.blue),
                ),
                title: const Text('Edit'),
                onTap: () {
                  Navigator.of(context).pop();
                  _editFlashcard(flashcard);
                },
              ),
            ),
            FadeInUp(
              delay: const Duration(milliseconds: 100),
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.delete, color: Colors.red),
                ),
                title: const Text('Delete', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.of(context).pop();
                  _deleteFlashcard(flashcard);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _startReview() {
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
        builder: (context) => review.FlashcardReviewScreen(
          flashcards: _flashcardController.flashcards,
          categoryId: widget.categoryId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  hintText: 'Search flashcards...',
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: Colors.white70),
                ),
                style: const TextStyle(color: Colors.white),
                onChanged: _onSearchChanged,
                autofocus: true,
              )
            : Text(widget.categoryName),
        actions: [
          if (_isSearching)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: _stopSearch,
            )
          else ...[
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: _startSearch,
            ),
            IconButton(
              icon: const Icon(Icons.play_arrow),
              onPressed: _startReview,
              tooltip: 'Start Review',
            ),
          ],
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshFlashcards,
        child: AnimatedBuilder(
          animation: _flashcardController,
          builder: (context, child) {
            if (_flashcardController.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (_flashcardController.error != null) {
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
                      'Error loading flashcards',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _flashcardController.error!,
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _refreshFlashcards,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            final flashcards = _flashcardController.flashcards;

            if (flashcards.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _isSearching ? Icons.search_off : Icons.note_add,
                      size: 64,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _isSearching ? 'No flashcards found' : 'No flashcards yet',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _isSearching 
                          ? 'Try a different search term'
                          : 'Create your first flashcard to get started',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    if (!_isSearching)
                      ElevatedButton(
                        onPressed: _addFlashcard,
                        child: const Text('Add Flashcard'),
                      ),
                  ],
                ),
              );
            }

            return Column(
              children: [
                // Summary with animation
                if (!_isSearching)
                  Container(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Expanded(
                          child: Card(
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                children: [
                                  Text(
                                    '${flashcards.length}',
                                    style: Theme.of(context).textTheme.displayMedium?.copyWith(
                                      color: Theme.of(context).colorScheme.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Flashcards',
                                    style: Theme.of(context).textTheme.bodyMedium,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _startReview,
                            icon: const Icon(Icons.play_arrow),
                            label: const Text('Review'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.all(16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Flashcards List
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: flashcards.length,
                    itemBuilder: (context, index) {
                      final flashcard = flashcards[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: ListTile(
                          title: Text(
                            flashcard.question,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          subtitle: Text(
                            flashcard.answer,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.more_vert),
                            onPressed: () => _showFlashcardOptions(flashcard),
                          ),
                          onTap: () => _editFlashcard(flashcard),
                          onLongPress: () => _showFlashcardOptions(flashcard),
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
}