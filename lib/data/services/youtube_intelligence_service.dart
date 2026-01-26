// lib/data/services/youtube_intelligence_service.dart

import 'package:flutter/foundation.dart';
import '../models/youtube_video_model.dart';
import 'academic_search_engine.dart';
import 'dart:math' as math;
/// 🎥 YOUTUBE INTELLIGENCE SERVICE
/// Advanced video ranking & recommendation algorithm
class YouTubeIntelligenceService {
  // ═══════════════════════════════════════════════════════════════
  // RANK VIDEOS BY MULTIPLE CRITERIA
  // ═══════════════════════════════════════════════════════════════

  Future<List<RankedVideo>> rankVideos({
    required List<YouTubeVideoModel> videos,
    required String query,
    required Map<String, dynamic> intentAnalysis,
  }) async {
    try {
      debugPrint('🎯 Ranking ${videos.length} videos...');

      final rankedVideos = <RankedVideo>[];

      for (var video in videos) {
        // Calculate individual scores
        final teachingClarity = _calculateTeachingClarityScore(video);
        final syllabusMatch = _calculateSyllabusMatchScore(video, query, intentAnalysis);
        final conceptDepth = _calculateConceptDepthScore(video);
        final examUsefulness = _calculateExamUsefulnessScore(video, intentAnalysis);

        // Weighted overall score
        final overallScore = (
            teachingClarity * 0.30 +
                syllabusMatch * 0.35 +
                conceptDepth * 0.20 +
                examUsefulness * 0.15
        ).clamp(0.0, 1.0);

        // Generate recommendation reason
        final reason = _generateRecommendationReason(
          video: video,
          teachingClarity: teachingClarity,
          syllabusMatch: syllabusMatch,
          conceptDepth: conceptDepth,
          examUsefulness: examUsefulness,
        );

        // Extract enhanced timestamps
        final timestamps = _extractEnhancedTimestamps(video);

        rankedVideos.add(RankedVideo(
          video: video,
          overallScore: overallScore,
          teachingClarityScore: teachingClarity,
          syllabusMatchScore: syllabusMatch,
          conceptDepthScore: conceptDepth,
          examUsefulnessScore: examUsefulness,
          recommendationReason: reason,
          enhancedTimestamps: timestamps,
        ));
      }

      // Sort by overall score (highest first)
      rankedVideos.sort((a, b) => b.overallScore.compareTo(a.overallScore));

      debugPrint('✅ Ranked ${rankedVideos.length} videos');
      if (rankedVideos.isNotEmpty) {
        debugPrint('🏆 Top video: ${rankedVideos.first.video.title}');
        debugPrint('   Score: ${(rankedVideos.first.overallScore * 100).toStringAsFixed(1)}%');
      }

      return rankedVideos;
    } catch (e) {
      debugPrint('❌ Video ranking error: $e');
      return [];
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // TEACHING CLARITY SCORE (0.0 - 1.0)
  // ═══════════════════════════════════════════════════════════════

  double _calculateTeachingClarityScore(YouTubeVideoModel video) {
    double score = 0.5; // Base score

    // Factor 1: View to Like Ratio (indicates quality)
    if (video.viewCount > 0 && video.likeCount > 0) {
      final likeRatio = video.likeCount / video.viewCount;
      if (likeRatio > 0.05) score += 0.2; // Very good like ratio
      else if (likeRatio > 0.03) score += 0.15;
      else if (likeRatio > 0.01) score += 0.1;
    }

    // Factor 2: View Count (popularity indicator)
    if (video.viewCount > 100000) score += 0.15;
    else if (video.viewCount > 50000) score += 0.1;
    else if (video.viewCount > 10000) score += 0.05;

    // Factor 3: Title Quality (clear, structured)
    final title = video.title.toLowerCase();
    if (title.contains('tutorial') || title.contains('explained') ||
        title.contains('complete')) score += 0.05;
    if (title.contains('step by step') || title.contains('easy')) score += 0.05;
    if (title.contains('full course') || title.contains('lecture')) score += 0.05;

    // Factor 4: Description Quality
    if (video.description.length > 200) score += 0.05;
    if (video.timestamps.isNotEmpty) score += 0.05;

    return score.clamp(0.0, 1.0);
  }

  // ═══════════════════════════════════════════════════════════════
  // SYLLABUS MATCH SCORE (0.0 - 1.0)
  // ═══════════════════════════════════════════════════════════════

  double _calculateSyllabusMatchScore(
      YouTubeVideoModel video,
      String query,
      Map<String, dynamic> intentAnalysis,
      ) {
    double score = 0.3; // Base score

    final title = video.title.toLowerCase();
    final description = video.description.toLowerCase();
    final queryLower = query.toLowerCase();
    final topics = (intentAnalysis['topics'] as List?)?.map((t) => t.toString().toLowerCase()).toList() ?? [];

    // Factor 1: Direct Query Match
    if (title.contains(queryLower)) score += 0.25;
    else if (description.contains(queryLower)) score += 0.15;

    // Factor 2: Topic Coverage
    int topicMatches = 0;
    for (var topic in topics) {
      if (title.contains(topic)) {
        topicMatches++;
        score += 0.1;
      } else if (description.contains(topic)) {
        topicMatches++;
        score += 0.05;
      }
    }

    // Factor 3: Subject Keywords
    final subject = intentAnalysis['subject']?.toString().toLowerCase() ?? '';
    if (title.contains(subject) || description.contains(subject)) {
      score += 0.1;
    }

    // Factor 4: Academic Keywords
    final academicKeywords = ['lecture', 'tutorial', 'course', 'university',
      'college', 'professor', 'explained', 'theory'];
    int academicCount = 0;
    for (var keyword in academicKeywords) {
      if (title.contains(keyword) || description.contains(keyword)) {
        academicCount++;
      }
    }
    score += (academicCount / academicKeywords.length) * 0.1;

    return score.clamp(0.0, 1.0);
  }

  // ═══════════════════════════════════════════════════════════════
  // CONCEPT DEPTH SCORE (0.0 - 1.0)
  // ═══════════════════════════════════════════════════════════════

  double _calculateConceptDepthScore(YouTubeVideoModel video) {
    double score = 0.4; // Base score

    // Factor 1: Video Duration (longer = more depth, but not too long)
    final duration = _parseDurationToMinutes(video.duration);
    if (duration >= 15 && duration <= 45) score += 0.25; // Optimal length
    else if (duration >= 10 && duration <= 60) score += 0.15;
    else if (duration >= 5) score += 0.05;

    // Factor 2: Description Depth
    if (video.description.length > 500) score += 0.15;
    else if (video.description.length > 300) score += 0.1;
    else if (video.description.length > 150) score += 0.05;

    // Factor 3: Timestamps (indicates structured content)
    if (video.timestamps.isNotEmpty) {
      score += 0.1;
      if (video.timestamps.length >= 5) score += 0.05;
    }

    // Factor 4: Key Topics Coverage
    if (video.keyTopics.isNotEmpty) {
      score += video.keyTopics.length * 0.02;
    }

    return score.clamp(0.0, 1.0);
  }

  // ═══════════════════════════════════════════════════════════════
  // EXAM USEFULNESS SCORE (0.0 - 1.0)
  // ═══════════════════════════════════════════════════════════════

  double _calculateExamUsefulnessScore(
      YouTubeVideoModel video,
      Map<String, dynamic> intentAnalysis,
      ) {
    double score = 0.3; // Base score

    final title = video.title.toLowerCase();
    final description = video.description.toLowerCase();
    final examRelevance = intentAnalysis['exam_relevance']?.toString().toLowerCase() ?? 'medium';

    // Factor 1: Exam-Related Keywords
    final examKeywords = ['exam', 'important', 'questions', 'previous year',
      'solved', 'practice', 'mcq', 'university', 'gate',
      'competitive', 'interview'];
    int examKeywordCount = 0;
    for (var keyword in examKeywords) {
      if (title.contains(keyword)) {
        examKeywordCount++;
        score += 0.08;
      } else if (description.contains(keyword)) {
        examKeywordCount++;
        score += 0.04;
      }
    }

    // Factor 2: Quick Revision Indicators
    if (title.contains('revision') || title.contains('summary') ||
        title.contains('quick') || title.contains('one shot')) {
      score += 0.15;
    }

    // Factor 3: Problem Solving
    if (title.contains('solved') || title.contains('example') ||
        title.contains('problem') || title.contains('numerical')) {
      score += 0.1;
    }

    // Factor 4: Exam Relevance Boost
    if (examRelevance == 'high') score += 0.15;
    else if (examRelevance == 'medium') score += 0.08;

    return score.clamp(0.0, 1.0);
  }

  // ═══════════════════════════════════════════════════════════════
  // GENERATE RECOMMENDATION REASON
  // ═══════════════════════════════════════════════════════════════

  String _generateRecommendationReason({
    required YouTubeVideoModel video,
    required double teachingClarity,
    required double syllabusMatch,
    required double conceptDepth,
    required double examUsefulness,
  }) {
    final reasons = <String>[];

    // Teaching Clarity
    if (teachingClarity > 0.75) {
      reasons.add('Excellent teaching quality with ${_formatViews(video.viewCount)} views');
    } else if (teachingClarity > 0.6) {
      reasons.add('Good teaching clarity');
    }

    // Syllabus Match
    if (syllabusMatch > 0.7) {
      reasons.add('Perfect match for your syllabus');
    } else if (syllabusMatch > 0.5) {
      reasons.add('Covers key topics');
    }

    // Concept Depth
    if (conceptDepth > 0.7) {
      reasons.add('In-depth coverage with structured content');
    } else if (conceptDepth > 0.5) {
      reasons.add('Good concept explanation');
    }

    // Exam Usefulness
    if (examUsefulness > 0.7) {
      reasons.add('Highly useful for exam preparation');
    } else if (examUsefulness > 0.5) {
      reasons.add('Contains exam-relevant content');
    }

    // Channel Credibility
    if (video.viewCount > 50000) {
      reasons.add('Popular educational content');
    }

    // Duration
    final duration = _parseDurationToMinutes(video.duration);
    if (duration >= 15 && duration <= 30) {
      reasons.add('Optimal length for focused learning');
    }

    if (reasons.isEmpty) {
      return 'Relevant content for your topic';
    }

    return reasons.take(3).join(' • ');
  }

  // ═══════════════════════════════════════════════════════════════
  // EXTRACT ENHANCED TIMESTAMPS
  // ═══════════════════════════════════════════════════════════════

  List<EnhancedTimestamp> _extractEnhancedTimestamps(YouTubeVideoModel video) {
    final enhanced = <EnhancedTimestamp>[];

    // Use existing timestamps if available
    if (video.timestamps.isNotEmpty) {
      for (var timestamp in video.timestamps.take(5)) {
        enhanced.add(EnhancedTimestamp(
          time: timestamp.time,
          concept: timestamp.label,
          description: timestamp.description ?? timestamp.label,
        ));
      }
      return enhanced;
    }

    // Generate smart timestamps from description
    final description = video.description;
    final lines = description.split('\n');

    for (var line in lines) {
      // Look for timestamp patterns
      final match = RegExp(r'(\d{1,2}:\d{2}(?::\d{2})?)\s*[-–—]?\s*(.+)')
          .firstMatch(line);

      if (match != null) {
        final time = match.group(1)!;
        final concept = match.group(2)!.trim();

        if (concept.isNotEmpty && concept.length < 100) {
          enhanced.add(EnhancedTimestamp(
            time: time,
            concept: _cleanConceptText(concept),
            description: concept,
          ));

          if (enhanced.length >= 5) break;
        }
      }
    }

    // If no timestamps found, create generic ones
    if (enhanced.isEmpty) {
      final duration = _parseDurationToMinutes(video.duration);
      if (duration > 5) {
        enhanced.add(EnhancedTimestamp(
          time: '0:00',
          concept: 'Introduction',
          description: 'Overview of the topic',
        ));

        if (duration > 10) {
          enhanced.add(EnhancedTimestamp(
            time: '${(duration * 0.3).toInt()}:00',
            concept: 'Main Concepts',
            description: 'Core theory and explanations',
          ));
        }

        if (duration > 15) {
          enhanced.add(EnhancedTimestamp(
            time: '${(duration * 0.6).toInt()}:00',
            concept: 'Examples & Applications',
            description: 'Practical examples and use cases',
          ));
        }

        if (duration > 20) {
          enhanced.add(EnhancedTimestamp(
            time: '${(duration * 0.85).toInt()}:00',
            concept: 'Summary',
            description: 'Key points recap',
          ));
        }
      }
    }

    return enhanced;
  }

  // ═══════════════════════════════════════════════════════════════
  // HELPER METHODS
  // ═══════════════════════════════════════════════════════════════

  int _parseDurationToMinutes(String duration) {
    try {
      final parts = duration.split(':');
      if (parts.length == 2) {
        return int.parse(parts[0]);
      } else if (parts.length == 3) {
        return int.parse(parts[0]) * 60 + int.parse(parts[1]);
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }

  String _formatViews(int views) {
    if (views >= 1000000) {
      return '${(views / 1000000).toStringAsFixed(1)}M';
    } else if (views >= 1000) {
      return '${(views / 1000).toStringAsFixed(1)}K';
    }
    return '$views';
  }

  String _cleanConceptText(String text) {
    return text
        .replaceAll(RegExp(r'[^\w\s\-]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}