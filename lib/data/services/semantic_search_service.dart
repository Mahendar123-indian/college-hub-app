// lib/data/services/semantic_search_service.dart

import 'package:flutter/foundation.dart';
import 'dart:math' as math;
import 'dart:io';
import 'academic_search_engine.dart';
import 'document_intelligence_service.dart';

/// 🔍 SEMANTIC SEARCH SERVICE - ULTRA ADVANCED VERSION
/// Multi-strategy text analysis, semantic chunking, and intelligent relevance scoring
/// Fully integrated with Document Intelligence Service and Academic Search Engine
class SemanticSearchService {
  static final SemanticSearchService _instance = SemanticSearchService._internal();
  factory SemanticSearchService() => _instance;
  SemanticSearchService._internal();

  final DocumentIntelligenceService _docService = DocumentIntelligenceService();

  bool _isInitialized = false;

  // Advanced stopwords list for better keyword extraction
  final _stopWords = {
    // Articles & Prepositions
    'the', 'a', 'an', 'and', 'or', 'but', 'in', 'on', 'at', 'to', 'for',
    'of', 'with', 'from', 'by', 'as', 'into', 'through', 'during', 'before',
    'after', 'above', 'below', 'between', 'under', 'over',

    // Pronouns
    'i', 'you', 'he', 'she', 'it', 'we', 'they', 'them', 'their', 'this',
    'that', 'these', 'those', 'my', 'your', 'his', 'her', 'its', 'our',

    // Verbs (common)
    'is', 'am', 'are', 'was', 'were', 'be', 'been', 'being', 'have', 'has',
    'had', 'do', 'does', 'did', 'will', 'would', 'should', 'could', 'may',
    'might', 'must', 'can', 'shall',

    // Adverbs & Adjectives
    'very', 'really', 'quite', 'rather', 'too', 'also', 'just', 'only',
    'even', 'still', 'yet', 'already', 'always', 'never', 'often', 'sometimes',
    'usually', 'rarely', 'ever', 'here', 'there', 'where', 'when', 'how',
    'why', 'what', 'which', 'who', 'whose', 'whom',

    // Quantifiers
    'all', 'some', 'any', 'many', 'much', 'few', 'more', 'most', 'less',
    'least', 'several', 'each', 'every', 'both', 'either', 'neither',

    // Conjunctions
    'than', 'then', 'so', 'because', 'since', 'unless', 'until', 'while',
    'although', 'though', 'if', 'whether',

    // Others
    'out', 'up', 'down', 'off', 'own', 'same', 'such', 'no', 'not', 'now',
    'about', 'against', 'along', 'among', 'around', 'aside', 'across',
  };

  // Academic keywords that should be preserved
  final _academicKeywords = {
    'algorithm', 'theorem', 'proof', 'definition', 'equation', 'formula',
    'method', 'approach', 'technique', 'concept', 'theory', 'principle',
    'analysis', 'solution', 'example', 'problem', 'question', 'answer',
    'explain', 'describe', 'compare', 'contrast', 'evaluate', 'discuss',
  };

