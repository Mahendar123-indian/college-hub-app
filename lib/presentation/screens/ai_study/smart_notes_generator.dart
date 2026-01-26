import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/color_constants.dart';
import '../../../data/services/unified_ai_service.dart';

class SmartNotesGenerator extends StatefulWidget {
  final String topic;
  final String subject;

  const SmartNotesGenerator({
    Key? key,
    required this.topic,
    required this.subject,
  }) : super(key: key);

  @override
  State<SmartNotesGenerator> createState() => _SmartNotesGeneratorState();
}

class _SmartNotesGeneratorState extends State<SmartNotesGenerator>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<FlashCard> _flashcards = [];
  String? _mindMap;
  String? _quickRevision;
  bool _isGenerating = false;
  int _currentFlashcardIndex = 0;
  bool _showFlashcardAnswer = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _generateContent();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _generateContent() async {
    setState(() => _isGenerating = true);

    try {
      // Generate all content in parallel
      await Future.wait([
        _generateFlashcards(),
        _generateMindMap(),
        _generateQuickRevision(),
      ]);

      setState(() => _isGenerating = false);
    } catch (e) {
      setState(() => _isGenerating = false);
      _showSnackBar('Error generating content: $e', Colors.red);
    }
  }

  Future<void> _generateFlashcards() async {
    try {
      // ✅ Use UnifiedAIService
      final aiService = UnifiedAIService();
      if (!aiService.isInitialized) {
        await aiService.initialize();
      }

      final flashcards = await aiService.generateFlashcards(
        widget.topic,
        widget.subject,
      );
      setState(() => _flashcards = flashcards);
    } catch (e) {
      debugPrint('❌ Flashcard generation error: $e');
    }
  }

  Future<void> _generateMindMap() async {
    try {
      // ✅ Use UnifiedAIService
      final aiService = UnifiedAIService();
      if (!aiService.isInitialized) {
        await aiService.initialize();
      }

      final mindMap = await aiService.generateMindMap(
        widget.topic,
        widget.subject,
      );
      setState(() => _mindMap = mindMap);
    } catch (e) {
      debugPrint('❌ Mind map generation error: $e');
    }
  }

  Future<void> _generateQuickRevision() async {
    try {
      // ✅ Use UnifiedAIService
      final aiService = UnifiedAIService();
      if (!aiService.isInitialized) {
        await aiService.initialize();
      }

      final revision = await aiService.generateQuickRevision(widget.topic, 30);
      setState(() => _quickRevision = revision);
    } catch (e) {
      debugPrint('❌ Quick revision generation error: $e');
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: _buildAppBar(),
      body: _isGenerating ? _buildLoadingState() : _buildContent(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.primaryColor,
              AppColors.primaryColor.withOpacity(0.8),
            ],
          ),
        ),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Smart Notes',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            widget.topic,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
      bottom: TabBar(
        controller: _tabController,
        indicatorColor: Colors.white,
        indicatorWeight: 3,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white60,
        tabs: const [
          Tab(icon: Icon(Icons.style_rounded), text: 'Flashcards'),
          Tab(icon: Icon(Icons.account_tree_rounded), text: 'Mind Map'),
          Tab(icon: Icon(Icons.flash_on_rounded), text: 'Quick Notes'),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primaryColor,
                  AppColors.accentColor,
                ],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryColor.withOpacity(0.3),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: Colors.white,
              size: 40,
            ),
          ),
          const SizedBox(height: 24),
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          const Text(
            'Generating Smart Notes...',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'AI is creating study materials for you',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return TabBarView(
      controller: _tabController,
      children: [
        _buildFlashcardsView(),
        _buildMindMapView(),
        _buildQuickRevisionView(),
      ],
    );
  }

  Widget _buildFlashcardsView() {
    if (_flashcards.isEmpty) {
      return _buildEmptyState(
        'No flashcards generated',
        Icons.style_rounded,
      );
    }

    final currentCard = _flashcards[_currentFlashcardIndex];

    return Column(
      children: [
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Card ${_currentFlashcardIndex + 1} of ${_flashcards.length}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryColor,
                ),
              ),
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _currentFlashcardIndex = 0;
                    _showFlashcardAnswer = false;
                  });
                },
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Restart'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                setState(() => _showFlashcardAnswer = !_showFlashcardAnswer);
              },
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: _showFlashcardAnswer ? 1.0 : 0.0),
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeInOut,
                builder: (context, value, child) {
                  return Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.001)
                      ..rotateY(value * 3.14159),
                    child: value < 0.5 ? _buildCardFront(currentCard) : _buildCardBack(currentCard),
                  );
                },
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _currentFlashcardIndex > 0
                      ? () {
                    HapticFeedback.lightImpact();
                    setState(() {
                      _currentFlashcardIndex--;
                      _showFlashcardAnswer = false;
                    });
                  }
                      : null,
                  icon: const Icon(Icons.arrow_back_rounded),
                  label: const Text('Previous'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[300],
                    foregroundColor: Colors.black87,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _currentFlashcardIndex < _flashcards.length - 1
                      ? () {
                    HapticFeedback.lightImpact();
                    setState(() {
                      _currentFlashcardIndex++;
                      _showFlashcardAnswer = false;
                    });
                  }
                      : null,
                  icon: const Icon(Icons.arrow_forward_rounded),
                  label: const Text('Next'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCardFront(FlashCard card) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryColor,
            AppColors.primaryColor.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryColor.withOpacity(0.4),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.help_outline_rounded,
            color: Colors.white,
            size: 48,
          ),
          const SizedBox(height: 24),
          Text(
            card.front,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'Tap to reveal answer',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardBack(FlashCard card) {
    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.identity()..rotateY(3.14159),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: AppColors.primaryColor,
            width: 3,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 30,
              offset: const Offset(0, 15),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.check_circle_rounded,
              color: AppColors.successColor,
              size: 48,
            ),
            const SizedBox(height: 24),
            Text(
              card.back,
              style: const TextStyle(
                fontSize: 18,
                color: Colors.black87,
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Tap to flip back',
                style: TextStyle(
                  color: AppColors.primaryColor,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMindMapView() {
    if (_mindMap == null) {
      return _buildEmptyState(
        'No mind map generated',
        Icons.account_tree_rounded,
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.account_tree_rounded,
                    color: AppColors.primaryColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Text(
                    'Mind Map',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy_rounded),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: _mindMap!));
                    _showSnackBar('Copied to clipboard!', AppColors.successColor);
                  },
                  tooltip: 'Copy',
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              _mindMap!,
              style: const TextStyle(
                fontSize: 15,
                fontFamily: 'Courier',
                height: 1.8,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickRevisionView() {
    if (_quickRevision == null) {
      return _buildEmptyState(
        'No revision notes generated',
        Icons.flash_on_rounded,
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primaryColor,
                        AppColors.accentColor,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.flash_on_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Text(
                    '30-Minute Quick Revision',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy_rounded),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: _quickRevision!));
                    _showSnackBar('Copied to clipboard!', AppColors.successColor);
                  },
                  tooltip: 'Copy',
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              _quickRevision!,
              style: const TextStyle(
                fontSize: 15,
                height: 1.8,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}