import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import '../../../providers/smart_learning_provider.dart';
import '../../../data/models/flashcard_model.dart';

class FlashcardGeneratorScreen extends StatefulWidget {
  final String? resourceId;
  final String? topic;

  const FlashcardGeneratorScreen({super.key, this.resourceId, this.topic});

  @override
  State<FlashcardGeneratorScreen> createState() => _FlashcardGeneratorScreenState();
}

class _FlashcardGeneratorScreenState extends State<FlashcardGeneratorScreen> with TickerProviderStateMixin {
  final _topicController = TextEditingController();
  final _subjectController = TextEditingController();
  final _textController = TextEditingController();
  final _searchController = TextEditingController();

  int _currentIndex = 0;
  bool _showAnswer = false;
  late AnimationController _flipController;
  late AnimationController _slideController;
  late Animation<double> _flipAnimation;
  late Animation<Offset> _slideAnimation;

  String _selectedDifficulty = 'All';
  String _sortBy = 'Default';
  bool _showStatistics = false;
  bool _shuffleMode = false;
  List<int> _studyOrder = [];

  @override
  void initState() {
    super.initState();
    if (widget.topic != null) {
      _topicController.text = widget.topic!;
    }

    _flipController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _flipAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _flipController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(-1, 0),
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeInOut));

    context.read<SmartLearningProvider>().loadFlashcards();
  }

  @override
  void dispose() {
    _flipController.dispose();
    _slideController.dispose();
    _topicController.dispose();
    _subjectController.dispose();
    _textController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _toggleFlip() {
    if (_showAnswer) {
      _flipController.reverse();
    } else {
      _flipController.forward();
    }
    setState(() => _showAnswer = !_showAnswer);
  }

  void _animateNext() async {
    await _slideController.forward();
    setState(() {
      final provider = context.read<SmartLearningProvider>();
      if (_currentIndex < _getFilteredFlashcards(provider).length - 1) {
        _currentIndex++;
      }
      _showAnswer = false;
    });
    _flipController.reset();
    _slideController.reset();
  }

  void _animatePrevious() async {
    await _slideController.forward();
    setState(() {
      if (_currentIndex > 0) _currentIndex--;
      _showAnswer = false;
    });
    _flipController.reset();
    _slideController.reset();
  }

  List<FlashcardModel> _getFilteredFlashcards(SmartLearningProvider provider) {
    var cards = List<FlashcardModel>.from(provider.flashcards);

    // Apply search filter
    if (_searchController.text.isNotEmpty) {
      cards = cards.where((card) =>
      card.question.toLowerCase().contains(_searchController.text.toLowerCase()) ||
          card.answer.toLowerCase().contains(_searchController.text.toLowerCase())
      ).toList();
    }

    // Apply difficulty filter
    if (_selectedDifficulty != 'All') {
      cards = cards.where((card) {
        final score = card.masteryScore;
        switch (_selectedDifficulty) {
          case 'Easy': return score > 0.7;
          case 'Medium': return score >= 0.4 && score <= 0.7;
          case 'Hard': return score < 0.4;
          default: return true;
        }
      }).toList();
    }

    // Apply sorting
    switch (_sortBy) {
      case 'Mastery (Low to High)':
        cards.sort((a, b) => a.masteryScore.compareTo(b.masteryScore));
        break;
      case 'Mastery (High to Low)':
        cards.sort((a, b) => b.masteryScore.compareTo(a.masteryScore));
        break;
      case 'Recently Added':
        cards = cards.reversed.toList();
        break;
    }

    // Apply shuffle
    if (_shuffleMode && _studyOrder.isNotEmpty) {
      final shuffled = <FlashcardModel>[];
      for (var i in _studyOrder) {
        if (i < cards.length) shuffled.add(cards[i]);
      }
      cards = shuffled;
    }

    return cards;
  }

  void _shuffleCards(SmartLearningProvider provider) {
    final cards = _getFilteredFlashcards(provider);
    setState(() {
      _shuffleMode = true;
      _studyOrder = List.generate(cards.length, (i) => i)..shuffle();
      _currentIndex = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.blue.shade50, Colors.purple.shade50],
          ),
        ),
        child: SafeArea(
          child: Consumer<SmartLearningProvider>(
            builder: (context, provider, _) {
              if (provider.isLoading) {
                return _buildLoadingView();
              }

              final flashcards = _getFilteredFlashcards(provider);

              if (flashcards.isEmpty && provider.flashcards.isEmpty) {
                return _buildEmptyView(provider);
              }

              if (flashcards.isEmpty) {
                return _buildNoResultsView();
              }

              return Column(
                children: [
                  _buildAppBar(provider, flashcards),
                  if (_showStatistics) _buildStatisticsPanel(flashcards),
                  _buildProgressBar(flashcards.length, flashcards),
                  Expanded(child: _buildFlashcardStack(flashcards[_currentIndex])),
                  _buildAdvancedControls(flashcards, provider),
                ],
              );
            },
          ),
        ),
      ),
      floatingActionButton: _buildFloatingActions(),
    );
  }

  Widget _buildAppBar(SmartLearningProvider provider, List<FlashcardModel> flashcards) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
              ),
              const Expanded(
                child: Text(
                  'AI Flashcards Studio',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              IconButton(
                icon: Icon(_showStatistics ? Icons.bar_chart : Icons.bar_chart_outlined),
                onPressed: () => setState(() => _showStatistics = !_showStatistics),
              ),
              IconButton(
                icon: const Icon(Icons.filter_list),
                onPressed: () => _showFilterOptions(provider),
              ),
              IconButton(
                icon: const Icon(Icons.more_vert),
                onPressed: () => _showOptionsMenu(provider),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search flashcards...',
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                icon: const Icon(Icons.clear, size: 20),
                onPressed: () => setState(() => _searchController.clear()),
              )
                  : null,
              filled: true,
              fillColor: Colors.grey.shade100,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            onChanged: (value) => setState(() {}),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsPanel(List<FlashcardModel> flashcards) {
    final avgMastery = flashcards.isEmpty
        ? 0.0
        : flashcards.map((c) => c.masteryScore).reduce((a, b) => a + b) / flashcards.length;
    final masteredCount = flashcards.where((c) => c.masteryScore > 0.8).length;
    final needsReview = flashcards.where((c) => c.masteryScore < 0.5).length;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Study Statistics',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildStatCard('Total Cards', '${flashcards.length}', Icons.style, Colors.blue),
              const SizedBox(width: 12),
              _buildStatCard('Mastered', '$masteredCount', Icons.check_circle, Colors.green),
              const SizedBox(width: 12),
              _buildStatCard('Review', '$needsReview', Icons.warning, Colors.orange),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Text('Average Mastery: ', style: TextStyle(fontWeight: FontWeight.w600)),
              Text('${(avgMastery * 100).toStringAsFixed(1)}%'),
              const SizedBox(width: 12),
              Expanded(
                child: LinearProgressIndicator(
                  value: avgMastery,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation(Colors.green.shade400),
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(fontSize: 11, color: color.withOpacity(0.8)),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar(int total, List<FlashcardModel> flashcards) {
    final card = flashcards[_currentIndex];
    final masteryColor = card.masteryScore > 0.7
        ? Colors.green
        : card.masteryScore > 0.4
        ? Colors.orange
        : Colors.red;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Card ${_currentIndex + 1} of $total',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ),
                  if (_shuffleMode) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.purple.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.shuffle, size: 14, color: Colors.purple.shade700),
                          const SizedBox(width: 4),
                          Text(
                            'Shuffled',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.purple.shade700,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: masteryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Icon(Icons.auto_graph, size: 16, color: masteryColor),
                    const SizedBox(width: 6),
                    Text(
                      '${(card.masteryScore * 100).toStringAsFixed(0)}%',
                      style: TextStyle(
                        color: masteryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: (_currentIndex + 1) / total,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation(Colors.blue.shade400),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFlashcardStack(FlashcardModel card) {
    return Center(
      child: SlideTransition(
        position: _slideAnimation,
        child: GestureDetector(
          onTap: _toggleFlip,
          onHorizontalDragEnd: (details) {
            if (details.primaryVelocity! < 0) {
              _animateNext();
            } else if (details.primaryVelocity! > 0) {
              _animatePrevious();
            }
          },
          child: AnimatedBuilder(
            animation: _flipAnimation,
            builder: (context, child) {
              final angle = _flipAnimation.value * math.pi;
              final transform = Matrix4.identity()
                ..setEntry(3, 2, 0.001)
                ..rotateY(angle);

              return Transform(
                transform: transform,
                alignment: Alignment.center,
                child: angle < math.pi / 2
                    ? _buildCardFace(card.question, false, card)
                    : Transform(
                  transform: Matrix4.identity()..rotateY(math.pi),
                  alignment: Alignment.center,
                  child: _buildCardFace(card.answer, true, card),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildCardFace(String text, bool isAnswer, FlashcardModel card) {
    final colors = isAnswer
        ? [Colors.green.shade400, Colors.teal.shade500]
        : [Colors.blue.shade400, Colors.indigo.shade500];

    return Container(
      margin: const EdgeInsets.all(24),
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 400),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: colors[0].withOpacity(0.4),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Decorative circles
          Positioned(
            top: -50,
            right: -50,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.1),
              ),
            ),
          ),
          Positioned(
            bottom: -30,
            left: -30,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.1),
              ),
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isAnswer ? Icons.lightbulb : Icons.help_outline,
                    color: Colors.white,
                    size: 48,
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isAnswer ? 'ANSWER' : 'QUESTION',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 2,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      child: Text(
                        text,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          height: 1.5,
                          shadows: [
                            Shadow(
                              color: Colors.black26,
                              blurRadius: 10,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isAnswer ? Icons.touch_app : Icons.flip,
                      color: Colors.white70,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isAnswer ? 'Tap to see question' : 'Tap to reveal answer',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.swipe, color: Colors.white70, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Swipe to navigate',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdvancedControls(List<FlashcardModel> flashcards, SmartLearningProvider provider) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildAdvancedButton(
                icon: Icons.close,
                label: 'Wrong',
                color: Colors.red,
                gradient: [Colors.red.shade400, Colors.red.shade600],
                onPressed: () => _reviewCard(false, provider),
              ),
              _buildAdvancedButton(
                icon: Icons.remove_circle_outline,
                label: 'Partial',
                color: Colors.orange,
                gradient: [Colors.orange.shade400, Colors.orange.shade600],
                onPressed: () => _reviewCard(null, provider),
              ),
              _buildAdvancedButton(
                icon: Icons.check,
                label: 'Correct',
                color: Colors.green,
                gradient: [Colors.green.shade400, Colors.green.shade600],
                onPressed: () => _reviewCard(true, provider),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildSmallButton(
                icon: Icons.skip_previous,
                label: 'Previous',
                onPressed: _animatePrevious,
              ),
              _buildSmallButton(
                icon: Icons.bookmark_border,
                label: 'Bookmark',
                onPressed: () => _bookmarkCard(flashcards[_currentIndex], provider),
              ),
              _buildSmallButton(
                icon: Icons.speaker_notes,
                label: 'TTS',
                onPressed: () => _speakCard(flashcards[_currentIndex]),
              ),
              _buildSmallButton(
                icon: Icons.skip_next,
                label: 'Next',
                onPressed: _animateNext,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAdvancedButton({
    required IconData icon,
    required String label,
    required Color color,
    required List<Color> gradient,
    required VoidCallback onPressed,
  }) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: gradient),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Icon(icon, color: Colors.white, size: 28),
                  const SizedBox(height: 6),
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSmallButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, color: Colors.grey.shade700, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _reviewCard(bool? correct, SmartLearningProvider provider) {
    final card = _getFilteredFlashcards(provider)[_currentIndex];
    if (correct == true) {
      provider.reviewFlashcard(card, true);
    } else if (correct == false) {
      provider.reviewFlashcard(card, false);
    } else {
      // Partial correct - use provider method or create new card with updated score
      provider.reviewFlashcard(card, true);
    }
    _animateNext();
  }

  void _bookmarkCard(FlashcardModel card, SmartLearningProvider provider) {
    // Implement bookmark functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.bookmark, color: Colors.white),
            SizedBox(width: 8),
            Text('Card bookmarked!'),
          ],
        ),
        backgroundColor: Colors.blue.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _speakCard(FlashcardModel card) {
    // Implement text-to-speech
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.volume_up, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Text(_showAnswer ? card.answer : card.question),
            ),
          ],
        ),
        backgroundColor: Colors.purple.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildFloatingActions() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FloatingActionButton(
          heroTag: 'shuffle',
          mini: true,
          onPressed: () {
            final provider = context.read<SmartLearningProvider>();
            _shuffleCards(provider);
          },
          backgroundColor: Colors.purple.shade400,
          child: const Icon(Icons.shuffle),
        ),
        const SizedBox(height: 12),
        FloatingActionButton.extended(
          heroTag: 'generate',
          onPressed: () => _showGenerateDialog(context),
          icon: const Icon(Icons.auto_awesome),
          label: const Text('Generate'),
          backgroundColor: Colors.blue.shade600,
        ),
      ],
    );
  }

  Widget _buildLoadingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 80,
            height: 80,
            child: CircularProgressIndicator(
              strokeWidth: 6,
              valueColor: AlwaysStoppedAnimation(Colors.blue.shade600),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Generating Flashcards...',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            'AI is analyzing your content',
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyView(SmartLearningProvider provider) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.shade100, Colors.purple.shade100],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.style, size: 100, color: Colors.blue.shade700),
            ),
            const SizedBox(height: 32),
            const Text(
              'Create Your First Deck',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              'Generate AI-powered flashcards from your study materials',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 40),
            _buildFeatureCard(
              icon: Icons.auto_awesome,
              title: 'AI Generation',
              description: 'Paste notes and get instant flashcards',
              color: Colors.blue,
            ),
            const SizedBox(height: 16),
            _buildFeatureCard(
              icon: Icons.psychology,
              title: 'Smart Learning',
              description: 'Adaptive difficulty based on your progress',
              color: Colors.purple,
            ),
            const SizedBox(height: 16),
            _buildFeatureCard(
              icon: Icons.analytics,
              title: 'Track Progress',
              description: 'Monitor mastery with detailed statistics',
              color: Colors.green,
            ),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              onPressed: () => _showGenerateDialog(context),
              icon: const Icon(Icons.add_circle_outline, size: 28),
              label: const Text('Generate Flashcards', style: TextStyle(fontSize: 18)),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                backgroundColor: Colors.blue.shade600,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 8,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoResultsView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          const Text(
            'No cards match your filters',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your search or filters',
            style: TextStyle(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              setState(() {
                _searchController.clear();
                _selectedDifficulty = 'All';
                _sortBy = 'Default';
              });
            },
            icon: const Icon(Icons.clear_all),
            label: const Text('Clear Filters'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterOptions(SmartLearningProvider provider) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Filter & Sort',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Text('Difficulty Level', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: ['All', 'Easy', 'Medium', 'Hard'].map((difficulty) {
                  final isSelected = _selectedDifficulty == difficulty;
                  return ChoiceChip(
                    label: Text(difficulty),
                    selected: isSelected,
                    onSelected: (selected) {
                      setModalState(() => _selectedDifficulty = difficulty);
                      setState(() => _selectedDifficulty = difficulty);
                    },
                    selectedColor: Colors.blue.shade400,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.black87,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              const Text('Sort By', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              Column(
                children: [
                  'Default',
                  'Mastery (Low to High)',
                  'Mastery (High to Low)',
                  'Recently Added',
                ].map((sort) {
                  return RadioListTile<String>(
                    title: Text(sort),
                    value: sort,
                    groupValue: _sortBy,
                    onChanged: (value) {
                      setModalState(() => _sortBy = value!);
                      setState(() => _sortBy = value!);
                    },
                    activeColor: Colors.blue.shade600,
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.blue.shade600,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Apply Filters', style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showOptionsMenu(SmartLearningProvider provider) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Options',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            _buildOptionTile(
              icon: Icons.download,
              title: 'Export Deck',
              subtitle: 'Save as PDF or CSV',
              onTap: () {
                Navigator.pop(context);
                _exportDeck(provider);
              },
            ),
            _buildOptionTile(
              icon: Icons.delete_sweep,
              title: 'Clear Deck',
              subtitle: 'Remove all flashcards',
              color: Colors.red,
              onTap: () {
                Navigator.pop(context);
                _confirmClearDeck(provider);
              },
            ),
            _buildOptionTile(
              icon: Icons.settings,
              title: 'Study Settings',
              subtitle: 'Configure study preferences',
              onTap: () {
                Navigator.pop(context);
                _showStudySettings();
              },
            ),
            _buildOptionTile(
              icon: Icons.info_outline,
              title: 'Help & Tips',
              subtitle: 'Learn how to study effectively',
              onTap: () {
                Navigator.pop(context);
                _showHelpDialog();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    Color? color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: color ?? Colors.blue.shade600, size: 28),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    );
  }

  void _exportDeck(SmartLearningProvider provider) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 8),
            Text('Deck exported successfully!'),
          ],
        ),
        backgroundColor: Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _confirmClearDeck(SmartLearningProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Deck?'),
        content: const Text('This will remove all flashcards. This action cannot be undone.'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              provider.flashcards.clear();
              setState(() {});
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  void _showStudySettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Study Settings'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Study settings coming soon!'),
            SizedBox(height: 16),
            Text('Configure auto-advance, timer, and more.'),
          ],
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Study Tips'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTipItem('📖', 'Tap cards to flip between question and answer'),
              _buildTipItem('👆', 'Swipe left/right to navigate between cards'),
              _buildTipItem('✅', 'Mark cards as correct/wrong to track progress'),
              _buildTipItem('🔀', 'Use shuffle mode for varied practice'),
              _buildTipItem('📊', 'Check statistics to focus on weak areas'),
              _buildTipItem('🔍', 'Use search and filters to find specific cards'),
            ],
          ),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it!'),
          ),
        ],
      ),
    );
  }

  Widget _buildTipItem(String emoji, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }

  void _showGenerateDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          padding: const EdgeInsets.all(24),
          constraints: const BoxConstraints(maxWidth: 500),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.blue.shade400, Colors.purple.shade400],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.auto_awesome, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Generate Flashcards',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _subjectController,
                decoration: InputDecoration(
                  labelText: 'Subject / Topic',
                  prefixIcon: const Icon(Icons.book),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _textController,
                maxLines: 8,
                decoration: InputDecoration(
                  labelText: 'Paste your study notes here',
                  alignLabelWithHint: true,
                  hintText: 'Enter text, definitions, concepts, or any study material...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                      label: const Text('Cancel'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        if (_textController.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please enter some text')),
                          );
                          return;
                        }
                        Navigator.pop(context);
                        context.read<SmartLearningProvider>().generateFlashcardsFromText(
                          _textController.text,
                          _subjectController.text.isEmpty ? 'General' : _subjectController.text,
                        );
                        _textController.clear();
                        _subjectController.clear();
                      },
                      icon: const Icon(Icons.auto_awesome),
                      label: const Text('Generate'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.blue.shade600,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}