// lib/data/services/response_generator_service.dart

import 'package:flutter/foundation.dart';
import 'academic_search_engine.dart';

/// 📝 RESPONSE GENERATOR SERVICE
/// Parses AI responses into structured multi-layer explanations
class ResponseGeneratorService {
  // ═══════════════════════════════════════════════════════════════
  // PARSE MULTI-LAYER EXPLANATION
  // ═══════════════════════════════════════════════════════════════

  MultiLayerExplanation parseMultiLayerExplanation({
    required String response,
    required List<PDFChunk> pdfChunks,
    required List<RankedVideo> videos,
  }) {
    try {
      debugPrint('📝 Parsing AI response into structured format...');

      // Extract sections using regex patterns
      final intuition = _extractSection(
        response,
        ['beginner', 'intuition', 'simple'],
        ['theory', 'formal', 'step'],
      );

      final theory = _extractSection(
        response,
        ['theory', 'formal', 'university'],
        ['step', 'breakdown', 'real-world'],
      );

      final stepByStep = _extractSection(
        response,
        ['step', 'breakdown', 'algorithm', 'derivation'],
        ['real-world', 'analogy', 'exam'],
      );

      final realWorld = _extractSection(
        response,
        ['real-world', 'analogy', 'example'],
        ['exam', '2-mark', 'practice'],
      );

      final examAnswers = _extractExamAnswers(response);

      // Extract source citations
      final citations = _extractSourceCitations(response, pdfChunks, videos);

      debugPrint('✅ Successfully parsed explanation');
      debugPrint('   - Intuition: ${intuition.isNotEmpty ? "✓" : "✗"}');
      debugPrint('   - Theory: ${theory.isNotEmpty ? "✓" : "✗"}');
      debugPrint('   - Step-by-step: ${stepByStep.isNotEmpty ? "✓" : "✗"}');
      debugPrint('   - Citations: ${citations.length}');

      return MultiLayerExplanation(
        intuition: intuition.isNotEmpty ? intuition : _generateFallbackIntuition(response),
        theory: theory.isNotEmpty ? theory : _extractFirstParagraphs(response, 3),
        stepByStep: stepByStep.isNotEmpty ? stepByStep : _extractListsAndSteps(response),
        realWorld: realWorld.isNotEmpty ? realWorld : _generateFallbackRealWorld(),
        examAnswers: examAnswers,
        sourceCitations: citations,
      );
    } catch (e) {
      debugPrint('❌ Response parsing error: $e');
      return MultiLayerExplanation(
        intuition: 'Error parsing response. Please try again.',
        theory: response,
        stepByStep: '',
        realWorld: '',
        examAnswers: ExamAnswers(twoMark: '', fiveMark: '', tenMark: ''),
        sourceCitations: [],
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // EXTRACT SECTION BY KEYWORDS
  // ═══════════════════════════════════════════════════════════════

  String _extractSection(
      String text,
      List<String> startKeywords,
      List<String> endKeywords,
      ) {
    try {
      final lines = text.split('\n');
      final buffer = StringBuffer();
      bool inSection = false;
      int emptyLineCount = 0;

      for (var line in lines) {
        final lineLower = line.toLowerCase();

        // Check if we're entering the section
        if (!inSection) {
          for (var keyword in startKeywords) {
            if (lineLower.contains(keyword) &&
                (lineLower.contains('**') || lineLower.contains('#') || lineLower.contains(':'))) {
              inSection = true;
              buffer.clear();
              break;
            }
          }
          continue;
        }

        // Check if we're leaving the section
        bool shouldExit = false;
        for (var keyword in endKeywords) {
          if (lineLower.contains(keyword) &&
              (lineLower.contains('**') || lineLower.contains('#') || lineLower.contains(':'))) {
            shouldExit = true;
            break;
          }
        }

        if (shouldExit) break;

        // Count empty lines
        if (line.trim().isEmpty) {
          emptyLineCount++;
          if (emptyLineCount > 2) break; // Stop after 2 empty lines
        } else {
          emptyLineCount = 0;
        }

        // Add line to buffer (skip headers)
        if (!lineLower.contains('**') || buffer.isNotEmpty) {
          buffer.writeln(line);
        }
      }

      return buffer.toString().trim();
    } catch (e) {
      debugPrint('⚠️ Section extraction error: $e');
      return '';
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // EXTRACT EXAM ANSWERS
  // ═══════════════════════════════════════════════════════════════

  ExamAnswers _extractExamAnswers(String text) {
    String twoMark = '';
    String fiveMark = '';
    String tenMark = '';

    try {
      // Extract 2-mark answer
      final twoMarkMatch = RegExp(
        r'\*\*2[- ]?Mark.*?\*\*:?\s*([\s\S]*?)(?=\*\*[35][- ]?Mark|\*\*Practice|$)',
        caseSensitive: false,
      ).firstMatch(text);

      if (twoMarkMatch != null) {
        twoMark = twoMarkMatch.group(1)!.trim();
      }

      // Extract 5-mark answer
      final fiveMarkMatch = RegExp(
        r'\*\*5[- ]?Mark.*?\*\*:?\s*([\s\S]*?)(?=\*\*10[- ]?Mark|\*\*Practice|$)',
        caseSensitive: false,
      ).firstMatch(text);

      if (fiveMarkMatch != null) {
        fiveMark = fiveMarkMatch.group(1)!.trim();
      }

      // Extract 10-mark answer
      final tenMarkMatch = RegExp(
        r'\*\*10[- ]?Mark.*?\*\*:?\s*([\s\S]*?)(?=\*\*Practice|##|$)',
        caseSensitive: false,
      ).firstMatch(text);

      if (tenMarkMatch != null) {
        tenMark = tenMarkMatch.group(1)!.trim();
      }

      // Fallback: Generate from theory if not found
      if (twoMark.isEmpty) {
        twoMark = _generateTwoMarkAnswer(text);
      }
      if (fiveMark.isEmpty) {
        fiveMark = _generateFiveMarkAnswer(text);
      }
      if (tenMark.isEmpty) {
        tenMark = _generateTenMarkAnswer(text);
      }

    } catch (e) {
      debugPrint('⚠️ Exam answer extraction error: $e');
    }

    return ExamAnswers(
      twoMark: twoMark,
      fiveMark: fiveMark,
      tenMark: tenMark,
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // EXTRACT SOURCE CITATIONS
  // ═══════════════════════════════════════════════════════════════

  List<SourceCitation> _extractSourceCitations(
      String text,
      List<PDFChunk> pdfChunks,
      List<RankedVideo> videos,
      ) {
    final citations = <SourceCitation>[];

    try {
      // Find PDF citations: (PDF: filename, Page X)
      final pdfPattern = RegExp(r'\(PDF:\s*([^,]+),\s*Page\s*(\d+)\)');
      for (var match in pdfPattern.allMatches(text)) {
        final fileName = match.group(1)?.trim();
        final page = int.tryParse(match.group(2) ?? '0');

        if (fileName != null && page != null) {
          // Find concept before citation
          final startIndex = (match.start - 100).clamp(0, match.start);
          final context = text.substring(startIndex, match.start);
          final concept = _extractConceptFromContext(context);

          citations.add(SourceCitation(
            concept: concept,
            pdfSource: fileName,
            pdfPage: page,
          ));
        }
      }

      // Find video citations: (Video: title @ mm:ss)
      final videoPattern = RegExp(r'\(Video:\s*"?([^"@]+)"?\s*@\s*(\d+:\d+)\)');
      for (var match in videoPattern.allMatches(text)) {
        final videoTitle = match.group(1)?.trim();
        final timestamp = match.group(2)?.trim();

        if (videoTitle != null && timestamp != null) {
          // Find matching video
          final video = videos.firstWhere(
                (v) => videoTitle.toLowerCase().contains(v.video.title.toLowerCase().substring(0, 20)),
            orElse: () => videos.first,
          );

          final startIndex = (match.start - 100).clamp(0, match.start);
          final context = text.substring(startIndex, match.start);
          final concept = _extractConceptFromContext(context);

          citations.add(SourceCitation(
            concept: concept,
            videoId: video.video.videoId,
            videoTimestamp: timestamp,
          ));
        }
      }

      debugPrint('📌 Extracted ${citations.length} source citations');
    } catch (e) {
      debugPrint('⚠️ Citation extraction error: $e');
    }

    return citations;
  }

  // ═══════════════════════════════════════════════════════════════
  // HELPER METHODS
  // ═══════════════════════════════════════════════════════════════

  String _extractConceptFromContext(String context) {
    final sentences = context.split(RegExp(r'[.!?]'));
    if (sentences.isNotEmpty) {
      final lastSentence = sentences.last.trim();
      if (lastSentence.length > 10 && lastSentence.length < 100) {
        return lastSentence;
      }
    }
    return 'Key concept';
  }

  String _generateFallbackIntuition(String response) {
    final firstParagraph = _extractFirstParagraphs(response, 1);
    if (firstParagraph.length > 50) {
      return firstParagraph.length > 300
          ? '${firstParagraph.substring(0, 300)}...'
          : firstParagraph;
    }
    return 'Please refer to the detailed explanation below.';
  }

  String _extractFirstParagraphs(String text, int count) {
    final paragraphs = text.split('\n\n').where((p) => p.trim().isNotEmpty).toList();
    return paragraphs.take(count).join('\n\n').trim();
  }

  String _extractListsAndSteps(String text) {
    final lines = text.split('\n');
    final buffer = StringBuffer();

    for (var line in lines) {
      final trimmed = line.trim();
      if (trimmed.startsWith(RegExp(r'^\d+\.|^-|^•|^Step'))) {
        buffer.writeln(line);
      }
    }

    return buffer.toString().trim();
  }

  String _generateFallbackRealWorld() {
    return 'Real-world applications and analogies will help you understand this concept better in practical scenarios.';
  }

  String _generateTwoMarkAnswer(String text) {
    final sentences = text.split(RegExp(r'[.!?]')).where((s) => s.trim().isNotEmpty).take(2);
    return sentences.join('. ').trim() + '.';
  }

  String _generateFiveMarkAnswer(String text) {
    final paragraphs = text.split('\n\n').where((p) => p.trim().isNotEmpty).take(2);
    return paragraphs.join('\n\n').trim();
  }

  String _generateTenMarkAnswer(String text) {
    final paragraphs = text.split('\n\n').where((p) => p.trim().isNotEmpty).take(4);
    return paragraphs.join('\n\n').trim();
  }
}