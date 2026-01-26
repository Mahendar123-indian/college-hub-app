import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'dart:async';

import '../../../config/routes.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/color_constants.dart';
import '../../../data/models/resource_model.dart';
import '../../../providers/resource_provider.dart';
import '../../../providers/filter_provider.dart';
import '../../widgets/resource_card.dart';

class EnhancedSearchScreen extends StatefulWidget {
  const EnhancedSearchScreen({Key? key}) : super(key: key);

  @override
  State<EnhancedSearchScreen> createState() => _EnhancedSearchScreenState();
}

class _EnhancedSearchScreenState extends State<EnhancedSearchScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();

  Timer? _debounce;
  String _searchQuery = '';
  List<String> _searchHistory = [];
  List<String> _trendingSearches = [];
  List<String> _suggestions = [];
  bool _isVoiceListening = false;
  late stt.SpeechToText _speech;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _speech = stt.SpeechToText();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );

    _animationController.forward();
    _loadSearchHistory();
    _loadTrendingSearches();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _searchFocus.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadSearchHistory() async {
    final box = await Hive.openBox('searchHistory');
    setState(() {
      _searchHistory = box.values.cast<String>().toList();
      if (_searchHistory.length > 10) {
        _searchHistory = _searchHistory.sublist(0, 10);
      }
    });
  }

  Future<void> _loadTrendingSearches() async {
    setState(() {
      _trendingSearches = [
        'Data Structures',
        'Operating Systems',
        'DBMS Notes',
        'Previous Year Papers',
        'Java Programming',
      ];
    });
  }

  Future<void> _saveToHistory(String query) async {
    if (query.trim().isEmpty) return;

    final box = await Hive.openBox('searchHistory');
    _searchHistory.remove(query);
    _searchHistory.insert(0, query);
    if (_searchHistory.length > 10) {
      _searchHistory.removeLast();
    }
    await box.clear();
    for (var item in _searchHistory) {
      await box.add(item);
    }
    setState(() {});
  }

  Future<void> _clearHistory() async {
    final box = await Hive.openBox('searchHistory');
    await box.clear();
    setState(() {
      _searchHistory.clear();
    });
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (query.trim().isNotEmpty) {
        setState(() {
          _searchQuery = query.trim();
        });
        _performSearch(query.trim());
        _loadSuggestions(query.trim());
      } else {
        setState(() {
          _searchQuery = '';
          _suggestions.clear();
        });
      }
    });
  }

  Future<void> _performSearch(String query) async {
    final provider = Provider.of<ResourceProvider>(context, listen: false);
    await provider.searchResources(query);
    await _saveToHistory(query);
  }

  Future<void> _loadSuggestions(String query) async {
    final provider = Provider.of<ResourceProvider>(context, listen: false);
    final suggestions = await provider.getSearchSuggestions(query);

    if (mounted) {
      setState(() {
        _suggestions = suggestions.take(5).toList();
      });
    }
  }

  Future<void> _startVoiceSearch() async {
    if (!await _speech.initialize()) {
      _showSnack('Voice search not available', isError: true);
      return;
    }

    setState(() => _isVoiceListening = true);

    await _speech.listen(
      onResult: (result) {
        setState(() {
          _searchController.text = result.recognizedWords;
          _searchQuery = result.recognizedWords;
        });

        if (result.finalResult) {
          _performSearch(result.recognizedWords);
          setState(() => _isVoiceListening = false);
        }
      },
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 5),
    );
  }

  void _stopVoiceSearch() {
    _speech.stop();
    setState(() => _isVoiceListening = false);
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red : AppColors.successColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primaryColor.withOpacity(0.05),
              Colors.white,
              AppColors.accentColor.withOpacity(0.05),
            ],
          ),
        ),
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildAppBar(),
              _buildSearchBar(),
              if (_searchQuery.isEmpty) ...[
                if (_searchHistory.isNotEmpty) _buildSearchHistory(),
                if (_trendingSearches.isNotEmpty) _buildTrendingSearches(),
              ] else ...[
                if (_suggestions.isNotEmpty) _buildSuggestions(),
                _buildSearchResults(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 80,
      floating: true,
      pinned: true,
      elevation: 0,
      backgroundColor: AppColors.primaryColor,
      title: const Text(
        'Search Resources',
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.filter_list_rounded),
          onPressed: () => Navigator.pushNamed(context, AppRoutes.filter),
          tooltip: 'Filters',
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: TextField(
            controller: _searchController,
            focusNode: _searchFocus,
            onChanged: _onSearchChanged,
            decoration: InputDecoration(
              hintText: 'Search by title, subject, or department...',
              prefixIcon: const Icon(
                Icons.search_rounded,
                color: AppColors.primaryColor,
              ),
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_searchQuery.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _searchQuery = '';
                          _suggestions.clear();
                        });
                      },
                    ),
                  IconButton(
                    icon: Icon(
                      _isVoiceListening
                          ? Icons.mic_rounded
                          : Icons.mic_none_rounded,
                      color: _isVoiceListening ? Colors.red : AppColors.primaryColor,
                    ),
                    onPressed: _isVoiceListening ? _stopVoiceSearch : _startVoiceSearch,
                    tooltip: 'Voice Search',
                  ),
                ],
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 15),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchHistory() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.history_rounded, color: AppColors.primaryColor, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Recent Searches',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: _clearHistory,
                  child: const Text('Clear'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _searchHistory.map((query) {
                return ActionChip(
                  label: Text(query),
                  avatar: const Icon(Icons.history_rounded, size: 16),
                  onPressed: () {
                    _searchController.text = query;
                    _searchQuery = query;
                    _performSearch(query);
                  },
                  backgroundColor: Colors.white,
                  side: BorderSide(color: Colors.grey[300]!),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendingSearches() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.trending_up_rounded, color: AppColors.accentColor, size: 20),
                SizedBox(width: 8),
                Text(
                  'Trending Searches',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ..._trendingSearches.asMap().entries.map((entry) {
              return ListTile(
                leading: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.accentColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${entry.key + 1}',
                      style: const TextStyle(
                        color: AppColors.accentColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                title: Text(entry.value),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                onTap: () {
                  _searchController.text = entry.value;
                  _searchQuery = entry.value;
                  _performSearch(entry.value);
                },
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestions() {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Suggestions',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            ..._suggestions.map((suggestion) {
              return ListTile(
                leading: const Icon(Icons.search_rounded, size: 20),
                title: Text(suggestion),
                dense: true,
                onTap: () {
                  _searchController.text = suggestion;
                  _searchQuery = suggestion;
                  _performSearch(suggestion);
                },
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    return Consumer<ResourceProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const SliverFillRemaining(
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final results = provider.searchResults;

        if (results.isEmpty) {
          return SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.search_off_rounded,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No results found',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Try different keywords',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
                  (context, index) {
                return TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: Duration(milliseconds: 300 + (index * 50)),
                  curve: Curves.easeOut,
                  builder: (context, value, child) {
                    return Opacity(
                      opacity: value,
                      child: Transform.translate(
                        offset: Offset(0, 20 * (1 - value)),
                        child: child,
                      ),
                    );
                  },
                  child: ResourceCard(
                    resource: results[index],
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      AppRoutes.navigateToResourceDetail(
                        context,
                        results[index].id,
                      );
                    },
                  ),
                );
              },
              childCount: results.length,
            ),
          ),
        );
      },
    );
  }
}