// lib/data/services/academic_search_engine.dart

import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'dart:io';

import '../models/youtube_video_model.dart';
import 'unified_ai_service.dart';
import 'youtube_service.dart';
import 'document_intelligence_service.dart';
import 'semantic_search_service.dart';
import 'youtube_intelligence_service.dart';
import 'response_generator_service.dart';

/// 🎓 ACADEMIC SEARCH & REASONING ENGINE
/// Perplexity-style multi-source intelligent learning system
class AcademicSearchEngine {
  static final AcademicSearchEngine _instance = AcademicSearchEngine._internal();
  factory AcademicSearchEngine() => _instance;
  AcademicSearchEngine._internal();

  final UnifiedAIService _aiService = UnifiedAIService();
  final YouTubeService _youtubeService = YouTubeService();
  final DocumentIntelligenceService _docService = DocumentIntelligenceService();
  final SemanticSearchService _semanticSearch = SemanticSearchService();
  final YouTubeIntelligenceService _youtubeIntelligence = YouTubeIntelligenceService();
  final ResponseGeneratorService _responseGenerator = ResponseGeneratorService();

  bool _isInitialized = false;

  // ═══════════════════════════════════════════════════════════════
  // INITIALIZATION
  // ═══════════════════════════════════════════════════════════════

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      debugPrint('🔄 Initializing Academic Search Engine...');

      await Future.wait([
        _aiService.initialize(),
        _youtubeService.init(),
        _semanticSearch.initialize(),
      ]);

