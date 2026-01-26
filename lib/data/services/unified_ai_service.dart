// lib/data/services/unified_ai_service.dart

import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'dart:convert';

/// 🤖 UNIFIED AI SERVICE - Production Ready with Academic Search
/// Combines all AI functionality: Chat, Document Analysis, Study Tools, Academic Search
class UnifiedAIService {
  static final UnifiedAIService _instance = UnifiedAIService._internal();
  factory UnifiedAIService() => _instance;
  UnifiedAIService._internal();

  GenerativeModel? _model;
  ChatSession? _chatSession;
  bool _isInitialized = false;

  // Current context
  StudyModeType _currentMode = StudyModeType.general;
  String? _currentSubject;
  List<Content> _conversationHistory = [];

  // ═══════════════════════════════════════════════════════════════
  // INITIALIZATION
  // ═══════════════════════════════════════════════════════════════

  Future<void> initialize() async {
    if (_isInitialized) return;

    debugPrint('🔄 Initializing Unified AI Service...');

    try {
      // Load environment if not already loaded
      if (!dotenv.isInitialized) {
        await dotenv.load(fileName: ".env");
      }

      final apiKey = dotenv.env['GEMINI_API_KEY'];

      if (apiKey == null || apiKey.isEmpty) {
        throw AIServiceException(
          'API_KEY_MISSING',
          'Gemini API key not found in .env file.\n\n'
              'Steps to fix:\n'
              '1. Create .env file in project root\n'
              '2. Add: GEMINI_API_KEY=your_key_here\n'
              '3. Get key from: https://aistudio.google.com/app/apikey',
        );
      }

      debugPrint('✅ API Key loaded: ${apiKey.substring(0, 8)}...');

      // Initialize model with correct configuration
      _model = GenerativeModel(
        model: 'gemini-2.0-flash-exp',
        apiKey: apiKey,
        generationConfig: GenerationConfig(
          temperature: 0.8,
          topK: 40,
          topP: 0.95,
          maxOutputTokens: 8192,
          responseMimeType: 'text/plain',
        ),
        safetySettings: [
          SafetySetting(
            HarmCategory.harassment,
            HarmBlockThreshold.medium,
          ),
          SafetySetting(
            HarmCategory.hateSpeech,
            HarmBlockThreshold.medium,
          ),
        ],
      );

      // Start chat with system context
      _chatSession = _model!.startChat(
        history: _buildInitialHistory(),
      );

      _isInitialized = true;
      debugPrint('✅ AI Service initialized successfully');
    } catch (e) {
      debugPrint('❌ AI Service initialization failed: $e');
      _isInitialized = false;
      rethrow;
    }
  }

  List<Content> _buildInitialHistory() {
    return [
      Content.text(_getSystemPrompt()),
      Content.model([
        TextPart(
          'Hello! I\'m your AI Study Assistant, powered by Google Gemini. '
              'I\'m here to help you with:\n\n'
              '📚 Study & Learning\n'
              '📝 Exam Preparation\n'
              '🧮 Problem Solving\n'
              '📄 Document Analysis\n'
              '🎯 Academic Search (Perplexity-style)\n'
              '🎬 Video Recommendations\n\n'
              'How can I help you today?',
        )
      ]),
    ];
  }

  String _getSystemPrompt() {
    return '''You are an advanced AI Study Assistant for college students, powered by Google Gemini.

CORE IDENTITY:
- You are helpful, encouraging, and patient
- You explain complex topics in simple terms
- You adapt your teaching style based on student needs
- You provide exam-oriented, practical knowledge
- You can perform multi-source academic search with citations

CAPABILITIES:
1. Concept Explanation - Break down complex topics with examples
2. Problem Solving - Step-by-step solutions with formulas
3. Exam Preparation - Important questions, MCQs, study strategies
4. Document Analysis - Summaries, notes, key points from PDFs/images
5. Study Planning - Personalized schedules and revision plans
6. Quick Revision - Concise notes for last-minute study
7. Academic Search - Multi-source grounded answers with citations
8. Video Recommendations - Suggest best educational videos

GUIDELINES:
✅ Use bullet points and structured formatting
✅ Include real-world examples and analogies
✅ Provide formulas and key definitions
✅ Give step-by-step explanations
✅ Be encouraging and supportive
✅ Focus on exam-relevant content
✅ Use emojis sparingly for emphasis
✅ Cite sources when performing academic search
✅ Provide exam answers in 2/5/10 mark formats

❌ Don't use overly technical jargon
❌ Don't give one-word answers
❌ Don't make up facts or formulas
❌ Don't be discouraging

FORMATTING:
- Use markdown for structure (bold, lists, code blocks)
- Keep paragraphs concise (3-4 lines max)
- Use numbered lists for steps
- Use bullet points for key information

Remember: Your goal is to help students learn effectively and succeed in their exams!''';
  }