  // ═══════════════════════════════════════════════════════════════
  // INITIALIZATION
  // ═══════════════════════════════════════════════════════════════

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      debugPrint('🔄 Initializing Semantic Search Service...');
      _isInitialized = true;
      debugPrint('✅ Semantic Search Service initialized');
    } catch (e) {
      debugPrint('❌ Semantic Search Service init error: $e');
      _isInitialized = false;
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // PRIMARY SEARCH METHOD - SINGLE DOCUMENT
  // ═══════════════════════════════════════════════════════════════

  Future<List<PDFChunk>> searchInDocument({
    required String documentText,
    required String query,
    required String fileName,
    int maxResults = 5,
  }) async {
    try {
      if (!_isInitialized) await initialize();

      debugPrint('🔍 Searching document: $fileName');
      debugPrint('📄 Document length: ${documentText.length} characters');
      debugPrint('🎯 Query: "$query"');

      // Clean and prepare document
      final cleanedText = _cleanText(documentText);

      if (cleanedText.length < 50) {
        debugPrint('⚠️ Document too short for meaningful search');
        return [];
      }

      // Use DocumentIntelligenceService for semantic chunking
      final intelligentChunks = _docService.splitIntoSemanticChunks(
        cleanedText,
        fileName: fileName,
        maxChunkSize: 1000,
        overlapSize: 200,
      );

      debugPrint('📑 Created ${intelligentChunks.length} semantic chunks');

      // Extract and analyze query
      final queryKeywords = _extractKeywords(query);
      final queryLower = query.toLowerCase();

      debugPrint('🔑 Query keywords: ${queryKeywords.take(5).join(", ")}');

      // Score each chunk with advanced multi-factor algorithm
      final scoredChunks = <_ScoredChunk>[];

      for (var chunk in intelligentChunks) {
        final score = _calculateAdvancedRelevanceScore(
          chunkText: chunk.text,
          chunkKeywords: chunk.keywords,
          queryKeywords: queryKeywords,
          query: query,
          queryLower: queryLower,
        );

        if (score > 0.05) {
          // Minimum relevance threshold
          scoredChunks.add(_ScoredChunk(
            chunk: _DocumentChunk(
              text: chunk.text,
              fileName: chunk.fileName,
              pageNumber: chunk.pageNumber,
              keywords: chunk.keywords,
              startPosition: chunk.startPosition,
              endPosition: chunk.endPosition,
            ),
            score: score,
          ));
        }
      }

      // Sort by relevance score (highest first)
      scoredChunks.sort((a, b) => b.score.compareTo(a.score));

      // Convert to PDFChunk format
      final topChunks = scoredChunks
          .take(maxResults)
          .map((sc) => PDFChunk(
        text: sc.chunk.text,
        fileName: sc.chunk.fileName,
        pageNumber: sc.chunk.pageNumber,
        relevanceScore: sc.score,
        keywords: sc.chunk.keywords,
      ))
          .toList();

      debugPrint('✅ Found ${topChunks.length} relevant chunks');
      if (topChunks.isNotEmpty) {
        debugPrint('🏆 Top chunk score: ${(topChunks.first.relevanceScore * 100).toStringAsFixed(1)}%');
        debugPrint('📄 Top chunk page: ${topChunks.first.pageNumber}');
      }

      return topChunks;
    } catch (e) {
      debugPrint('❌ Semantic search error: $e');
      return [];
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // ADVANCED: SEARCH MULTIPLE DOCUMENTS
  // ═══════════════════════════════════════════════════════════════

  Future<List<PDFChunk>> searchInMultipleDocuments({
    required List<File> files,
    required String query,
    int maxResults = 10,
  }) async {
    try {
      if (!_isInitialized) await initialize();

      debugPrint('🔍 Searching ${files.length} documents for: "$query"');

      final allChunks = <PDFChunk>[];

      for (final file in files) {
        try {
          // Extract text using DocumentIntelligenceService
          final text = await _docService.extractText(file);

          if (text.isEmpty || text.length < 50) {
            debugPrint('⚠️ Skipping ${file.path} - insufficient content');
            continue;
          }

          // Search this document
          final chunks = await searchInDocument(
            documentText: text,
            query: query,
            fileName: file.path.split('/').last,
            maxResults: 5,
          );

          allChunks.addAll(chunks);
        } catch (e) {
          debugPrint('⚠️ Error processing ${file.path}: $e');
          continue;
        }
      }

      // Re-rank all chunks together
      allChunks.sort((a, b) => b.relevanceScore.compareTo(a.relevanceScore));

      final topResults = allChunks.take(maxResults).toList();

      debugPrint('✅ Multi-document search complete: ${topResults.length} results');

      return topResults;
    } catch (e) {
      debugPrint('❌ Multi-document search error: $e');
      return [];
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // TEXT CLEANING & NORMALIZATION
  // ═══════════════════════════════════════════════════════════════

  String _cleanText(String text) {
    return text
        .replaceAll(RegExp(r'\s+'), ' ') // Normalize whitespace
        .replaceAll(RegExp(r'\n\s*\n+'), '\n\n') // Clean multiple newlines
        .replaceAll(RegExp(r'[^\S\n]+'), ' ') // Replace tabs with spaces
        .trim();
  }

  // ═══════════════════════════════════════════════════════════════
  // ADVANCED KEYWORD EXTRACTION
  // ═══════════════════════════════════════════════════════════════

  List<String> _extractKeywords(String text, {int limit = 20}) {
    // Tokenize and filter
    final words = text
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), ' ')
        .split(RegExp(r'\s+'))
        .where((word) =>
    word.length > 2 &&
        (!_stopWords.contains(word) || _academicKeywords.contains(word)))
        .toList();

    // Calculate word frequencies
    final frequency = <String, int>{};
    for (var word in words) {
      frequency[word] = (frequency[word] ?? 0) + 1;
    }

    // Boost academic keywords
    for (var word in _academicKeywords) {
      if (frequency.containsKey(word)) {
        frequency[word] = (frequency[word]! * 1.5).round();
      }
    }

    // Sort by frequency
    final sortedKeywords = frequency.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Return top keywords
    return sortedKeywords.take(limit).map((e) => e.key).toList();
  }

  // ═══════════════════════════════════════════════════════════════
  // ADVANCED MULTI-FACTOR RELEVANCE SCORING
  // ═══════════════════════════════════════════════════════════════

  double _calculateAdvancedRelevanceScore({
    required String chunkText,
    required List<String> chunkKeywords,
    required List<String> queryKeywords,
    required String query,
    required String queryLower,
  }) {
    double score = 0.0;
    final chunkLower = chunkText.toLowerCase();

    // FACTOR 1: Exact Query Match (35% weight)
    // Highest priority - exact phrase match
    if (chunkLower.contains(queryLower)) {
      score += 0.35;

      // Bonus for multiple occurrences
      final occurrences = _countOccurrences(chunkLower, queryLower);
      score += math.min(occurrences - 1, 3) * 0.05; // Max +0.15
    }

    // FACTOR 2: Keyword Overlap Score (25% weight)
    // Exact keyword matches from query
    if (queryKeywords.isNotEmpty) {
      final matchCount = queryKeywords.where((qk) => chunkKeywords.contains(qk)).length;
      final keywordScore = matchCount / queryKeywords.length;
      score += keywordScore * 0.25;
    }

    // FACTOR 3: Partial Keyword Matching (20% weight)
    // Keywords appear in text even if not in extracted keywords
    if (queryKeywords.isNotEmpty) {
      final partialMatches = queryKeywords.where((qk) => chunkLower.contains(qk)).length;
      final partialScore = partialMatches / queryKeywords.length;
      score += partialScore * 0.20;
    }

    // FACTOR 4: Word Proximity Score (10% weight)
    // Query words appear close together
    final proximityScore = _calculateProximityScore(chunkLower, queryLower);
    score += proximityScore * 0.10;

    // FACTOR 5: Semantic Similarity (10% weight)
    // Keyword overlap between query and chunk
    final semanticScore = _calculateSemanticSimilarity(queryKeywords, chunkKeywords);
    score += semanticScore * 0.10;

    // BONUS FACTORS
    // Academic keyword bonus
    final academicBonus = _calculateAcademicBonus(chunkKeywords, queryKeywords);
    score += academicBonus * 0.05;

    return score.clamp(0.0, 1.0);
  }

  // ═══════════════════════════════════════════════════════════════
  // HELPER: COUNT OCCURRENCES
  // ═══════════════════════════════════════════════════════════════

  int _countOccurrences(String text, String pattern) {
    if (pattern.isEmpty) return 0;

    int count = 0;
    int index = 0;

    while ((index = text.indexOf(pattern, index)) != -1) {
      count++;
      index += pattern.length;
    }

    return count;
  }

  // ═══════════════════════════════════════════════════════════════
  // HELPER: PROXIMITY SCORE
  // ═══════════════════════════════════════════════════════════════

  double _calculateProximityScore(String chunkLower, String queryLower) {
    final queryWords = queryLower.split(RegExp(r'\s+'));

    if (queryWords.length <= 1) return 0.0;

    int proximityMatches = 0;
    const maxDistance = 50; // Characters

    for (int i = 0; i < queryWords.length - 1; i++) {
      final word1 = queryWords[i];
      final word2 = queryWords[i + 1];

      final index1 = chunkLower.indexOf(word1);
      final index2 = chunkLower.indexOf(word2, index1);

      if (index1 != -1 && index2 != -1) {
        final distance = (index2 - index1).abs();
        if (distance > 0 && distance < maxDistance) {
          proximityMatches++;
        }
      }
    }

    final maxPossibleMatches = queryWords.length - 1;
    return maxPossibleMatches > 0 ? proximityMatches / maxPossibleMatches : 0.0;
  }

  // ═══════════════════════════════════════════════════════════════
  // HELPER: SEMANTIC SIMILARITY
  // ═══════════════════════════════════════════════════════════════

  double _calculateSemanticSimilarity(
      List<String> queryKeywords,
      List<String> chunkKeywords,
      ) {
    if (queryKeywords.isEmpty || chunkKeywords.isEmpty) return 0.0;

    final querySet = queryKeywords.toSet();
    final chunkSet = chunkKeywords.toSet();

    final intersection = querySet.intersection(chunkSet).length;
    final union = querySet.union(chunkSet).length;

    return union > 0 ? intersection / union : 0.0;
  }

  // ═══════════════════════════════════════════════════════════════
  // HELPER: ACADEMIC KEYWORD BONUS
  // ═══════════════════════════════════════════════════════════════

  double _calculateAcademicBonus(
      List<String> chunkKeywords,
      List<String> queryKeywords,
      ) {
    final academicInChunk = chunkKeywords.where((k) => _academicKeywords.contains(k)).length;
    final academicInQuery = queryKeywords.where((k) => _academicKeywords.contains(k)).length;

    if (academicInQuery > 0 && academicInChunk > 0) {
      return math.min(academicInChunk / academicInQuery, 1.0);
    }

    return academicInChunk > 0 ? 0.3 : 0.0;
  }

  // ═══════════════════════════════════════════════════════════════
  // ADVANCED: TF-IDF CALCULATION
  // ═══════════════════════════════════════════════════════════════

  Map<String, double> calculateTfIdf(String text, List<String> allDocuments) {
    final tfIdf = <String, double>{};
    final keywords = _extractKeywords(text, limit: 50);

    for (var keyword in keywords) {
      // Term Frequency (TF)
      final tf = _countOccurrences(text.toLowerCase(), keyword);

      // Document Frequency (DF)
      int df = 0;
      for (var doc in allDocuments) {
        if (doc.toLowerCase().contains(keyword)) {
          df++;
        }
      }

      // TF-IDF Calculation
      if (df > 0 && tf > 0) {
        final idf = math.log(allDocuments.length / df);
        tfIdf[keyword] = tf * idf;
      }
    }

    return tfIdf;
  }

  // ═══════════════════════════════════════════════════════════════
  // ADVANCED: COSINE SIMILARITY
  // ═══════════════════════════════════════════════════════════════

  double calculateCosineSimilarity(String text1, String text2) {
    final keywords1 = _extractKeywords(text1, limit: 50).toSet();
    final keywords2 = _extractKeywords(text2, limit: 50).toSet();

    if (keywords1.isEmpty || keywords2.isEmpty) return 0.0;

    final intersection = keywords1.intersection(keywords2).length;
    final magnitude = math.sqrt(
        keywords1.length.toDouble() * keywords2.length.toDouble()
    );

    return magnitude > 0 ? intersection / magnitude : 0.0;
  }

  // ═══════════════════════════════════════════════════════════════
  // ADVANCED: JACCARD SIMILARITY
  // ═══════════════════════════════════════════════════════════════

  double calculateJaccardSimilarity(String text1, String text2) {
    final keywords1 = _extractKeywords(text1, limit: 50).toSet();
    final keywords2 = _extractKeywords(text2, limit: 50).toSet();

    if (keywords1.isEmpty && keywords2.isEmpty) return 1.0;
    if (keywords1.isEmpty || keywords2.isEmpty) return 0.0;

    final intersection = keywords1.intersection(keywords2).length;
    final union = keywords1.union(keywords2).length;

    return union > 0 ? intersection / union : 0.0;
  }

  // ═══════════════════════════════════════════════════════════════
  // RANKING & FILTERING
  // ═══════════════════════════════════════════════════════════════

  List<PDFChunk> rankAndFilterChunks(
      List<PDFChunk> chunks, {
        double minRelevanceScore = 0.1,
        int maxResults = 10,
      }) {
    // Filter by minimum score
    final filtered = chunks.where((c) => c.relevanceScore >= minRelevanceScore).toList();

    // Sort by relevance
    filtered.sort((a, b) => b.relevanceScore.compareTo(a.relevanceScore));

    // Return top results
    return filtered.take(maxResults).toList();
  }

  // ═══════════════════════════════════════════════════════════════
  // QUERY EXPANSION
  // ═══════════════════════════════════════════════════════════════

  List<String> expandQuery(String query) {
    final expanded = <String>[query];
    final keywords = _extractKeywords(query);

    // Add individual keywords
    expanded.addAll(keywords);

    // Add bigrams (word pairs)
    final words = query.toLowerCase().split(RegExp(r'\s+'));
    for (int i = 0; i < words.length - 1; i++) {
      expanded.add('${words[i]} ${words[i + 1]}');
    }

    return expanded.toSet().toList();
  }

  // ═══════════════════════════════════════════════════════════════
  // STATISTICS & ANALYTICS
  // ═══════════════════════════════════════════════════════════════

  Map<String, dynamic> getSearchStatistics(
      String query,
      List<PDFChunk> results,
      ) {
    if (results.isEmpty) {
      return {
        'query': query,
        'totalResults': 0,
        'averageScore': 0.0,
        'maxScore': 0.0,
        'minScore': 0.0,
        'uniqueFiles': 0,
        'uniquePages': 0,
      };
    }

    final scores = results.map((r) => r.relevanceScore).toList();
    final files = results.map((r) => r.fileName).toSet();
    final pages = results.map((r) => r.pageNumber).toSet();

    return {
      'query': query,
      'totalResults': results.length,
      'averageScore': scores.reduce((a, b) => a + b) / scores.length,
      'maxScore': scores.reduce((a, b) => a > b ? a : b),
      'minScore': scores.reduce((a, b) => a < b ? a : b),
      'uniqueFiles': files.length,
      'uniquePages': pages.length,
      'topKeywords': _extractKeywords(
        results.map((r) => r.text).join(' '),
        limit: 10,
      ),
    };
  }

  // ═══════════════════════════════════════════════════════════════
  // UTILITY: HIGHLIGHT MATCHES
  // ═══════════════════════════════════════════════════════════════

  String highlightMatches(String text, String query, {String highlightTag = '**'}) {
    final queryLower = query.toLowerCase();
    final textLower = text.toLowerCase();

    if (!textLower.contains(queryLower)) return text;

    final index = textLower.indexOf(queryLower);
    if (index == -1) return text;

    return text.substring(0, index) +
        highlightTag +
        text.substring(index, index + query.length) +
        highlightTag +
        text.substring(index + query.length);
  }

  // ═══════════════════════════════════════════════════════════════
  // GETTERS
  // ═══════════════════════════════════════════════════════════════

  bool get isInitialized => _isInitialized;
  Set<String> get stopWords => _stopWords;
  Set<String> get academicKeywords => _academicKeywords;
}

// ═══════════════════════════════════════════════════════════════
// INTERNAL DATA MODELS
// ═══════════════════════════════════════════════════════════════

class _DocumentChunk {
  final String text;
  final String fileName;
  final int pageNumber;
  final List<String> keywords;
  final int startPosition;
  final int endPosition;

  _DocumentChunk({
    required this.text,
    required this.fileName,
    required this.pageNumber,
    required this.keywords,
    required this.startPosition,
    required this.endPosition,
  });

  @override
  String toString() {
    return '_DocumentChunk(file: $fileName, page: $pageNumber, length: ${text.length})';
  }
}

class _ScoredChunk {
  final _DocumentChunk chunk;
  final double score;

  _ScoredChunk({
    required this.chunk,
    required this.score,
  });

  @override
  String toString() {
    return '_ScoredChunk(score: ${(score * 100).toStringAsFixed(1)}%, ${chunk.toString()})';
  }
}