      _isInitialized = true;
      debugPrint('✅ Academic Search Engine ready');
    } catch (e) {
      debugPrint('❌ Academic Search Engine init error: $e');
      rethrow;
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // MAIN SEARCH METHOD
  // ═══════════════════════════════════════════════════════════════

  Future<AcademicSearchResult> search({
    required String query,
    required String subject,
    required String academicLevel,
    required String branch,
    String? examType,
    String? language,
    List<File>? pdfFiles,
    List<File>? imageFiles,
    String? resourceId,
  }) async {
    try {
      if (!_isInitialized) await initialize();

      debugPrint('🔍 Academic Search: $query');
      debugPrint('📚 Subject: $subject | Level: $academicLevel');

      // STEP 1: INTENT & CONCEPT ANALYSIS
      final intentAnalysis = await _analyzeIntent(
        query: query,
        subject: subject,
        academicLevel: academicLevel,
        branch: branch,
      );

      debugPrint('✅ Intent Analysis: ${intentAnalysis['intent']}');

      // STEP 2: PARALLEL MULTI-SOURCE SEARCH
      final results = await Future.wait([
        _searchPDFNotes(
          query: query,
          subject: subject,
          pdfFiles: pdfFiles,
          resourceId: resourceId,
          intentAnalysis: intentAnalysis,
        ),
        _searchYouTubeVideos(
          query: query,
          subject: subject,
          intentAnalysis: intentAnalysis,
        ),
      ]);

      final pdfResults = results[0] as PDFSearchResult;
      final videoResults = results[1] as List<RankedVideo>;

      debugPrint('✅ Found ${pdfResults.chunks.length} PDF sections');
      debugPrint('✅ Found ${videoResults.length} ranked videos');

      // STEP 3: GENERATE MULTI-LAYER EXPLANATION
      final explanation = await _generateExplanation(
        query: query,
        subject: subject,
        academicLevel: academicLevel,
        examType: examType ?? 'semester',
        intentAnalysis: intentAnalysis,
        pdfContext: pdfResults.chunks,
        videos: videoResults,
      );

      debugPrint('✅ Generated multi-layer explanation');

      // STEP 4: GENERATE PRACTICE QUESTIONS
      final practiceQuestions = await _generatePracticeQuestions(
        topic: intentAnalysis['topics']?.join(', ') ?? query,
        subject: subject,
        difficulty: intentAnalysis['difficulty'] ?? 'Medium',
      );

      // STEP 5: BUILD LEARNING PATH
      final learningPath = _buildLearningPath(
        videos: videoResults,
        intentAnalysis: intentAnalysis,
      );

      // RETURN COMPLETE RESULT
      return AcademicSearchResult(
        query: query,
        subject: subject,
        intentAnalysis: intentAnalysis,
        explanation: explanation,
        pdfSources: pdfResults,
        rankedVideos: videoResults,
        practiceQuestions: practiceQuestions,
        learningPath: learningPath,
        timestamp: DateTime.now(),
      );
    } catch (e) {
      debugPrint('❌ Academic search error: $e');
      rethrow;
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // INTENT ANALYSIS
  // ═══════════════════════════════════════════════════════════════

  Future<Map<String, dynamic>> _analyzeIntent({
    required String query,
    required String subject,
    required String academicLevel,
    required String branch,
  }) async {
    try {
      final prompt = '''Analyze this student question for academic search:

Question: "$query"
Subject: $subject
Level: $academicLevel
Branch: $branch

Provide structured analysis:
1. Core concepts (main topics)
2. Sub-concepts (related topics)
3. Syllabus unit mapping (which unit/chapter)
4. Cognitive level (remember/understand/apply/analyze/evaluate/create)
5. Required response type (theory/derivation/algorithm/example/code/exam answer)
6. Difficulty (Easy/Medium/Advanced)
7. Exam relevance (Low/Medium/High)

Return ONLY valid JSON in this exact format:
{
  "subject": "$subject",
  "unit": "Unit name or number",
  "topics": ["topic1", "topic2"],
  "intent": "What student wants to learn",
  "difficulty": "Easy/Medium/Advanced",
  "exam_relevance": "Low/Medium/High",
  "cognitive_level": "understand/apply/analyze",
  "response_type": "theory/derivation/algorithm"
}''';

      _aiService.setSubject(subject);
      final response = await _aiService.sendMessage(prompt);

      // Extract JSON from response
      final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(response);
      if (jsonMatch != null) {
        final jsonStr = jsonMatch.group(0)!;
        return json.decode(jsonStr);
      }

      // Fallback
      return {
        'subject': subject,
        'unit': 'General',
        'topics': [query],
        'intent': query,
        'difficulty': 'Medium',
        'exam_relevance': 'High',
        'cognitive_level': 'understand',
        'response_type': 'theory',
      };
    } catch (e) {
      debugPrint('❌ Intent analysis error: $e');
      return {
        'subject': subject,
        'unit': 'General',
        'topics': [query],
        'intent': query,
        'difficulty': 'Medium',
        'exam_relevance': 'High',
      };
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // PDF NOTES SEARCH
  // ═══════════════════════════════════════════════════════════════

  Future<PDFSearchResult> _searchPDFNotes({
    required String query,
    required String subject,
    List<File>? pdfFiles,
    String? resourceId,
    required Map<String, dynamic> intentAnalysis,
  }) async {
    try {
      if (pdfFiles == null || pdfFiles.isEmpty) {
        return PDFSearchResult(chunks: [], sources: []);
      }

      final allChunks = <PDFChunk>[];

      for (var file in pdfFiles) {
        // Extract text
        final text = await _docService.extractText(file);

        if (text.isEmpty || text.length < 50) continue;

        // Chunk and search
        final chunks = await _semanticSearch.searchInDocument(
          documentText: text,
          query: query,
          fileName: file.path.split('/').last,
          maxResults: 5,
        );

        allChunks.addAll(chunks);
      }

      // Sort by relevance
      allChunks.sort((a, b) => b.relevanceScore.compareTo(a.relevanceScore));

      // Take top 10
      final topChunks = allChunks.take(10).toList();

      return PDFSearchResult(
        chunks: topChunks,
        sources: pdfFiles.map((f) => f.path.split('/').last).toList(),
      );
    } catch (e) {
      debugPrint('❌ PDF search error: $e');
      return PDFSearchResult(chunks: [], sources: []);
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // YOUTUBE VIDEO SEARCH & RANKING
  // ═══════════════════════════════════════════════════════════════

  Future<List<RankedVideo>> _searchYouTubeVideos({
    required String query,
    required String subject,
    required Map<String, dynamic> intentAnalysis,
  }) async {
    try {
      // Search videos
      final videos = await _youtubeService.searchVideos(
        query: query,
        subject: subject,
        topic: intentAnalysis['topics']?.join(' '),
        maxResults: 15,
      );

      if (videos.isEmpty) {
        debugPrint('⚠️ No YouTube videos found');
        return [];
      }

      // Rank videos using intelligence service
      final rankedVideos = await _youtubeIntelligence.rankVideos(
        videos: videos,
        query: query,
        intentAnalysis: intentAnalysis,
      );

      // Take top 5
      return rankedVideos.take(5).toList();
    } catch (e) {
      debugPrint('❌ YouTube search error: $e');
      return [];
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // GENERATE MULTI-LAYER EXPLANATION
  // ═══════════════════════════════════════════════════════════════

  Future<MultiLayerExplanation> _generateExplanation({
    required String query,
    required String subject,
    required String academicLevel,
    required String examType,
    required Map<String, dynamic> intentAnalysis,
    required List<PDFChunk> pdfContext,
    required List<RankedVideo> videos,
  }) async {
    try {
      // Build context from PDFs
      final pdfContextText = pdfContext.take(5).map((chunk) {
        return 'PDF: ${chunk.fileName} (Page ${chunk.pageNumber})\n${chunk.text}';
      }).join('\n\n---\n\n');

      // Build context from videos
      final videoContextText = videos.take(3).map((video) {
        return 'Video: "${video.video.title}" by ${video.video.channelName}\n'
            'Duration: ${video.video.duration} | Views: ${video.video.viewCount}\n'
            'Relevance Score: ${(video.overallScore * 100).toStringAsFixed(1)}%';
      }).join('\n\n');

      final prompt = '''You are an advanced Academic Search & Reasoning Engine for a University Learning Platform.

Student Question: "$query"
Academic Level: $academicLevel
Subject: $subject
Exam Type: $examType

Intent Analysis:
${json.encode(intentAnalysis)}

PDF Knowledge Base:
$pdfContextText

YouTube Videos Available:
$videoContextText

Generate a comprehensive multi-layer learning response with:

1. **BEGINNER-FRIENDLY INTUITION** (2-3 sentences explaining the concept simply)

2. **FORMAL UNIVERSITY-LEVEL THEORY** (Complete academic explanation with definitions)

3. **STEP-BY-STEP BREAKDOWN** (Algorithm/Derivation/Process flow with numbered steps)

4. **REAL-WORLD ANALOGY** (Relate to everyday examples for better understanding)

5. **EXAM-READY ANSWERS**:
   - **2-Mark Answer**: Concise definition/key points
   - **5-Mark Answer**: Detailed explanation with examples
   - **10-Mark Answer**: Comprehensive answer with diagrams description, examples, advantages/disadvantages

For each major concept, cite sources:
- (PDF: [filename], Page X)
- (Video: [title] @ mm:ss)

Format response in clear sections with markdown headers.''';

      _aiService.setSubject(subject);
      _aiService.setStudyMode(StudyModeType.exam);

      final response = await _aiService.sendMessage(prompt);

      // Parse response into structured format
      return _responseGenerator.parseMultiLayerExplanation(
        response: response,
        pdfChunks: pdfContext,
        videos: videos,
      );
    } catch (e) {
      debugPrint('❌ Explanation generation error: $e');
      return MultiLayerExplanation(
        intuition: 'Error generating explanation. Please try again.',
        theory: '',
        stepByStep: '',
        realWorld: '',
        examAnswers: ExamAnswers(
          twoMark: '',
          fiveMark: '',
          tenMark: '',
        ),
        sourceCitations: [],
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // GENERATE PRACTICE QUESTIONS
  // ═══════════════════════════════════════════════════════════════

  Future<List<PracticeQuestion>> _generatePracticeQuestions({
    required String topic,
    required String subject,
    required String difficulty,
  }) async {
    try {
      final prompt = '''Generate 5 practice questions for:
Topic: $topic
Subject: $subject
Difficulty: $difficulty

For each question provide:
1. Question text
2. Question type (MCQ/Short/Long/Numerical)
3. Difficulty level
4. Marks
5. Brief hint

Format each as:
Q1: [question text] (Type: MCQ, Difficulty: Medium, Marks: 2)
Hint: [brief hint]''';

      _aiService.setSubject(subject);
      final response = await _aiService.sendMessage(prompt);

      return _parsePracticeQuestions(response);
    } catch (e) {
      debugPrint('❌ Practice questions error: $e');
      return [];
    }
  }

  List<PracticeQuestion> _parsePracticeQuestions(String response) {
    final questions = <PracticeQuestion>[];
    final questionBlocks = response.split(RegExp(r'Q\d+:'));

    for (var i = 1; i < questionBlocks.length && i <= 5; i++) {
      final block = questionBlocks[i].trim();
      final lines = block.split('\n');

      if (lines.isEmpty) continue;

      final firstLine = lines[0];
      String questionText = firstLine;
      String type = 'Short';
      String difficulty = 'Medium';
      int marks = 2;
      String hint = '';

      // Extract type, difficulty, marks from parentheses
      final metaMatch = RegExp(r'\((.*?)\)').firstMatch(firstLine);
      if (metaMatch != null) {
        final meta = metaMatch.group(1)!;
        questionText = firstLine.substring(0, metaMatch.start).trim();

        if (meta.contains('MCQ')) type = 'MCQ';
        if (meta.contains('Long')) type = 'Long';
        if (meta.contains('Numerical')) type = 'Numerical';

        final marksMatch = RegExp(r'Marks:\s*(\d+)').firstMatch(meta);
        if (marksMatch != null) {
          marks = int.tryParse(marksMatch.group(1)!) ?? 2;
        }
      }

      // Extract hint
      for (var line in lines) {
        if (line.toLowerCase().startsWith('hint:')) {
          hint = line.substring(5).trim();
          break;
        }
      }

      questions.add(PracticeQuestion(
        question: questionText,
        type: type,
        difficulty: difficulty,
        marks: marks,
        hint: hint,
      ));
    }

    return questions;
  }

  // ═══════════════════════════════════════════════════════════════
  // BUILD LEARNING PATH
  // ═══════════════════════════════════════════════════════════════

  LearningPath _buildLearningPath({
    required List<RankedVideo> videos,
    required Map<String, dynamic> intentAnalysis,
  }) {
    if (videos.isEmpty) {
      return LearningPath(
        watchFirst: null,
        deepStudy: null,
        quickRevision: null,
        nextTopics: [],
        studyPlanTip: 'No videos available. Please search manually.',
      );
    }

    // Watch First: Highest ranked beginner-friendly video
    RankedVideo? watchFirst;
    RankedVideo? deepStudy;
    RankedVideo? quickRevision;

    for (var video in videos) {
      if (watchFirst == null) {
        watchFirst = video;
      } else if (deepStudy == null && video.video.duration.contains(':') &&
          _parseDuration(video.video.duration) > 15) {
        deepStudy = video;
      } else if (quickRevision == null && video.video.duration.contains(':') &&
          _parseDuration(video.video.duration) < 10) {
        quickRevision = video;
      }
    }

    // Generate next topics
    final currentTopics = intentAnalysis['topics'] as List? ?? [];
    final nextTopics = _generateNextTopics(currentTopics, intentAnalysis['subject']);

    return LearningPath(
      watchFirst: watchFirst,
      deepStudy: deepStudy ?? videos.first,
      quickRevision: quickRevision,
      nextTopics: nextTopics,
      studyPlanTip: _generateStudyTip(intentAnalysis),
    );
  }

  int _parseDuration(String duration) {
    try {
      final parts = duration.split(':');
      if (parts.length == 2) {
        return int.parse(parts[0]);
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }

  List<String> _generateNextTopics(List<dynamic> currentTopics, String? subject) {
    return [
      'Practice problems on ${currentTopics.isNotEmpty ? currentTopics[0] : 'this topic'}',
      'Advanced concepts in $subject',
      'Real-world applications',
    ];
  }

  String _generateStudyTip(Map<String, dynamic> intentAnalysis) {
    final difficulty = intentAnalysis['difficulty'] ?? 'Medium';

    if (difficulty == 'Easy') {
      return '💡 Start with the intro video, then practice basic problems.';
    } else if (difficulty == 'Advanced') {
      return '💡 Watch the full lecture first, take notes, then solve numerical problems.';
    } else {
      return '💡 Watch the intro, read your notes, then attempt practice questions.';
    }
  }
}

// ═══════════════════════════════════════════════════════════════
// 📦 DATA MODELS - ALL CLASSES DEFINED BELOW
// ═══════════════════════════════════════════════════════════════

class AcademicSearchResult {
  final String query;
  final String subject;
  final Map<String, dynamic> intentAnalysis;
  final MultiLayerExplanation explanation;
  final PDFSearchResult pdfSources;
  final List<RankedVideo> rankedVideos;
  final List<PracticeQuestion> practiceQuestions;
  final LearningPath learningPath;
  final DateTime timestamp;

  AcademicSearchResult({
    required this.query,
    required this.subject,
    required this.intentAnalysis,
    required this.explanation,
    required this.pdfSources,
    required this.rankedVideos,
    required this.practiceQuestions,
    required this.learningPath,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'query': query,
    'subject': subject,
    'intent_analysis': intentAnalysis,
    'explanation': explanation.toJson(),
    'pdf_sources': pdfSources.toJson(),
    'ranked_videos': rankedVideos.map((v) => v.toJson()).toList(),
    'practice_questions': practiceQuestions.map((q) => q.toJson()).toList(),
    'learning_path': learningPath.toJson(),
    'timestamp': timestamp.toIso8601String(),
  };
}

class PDFSearchResult {
  final List<PDFChunk> chunks;
  final List<String> sources;

  PDFSearchResult({required this.chunks, required this.sources});

  Map<String, dynamic> toJson() => {
    'chunks': chunks.map((c) => c.toJson()).toList(),
    'sources': sources,
  };
}

class PDFChunk {
  final String text;
  final String fileName;
  final int pageNumber;
  final double relevanceScore;
  final List<String> keywords;

  PDFChunk({
    required this.text,
    required this.fileName,
    required this.pageNumber,
    required this.relevanceScore,
    required this.keywords,
  });

  Map<String, dynamic> toJson() => {
    'text': text,
    'file_name': fileName,
    'page_number': pageNumber,
    'relevance_score': relevanceScore,
    'keywords': keywords,
  };
}

class MultiLayerExplanation {
  final String intuition;
  final String theory;
  final String stepByStep;
  final String realWorld;
  final ExamAnswers examAnswers;
  final List<SourceCitation> sourceCitations;

  MultiLayerExplanation({
    required this.intuition,
    required this.theory,
    required this.stepByStep,
    required this.realWorld,
    required this.examAnswers,
    required this.sourceCitations,
  });

  Map<String, dynamic> toJson() => {
    'intuition': intuition,
    'theory': theory,
    'step_by_step': stepByStep,
    'real_world': realWorld,
    'exam_answers': examAnswers.toJson(),
    'source_citations': sourceCitations.map((s) => s.toJson()).toList(),
  };
}

class ExamAnswers {
  final String twoMark;
  final String fiveMark;
  final String tenMark;

  ExamAnswers({
    required this.twoMark,
    required this.fiveMark,
    required this.tenMark,
  });

  Map<String, dynamic> toJson() => {
    '2_mark': twoMark,
    '5_mark': fiveMark,
    '10_mark': tenMark,
  };
}

class SourceCitation {
  final String concept;
  final String? pdfSource;
  final int? pdfPage;
  final String? videoId;
  final String? videoTimestamp;

  SourceCitation({
    required this.concept,
    this.pdfSource,
    this.pdfPage,
    this.videoId,
    this.videoTimestamp,
  });

  Map<String, dynamic> toJson() => {
    'concept': concept,
    'pdf_source': pdfSource,
    'pdf_page': pdfPage,
    'video_id': videoId,
    'video_timestamp': videoTimestamp,
  };
}

class PracticeQuestion {
  final String question;
  final String type;
  final String difficulty;
  final int marks;
  final String hint;

  PracticeQuestion({
    required this.question,
    required this.type,
    required this.difficulty,
    required this.marks,
    required this.hint,
  });

  Map<String, dynamic> toJson() => {
    'question': question,
    'type': type,
    'difficulty': difficulty,
    'marks': marks,
    'hint': hint,
  };
}

class LearningPath {
  final RankedVideo? watchFirst;
  final RankedVideo? deepStudy;
  final RankedVideo? quickRevision;
  final List<String> nextTopics;
  final String studyPlanTip;

  LearningPath({
    this.watchFirst,
    this.deepStudy,
    this.quickRevision,
    required this.nextTopics,
    required this.studyPlanTip,
  });

  Map<String, dynamic> toJson() => {
    'watch_first': watchFirst?.toJson(),
    'deep_study': deepStudy?.toJson(),
    'quick_revision': quickRevision?.toJson(),
    'next_topics': nextTopics,
    'study_plan_tip': studyPlanTip,
  };
}

class RankedVideo {
  final YouTubeVideoModel video;
  final double overallScore;
  final double teachingClarityScore;
  final double syllabusMatchScore;
  final double conceptDepthScore;
  final double examUsefulnessScore;
  final String recommendationReason;
  final List<EnhancedTimestamp> enhancedTimestamps;

  RankedVideo({
    required this.video,
    required this.overallScore,
    required this.teachingClarityScore,
    required this.syllabusMatchScore,
    required this.conceptDepthScore,
    required this.examUsefulnessScore,
    required this.recommendationReason,
    required this.enhancedTimestamps,
  });

  Map<String, dynamic> toJson() => {
    'video': video.toMap(),
    'overall_score': overallScore,
    'teaching_clarity_score': teachingClarityScore,
    'syllabus_match_score': syllabusMatchScore,
    'concept_depth_score': conceptDepthScore,
    'exam_usefulness_score': examUsefulnessScore,
    'recommendation_reason': recommendationReason,
    'enhanced_timestamps': enhancedTimestamps.map((t) => t.toJson()).toList(),
  };
}

class EnhancedTimestamp {
  final String time;
  final String concept;
  final String description;

  EnhancedTimestamp({
    required this.time,
    required this.concept,
    required this.description,
  });

  Map<String, dynamic> toJson() => {
    'time': time,
    'concept': concept,
    'description': description,
  };
}