import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../../../core/constants/color_constants.dart';
import '../../../data/models/youtube_video_model.dart';
import '../../../providers/youtube_provider.dart';
import '../../widgets/youtube/video_card.dart';
import '../../../config/routes.dart';

class YouTubeSearchScreenAdvanced extends StatefulWidget {
  final String subject;
  final String? topic;

  const YouTubeSearchScreenAdvanced({
    Key? key,
    required this.subject,
    this.topic,
  }) : super(key: key);

  @override
  State<YouTubeSearchScreenAdvanced> createState() => _YouTubeSearchScreenAdvancedState();
}

class _YouTubeSearchScreenAdvancedState extends State<YouTubeSearchScreenAdvanced>
    with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();

  late AnimationController _searchBarAnimationController;
  late AnimationController _resultsAnimationController;
  late Animation<double> _searchBarAnimation;
  late Animation<Offset> _slideAnimation;

  bool _hasSearched = false;
  bool _isDisposed = false;
  bool _showFilters = false;

  // Search filters
  String _sortBy = 'relevance'; // relevance, views, date, rating
  String _duration = 'any'; // any, short, medium, long
  String _uploadDate = 'any'; // any, hour, today, week, month, year

  // Search history
  List<String> _searchHistory = [];
  final int _maxHistoryItems = 5;

  // Trending searches
  final List<String> _trendingSearches = [
    'Latest tutorials',
    'Exam preparation',
    'Quick revision',
    'Full course',
    'Problem solving',
  ];

  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadSearchHistory();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_isDisposed) {
        _searchFocus.requestFocus();
        _searchBarAnimationController.forward();
      }
    });
  }

  void _initializeAnimations() {
    _searchBarAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _resultsAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _searchBarAnimation = CurvedAnimation(
      parent: _searchBarAnimationController,
      curve: Curves.easeOutCubic,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _resultsAnimationController,
      curve: Curves.easeOut,
    ));
  }

  void _loadSearchHistory() {
    // In production, load from SharedPreferences or Hive
    setState(() {
      _searchHistory = [
        'Machine learning basics',
        'Data structures',
        'Algorithm analysis',
      ];
    });
  }

  void _saveToHistory(String query) {
    if (query.trim().isEmpty) return;

    setState(() {
      _searchHistory.remove(query);
      _searchHistory.insert(0, query);
      if (_searchHistory.length > _maxHistoryItems) {
        _searchHistory = _searchHistory.take(_maxHistoryItems).toList();
      }
    });
    // In production, save to SharedPreferences or Hive
  }

  @override
  void dispose() {
    _isDisposed = true;
    _searchController.dispose();
    _searchFocus.dispose();
    _debounceTimer?.cancel();
    _searchBarAnimationController.dispose();
    _resultsAnimationController.dispose();
    super.dispose();
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) return;
    if (_isDisposed || !mounted) return;

    HapticFeedback.mediumImpact();
    _saveToHistory(query);

    try {
      final provider = Provider.of<YouTubeProvider>(context, listen: false);

      await provider.searchVideos(
        query: query,
        subject: widget.subject,
        topic: widget.topic,
        maxResults: 30,
      );

      if (mounted && !_isDisposed) {
        setState(() => _hasSearched = true);
        _resultsAnimationController.forward();
      }
    } catch (e) {
      debugPrint('❌ Search error: $e');
      if (mounted && !_isDisposed) {
        _showErrorSnackbar('Search failed. Please try again.');
      }
    }
  }

  void _onSearchChanged(String value) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      if (value.length >= 3 && mounted && !_isDisposed) {
        // Auto-search after 500ms of no typing
        // _performSearch(value);
      }
    });

    if (mounted && !_isDisposed) {
      setState(() {});
    }
  }

  void _clearSearch() {
    if (_isDisposed || !mounted) return;

    _searchController.clear();
    if (mounted) {
      setState(() {
        _hasSearched = false;
        _showFilters = false;
      });
      _resultsAnimationController.reset();
    }
    HapticFeedback.lightImpact();
  }

  void _clearHistory() {
    setState(() => _searchHistory.clear());
    HapticFeedback.mediumImpact();
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // Animated gradient background
          AnimatedContainer(
            duration: const Duration(seconds: 3),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.red.shade900.withOpacity(0.3),
                  const Color(0xFF0F0F0F),
                  const Color(0xFF0F0F0F),
                ],
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                _buildSearchBar(),
                if (_showFilters) _buildFilterSection(),
                Expanded(child: _buildBody()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, -1),
        end: Offset.zero,
      ).animate(_searchBarAnimation),
      child: Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withOpacity(0.1),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.red.withOpacity(0.1),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  // Back Button
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Search TextField
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      focusNode: _searchFocus,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Search ${widget.subject}...',
                        hintStyle: TextStyle(
                          color: Colors.white.withOpacity(0.4),
                          fontSize: 15,
                        ),
                        border: InputBorder.none,
                        isDense: true,
                      ),
                      textInputAction: TextInputAction.search,
                      onSubmitted: _performSearch,
                      onChanged: _onSearchChanged,
                    ),
                  ),

                  // Clear/Voice Button
                  if (_searchController.text.isNotEmpty)
                    GestureDetector(
                      onTap: _clearSearch,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.clear,
                          color: Colors.white70,
                          size: 20,
                        ),
                      ),
                    )
                  else
                    GestureDetector(
                      onTap: () {
                        // Voice search implementation
                        HapticFeedback.mediumImpact();
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.mic,
                          color: Colors.red,
                          size: 20,
                        ),
                      ),
                    ),

                  const SizedBox(width: 8),

                  // Search Button
                  GestureDetector(
                    onTap: () => _performSearch(_searchController.text),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.red.shade700,
                            Colors.red.shade900,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.search,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Filter & Sort Row
            if (_hasSearched)
              Container(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildQuickFilter('Relevance', _sortBy == 'relevance'),
                            _buildQuickFilter('Views', _sortBy == 'views'),
                            _buildQuickFilter('Latest', _sortBy == 'date'),
                            _buildQuickFilter('Rating', _sortBy == 'rating'),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () {
                        setState(() => _showFilters = !_showFilters);
                        HapticFeedback.selectionClick();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _showFilters
                              ? Colors.red.withOpacity(0.2)
                              : Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _showFilters
                                ? Colors.red.withOpacity(0.5)
                                : Colors.white.withOpacity(0.1),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _showFilters
                                  ? Icons.filter_list_off
                                  : Icons.tune,
                              color: _showFilters ? Colors.red : Colors.white70,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Filters',
                              style: TextStyle(
                                color: _showFilters ? Colors.red : Colors.white70,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickFilter(String label, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          switch (label) {
            case 'Relevance':
              _sortBy = 'relevance';
              break;
            case 'Views':
              _sortBy = 'views';
              break;
            case 'Latest':
              _sortBy = 'date';
              break;
            case 'Rating':
              _sortBy = 'rating';
              break;
          }
        });
        HapticFeedback.selectionClick();
      },
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
            colors: [Colors.red.shade700, Colors.red.shade900],
          )
              : null,
          color: isSelected ? null : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? Colors.transparent
                : Colors.white.withOpacity(0.1),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white70,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildFilterSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.filter_alt, color: Colors.red, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Advanced Filters',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () {
                  setState(() {
                    _duration = 'any';
                    _uploadDate = 'any';
                  });
                },
                child: const Text(
                  'Reset',
                  style: TextStyle(color: Colors.red, fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Duration Filter
          Text(
            'Duration',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              _buildFilterChip('Any', _duration == 'any', () {
                setState(() => _duration = 'any');
              }),
              _buildFilterChip('< 4 min', _duration == 'short', () {
                setState(() => _duration = 'short');
              }),
              _buildFilterChip('4-20 min', _duration == 'medium', () {
                setState(() => _duration = 'medium');
              }),
              _buildFilterChip('> 20 min', _duration == 'long', () {
                setState(() => _duration = 'long');
              }),
            ],
          ),

          const SizedBox(height: 16),

          // Upload Date Filter
          Text(
            'Upload Date',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              _buildFilterChip('Any', _uploadDate == 'any', () {
                setState(() => _uploadDate = 'any');
              }),
              _buildFilterChip('Today', _uploadDate == 'today', () {
                setState(() => _uploadDate = 'today');
              }),
              _buildFilterChip('This Week', _uploadDate == 'week', () {
                setState(() => _uploadDate = 'week');
              }),
              _buildFilterChip('This Month', _uploadDate == 'month', () {
                setState(() => _uploadDate = 'month');
              }),
              _buildFilterChip('This Year', _uploadDate == 'year', () {
                setState(() => _uploadDate = 'year');
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: () {
        onTap();
        HapticFeedback.selectionClick();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
            colors: [Colors.red.shade700, Colors.red.shade900],
          )
              : null,
          color: isSelected ? null : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? Colors.transparent
                : Colors.white.withOpacity(0.2),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (!_hasSearched) {
      return _buildSearchSuggestions();
    }

    return Consumer<YouTubeProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return _buildLoadingState();
        }

        if (provider.errorMessage != null) {
          return _buildErrorState(provider.errorMessage!);
        }

        if (provider.videos.isEmpty) {
          return _buildNoResults();
        }

        return _buildSearchResults(provider.videos);
      },
    );
  }

  Widget _buildSearchSuggestions() {
    return FadeTransition(
      opacity: _searchBarAnimation,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Recent Searches
          if (_searchHistory.isNotEmpty) ...[
            _buildSectionHeader(
              icon: Icons.history,
              title: 'Recent Searches',
              action: TextButton(
                onPressed: _clearHistory,
                child: const Text(
                  'Clear',
                  style: TextStyle(color: Colors.red, fontSize: 12),
                ),
              ),
            ),
            const SizedBox(height: 12),
            ..._searchHistory.map((query) => _buildSearchHistoryItem(query)),
            const SizedBox(height: 24),
          ],

          // Trending Searches
          _buildSectionHeader(
            icon: Icons.trending_up,
            title: 'Trending in ${widget.subject}',
          ),
          const SizedBox(height: 12),
          ..._trendingSearches.map((query) => _buildTrendingItem(query)),

          const SizedBox(height: 24),

          // Smart Suggestions
          _buildSectionHeader(
            icon: Icons.auto_awesome,
            title: 'Smart Suggestions',
          ),
          const SizedBox(height: 12),
          _buildSmartSuggestions(),

          const SizedBox(height: 24),

          // Tips
          _buildTipsCard(),
        ],
      ),
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    Widget? action,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.red.shade700, Colors.red.shade900],
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: Colors.white, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        if (action != null) action,
      ],
    );
  }

  Widget _buildSearchHistoryItem(String query) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.history,
            color: Colors.white70,
            size: 20,
          ),
        ),
        title: Text(
          query,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_upward, color: Colors.white70, size: 18),
              onPressed: () {
                _searchController.text = query;
                _searchFocus.requestFocus();
              },
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white54, size: 18),
              onPressed: () {
                setState(() => _searchHistory.remove(query));
              },
            ),
          ],
        ),
        onTap: () {
          _searchController.text = query;
          _performSearch(query);
        },
      ),
    );
  }

  Widget _buildTrendingItem(String query) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.red.withOpacity(0.1),
            Colors.red.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withOpacity(0.2)),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.whatshot,
            color: Colors.red,
            size: 20,
          ),
        ),
        title: Text(
          query,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          color: Colors.white54,
          size: 16,
        ),
        onTap: () {
          _searchController.text = query;
          _performSearch(query);
        },
      ),
    );
  }

  Widget _buildSmartSuggestions() {
    final suggestions = [
      {
        'title': 'Complete ${widget.subject} Course',
        'subtitle': 'Full tutorials from basics to advanced',
        'icon': Icons.school,
      },
      {
        'title': 'Quick Revision',
        'subtitle': 'Short videos for exam preparation',
        'icon': Icons.speed,
      },
      {
        'title': 'Problem Solving',
        'subtitle': 'Practice questions and solutions',
        'icon': Icons.psychology,
      },
      if (widget.topic != null)
        {
          'title': '${widget.topic} Explained',
          'subtitle': 'In-depth explanation videos',
          'icon': Icons.lightbulb,
        },
    ];

    return Column(
      children: suggestions.map((suggestion) {
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.shade700, Colors.blue.shade900],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                suggestion['icon'] as IconData,
                color: Colors.white,
                size: 20,
              ),
            ),
            title: Text(
              suggestion['title'] as String,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(
              suggestion['subtitle'] as String,
              style: TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
            trailing: const Icon(
              Icons.arrow_forward_ios,
              color: Colors.white54,
              size: 16,
            ),
            onTap: () {
              _searchController.text = suggestion['title'] as String;
              _performSearch(suggestion['title'] as String);
            },
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTipsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.purple.withOpacity(0.2),
            Colors.blue.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.purple.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.purple.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.tips_and_updates,
                  color: Colors.purpleAccent,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Search Tips',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildTipItem('Use specific keywords for better results'),
          _buildTipItem('Try "tutorial", "explained", or "course"'),
          _buildTipItem('Filter by duration for quick learning'),
          _buildTipItem('Sort by views to find popular content'),
        ],
      ),
    );
  }

  Widget _buildTipItem(String tip) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 4),
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: Colors.purpleAccent,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              tip,
              style: TextStyle(
                color: Colors.white70,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      Colors.red.withOpacity(0.3),
                      Colors.red.withOpacity(0.1),
                    ],
                  ),
                ),
              ),
              const SizedBox(
                width: 60,
                height: 60,
                child: CircularProgressIndicator(
                  color: Colors.red,
                  strokeWidth: 3,
                ),
              ),
              const Icon(
                Icons.search,
                color: Colors.white,
                size: 30,
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            'Finding the best videos...',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Searching through thousands of videos',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.red.withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red.shade400,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Oops! Something went wrong',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              error,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => _performSearch(_searchController.text),
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade700,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoResults() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.search_off,
                size: 80,
                color: Colors.white.withOpacity(0.3),
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'No videos found',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Try different keywords or adjust your filters',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white70,
                fontSize: 15,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: _clearSearch,
                  icon: const Icon(Icons.refresh),
                  label: const Text('New Search'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white30),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() => _showFilters = true);
                  },
                  icon: const Icon(Icons.tune),
                  label: const Text('Adjust Filters'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResults(List<YouTubeVideoModel> videos) {
    // Apply sorting
    var sortedVideos = List<YouTubeVideoModel>.from(videos);
    switch (_sortBy) {
      case 'views':
        sortedVideos.sort((a, b) => b.viewCount.compareTo(a.viewCount));
        break;
      case 'date':
        sortedVideos.sort((a, b) => b.publishedAt.compareTo(a.publishedAt));
        break;
      case 'rating':
        sortedVideos.sort((a, b) => b.likeCount.compareTo(a.likeCount));
        break;
      case 'relevance':
      default:
        sortedVideos.sort((a, b) => b.relevanceScore.compareTo(a.relevanceScore));
    }

    return SlideTransition(
      position: _slideAnimation,
      child: Column(
        children: [
          // Results Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              border: Border(
                bottom: BorderSide(color: Colors.white.withOpacity(0.1)),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.green.shade700, Colors.green.shade900],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.check_circle,
                        size: 16,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${sortedVideos.length} results',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: _clearSearch,
                  icon: const Icon(Icons.clear_all, size: 18),
                  label: const Text('Clear'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white70,
                  ),
                ),
              ],
            ),
          ),

          // Video List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: sortedVideos.length,
              itemBuilder: (context, index) {
                final video = sortedVideos[index];
                return TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: Duration(milliseconds: 200 + (index * 30)),
                  curve: Curves.easeOut,
                  builder: (context, value, child) {
                    return Transform.translate(
                      offset: Offset(0, 20 * (1 - value)),
                      child: Opacity(
                        opacity: value,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: VideoCard(
                            video: video,
                            onTap: () {
                              if (!mounted || _isDisposed) return;

                              HapticFeedback.mediumImpact();
                              AppRoutes.navigateToYouTubePlayer(
                                context,
                                video: video,
                                relatedVideos: sortedVideos
                                    .where((v) => v.videoId != video.videoId)
                                    .toList(),
                              );
                            },
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}