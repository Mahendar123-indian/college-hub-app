// lib/providers/academic_search_provider.dart

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:io';

import '../data/services/academic_search_engine.dart';
import '../core/constants/app_constants.dart';

/// 🎓 ACADEMIC SEARCH PROVIDER - ULTRA MODERN VERSION
/// State management for academic search with persistent history and analytics
class AcademicSearchProvider with ChangeNotifier {
  final AcademicSearchEngine _searchEngine = AcademicSearchEngine();

  List<SearchHistoryItem> _searchHistory = [];
  List<SearchHistoryItem> _pinnedSearches = [];
  List<SearchHistoryItem> _recentSearches = [];
  Map<String, int> _subjectStats = {};
  bool _isInitialized = false;
  bool _isSearching = false;

  // Getters
  List<SearchHistoryItem> get searchHistory => _searchHistory;
  List<SearchHistoryItem> get pinnedSearches => _pinnedSearches;
  List<SearchHistoryItem> get recentSearches => _recentSearches;
  Map<String, int> get subjectStats => _subjectStats;
  bool get isInitialized => _isInitialized;
  bool get isSearching => _isSearching;

  // ═══════════════════════════════════════════════════════════════
  // INITIALIZATION
  // ═══════════════════════════════════════════════════════════════

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      debugPrint('🔄 Initializing Academic Search Provider...');

      await _searchEngine.initialize();
      await loadHistory();
      _calculateStats();

      _isInitialized = true;
      notifyListeners();

