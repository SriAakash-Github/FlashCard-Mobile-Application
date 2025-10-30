import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import '../models/flashcard.dart';
import '../controllers/review_controller.dart';

class FlashcardReviewScreen extends StatefulWidget {
  final List<Flashcard> flashcards;
  final String categoryId;

  const FlashcardReviewScreen({
    super.key,
    required this.flashcards,
    required this.categoryId,
  });

  @override
  State<FlashcardReviewScreen> createState() => _FlashcardReviewScreenState();
}

class _FlashcardReviewScreenState extends State<FlashcardReviewScreen>
    with TickerProviderStateMixin {
  late ReviewController _reviewController;
  late AnimationController _flipController;
  late Animation<double> _flipAnimation;

  @override
  void initState() {
    super.initState();
    _reviewController = ReviewController();
    _reviewController.initializeReview(
      widget.flashcards,
      categoryId: widget.categoryId,
    );

    _flipController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _flipAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _flipController,
      curve: Curves.easeInOutCubic,
    ));

    // Listen to review controller changes to sync flip animation
    _reviewController.addListener(_onReviewStateChanged);
  }

  @override
  void dispose() {
    _reviewController.removeListener(_onReviewStateChanged);
    _reviewController.dispose();
    _flipController.dispose();
    super.dispose();
  }

  void _onReviewStateChanged() {
    if (_reviewController.isFlipped) {
      _flipController.forward();
    } else {
      _flipController.reverse();
    }
  }

  void _flipCard() {
    _reviewController.flipCard();
  }

  void _nextCard() {
    if (_reviewController.nextCard()) {
      _flipController.reset();
      // Add a subtle animation for the card transition
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          setState(() {});
        }
      });
    } else {
      _showEndOfDeckDialog();
    }
  }

  void _previousCard() {
    if (_reviewController.previousCard()) {
      _flipController.reset();
      // Add a subtle animation for the card transition
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          setState(() {});
        }
      });
    } else {
      _showStartOfDeckDialog();
    }
  }

  void _showEndOfDeckDialog() {
    showDialog(
      context: context,
      builder: (context) => ZoomIn(
        child: AlertDialog(
          title: const Text('End of Deck'),
          content: const Text('You\'ve reached the end of the flashcards. Would you like to restart?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Stay Here'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _reviewController.restart();
                _flipController.reset();
              },
              child: const Text('Restart'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
              child: const Text('Exit Review'),
            ),
          ],
        ),
      ),
    );
  }

  void _showStartOfDeckDialog() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('You\'re at the first card'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showReviewMenu() {
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
              delay: const Duration(milliseconds: 50),
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.purple[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.shuffle, color: Colors.purple),
                ),
                title: const Text('Shuffle Cards'),
                onTap: () {
                  Navigator.of(context).pop();
                  _reviewController.setReviewMode(ReviewMode.random);
                  _reviewController.shuffleCards();
                },
              ),
            ),
            FadeInUp(
              delay: const Duration(milliseconds: 100),
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.sort, color: Colors.blue),
                ),
                title: const Text('Sequential Order'),
                onTap: () {
                  Navigator.of(context).pop();
                  _reviewController.setReviewMode(ReviewMode.sequential);
                },
              ),
            ),
            FadeInUp(
              delay: const Duration(milliseconds: 150),
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.restart_alt, color: Colors.green),
                ),
                title: const Text('Restart Review'),
                onTap: () {
                  Navigator.of(context).pop();
                  _reviewController.restart();
                  _flipController.reset();
                },
              ),
            ),
            FadeInUp(
              delay: const Duration(milliseconds: 200),
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.exit_to_app, color: Colors.red),
                ),
                title: const Text('Exit Review'),
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Review'),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: _showReviewMenu,
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: _reviewController,
        builder: (context, child) {
          if (!_reviewController.hasCards) {
            return const Center(
              child: Text('No flashcards to review'),
            );
          }

          final currentCard = _reviewController.currentFlashcard!;

          return Column(
            children: [
              // Progress indicator with animation
              Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${_reviewController.currentPosition} of ${_reviewController.totalCards}',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        Text(
                          '${(_reviewController.progress * 100).round()}%',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TweenAnimationBuilder<double>(
                      tween: Tween<double>(
                        begin: 0,
                        end: _reviewController.progress,
                      ),
                      duration: const Duration(milliseconds: 500),
                      builder: (context, value, child) {
                        return LinearProgressIndicator(
                          value: value,
                          backgroundColor: Colors.grey[300],
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Theme.of(context).colorScheme.primary,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),

              // Flashcard with enhanced flip animation
              Expanded(
                child: Center(
                  child: GestureDetector(
                    onTap: _flipCard,
                    onHorizontalDragEnd: (details) {
                      if (details.primaryVelocity! > 0) {
                        _previousCard();
                      } else if (details.primaryVelocity! < 0) {
                        _nextCard();
                      }
                    },
                    child: Container(
                      margin: const EdgeInsets.all(16),
                      child: AnimatedBuilder(
                        animation: _flipAnimation,
                        builder: (context, child) {
                          final isShowingFront = _flipAnimation.value < 0.5;
                          return Transform(
                            alignment: Alignment.center,
                            transform: Matrix4.identity()
                              ..setEntry(3, 2, 0.001)
                              ..rotateY(_flipAnimation.value * 3.14159),
                            child: Card(
                              elevation: 12,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Container(
                                width: double.infinity,
                                height: 400,
                                padding: const EdgeInsets.all(24),
                                child: isShowingFront
                                    ? _buildQuestionSide(currentCard)
                                    : Transform(
                                        alignment: Alignment.center,
                                        transform: Matrix4.identity()..rotateY(3.14159),
                                        child: _buildAnswerSide(currentCard),
                                      ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),

              // Instructions and controls with animations
              Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      _reviewController.isFlipped
                          ? 'Tap to see question • Swipe for next card'
                          : 'Tap to reveal answer • Swipe to navigate',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // Previous button
                        IconButton(
                          onPressed: _reviewController.canGoPrevious() ? _previousCard : null,
                          icon: const Icon(Icons.arrow_back_rounded),
                          iconSize: 36,
                          tooltip: 'Previous Card',
                          color: _reviewController.canGoPrevious() 
                              ? Theme.of(context).colorScheme.primary 
                              : Colors.grey,
                        ),
                        // Flip button
                        IconButton(
                          onPressed: _flipCard,
                          icon: Icon(_reviewController.isFlipped 
                              ? Icons.quiz 
                              : Icons.lightbulb_outline),
                          iconSize: 40,
                          tooltip: _reviewController.isFlipped 
                              ? 'Show Question' 
                              : 'Show Answer',
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                        // Next button
                        IconButton(
                          onPressed: _reviewController.canGoNext() ? _nextCard : null,
                          icon: const Icon(Icons.arrow_forward_rounded),
                          iconSize: 36,
                          tooltip: 'Next Card',
                          color: _reviewController.canGoNext() 
                              ? Theme.of(context).colorScheme.primary 
                              : Colors.grey,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildQuestionSide(Flashcard flashcard) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ElasticIn(
          child: Icon(
            Icons.quiz,
            size: 56,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(height: 16),
        FadeInDown(
          child: Text(
            'Question',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 24),
        Expanded(
          child: Center(
            child: SingleChildScrollView(
              child: FadeInUp(
                child: Text(
                  flashcard.question,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAnswerSide(Flashcard flashcard) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ElasticIn(
          child: Icon(
            Icons.lightbulb,
            size: 56,
            color: Theme.of(context).colorScheme.secondary,
          ),
        ),
        const SizedBox(height: 16),
        FadeInDown(
          child: Text(
            'Answer',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Theme.of(context).colorScheme.secondary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 24),
        Expanded(
          child: Center(
            child: SingleChildScrollView(
              child: FadeInUp(
                child: Text(
                  flashcard.answer,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}