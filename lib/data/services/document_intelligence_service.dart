// lib/data/services/document_intelligence_service.dart

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

/// 📄 DOCUMENT INTELLIGENCE SERVICE
/// Enhanced with semantic chunking, page-level indexing, and advanced text analysis
/// Fully integrated with Academic Search Screen for PDF processing and analysis
class DocumentIntelligenceService {
  static final DocumentIntelligenceService _instance =
  DocumentIntelligenceService._internal();
  factory DocumentIntelligenceService() => _instance;
  DocumentIntelligenceService._internal();

  // ═══════════════════════════════════════════════════════════════
  // CORE PDF TEXT EXTRACTION
  // ═══════════════════════════════════════════════════════════════

  /// Extract text from entire PDF document
  Future<String> extractTextFromPdf(File file) async {
    try {
      debugPrint('📄 Extracting text from PDF: ${file.path}');

      final bytes = await file.readAsBytes();
      final PdfDocument document = PdfDocument(inputBytes: bytes);

      final String text = PdfTextExtractor(document).extractText();

      document.dispose();

      debugPrint('✅ PDF text extracted: ${text.length} characters');

      if (text.trim().isEmpty) {
        return 'Unable to extract text from this PDF. '
            'It might be an image-based or scanned PDF.';
      }

      return _cleanText(text);
    } catch (e) {
      debugPrint('❌ PDF extraction error: $e');
      return 'Error extracting text from PDF: ${e.toString()}';
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // ADVANCED: EXTRACT TEXT WITH PAGE NUMBERS
  // ═══════════════════════════════════════════════════════════════

  /// Extract text by page with page number mapping
  /// Returns Map<pageNumber, text> where pageNumber is 1-indexed
  Future<Map<int, String>> extractTextByPage(File file) async {
    try {
      debugPrint('📄 Extracting text by page from PDF...');

      final bytes = await file.readAsBytes();
      final PdfDocument document = PdfDocument(inputBytes: bytes);

      final pageTexts = <int, String>{};

      for (int i = 0; i < document.pages.count; i++) {
        try {
          final text = PdfTextExtractor(document)
              .extractText(startPageIndex: i, endPageIndex: i);

          if (text.trim().isNotEmpty) {
            pageTexts[i + 1] = _cleanText(text); // 1-indexed page numbers
          }
        } catch (e) {
          debugPrint('⚠️ Error extracting page ${i + 1}: $e');
        }
      }

      document.dispose();

      debugPrint('✅ Extracted ${pageTexts.length} pages');
      return pageTexts;
    } catch (e) {
      debugPrint('❌ Page extraction error: $e');
      return {};
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // IMAGE TEXT EXTRACTION (OCR PLACEHOLDER)
  // ═══════════════════════════════════════════════════════════════

  /// Extract text from image using OCR
  /// TODO: Implement using google_ml_kit or firebase_ml_vision
  Future<String> extractTextFromImage(File file) async {
    debugPrint('📸 Image OCR requested but not yet implemented');
    return 'Image text extraction coming soon!\n\n'
        'Currently supported formats:\n'
        '• PDF documents (.pdf)\n'
        '• Text files (.txt)\n'
        '• Word documents (.doc, .docx - coming soon)';
  }

  // ═══════════════════════════════════════════════════════════════
  // WORD DOCUMENT EXTRACTION
  // ═══════════════════════════════════════════════════════════════

  /// Extract text from Word document
  /// TODO: Implement using docx_to_text or similar package
  Future<String> extractTextFromWord(File file) async {
    try {
      debugPrint('📝 Word document processing requested but not yet implemented');
      return 'Word document processing coming soon!\n\n'
          'Please convert your document to PDF for now.';
    } catch (e) {
      debugPrint('❌ Word extraction error: $e');
      return 'Error extracting text from Word document: ${e.toString()}';
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // UNIVERSAL TEXT EXTRACTION (AUTO-DETECT FORMAT)
  // ═══════════════════════════════════════════════════════════════

  /// Extract text from any supported file format
  /// Automatically detects format and uses appropriate extraction method
  Future<String> extractText(File file) async {
    final extension = file.path.split('.').last.toLowerCase();

    debugPrint('📄 Extracting text from .$extension file');

    switch (extension) {
      case 'pdf':
        return await extractTextFromPdf(file);
      case 'txt':
        return await file.readAsString();
      case 'doc':
      case 'docx':
        return await extractTextFromWord(file);
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'bmp':
        return await extractTextFromImage(file);
      default:
        return 'Unsupported file format: .$extension\n\n'
            'Supported formats:\n'
            '• PDF (.pdf)\n'
            '• Text (.txt)\n'
            '• Word (.doc, .docx)\n'
            '• Images (.jpg, .png, .gif)';
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // TEXT CLEANING & NORMALIZATION
  // ═══════════════════════════════════════════════════════════════

  /// Clean and normalize extracted text
  String _cleanText(String text) {
    return text
        .replaceAll(RegExp(r'\s+'), ' ') // Normalize whitespace
        .replaceAll(RegExp(r'\n\s*\n+'), '\n\n') // Clean multiple newlines
        .replaceAll(RegExp(r'[^\S\n]+'), ' ') // Replace tabs with spaces
        .trim();
  }

  // ═══════════════════════════════════════════════════════════════
  // DOCUMENT STRUCTURE ANALYSIS
  // ═══════════════════════════════════════════════════════════════

  /// Analyze document structure and extract metadata
  Map<String, dynamic> analyzeDocumentStructure(String text) {
    final lines = text.split('\n').where((l) => l.trim().isNotEmpty).toList();
    final words = text.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    final sentences = text
        .split(RegExp(r'[.!?]+\s+'))
        .where((s) => s.trim().isNotEmpty)
        .toList();

    // Extract potential headings (all caps or numbered)
    final headings = lines.where((line) {
      final trimmed = line.trim();
      return trimmed.isNotEmpty &&
          (trimmed == trimmed.toUpperCase() ||
              RegExp(r'^\d+\.').hasMatch(trimmed) ||
              RegExp(r'^Chapter\s+\d+', caseSensitive: false)
                  .hasMatch(trimmed));
    }).toList();

    return {
      'lineCount': lines.length,
      'wordCount': words.length,
      'sentenceCount': sentences.length,
      'headingCount': headings.length,
      'headings': headings.take(10).toList(),
      'averageWordsPerSentence':
      sentences.isEmpty ? 0.0 : words.length / sentences.length,
      'readingTimeMinutes': (words.length / 200).ceil(),
      'estimatedPages': (words.length / 500).ceil(),
    };
  }

  // ═══════════════════════════════════════════════════════════════
  // KEY TERMS EXTRACTION WITH IMPORTANCE SCORING
  // ═══════════════════════════════════════════════════════════════

  /// Extract key terms with importance scores (0.0 to 1.0)
  Map<String, double> extractKeyTermsWithScores(String text, {int limit = 20}) {
    // Common stopwords to filter out
    final stopwords = {
      'the',
      'is',
      'are',
      'was',
      'were',
      'be',
      'been',
      'being',
      'have',
      'has',
      'had',
      'do',
      'does',
      'did',
      'will',
      'would',
      'could',
      'should',
      'may',
      'might',
      'can',
      'this',
      'that',
      'these',
      'those',
      'and',
      'or',
      'but',
      'if',
      'in',
      'on',
      'at',
      'to',
      'for',
      'of',
      'with',
      'from',
      'by',
      'about',
      'as',
      'into',
      'through',
      'during',
      'before',
      'after',
      'above',
      'below',
      'between',
      'under',
      'again',
      'further',
      'then',
      'once',
      'here',
      'there',
      'when',
      'where',
      'why',
      'how',
      'all',
      'both',
      'each',
      'few',
      'more',
      'most',
      'other',
      'some',
      'such',
      'only',
      'own',
      'same',
      'than',
      'too',
      'very',
      'just',
      'also',
    };

    final words = text
        .toLowerCase()
        .split(RegExp(r'\W+'))
        .where((w) => w.length > 3 && !stopwords.contains(w))
        .toList();

    final frequency = <String, int>{};
    for (final word in words) {
      frequency[word] = (frequency[word] ?? 0) + 1;
    }

    // Calculate importance scores (frequency-based with normalization)
    final maxFrequency = frequency.values.isEmpty
        ? 1
        : frequency.values.reduce((a, b) => a > b ? a : b);

    final scored = <String, double>{};
    frequency.forEach((word, count) {
      scored[word] = count / maxFrequency;
    });

    // Sort by score and return top N
    final sorted = scored.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Map.fromEntries(sorted.take(limit));
  }

  /// Extract key terms as simple list
  List<String> extractKeyTerms(String text, {int limit = 20}) {
    return extractKeyTermsWithScores(text, limit: limit).keys.toList();
  }

  // ═══════════════════════════════════════════════════════════════
  // SEMANTIC CHUNKING WITH PAGE TRACKING (PRIMARY METHOD)
  // ═══════════════════════════════════════════════════════════════

  /// Split text into semantic chunks with page tracking and keyword extraction
  /// This is the PRIMARY chunking method used by Academic Search Screen
  List<DocumentChunk> splitIntoSemanticChunks(
      String text, {
        String fileName = 'document.pdf',
        int maxChunkSize = 1000,
        int overlapSize = 200,
      }) {
    final chunks = <DocumentChunk>[];
    const wordsPerPage = 500; // Estimate words per page

    // Split by sentences for better semantic boundaries
    final sentences = text
        .split(RegExp(r'(?<=[.!?])\s+'))
        .where((s) => s.trim().isNotEmpty)
        .toList();

    final buffer = StringBuffer();
    int wordCount = 0;
    int startPosition = 0;
    int chunkStartSentenceIndex = 0;

    for (int i = 0; i < sentences.length; i++) {
      final sentence = sentences[i];
      final sentenceWords =
          sentence.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;

      // Check if adding this sentence would exceed max chunk size
      if (wordCount + sentenceWords > maxChunkSize && buffer.isNotEmpty) {
        // Create chunk from accumulated sentences
        final chunkText = buffer.toString().trim();
        final pageNumber = (startPosition / wordsPerPage).floor() + 1;

        chunks.add(DocumentChunk(
          text: chunkText,
          fileName: fileName,
          pageNumber: pageNumber,
          startPosition: startPosition,
          endPosition: startPosition + wordCount,
          keywords: extractKeyTerms(chunkText, limit: 10),
        ));

        // Calculate overlap: keep last few sentences
        final overlapSentences = (overlapSize / 50).ceil(); // ~50 words per sentence estimate
        final overlapStart = (i - overlapSentences).clamp(0, i);

        // Reset buffer with overlap
        buffer.clear();
        wordCount = 0;

        // Add overlap sentences
        for (int j = overlapStart; j < i; j++) {
          buffer.write(sentences[j]);
          buffer.write(' ');
          wordCount += sentences[j]
              .split(RegExp(r'\s+'))
              .where((w) => w.isNotEmpty)
              .length;
        }

        chunkStartSentenceIndex = overlapStart;
        startPosition += wordCount;
      }

      // Add current sentence to buffer
      buffer.write(sentence);
      buffer.write(' ');
      wordCount += sentenceWords;

      // Safety limit to prevent infinite loops
      if (chunks.length >= 100) {
        debugPrint('⚠️ Reached maximum chunk limit (100)');
        break;
      }
    }

    // Add remaining text as final chunk
    if (buffer.isNotEmpty) {
      final chunkText = buffer.toString().trim();
      final pageNumber = (startPosition / wordsPerPage).floor() + 1;

      chunks.add(DocumentChunk(
        text: chunkText,
        fileName: fileName,
        pageNumber: pageNumber,
        startPosition: startPosition,
        endPosition: startPosition + wordCount,
        keywords: extractKeyTerms(chunkText, limit: 10),
      ));
    }

    debugPrint('✅ Created ${chunks.length} semantic chunks from $fileName');
    return chunks;
  }

  // ═══════════════════════════════════════════════════════════════
  // LEGACY TEXT CHUNKING (BASIC METHOD)
  // ═══════════════════════════════════════════════════════════════

  /// Simple text chunking without semantic analysis (legacy method)
  /// Use splitIntoSemanticChunks() for better results
  List<String> splitIntoChunks(String text, {int maxChunkSize = 4000}) {
    final chunks = <String>[];
    final sentences =
    text.split(RegExp(r'[.!?]\s+')).where((s) => s.trim().isNotEmpty);

    final buffer = StringBuffer();

    for (final sentence in sentences) {
      if (buffer.length + sentence.length > maxChunkSize && buffer.isNotEmpty) {
        chunks.add(buffer.toString().trim());
        buffer.clear();
      }
      buffer.write(sentence);
      buffer.write('. ');
    }

    if (buffer.isNotEmpty) {
      chunks.add(buffer.toString().trim());
    }

    return chunks;
  }

  // ═══════════════════════════════════════════════════════════════
  // METADATA GENERATION
  // ═══════════════════════════════════════════════════════════════

  /// Generate comprehensive metadata for a document
  Map<String, dynamic> generateMetadata(File file, String text) {
    final structure = analyzeDocumentStructure(text);
    final keyTerms = extractKeyTerms(text, limit: 15);

    return {
      'fileName': file.path.split('/').last,
      'fileSize': file.lengthSync(),
      'fileSizeFormatted': _formatFileSize(file.lengthSync()),
      'uploadedAt': DateTime.now().toIso8601String(),
      'structure': structure,
      'keyTerms': keyTerms,
      'textLength': text.length,
      'estimatedPages': (text.split(RegExp(r'\s+')).length / 500).ceil(),
      'language': detectLanguage(text),
      'isAcademic': isAcademicDocument(text),
    };
  }

  /// Format file size in human-readable format
  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  // ═══════════════════════════════════════════════════════════════
  // LANGUAGE DETECTION
  // ═══════════════════════════════════════════════════════════════

  /// Detect document language (basic heuristic)
  String detectLanguage(String text) {
    final englishWords = [
      'the',
      'is',
      'and',
      'of',
      'to',
      'in',
      'for',
      'that',
      'with',
      'on'
    ];
    final hindiWords = ['का', 'की', 'के', 'में', 'है', 'और', 'से', 'को', 'ने', 'पर'];

    final lowerText = text.toLowerCase();
    int englishCount = 0;
    int hindiCount = 0;

    for (final word in englishWords) {
      if (lowerText.contains(' $word ')) englishCount++;
    }

    for (final word in hindiWords) {
      if (text.contains(word)) hindiCount++;
    }

    if (englishCount > hindiCount) return 'English';
    if (hindiCount > englishCount) return 'Hindi';
    return 'Unknown';
  }

  // ═══════════════════════════════════════════════════════════════
  // ACADEMIC DOCUMENT DETECTION
  // ═══════════════════════════════════════════════════════════════

  /// Check if document appears to be academic/educational
  bool isAcademicDocument(String text) {
    final academicKeywords = [
      'theorem',
      'definition',
      'proof',
      'equation',
      'algorithm',
      'formula',
      'research',
      'methodology',
      'results',
      'discussion',
      'conclusion',
      'abstract',
      'introduction',
      'hypothesis',
      'analysis',
      'experiment',
      'study',
      'theory',
    ];

    final lowerText = text.toLowerCase();
    int matchCount = 0;

    for (final keyword in academicKeywords) {
      if (lowerText.contains(keyword)) matchCount++;
    }

    return matchCount >= 3;
  }

  // ═══════════════════════════════════════════════════════════════
  // FORMULA EXTRACTION
  // ═══════════════════════════════════════════════════════════════

  /// Extract mathematical formulas and equations
  List<String> extractFormulas(String text) {
    final formulas = <String>[];

    final patterns = [
      RegExp(r'[a-zA-Z]\s*=\s*[^,\n]+'), // Simple equations
      RegExp(r'∫.*d[a-z]'), // Integrals
      RegExp(r'∑[^\n]+'), // Summations
      RegExp(r'√[^\s]+'), // Square roots
      RegExp(r'[a-zA-Z][²³⁴⁵⁶⁷⁸⁹]'), // Superscripts
      RegExp(r'\([^)]+\)\s*[+\-*/]\s*\([^)]+\)'), // Parenthetical expressions
    ];

    for (final pattern in patterns) {
      final matches = pattern.allMatches(text);
      formulas.addAll(matches.map((m) => m.group(0)!.trim()));
    }

    return formulas.take(20).toList();
  }

  // ═══════════════════════════════════════════════════════════════
  // DEFINITIONS EXTRACTION
  // ═══════════════════════════════════════════════════════════════

  /// Extract definitions (term: definition or term - definition patterns)
  List<Map<String, String>> extractDefinitions(String text) {
    final definitions = <Map<String, String>>[];
    final lines = text.split('\n').where((l) => l.trim().isNotEmpty);

    for (final line in lines) {
      // Pattern: "Term: definition"
      final colonMatch = RegExp(r'^([^:]{3,50}):\s*(.+)$').firstMatch(line);

      // Pattern: "Term - definition"
      final dashMatch = RegExp(r'^([^-]{3,50})\s*-\s*(.+)$').firstMatch(line);

      final match = colonMatch ?? dashMatch;
      if (match != null) {
        final term = match.group(1)?.trim();
        final definition = match.group(2)?.trim();

        if (term != null &&
            definition != null &&
            term.length >= 3 &&
            term.length <= 50 &&
            definition.length >= 10) {
          definitions.add({
            'term': term,
            'definition': definition,
          });
        }
      }
    }

    return definitions.take(20).toList();
  }

  // ═══════════════════════════════════════════════════════════════
  // NOTES OUTLINE GENERATION
  // ═══════════════════════════════════════════════════════════════

  /// Generate a study notes outline from document
  Map<String, dynamic> generateNotesOutline(String text) {
    final structure = analyzeDocumentStructure(text);
    final headings = structure['headings'] as List<String>;
    final keyTerms = extractKeyTerms(text, limit: 15);
    final formulas = extractFormulas(text);
    final definitions = extractDefinitions(text);

    return {
      'mainTopics': headings.take(10).toList(),
      'keyTerms': keyTerms,
      'formulas': formulas,
      'definitions': definitions,
      'estimatedStudyTime': structure['readingTimeMinutes'],
      'complexity': _estimateComplexity(text),
      'wordCount': structure['wordCount'],
      'pageCount': structure['estimatedPages'],
    };
  }

  /// Estimate document complexity based on various factors
  String _estimateComplexity(String text) {
    final words = text.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    if (words.isEmpty) return 'Unknown';

    // Average word length
    final avgWordLength =
        words.map((w) => w.length).reduce((a, b) => a + b) / words.length;

    // Check for technical terms
    final technicalPatterns = [
      RegExp(r'[A-Z]{2,}'), // Acronyms
      RegExp(r'\b\w{12,}\b'), // Long technical words
    ];

    int technicalTermCount = 0;
    for (final pattern in technicalPatterns) {
      technicalTermCount += pattern.allMatches(text).length;
    }

    final technicalDensity = technicalTermCount / words.length;

    // Determine complexity
    if (avgWordLength < 5 && technicalDensity < 0.02) return 'Beginner';
    if (avgWordLength < 7 && technicalDensity < 0.05) return 'Intermediate';
    return 'Advanced';
  }

  // ═══════════════════════════════════════════════════════════════
  // BATCH PROCESSING FOR MULTIPLE FILES
  // ═══════════════════════════════════════════════════════════════

  /// Process multiple PDF files and combine their chunks
  Future<List<DocumentChunk>> processPDFFiles(
      List<File> files, {
        int maxChunkSize = 1000,
        int overlapSize = 200,
      }) async {
    final allChunks = <DocumentChunk>[];

    debugPrint('📚 Processing ${files.length} PDF files...');

    for (final file in files) {
      try {
        final text = await extractTextFromPdf(file);
        if (text.isNotEmpty && !text.startsWith('Error') && !text.startsWith('Unable')) {
          final chunks = splitIntoSemanticChunks(
            text,
            fileName: file.path.split('/').last,
            maxChunkSize: maxChunkSize,
            overlapSize: overlapSize,
          );
          allChunks.addAll(chunks);
        }
      } catch (e) {
        debugPrint('⚠️ Error processing ${file.path}: $e');
      }
    }

    debugPrint('✅ Total chunks extracted: ${allChunks.length}');
    return allChunks;
  }

  // ═══════════════════════════════════════════════════════════════
  // SIMILARITY SCORING (FOR SEARCH RELEVANCE)
  // ═══════════════════════════════════════════════════════════════

  /// Calculate similarity score between query and chunk text
  /// Returns value between 0.0 and 1.0
  double calculateSimilarityScore(String query, String chunkText) {
    final queryWords = query
        .toLowerCase()
        .split(RegExp(r'\W+'))
        .where((w) => w.length > 2)
        .toSet();

    final chunkWords = chunkText
        .toLowerCase()
        .split(RegExp(r'\W+'))
        .where((w) => w.length > 2)
        .toSet();

    if (queryWords.isEmpty || chunkWords.isEmpty) return 0.0;

    // Calculate Jaccard similarity
    final intersection = queryWords.intersection(chunkWords).length;
    final union = queryWords.union(chunkWords).length;

    return intersection / union;
  }

  /// Rank chunks by relevance to query
  List<DocumentChunk> rankChunksByRelevance(
      String query,
      List<DocumentChunk> chunks,
      ) {
    final scored = chunks.map((chunk) {
      final score = calculateSimilarityScore(query, chunk.text);
      return MapEntry(chunk, score);
    }).toList();

    // Sort by score descending
    scored.sort((a, b) => b.value.compareTo(a.value));

    return scored.map((e) => e.key).toList();
  }
}

// ═══════════════════════════════════════════════════════════════
// DOCUMENT CHUNK DATA MODEL
// ═══════════════════════════════════════════════════════════════

/// Represents a chunk of document text with metadata
class DocumentChunk {
  final String text;
  final String fileName;
  final int pageNumber;
  final int startPosition;
  final int endPosition;
  final List<String> keywords;

  DocumentChunk({
    required this.text,
    required this.fileName,
    required this.pageNumber,
    required this.startPosition,
    required this.endPosition,
    required this.keywords,
  });

  /// Convert to map for serialization
  Map<String, dynamic> toMap() => {
    'text': text,
    'fileName': fileName,
    'pageNumber': pageNumber,
    'startPosition': startPosition,
    'endPosition': endPosition,
    'keywords': keywords,
  };

  /// Create from map
  factory DocumentChunk.fromMap(Map<String, dynamic> map) {
    return DocumentChunk(
      text: map['text'] as String,
      fileName: map['fileName'] as String,
      pageNumber: map['pageNumber'] as int,
      startPosition: map['startPosition'] as int,
      endPosition: map['endPosition'] as int,
      keywords: List<String>.from(map['keywords'] as List),
    );
  }

  /// Create a copy with updated fields
  DocumentChunk copyWith({
    String? text,
    String? fileName,
    int? pageNumber,
    int? startPosition,
    int? endPosition,
    List<String>? keywords,
  }) {
    return DocumentChunk(
      text: text ?? this.text,
      fileName: fileName ?? this.fileName,
      pageNumber: pageNumber ?? this.pageNumber,
      startPosition: startPosition ?? this.startPosition,
      endPosition: endPosition ?? this.endPosition,
      keywords: keywords ?? this.keywords,
    );
  }

  @override
  String toString() {
    return 'DocumentChunk(fileName: $fileName, page: $pageNumber, '
        'length: ${text.length}, keywords: ${keywords.length})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is DocumentChunk &&
        other.text == text &&
        other.fileName == fileName &&
        other.pageNumber == pageNumber;
  }

  @override
  int get hashCode {
    return text.hashCode ^ fileName.hashCode ^ pageNumber.hashCode;
  }
}