      debugPrint('✅ Academic Search Provider ready');
    } catch (e) {
      debugPrint('❌ Academic Search Provider init error: $e');
      rethrow;
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // SEARCH EXECUTION
  // ═══════════════════════════════════════════════════════════════

  Future<AcademicSearchResult> performSearch({
    required String query,
    required String subject,
    required String academicLevel,
    required String examType,
    List<File>? pdfFiles,
    List<File>? imageFiles,
    String? userId,
  }) async {
    try {
      if (!_isInitialized) await initialize();

      _isSearching = true;
      notifyListeners();

      debugPrint('🔍 Starting search: "$query"');
      debugPrint('📚 Subject: $subject | Level: $academicLevel | Exam: $examType');
      debugPrint('📄 PDFs: ${pdfFiles?.length ?? 0} | Images: ${imageFiles?.length ?? 0}');

      // Perform search
      final result = await _searchEngine.search(
        query: query,
        subject: subject,
        academicLevel: academicLevel,
        branch: 'Engineering',
        examType: examType,
        pdfFiles: pdfFiles,
        imageFiles: imageFiles,
      );

      debugPrint('✅ Search completed successfully');
      debugPrint('   - Videos: ${result.rankedVideos.length}');
      debugPrint('   - PDF Chunks: ${result.pdfSources.chunks.length}');
      debugPrint('   - Practice Questions: ${result.practiceQuestions.length}');

      // Save to history
      await _saveToHistory(
        query: query,
        subject: subject,
        academicLevel: academicLevel,
        examType: examType,
        userId: userId,
      );

      _isSearching = false;
      notifyListeners();

      return result;
    } catch (e) {
      debugPrint('❌ Search error: $e');
      _isSearching = false;
      notifyListeners();
      rethrow;
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // SEARCH HISTORY MANAGEMENT
  // ═══════════════════════════════════════════════════════════════

  Future<void> loadHistory() async {
    try {
      debugPrint('📖 Loading search history...');

      final box = await Hive.openBox<Map>(AppConstants.academicSearchHistoryBox);

      _searchHistory = box.values
          .map((item) {
        try {
          return SearchHistoryItem.fromMap(Map<String, dynamic>.from(item));
        } catch (e) {
          debugPrint('⚠️ Error parsing history item: $e');
          return null;
        }
      })
          .whereType<SearchHistoryItem>()
          .toList();

      // Sort by timestamp (newest first)
      _searchHistory.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      // Load pinned searches
      final pinnedBox = await Hive.openBox<Map>(AppConstants.pinnedSearchesBox);
      _pinnedSearches = pinnedBox.values
          .map((item) {
        try {
          return SearchHistoryItem.fromMap(Map<String, dynamic>.from(item));
        } catch (e) {
          debugPrint('⚠️ Error parsing pinned item: $e');
          return null;
        }
      })
          .whereType<SearchHistoryItem>()
          .toList();

      // Get recent searches (last 10)
      _recentSearches = _searchHistory.take(10).toList();

      // Calculate statistics
      _calculateStats();

      debugPrint('✅ Loaded ${_searchHistory.length} history items');
      debugPrint('✅ Loaded ${_pinnedSearches.length} pinned items');

      notifyListeners();
    } catch (e) {
      debugPrint('❌ Load history error: $e');
    }
  }

  Future<void> _saveToHistory({
    required String query,
    required String subject,
    required String academicLevel,
    required String examType,
    String? userId,
  }) async {
    try {
      final box = await Hive.openBox<Map>(AppConstants.academicSearchHistoryBox);

      // Check if query already exists
      final existingIndex = _searchHistory.indexWhere(
            (item) => item.query.toLowerCase() == query.toLowerCase(),
      );

      final newItem = SearchHistoryItem(
        query: query,
        subject: subject,
        academicLevel: academicLevel,
        examType: examType,
        timestamp: DateTime.now(),
        userId: userId,
      );

      if (existingIndex != -1) {
        // Update existing entry
        _searchHistory[existingIndex] = newItem;
        await box.putAt(existingIndex, newItem.toMap());
        debugPrint('✅ Updated existing history entry');
      } else {
        // Add new entry
        _searchHistory.insert(0, newItem);
        await box.add(newItem.toMap());

        // Keep only last 100 searches
        if (_searchHistory.length > 100) {
          _searchHistory.removeLast();
          await box.deleteAt(box.length - 1);
        }

        debugPrint('✅ Added new history entry');
      }

      // Update recent searches
      _recentSearches = _searchHistory.take(10).toList();

      // Update statistics
      _calculateStats();

      notifyListeners();
    } catch (e) {
      debugPrint('❌ Save history error: $e');
    }
  }

  Future<void> removeFromHistory(String query) async {
    try {
      final box = await Hive.openBox<Map>(AppConstants.academicSearchHistoryBox);

      final index = _searchHistory.indexWhere(
            (item) => item.query == query,
      );

      if (index != -1) {
        _searchHistory.removeAt(index);
        await box.deleteAt(index);

        // Update recent searches
        _recentSearches = _searchHistory.take(10).toList();

        // Update statistics
        _calculateStats();

        debugPrint('✅ Removed from history: $query');
        notifyListeners();
      }
    } catch (e) {
      debugPrint('❌ Remove from history error: $e');
    }
  }

  Future<void> clearHistory() async {
    try {
      final box = await Hive.openBox<Map>(AppConstants.academicSearchHistoryBox);
      await box.clear();
      _searchHistory.clear();
      _recentSearches.clear();
      _subjectStats.clear();

      debugPrint('✅ History cleared');
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Clear history error: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // PINNED SEARCHES
  // ═══════════════════════════════════════════════════════════════

  Future<void> pinSearch(SearchHistoryItem item) async {
    try {
      if (_pinnedSearches.any((p) => p.query == item.query)) {
        debugPrint('⚠️ Search already pinned: ${item.query}');
        return;
      }

      final box = await Hive.openBox<Map>(AppConstants.pinnedSearchesBox);

      _pinnedSearches.insert(0, item);
      await box.add(item.toMap());

      // Keep only 10 pinned searches
      if (_pinnedSearches.length > 10) {
        _pinnedSearches.removeLast();
        await box.deleteAt(box.length - 1);
      }

      debugPrint('✅ Pinned search: ${item.query}');
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Pin search error: $e');
    }
  }

  Future<void> unpinSearch(String query) async {
    try {
      final box = await Hive.openBox<Map>(AppConstants.pinnedSearchesBox);

      final index = _pinnedSearches.indexWhere(
            (item) => item.query == query,
      );

      if (index != -1) {
        _pinnedSearches.removeAt(index);
        await box.deleteAt(index);

        debugPrint('✅ Unpinned search: $query');
        notifyListeners();
      }
    } catch (e) {
      debugPrint('❌ Unpin search error: $e');
    }
  }

  bool isPinned(String query) {
    return _pinnedSearches.any((item) => item.query == query);
  }

  Future<void> clearPinnedSearches() async {
    try {
      final box = await Hive.openBox<Map>(AppConstants.pinnedSearchesBox);
      await box.clear();
      _pinnedSearches.clear();

      debugPrint('✅ Pinned searches cleared');
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Clear pinned searches error: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // SEARCH ANALYTICS
  // ═══════════════════════════════════════════════════════════════

  void _calculateStats() {
    _subjectStats.clear();

    for (var item in _searchHistory) {
      _subjectStats[item.subject] = (_subjectStats[item.subject] ?? 0) + 1;
    }

    debugPrint('📊 Stats calculated: ${_subjectStats.length} subjects tracked');
  }

  Map<String, int> getTopSubjects({int limit = 5}) {
    final sorted = _subjectStats.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Map.fromEntries(sorted.take(limit));
  }

  Map<String, int> getExamTypeDistribution() {
    final distribution = <String, int>{};

    for (var item in _searchHistory) {
      distribution[item.examType] = (distribution[item.examType] ?? 0) + 1;
    }

    return distribution;
  }

  Map<String, int> getAcademicLevelDistribution() {
    final distribution = <String, int>{};

    for (var item in _searchHistory) {
      distribution[item.academicLevel] =
          (distribution[item.academicLevel] ?? 0) + 1;
    }

    return distribution;
  }

  int getTotalSearches() => _searchHistory.length;

  List<SearchHistoryItem> getRecentSearches({int limit = 10}) {
    return _searchHistory.take(limit).toList();
  }

  List<SearchHistoryItem> getSearchesBySubject(String subject) {
    return _searchHistory
        .where((item) => item.subject.toLowerCase() == subject.toLowerCase())
        .toList();
  }

  List<SearchHistoryItem> getSearchesByExamType(String examType) {
    return _searchHistory
        .where((item) => item.examType.toLowerCase() == examType.toLowerCase())
        .toList();
  }

  List<SearchHistoryItem> searchInHistory(String searchTerm) {
    final term = searchTerm.toLowerCase();
    return _searchHistory.where((item) {
      return item.query.toLowerCase().contains(term) ||
          item.subject.toLowerCase().contains(term);
    }).toList();
  }

  // ═══════════════════════════════════════════════════════════════
  // TIME-BASED ANALYTICS
  // ═══════════════════════════════════════════════════════════════

  List<SearchHistoryItem> getSearchesToday() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return _searchHistory.where((item) {
      final itemDate = DateTime(
        item.timestamp.year,
        item.timestamp.month,
        item.timestamp.day,
      );
      return itemDate.isAtSameMomentAs(today);
    }).toList();
  }

  List<SearchHistoryItem> getSearchesThisWeek() {
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));

    return _searchHistory
        .where((item) => item.timestamp.isAfter(weekAgo))
        .toList();
  }

  List<SearchHistoryItem> getSearchesThisMonth() {
    final now = DateTime.now();
    final monthAgo = now.subtract(const Duration(days: 30));

    return _searchHistory
        .where((item) => item.timestamp.isAfter(monthAgo))
        .toList();
  }

  // ═══════════════════════════════════════════════════════════════
  // SUGGESTIONS & RECOMMENDATIONS
  // ═══════════════════════════════════════════════════════════════

  List<String> getSuggestedQueries({int limit = 5}) {
    // Return most frequent searches
    final queryCounts = <String, int>{};

    for (var item in _searchHistory) {
      queryCounts[item.query] = (queryCounts[item.query] ?? 0) + 1;
    }

    final sorted = queryCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sorted.take(limit).map((e) => e.key).toList();
  }

  List<String> getRelatedQueries(String query, {int limit = 5}) {
    // Find queries with similar subjects
    final item = _searchHistory.firstWhere(
          (item) => item.query.toLowerCase() == query.toLowerCase(),
      orElse: () => _searchHistory.first,
    );

    return _searchHistory
        .where((h) =>
    h.subject == item.subject &&
        h.query.toLowerCase() != query.toLowerCase())
        .take(limit)
        .map((h) => h.query)
        .toList();
  }

  // ═══════════════════════════════════════════════════════════════
  // EXPORT & IMPORT
  // ═══════════════════════════════════════════════════════════════

  Map<String, dynamic> exportHistory() {
    return {
      'version': '1.0',
      'exported_at': DateTime.now().toIso8601String(),
      'total_searches': _searchHistory.length,
      'history': _searchHistory.map((item) => item.toMap()).toList(),
      'pinned': _pinnedSearches.map((item) => item.toMap()).toList(),
      'stats': {
        'subjects': _subjectStats,
        'exam_types': getExamTypeDistribution(),
        'academic_levels': getAcademicLevelDistribution(),
      },
    };
  }

  Future<void> importHistory(Map<String, dynamic> data) async {
    try {
      final historyData = data['history'] as List?;
      final pinnedData = data['pinned'] as List?;

      if (historyData != null) {
        final box = await Hive.openBox<Map>(AppConstants.academicSearchHistoryBox);
        await box.clear();

        for (var item in historyData) {
          final historyItem = SearchHistoryItem.fromMap(
              Map<String, dynamic>.from(item));
          await box.add(historyItem.toMap());
        }
      }

      if (pinnedData != null) {
        final box = await Hive.openBox<Map>(AppConstants.pinnedSearchesBox);
        await box.clear();

        for (var item in pinnedData) {
          final pinnedItem = SearchHistoryItem.fromMap(
              Map<String, dynamic>.from(item));
          await box.add(pinnedItem.toMap());
        }
      }

      await loadHistory();
      debugPrint('✅ History imported successfully');
    } catch (e) {
      debugPrint('❌ Import history error: $e');
      rethrow;
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // CLEANUP & MAINTENANCE
  // ═══════════════════════════════════════════════════════════════

  Future<void> removeOldSearches({int daysOld = 90}) async {
    try {
      final cutoffDate = DateTime.now().subtract(Duration(days: daysOld));

      final box = await Hive.openBox<Map>(AppConstants.academicSearchHistoryBox);

      final indicesToRemove = <int>[];
      for (int i = 0; i < _searchHistory.length; i++) {
        if (_searchHistory[i].timestamp.isBefore(cutoffDate)) {
          indicesToRemove.add(i);
        }
      }

      // Remove in reverse order to maintain indices
      for (var index in indicesToRemove.reversed) {
        _searchHistory.removeAt(index);
        await box.deleteAt(index);
      }

      if (indicesToRemove.isNotEmpty) {
        _recentSearches = _searchHistory.take(10).toList();
        _calculateStats();
        notifyListeners();

        debugPrint('✅ Removed ${indicesToRemove.length} old searches');
      }
    } catch (e) {
      debugPrint('❌ Remove old searches error: $e');
    }
  }

  Future<void> compactHistory() async {
    try {
      final box = await Hive.openBox<Map>(AppConstants.academicSearchHistoryBox);
      await box.compact();

      final pinnedBox = await Hive.openBox<Map>(AppConstants.pinnedSearchesBox);
      await pinnedBox.compact();

      debugPrint('✅ History compacted');
    } catch (e) {
      debugPrint('❌ Compact history error: $e');
    }
  }
}

// ═══════════════════════════════════════════════════════════════
// SEARCH HISTORY ITEM MODEL
// ═══════════════════════════════════════════════════════════════

class SearchHistoryItem {
  final String query;
  final String subject;
  final String academicLevel;
  final String examType;
  final DateTime timestamp;
  final String? userId;
  final Map<String, dynamic>? metadata;

  SearchHistoryItem({
    required this.query,
    required this.subject,
    required this.academicLevel,
    required this.examType,
    required this.timestamp,
    this.userId,
    this.metadata,
  });

  Map<String, dynamic> toMap() {
    return {
      'query': query,
      'subject': subject,
      'academicLevel': academicLevel,
      'examType': examType,
      'timestamp': timestamp.toIso8601String(),
      'userId': userId,
      'metadata': metadata,
    };
  }

  factory SearchHistoryItem.fromMap(Map<String, dynamic> map) {
    return SearchHistoryItem(
      query: map['query'] ?? '',
      subject: map['subject'] ?? '',
      academicLevel: map['academicLevel'] ?? '',
      examType: map['examType'] ?? '',
      timestamp: DateTime.parse(
          map['timestamp'] ?? DateTime.now().toIso8601String()),
      userId: map['userId'],
      metadata: map['metadata'] != null
          ? Map<String, dynamic>.from(map['metadata'])
          : null,
    );
  }

  SearchHistoryItem copyWith({
    String? query,
    String? subject,
    String? academicLevel,
    String? examType,
    DateTime? timestamp,
    String? userId,
    Map<String, dynamic>? metadata,
  }) {
    return SearchHistoryItem(
      query: query ?? this.query,
      subject: subject ?? this.subject,
      academicLevel: academicLevel ?? this.academicLevel,
      examType: examType ?? this.examType,
      timestamp: timestamp ?? this.timestamp,
      userId: userId ?? this.userId,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  String toString() {
    return 'SearchHistoryItem(query: $query, subject: $subject, timestamp: $timestamp)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is SearchHistoryItem &&
        other.query == query &&
        other.subject == subject &&
        other.timestamp == timestamp;
  }

  @override
  int get hashCode {
    return query.hashCode ^ subject.hashCode ^ timestamp.hashCode;
  }
}