  // ═══════════════════════════════════════════════════════════════
  // CORE CHAT FUNCTIONALITY
  // ═══════════════════════════════════════════════════════════════

  Future<String> sendMessage(String message, {List<File>? files}) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      // Build content with mode-specific context
      final enhancedMessage = _enhanceMessageWithContext(message);

      List<Part> parts = [TextPart(enhancedMessage)];

      // Add file attachments if present
      if (files != null && files.isNotEmpty) {
        for (final file in files) {
          try {
            final bytes = await file.readAsBytes();
            final mimeType = _getMimeType(file.path);

            parts.add(DataPart(mimeType, bytes));
          } catch (e) {
            debugPrint('⚠️ Error reading file: $e');
          }
        }
      }

      final content = Content.multi(parts);

      // Send to AI
      final response = await _chatSession!.sendMessage(content);

      // Store in history
      _conversationHistory.add(content);
      _conversationHistory.add(Content.model([TextPart(response.text ?? '')]));

      if (response.text != null && response.text!.isNotEmpty) {
        return response.text!;
      } else {
        return 'I apologize, but I couldn\'t generate a response. Please try rephrasing your question.';
      }
    } on GenerativeAIException catch (e) {
      debugPrint('❌ Gemini API Error: $e');
      return _handleAIError(e);
    } catch (e) {
      debugPrint('❌ Unexpected error: $e');
      return 'An unexpected error occurred. Please try again.\n\nError: ${e.toString()}';
    }
  }

  String _enhanceMessageWithContext(String message) {
    final buffer = StringBuffer();

    // Add study mode context
    if (_currentMode != StudyModeType.general) {
      buffer.writeln(_getModePrompt());
      buffer.writeln();
    }

    // Add subject context
    if (_currentSubject != null && _currentSubject!.isNotEmpty) {
      buffer.writeln('📚 Current Subject: $_currentSubject');
      buffer.writeln();
    }

    // Add user message
    buffer.write(message);

    return buffer.toString();
  }

  String _getModePrompt() {
    switch (_currentMode) {
      case StudyModeType.beginner:
        return '🎓 BEGINNER MODE: Explain in simple terms with basic examples. Avoid jargon.';
      case StudyModeType.exam:
        return '📝 EXAM MODE: Focus on marks-oriented answers, important questions, and exam patterns.';
      case StudyModeType.interview:
        return '💼 INTERVIEW MODE: Emphasize practical applications, real-world use cases, and in-depth explanations.';
      case StudyModeType.quickRevision:
        return '⚡ QUICK REVISION: Provide concise bullet points, key formulas, and must-know facts only.';
      case StudyModeType.general:
        return '';
    }
  }

  String _handleAIError(GenerativeAIException error) {
    if (error.message.contains('API_KEY_INVALID') ||
        error.message.contains('invalid_api_key')) {
      return '🔑 **Invalid API Key**\n\n'
          'Your Gemini API key is invalid or expired.\n\n'
          '**To fix:**\n'
          '1. Go to https://aistudio.google.com/app/apikey\n'
          '2. Generate a new API key\n'
          '3. Update your .env file\n'
          '4. Restart the app';
    } else if (error.message.contains('RESOURCE_EXHAUSTED') ||
        error.message.contains('quota')) {
      return '⏰ **API Quota Exceeded**\n\n'
          'You\'ve reached your API usage limit.\n\n'
          '**Solutions:**\n'
          '• Wait for quota reset (usually 24 hours)\n'
          '• Upgrade your API plan\n'
          '• Use a different API key';
    } else if (error.message.contains('SAFETY')) {
      return '⚠️ **Content Filtered**\n\n'
          'Your message was filtered by safety settings.\n\n'
          'Please rephrase your question in an academic context.';
    } else {
      return '❌ **AI Service Error**\n\n'
          '${error.message}\n\n'
          'Please try again or rephrase your question.';
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // ✅ NEW: ACADEMIC SEARCH WITH STRUCTURED OUTPUT
  // ═══════════════════════════════════════════════════════════════

  Future<String> performAcademicSearch({
    required String query,
    required String subject,
    required String academicLevel,
    required String branch,
    String? examType,
    List<String>? pdfContexts,
    List<Map<String, dynamic>>? videoMetadata,
  }) async {
    if (!_isInitialized) await initialize();

    try {
      final prompt = _buildAcademicSearchPrompt(
        query: query,
        subject: subject,
        academicLevel: academicLevel,
        branch: branch,
        examType: examType ?? 'semester',
        pdfContexts: pdfContexts ?? [],
        videoMetadata: videoMetadata ?? [],
      );

      // Create one-shot request (no chat history for academic search)
      final content = Content.text(prompt);
      final response = await _model!.generateContent([content]);

      if (response.text != null && response.text!.isNotEmpty) {
        return response.text!;
      } else {
        return 'Unable to generate academic response. Please try again.';
      }
    } catch (e) {
      debugPrint('❌ Academic search error: $e');
      return 'Error performing academic search: ${e.toString()}';
    }
  }

  String _buildAcademicSearchPrompt({
    required String query,
    required String subject,
    required String academicLevel,
    required String branch,
    required String examType,
    required List<String> pdfContexts,
    required List<Map<String, dynamic>> videoMetadata,
  }) {
    final buffer = StringBuffer();

    buffer.writeln('You are an advanced Academic Search & Reasoning Engine.');
    buffer.writeln();
    buffer.writeln('Student Question: "$query"');
    buffer.writeln('Academic Level: $academicLevel');
    buffer.writeln('Branch: $branch');
    buffer.writeln('Subject: $subject');
    buffer.writeln('Exam Type: $examType');
    buffer.writeln();

    // Add PDF contexts
    if (pdfContexts.isNotEmpty) {
      buffer.writeln('PDF Knowledge Base:');
      for (int i = 0; i < pdfContexts.length; i++) {
        buffer.writeln('PDF ${i + 1}:');
        buffer.writeln(pdfContexts[i]);
        buffer.writeln('---');
      }
      buffer.writeln();
    }

    // Add video metadata
    if (videoMetadata.isNotEmpty) {
      buffer.writeln('YouTube Videos Available:');
      for (var video in videoMetadata) {
        buffer.writeln('- "${video['title']}" by ${video['channel']}');
        buffer.writeln('  Duration: ${video['duration']} | Views: ${video['views']}');
        buffer.writeln('  Relevance: ${video['relevance']}%');
      }
      buffer.writeln();
    }

    buffer.writeln('''Generate a comprehensive multi-layer learning response with:

1. **BEGINNER-FRIENDLY INTUITION** (2-3 sentences explaining simply)

2. **FORMAL UNIVERSITY-LEVEL THEORY** (Complete academic explanation)

3. **STEP-BY-STEP BREAKDOWN** (Algorithm/Derivation/Process with numbered steps)

4. **REAL-WORLD ANALOGY** (Everyday examples for better understanding)

5. **EXAM-READY ANSWERS**:
   - **2-Mark Answer**: Concise definition/key points
   - **5-Mark Answer**: Detailed explanation with examples
   - **10-Mark Answer**: Comprehensive answer with diagrams, examples, advantages/disadvantages

For each major concept, cite sources when available:
- (PDF: Page X)
- (Video: [title] @ mm:ss)

Format response in clear sections with markdown headers.''');

    return buffer.toString();
  }

  // ═══════════════════════════════════════════════════════════════
  // DOCUMENT ANALYSIS
  // ═══════════════════════════════════════════════════════════════

  Future<DocumentAnalysisResult> analyzeDocument(
      File file,
      AnalysisType type,
      ) async {
    if (!_isInitialized) await initialize();

    try {
      debugPrint('📄 Analyzing document: ${file.path}');

      final bytes = await file.readAsBytes();
      final mimeType = _getMimeType(file.path);

      String prompt;
      switch (type) {
        case AnalysisType.summary:
          prompt = _getSummaryPrompt();
          break;
        case AnalysisType.mcq:
          prompt = _getMCQPrompt();
          break;
        case AnalysisType.notes:
          prompt = _getNotesPrompt();
          break;
        case AnalysisType.questions:
          prompt = _getQuestionsPrompt();
          break;
        case AnalysisType.flashcards:
          prompt = _getFlashcardsPrompt();
          break;
      }

      final content = Content.multi([
        TextPart(prompt),
        DataPart(mimeType, bytes),
      ]);

      final response = await _model!.generateContent([content]);

      return DocumentAnalysisResult(
        success: true,
        content: response.text ?? 'No analysis generated',
        type: type,
        fileName: file.path.split('/').last,
      );
    } catch (e) {
      debugPrint('❌ Document analysis error: $e');
      return DocumentAnalysisResult(
        success: false,
        content: 'Failed to analyze document: ${e.toString()}',
        type: type,
        fileName: file.path.split('/').last,
      );
    }
  }

  String _getSummaryPrompt() {
    return '''Analyze this document and provide a comprehensive summary.

Include:
1. **Main Topics** - Key concepts covered
2. **Important Points** - Critical information (bullet points)
3. **Key Definitions** - Essential terms explained
4. **Formulas/Equations** - If applicable
5. **Study Tips** - How to learn this content

Format: Use markdown with headers and bullet points.''';
  }

  String _getMCQPrompt() {
    return '''Generate 10 high-quality multiple choice questions from this document.

For each question:
**Q[number]:** [Question text]
A) [Option A]
B) [Option B]
C) [Option C]
D) [Option D]

**Answer:** [Correct option letter]
**Explanation:** [Brief explanation why this is correct]

Focus on exam-relevant content.''';
  }

  String _getNotesPrompt() {
    return '''Convert this document into structured study notes.

Format:
# Main Topic

## Subtopic 1
- Key Point 1
- Key Point 2
  - Detail if needed

## Subtopic 2
- Key Point 3
- Key Point 4

**Important Formulas:**
[List formulas with explanations]

**Exam Tips:**
[Key points for exam preparation]

Keep notes concise and exam-focused.''';
  }

  String _getQuestionsPrompt() {
    return '''Extract 10 potential exam questions from this document.

For each question, provide:
1. Question text
2. Question type (Short/Long/Numerical)
3. Marks value (estimate)
4. Brief answer outline

Format:
**Q1:** [Question] (5 marks, Long Answer)
**Answer:** [Brief outline of what answer should cover]

Focus on high-probability exam questions.''';
  }

  String _getFlashcardsPrompt() {
    return '''Create 15 flashcards for quick revision from this document.

Format each as:
**CARD [number]**
Front: [Question/Term]
Back: [Answer/Definition]

Focus on key concepts, definitions, formulas, and facts.
Keep cards concise for easy memorization.''';
  }

  // ═══════════════════════════════════════════════════════════════
  // STUDY TOOLS
  // ═══════════════════════════════════════════════════════════════

  Future<String> explainConcept(String concept, {String? subject}) async {
    final prompt = '''Explain the concept: "$concept"${subject != null ? ' (Subject: $subject)' : ''}

Provide:
1. **Definition** - Clear, simple explanation
2. **Key Points** - 3-5 important aspects (bullets)
3. **Real-World Example** - Practical application
4. **Why It Matters** - Importance for exams/career
5. **Common Mistakes** - What to avoid

${_getModePrompt()}''';

    return await sendMessage(prompt);
  }

  Future<String> generateImportantQuestions(String topic, String subject) async {
    final prompt = '''Generate important exam questions for:
Topic: $topic
Subject: $subject

Provide:

**SHORT ANSWER QUESTIONS (2-3 marks each):**
1. [Question 1]
2. [Question 2]
3. [Question 3]
4. [Question 4]
5. [Question 5]

**LONG ANSWER QUESTIONS (5-10 marks each):**
1. [Question 1]
2. [Question 2]
3. [Question 3]

**NUMERICAL PROBLEMS (if applicable):**
1. [Problem 1]
2. [Problem 2]

**MCQs:**
1. [Question with 4 options and answer]
2. [Question with 4 options and answer]
3. [Question with 4 options and answer]

Base questions on previous year patterns and high-probability topics.''';

    return await sendMessage(prompt);
  }

  Future<String> solveNumerical(String problem, String subject) async {
    final prompt = '''Solve this numerical problem step-by-step:

**Subject:** $subject
**Problem:** $problem

Provide:

**1. Given Data:**
[List all given values]

**2. Required:**
[What needs to be found]

**3. Formula:**
[Mathematical formula with explanation]

**4. Solution:**
Step 1: [Detailed step]
Step 2: [Detailed step]
Step 3: [Detailed step]
...

**5. Final Answer:**
[Answer with proper units]

**6. Key Points to Remember:**
- [Important point 1]
- [Important point 2]

Use university exam format and show all work.''';

    return await sendMessage(prompt);
  }

  Future<List<FlashCard>> generateFlashcards(String topic, String subject) async {
    final prompt = '''Create 15 flashcards for: $topic (Subject: $subject)

Format EXACTLY as:
CARD 1
FRONT: [Question/Term]
BACK: [Answer/Definition]

CARD 2
FRONT: [Question/Term]
BACK: [Answer/Definition]

...and so on.

Focus on exam-relevant content, key definitions, and formulas.''';

    final response = await sendMessage(prompt);
    return _parseFlashcards(response);
  }

  List<FlashCard> _parseFlashcards(String response) {
    final cards = <FlashCard>[];
    final lines = response.split('\n');

    String? front;

    for (var line in lines) {
      line = line.trim();

      if (line.startsWith('FRONT:')) {
        front = line.substring(6).trim();
      } else if (line.startsWith('BACK:') && front != null) {
        final back = line.substring(5).trim();
        cards.add(FlashCard(front: front, back: back));
        front = null;
      }
    }

    return cards;
  }

  Future<String> generateMindMap(String topic, String subject) async {
    final prompt = '''Create a hierarchical mind map for: $topic (Subject: $subject)

Format as ASCII tree:

$topic
├── Main Branch 1
│   ├── Sub-point 1.1
│   ├── Sub-point 1.2
│   └── Sub-point 1.3
├── Main Branch 2
│   ├── Sub-point 2.1
│   └── Sub-point 2.2
└── Main Branch 3
    ├── Sub-point 3.1
    └── Sub-point 3.2

Include all key concepts, formulas, and relationships.
Keep it exam-focused and comprehensive.''';

    return await sendMessage(prompt);
  }

  Future<String> generateQuickRevision(String topic, int minutes) async {
    final prompt = '''Create a $minutes-minute quick revision guide for: $topic

Structure:

**⚡ CORE CONCEPTS ($minutes min read)**

**1. Key Definitions** (must-know terms)
- Definition 1
- Definition 2

**2. Important Formulas**
- Formula 1: [explanation]
- Formula 2: [explanation]

**3. Critical Points**
- Point 1
- Point 2

**4. Common Mistakes to Avoid**
- Mistake 1
- Mistake 2

**5. Exam Tips**
- Tip 1
- Tip 2

Keep concise and high-yield for last-minute revision.''';

    return await sendMessage(prompt);
  }

  // ═══════════════════════════════════════════════════════════════
  // MODE & CONTEXT MANAGEMENT
  // ═══════════════════════════════════════════════════════════════

  void setStudyMode(StudyModeType mode) {
    _currentMode = mode;
    debugPrint('✅ Study mode: ${mode.name}');
  }

  void setSubject(String subject) {
    _currentSubject = subject;
    debugPrint('✅ Subject: $subject');
  }

  void clearSubject() {
    _currentSubject = null;
  }

  void resetChat() {
    if (_isInitialized && _model != null) {
      _chatSession = _model!.startChat(
        history: _buildInitialHistory(),
      );
      _conversationHistory.clear();
      debugPrint('✅ Chat reset');
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // UTILITIES
  // ═══════════════════════════════════════════════════════════════

  String _getMimeType(String filePath) {
    final extension = filePath.split('.').last.toLowerCase();

    switch (extension) {
      case 'pdf':
        return 'application/pdf';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      case 'txt':
        return 'text/plain';
      case 'doc':
      case 'docx':
        return 'application/msword';
      default:
        return 'application/octet-stream';
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // GETTERS
  // ═══════════════════════════════════════════════════════════════

  bool get isInitialized => _isInitialized;
  StudyModeType get currentMode => _currentMode;
  String? get currentSubject => _currentSubject;
  List<Content> get conversationHistory => _conversationHistory;
}

// ═══════════════════════════════════════════════════════════════
// DATA MODELS
// ═══════════════════════════════════════════════════════════════

enum StudyModeType {
  general,
  beginner,
  exam,
  interview,
  quickRevision,
}

enum AnalysisType {
  summary,
  mcq,
  notes,
  questions,
  flashcards,
}

class FlashCard {
  final String front;
  final String back;

  FlashCard({required this.front, required this.back});
}

class DocumentAnalysisResult {
  final bool success;
  final String content;
  final AnalysisType type;
  final String fileName;

  DocumentAnalysisResult({
    required this.success,
    required this.content,
    required this.type,
    required this.fileName,
  });
}

class AIServiceException implements Exception {
  final String code;
  final String message;

  AIServiceException(this.code, this.message);

  @override
  String toString() => 'AIServiceException($code): $message';
}