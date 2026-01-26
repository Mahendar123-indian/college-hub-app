// lib/providers/ai_assistant_provider.dart

import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../data/services/unified_ai_service.dart';
import '../data/models/ai_settings_model.dart';

/// 🎯 UNIFIED AI ASSISTANT PROVIDER - COMPLETE & UPDATED
/// All features with new AISettings model integration
/// Developer: Mahendar Reddy | CEO: Mahendar Reddy
class AIAssistantProvider extends ChangeNotifier {
  final UnifiedAIService _aiService = UnifiedAIService();

  // ═══════════════════════════════════════════════════════════════
  // STATE
  // ═══════════════════════════════════════════════════════════════

  List<ChatMessage> _messages = [];
  List<ChatSession> _sessions = [];
  ChatSession? _currentSession;
  List<File> _attachedFiles = [];

  StudyModeType _currentMode = StudyModeType.general;
  String? _currentSubject;

  bool _isLoading = false;
  bool _isInitializing = false;
  String? _errorMessage;

  bool _isAnalyzingDocument = false;
  DocumentAnalysisResult? _lastAnalysis;

  // Learning progress tracking
  LearningProgress _learningProgress = LearningProgress();

  // ✅ UPDATED: Use new AISettings model
  AISettings _settings = AISettings.defaults();

  // ═══════════════════════════════════════════════════════════════
  // GETTERS
  // ═══════════════════════════════════════════════════════════════

  List<ChatMessage> get messages => _messages;
  List<ChatSession> get sessions => _sessions;
  ChatSession? get currentSession => _currentSession;
  List<File> get attachedFiles => _attachedFiles;

  StudyModeType get currentMode => _currentMode;
  String? get currentSubject => _currentSubject;

  bool get isLoading => _isLoading;
  bool get isInitializing => _isInitializing;
  String? get errorMessage => _errorMessage;

  bool get isAnalyzingDocument => _isAnalyzingDocument;
  DocumentAnalysisResult? get lastAnalysis => _lastAnalysis;

  bool get hasAttachedFiles => _attachedFiles.isNotEmpty;
  int get attachedFilesCount => _attachedFiles.length;

  LearningProgress get learningProgress => _learningProgress;
  AISettings get settings => _settings;

  // SMART SUGGESTIONS GETTER
  List<String> get smartSuggestions {
    if (_messages.isEmpty || _isLoading) return [];

    final lastMessage = _messages.last;
    if (lastMessage.isUser) return [];

    // Only show suggestions if enabled in settings
    if (!_settings.autoSuggestQuestions) return [];

    final suggestions = <String>[];

    if (_currentSubject != null) {
      suggestions.add('Explain $_currentSubject basics');
      suggestions.add('Important questions in $_currentSubject');
      suggestions.add('$_currentSubject formulas summary');
    }

    if (_currentMode == StudyModeType.general) {
      suggestions.add('Can you explain the first step?');
      suggestions.add('Give me an example');
      suggestions.add('Is there an alternative method?');
    } else if (_currentMode == StudyModeType.exam) {
      suggestions.add('Generate practice questions');
      suggestions.add('Important topics to study');
      suggestions.add('Exam preparation tips');
    } else if (_currentMode == StudyModeType.quickRevision) {
      suggestions.add('Key points summary');
      suggestions.add('Create flashcards');
      suggestions.add('Common mistakes');
    }

    return suggestions.take(3).toList();
  }

  List<ConceptMastery> getMasteredConcepts() {
    return _learningProgress.concepts
        .where((c) => c.masteryLevel >= 0.8)
        .toList();
  }

  List<ConceptMastery> getStrugglingConcepts() {
    return _learningProgress.concepts
        .where((c) => c.masteryLevel < 0.5 && c.attempts > 2)
        .toList();
  }

  // ═══════════════════════════════════════════════════════════════
  // INITIALIZATION
  // ═══════════════════════════════════════════════════════════════

  Future<void> initialize() async {
    if (_isInitializing || _aiService.isInitialized) return;

    _isInitializing = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _aiService.initialize();
      await _loadSessions();
      await _loadLearningProgress();
      await _loadSettings();

      if (_currentSession == null) {
        _createNewSession();
      } else {
        _messages = List.from(_currentSession!.messages);
      }

      if (_messages.isEmpty) {
        _addWelcomeMessage();
      }

      _isInitializing = false;
      _errorMessage = null;
      notifyListeners();

      debugPrint('✅ AI Assistant Provider initialized');
    } catch (e) {
      _errorMessage = _formatError(e);
      _isInitializing = false;
      notifyListeners();
      debugPrint('❌ Provider initialization error: $e');
    }
  }

  String _formatError(dynamic error) {
    final errorStr = error.toString();

    if (errorStr.contains('API_KEY') || errorStr.contains('GEMINI_API_KEY')) {
      return '🔑 API Key Error\n\n'
          'Please add your Gemini API key to the .env file:\n\n'
          '1. Create .env in project root\n'
          '2. Add: GEMINI_API_KEY=your_key\n'
          '3. Get key from: aistudio.google.com';
    } else if (errorStr.contains('network') || errorStr.contains('Socket')) {
      return '🌐 Network Error\n\n'
          'Please check your internet connection and try again.';
    } else if (errorStr.contains('QUOTA') || errorStr.contains('quota')) {
      return '⏰ API Quota Exceeded\n\n'
          'Please wait or upgrade your API plan.';
    } else {
      return '⚠️ Error\n\n$errorStr';
    }
  }

  void _addWelcomeMessage() {
    _messages.add(ChatMessage.ai(
      '👋 **Welcome to AI Study Assistant!**\n\n'
          'I\'m powered by Google Gemini and here to help you with:\n\n'
          '📚 **Study & Learning** - Concept explanations with examples\n'
          '📝 **Exam Prep** - Important questions & practice materials\n'
          '🧮 **Problem Solving** - Step-by-step numerical solutions\n'
          '📄 **Document Analysis** - Summaries, notes, MCQs from PDFs\n'
          '🎯 **Study Tools** - Flashcards, mind maps, revision notes\n\n'
          '**Quick Tips:**\n'
          '• Tap 📎 to upload documents (PDF, images, docs)\n'
          '• Use 🎓 to change study mode\n'
          '• Select a subject for context-aware responses\n\n'
          'What would you like to learn today?',
    ));
    _saveCurrentSession();
  }

  // ═══════════════════════════════════════════════════════════════
  // UTILITY METHODS
  // ═══════════════════════════════════════════════════════════════

  void clearAttachedFiles() {
    _attachedFiles.clear();
    notifyListeners();
    debugPrint('✅ Cleared all attached files');
  }

  void removeAttachedFile(File file) {
    _attachedFiles.remove(file);
    notifyListeners();
    debugPrint('✅ Removed attached file');
  }

  void stopGeneration() {
    if (_isLoading) {
      _isLoading = false;
      notifyListeners();
      debugPrint('✅ Stopped message generation');
    }
  }

  void clearMessages() {
    _messages.clear();
    _addWelcomeMessage();
    notifyListeners();
    debugPrint('✅ Cleared all messages');
  }

  // ═══════════════════════════════════════════════════════════════
  // MESSAGE HANDLING
  // ═══════════════════════════════════════════════════════════════

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty && _attachedFiles.isEmpty) return;
    if (!_aiService.isInitialized) {
      _showError('AI service not initialized. Please retry.');
      return;
    }

    // Update learning progress (only if enabled in settings)
    if (_settings.analyzeProgress) {
      _learningProgress.questionsAsked++;
      _learningProgress.lastActiveDate = DateTime.now();
      _updateStreak();
    }

    final userMessage = ChatMessage.user(
      text.isEmpty ? '📎 Attached ${_attachedFiles.length} file(s)' : text,
      files: List.from(_attachedFiles),
    );

    _messages.add(userMessage);

    final files = List<File>.from(_attachedFiles);
    _attachedFiles.clear();

    _isLoading = true;
    notifyListeners();

    try {
      String response;

      if (files.isNotEmpty) {
        response = await _processFilesAndMessage(files, text);
      } else {
        response = await _aiService.sendMessage(text);
      }

      _messages.add(ChatMessage.ai(response));

      // Only save if enabled
      if (_settings.autoSaveConversations) {
        await _saveCurrentSession();
      }

      if (_settings.analyzeProgress) {
        await _saveLearningProgress();
      }

    } catch (e) {
      _messages.add(ChatMessage.ai(
        '❌ **Error**\n\n'
            'Sorry, I encountered an error:\n'
            '${e.toString()}\n\n'
            'Please try again or rephrase your question.',
        isError: true,
      ));
      debugPrint('❌ Send message error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _updateStreak() {
    final now = DateTime.now();
    final lastDate = _learningProgress.lastActiveDate;

    if (lastDate != null) {
      final difference = now.difference(lastDate).inDays;

      if (difference == 0) {
        return;
      } else if (difference == 1) {
        _learningProgress.currentStreak++;
        if (_learningProgress.currentStreak > _learningProgress.longestStreak) {
          _learningProgress.longestStreak = _learningProgress.currentStreak;
        }
      } else {
        _learningProgress.currentStreak = 1;
      }
    } else {
      _learningProgress.currentStreak = 1;
    }
  }

  Future<String> _processFilesAndMessage(List<File> files, String userPrompt) async {
    final buffer = StringBuffer();

    for (final file in files) {
      try {
        final fileName = file.path.split('/').last;
        final extension = fileName.split('.').last.toLowerCase();

        buffer.writeln('\n📄 **Processing: $fileName**\n');

        AnalysisType analysisType = AnalysisType.summary;

        if (userPrompt.toLowerCase().contains('mcq') ||
            userPrompt.toLowerCase().contains('question')) {
          analysisType = AnalysisType.mcq;
        } else if (userPrompt.toLowerCase().contains('note')) {
          analysisType = AnalysisType.notes;
        } else if (userPrompt.toLowerCase().contains('flashcard')) {
          analysisType = AnalysisType.flashcards;
        } else if (userPrompt.toLowerCase().contains('important question')) {
          analysisType = AnalysisType.questions;
        }

        if (['pdf', 'jpg', 'jpeg', 'png'].contains(extension)) {
          final result = await _aiService.analyzeDocument(file, analysisType);

          if (result.success) {
            buffer.writeln(result.content);
          } else {
            buffer.writeln('⚠️ Error analyzing file: ${result.content}');
          }
        } else {
          buffer.writeln('File uploaded successfully!');
          buffer.writeln('(Note: Currently supports PDF and image files)');
        }

        buffer.writeln();
      } catch (e) {
        buffer.writeln('❌ Error processing file: $e\n');
        debugPrint('❌ File error: $e');
      }
    }

    if (userPrompt.isNotEmpty &&
        !userPrompt.startsWith('📎') &&
        files.length <= 3) {
      buffer.writeln('\n---\n');
      buffer.writeln('**Your question:**');
      buffer.writeln(userPrompt);
      buffer.writeln();

      final response = await _aiService.sendMessage(userPrompt, files: files);
      buffer.writeln(response);
    }

    return buffer.toString();
  }

  // ═══════════════════════════════════════════════════════════════
  // FILE MANAGEMENT
  // ═══════════════════════════════════════════════════════════════

  Future<void> pickFiles() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'doc', 'docx', 'txt'],
      );

      if (result != null) {
        for (var file in result.files) {
          if (file.path != null) {
            _attachedFiles.add(File(file.path!));
          }
        }
        notifyListeners();
        debugPrint('✅ ${_attachedFiles.length} file(s) attached');
      }
    } catch (e) {
      debugPrint('❌ File picker error: $e');
      _showError('Error picking files: $e');
    }
  }

  Future<void> pickImages() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.image,
      );

      if (result != null) {
        for (var file in result.files) {
          if (file.path != null) {
            _attachedFiles.add(File(file.path!));
          }
        }
        notifyListeners();
        debugPrint('✅ ${_attachedFiles.length} image(s) attached');
      }
    } catch (e) {
      debugPrint('❌ Image picker error: $e');
      _showError('Error picking images: $e');
    }
  }

  void removeFile(int index) {
    if (index >= 0 && index < _attachedFiles.length) {
      _attachedFiles.removeAt(index);
      notifyListeners();
    }
  }

  void clearFiles() {
    _attachedFiles.clear();
    notifyListeners();
  }

  // ═══════════════════════════════════════════════════════════════
  // STUDY MODE & CONTEXT
  // ═══════════════════════════════════════════════════════════════

  void setStudyMode(StudyModeType mode) {
    _currentMode = mode;
    _aiService.setStudyMode(mode);
    notifyListeners();
    if (_settings.autoSaveConversations) {
      _saveCurrentSession();
    }
    debugPrint('✅ Mode: ${mode.name}');
  }

  void setSubject(String subject) {
    _currentSubject = subject;
    _aiService.setSubject(subject);
    notifyListeners();
    if (_settings.autoSaveConversations) {
      _saveCurrentSession();
    }
    debugPrint('✅ Subject: $subject');
  }

  void clearSubject() {
    _currentSubject = null;
    _aiService.clearSubject();
    notifyListeners();
  }

  // ═══════════════════════════════════════════════════════════════
  // SESSION MANAGEMENT
  // ═══════════════════════════════════════════════════════════════

  void _createNewSession() {
    _currentSession = ChatSession(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: 'New Chat',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      messages: [],
      studyMode: _currentMode,
      subject: _currentSubject,
    );

    _sessions.insert(0, _currentSession!);
    _messages.clear();
    _addWelcomeMessage();
    _saveSessions();
    notifyListeners();
  }

  void createNewSession() {
    _createNewSession();
    _aiService.resetChat();
    debugPrint('✅ New session created');
  }

  void switchSession(ChatSession session) {
    _currentSession = session;
    _messages = List.from(session.messages);
    _currentMode = session.studyMode;
    _currentSubject = session.subject;
    _attachedFiles.clear();
    _errorMessage = null;

    _aiService.setStudyMode(_currentMode);
    if (_currentSubject != null) {
      _aiService.setSubject(_currentSubject!);
    }

    _saveSessions();
    notifyListeners();
    debugPrint('✅ Switched to session: ${session.title}');
  }

  void deleteSession(ChatSession session) {
    _sessions.removeWhere((s) => s.id == session.id);

    if (_currentSession?.id == session.id) {
      if (_sessions.isEmpty) {
        _createNewSession();
      } else {
        switchSession(_sessions.first);
      }
    }

    _saveSessions();
    notifyListeners();
    debugPrint('✅ Session deleted');
  }

  void clearCurrentChat() {
    _aiService.resetChat();
    _messages.clear();
    _attachedFiles.clear();
    _errorMessage = null;
    _addWelcomeMessage();
    if (_settings.autoSaveConversations) {
      _saveCurrentSession();
    }
    notifyListeners();
    debugPrint('✅ Chat cleared');
  }

  // ═══════════════════════════════════════════════════════════════
  // EXPORT METHODS
  // ═══════════════════════════════════════════════════════════════

  Future<String> exportConversationAsPDF() async {
    try {
      final pdf = pw.Document();

      pdf.addPage(
        pw.MultiPage(
          build: (context) => [
            pw.Header(
              level: 0,
              child: pw.Text(
                _currentSession?.title ?? 'Chat Export',
                style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
              ),
            ),
            pw.SizedBox(height: 20),
            ..._messages.map((msg) {
              return pw.Container(
                margin: const pw.EdgeInsets.only(bottom: 12),
                child: pw.Column(
                  crossAxisAlignment: msg.isUser
                      ? pw.CrossAxisAlignment.end
                      : pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      msg.isUser ? 'You' : 'AI Assistant',
                      style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                        color: msg.isUser ? PdfColors.blue : PdfColors.green,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Container(
                      padding: const pw.EdgeInsets.all(10),
                      decoration: pw.BoxDecoration(
                        color: msg.isUser
                            ? PdfColors.blue50
                            : PdfColors.grey200,
                        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                      ),
                      child: pw.Text(
                        msg.text,
                        style: const pw.TextStyle(fontSize: 11),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      );

      final output = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final file = File('${output.path}/chat_export_$timestamp.pdf');
      await file.writeAsBytes(await pdf.save());

      debugPrint('✅ PDF exported: ${file.path}');
      return file.path;
    } catch (e) {
      debugPrint('❌ PDF export error: $e');
      throw Exception('Failed to export PDF: $e');
    }
  }

  Future<String> exportConversationAsText() async {
    try {
      final buffer = StringBuffer();
      buffer.writeln('========================================');
      buffer.writeln('CHAT EXPORT');
      buffer.writeln('Title: ${_currentSession?.title ?? "Untitled"}');
      buffer.writeln('Date: ${DateTime.now().toString()}');
      buffer.writeln('========================================\n');

      for (final msg in _messages) {
        buffer.writeln('${msg.isUser ? "[YOU]" : "[AI]"} ${msg.timestamp}');
        buffer.writeln(msg.text);
        buffer.writeln('\n${"=" * 40}\n');
      }

      final output = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final file = File('${output.path}/chat_export_$timestamp.txt');
      await file.writeAsString(buffer.toString());

      debugPrint('✅ Text exported: ${file.path}');
      return file.path;
    } catch (e) {
      debugPrint('❌ Text export error: $e');
      throw Exception('Failed to export text: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // ✅ SETTINGS MANAGEMENT (UPDATED)
  // ═══════════════════════════════════════════════════════════════

  void updateSettings(AISettings newSettings) {
    _settings = newSettings;
    _saveSettings();
    notifyListeners();
    debugPrint('✅ Settings updated');
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settingsJson = prefs.getString('ai_settings');
      if (settingsJson != null) {
        _settings = AISettings.fromJson(json.decode(settingsJson));
        debugPrint('✅ Settings loaded');
      } else {
        debugPrint('ℹ️ Using default settings');
      }
    } catch (e) {
      debugPrint('⚠️ Load settings error: $e');
    }
  }

  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('ai_settings', json.encode(_settings.toJson()));
      debugPrint('✅ Settings saved');
    } catch (e) {
      debugPrint('⚠️ Save settings error: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // ADVANCED FEATURES
  // ═══════════════════════════════════════════════════════════════

  Future<void> explainConcept(String concept) async {
    _isLoading = true;
    notifyListeners();

    try {
      _messages.add(ChatMessage.user('Explain: $concept'));

      final response = await _aiService.explainConcept(
        concept,
        subject: _currentSubject,
      );

      _messages.add(ChatMessage.ai(response));
      if (_settings.autoSaveConversations) {
        await _saveCurrentSession();
      }
    } catch (e) {
      _showError('Error explaining concept: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> generateImportantQuestions(String topic) async {
    if (_currentSubject == null) {
      _showError('Please select a subject first');
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      _messages.add(ChatMessage.user('Important questions for: $topic'));

      final response = await _aiService.generateImportantQuestions(
        topic,
        _currentSubject!,
      );

      _messages.add(ChatMessage.ai(response));
      if (_settings.autoSaveConversations) {
        await _saveCurrentSession();
      }
    } catch (e) {
      _showError('Error generating questions: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> solveNumerical(String problem) async {
    if (_currentSubject == null) {
      _showError('Please select a subject first');
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      _messages.add(ChatMessage.user('Solve: $problem'));

      final response = await _aiService.solveNumerical(
        problem,
        _currentSubject!,
      );

      _messages.add(ChatMessage.ai(response));
      if (_settings.autoSaveConversations) {
        await _saveCurrentSession();
      }
    } catch (e) {
      _showError('Error solving problem: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> generateFlashcards(String topic) async {
    if (_currentSubject == null) {
      _showError('Please select a subject first');
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      _messages.add(ChatMessage.user('Generate flashcards for: $topic'));

      final flashcards = await _aiService.generateFlashcards(
        topic,
        _currentSubject!,
      );

      final buffer = StringBuffer();
      buffer.writeln('**📚 Generated ${flashcards.length} Flashcards**\n');

      for (var i = 0; i < flashcards.length; i++) {
        buffer.writeln('**Card ${i + 1}:**');
        buffer.writeln('Front: ${flashcards[i].front}');
        buffer.writeln('Back: ${flashcards[i].back}');
        buffer.writeln();
      }

      _messages.add(ChatMessage.ai(buffer.toString()));
      if (_settings.autoSaveConversations) {
        await _saveCurrentSession();
      }
    } catch (e) {
      _showError('Error generating flashcards: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> analyzeDocument(File file, AnalysisType type) async {
    _isAnalyzingDocument = true;
    notifyListeners();

    try {
      final result = await _aiService.analyzeDocument(file, type);

      _lastAnalysis = result;

      if (result.success) {
        _messages.add(ChatMessage.user('Analyze: ${result.fileName}'));
        _messages.add(ChatMessage.ai(result.content));
        if (_settings.autoSaveConversations) {
          await _saveCurrentSession();
        }
      } else {
        _showError(result.content);
      }
    } catch (e) {
      _showError('Error analyzing document: $e');
    } finally {
      _isAnalyzingDocument = false;
      notifyListeners();
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // PERSISTENCE
  // ═══════════════════════════════════════════════════════════════

  Future<void> _loadSessions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sessionsJson = prefs.getStringList('ai_assistant_sessions') ?? [];

      _sessions = sessionsJson
          .map((s) => ChatSession.fromJson(json.decode(s)))
          .toList()
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

      final lastSessionId = prefs.getString('last_ai_session_id');
      if (lastSessionId != null && _sessions.isNotEmpty) {
        _currentSession = _sessions.firstWhere(
              (s) => s.id == lastSessionId,
          orElse: () => _sessions.first,
        );
      }

      debugPrint('✅ Loaded ${_sessions.length} sessions');
    } catch (e) {
      debugPrint('⚠️ Load sessions error: $e');
    }
  }

  Future<void> _saveSessions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sessionsJson = _sessions.map((s) => json.encode(s.toJson())).toList();
      await prefs.setStringList('ai_assistant_sessions', sessionsJson);

      if (_currentSession != null) {
        await prefs.setString('last_ai_session_id', _currentSession!.id);
      }
    } catch (e) {
      debugPrint('⚠️ Save sessions error: $e');
    }
  }

  Future<void> _saveCurrentSession() async {
    if (_currentSession == null) return;

    String title = 'New Chat';
    final firstUserMessage = _messages.firstWhere(
          (m) => m.isUser && m.text.isNotEmpty && !m.text.startsWith('📎'),
      orElse: () => ChatMessage.user(''),
    );

    if (firstUserMessage.text.isNotEmpty) {
      title = firstUserMessage.text.length > 40
          ? '${firstUserMessage.text.substring(0, 40)}...'
          : firstUserMessage.text;
    }

    final updatedSession = _currentSession!.copyWith(
      title: title,
      updatedAt: DateTime.now(),
      messages: _messages,
      studyMode: _currentMode,
      subject: _currentSubject,
    );

    final index = _sessions.indexWhere((s) => s.id == _currentSession!.id);
    if (index != -1) {
      _sessions[index] = updatedSession;
      _sessions.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    }

    _currentSession = updatedSession;
    await _saveSessions();
  }

  Future<void> _loadLearningProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final progressJson = prefs.getString('learning_progress');
      if (progressJson != null) {
        _learningProgress = LearningProgress.fromJson(json.decode(progressJson));
        debugPrint('✅ Learning progress loaded');
      }
    } catch (e) {
      debugPrint('⚠️ Load progress error: $e');
    }
  }

  Future<void> _saveLearningProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('learning_progress', json.encode(_learningProgress.toJson()));
    } catch (e) {
      debugPrint('⚠️ Save progress error: $e');
    }
  }

  void _showError(String message) {
    _messages.add(ChatMessage.ai(
      '❌ **Error**\n\n$message',
      isError: true,
    ));
    notifyListeners();
  }

  void retryInitialization() {
    initialize();
  }

  @override
  void dispose() {
    _messages.clear();
    _sessions.clear();
    _attachedFiles.clear();
    super.dispose();
  }
}

// ═══════════════════════════════════════════════════════════════
// DATA MODELS
// ═══════════════════════════════════════════════════════════════

class ChatMessage {
  final String id;
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final List<File> files;
  final bool isError;

  ChatMessage({
    required this.id,
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.files = const [],
    this.isError = false,
  });

  factory ChatMessage.user(String text, {List<File>? files}) {
    return ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: text,
      isUser: true,
      timestamp: DateTime.now(),
      files: files ?? [],
    );
  }

  factory ChatMessage.ai(String text, {bool isError = false}) {
    return ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: text,
      isUser: false,
      timestamp: DateTime.now(),
      isError: isError,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'text': text,
    'isUser': isUser,
    'timestamp': timestamp.toIso8601String(),
    'isError': isError,
  };

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'],
      text: json['text'],
      isUser: json['isUser'],
      timestamp: DateTime.parse(json['timestamp']),
      isError: json['isError'] ?? false,
    );
  }
}

class ChatSession {
  final String id;
  final String title;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<ChatMessage> messages;
  final StudyModeType studyMode;
  final String? subject;

  ChatSession({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    required this.messages,
    required this.studyMode,
    this.subject,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'messages': messages.map((m) => m.toJson()).toList(),
    'studyMode': studyMode.name,
    'subject': subject,
  };

  factory ChatSession.fromJson(Map<String, dynamic> json) {
    return ChatSession(
      id: json['id'],
      title: json['title'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      messages: (json['messages'] as List)
          .map((m) => ChatMessage.fromJson(m))
          .toList(),
      studyMode: StudyModeType.values.firstWhere(
            (e) => e.name == json['studyMode'],
        orElse: () => StudyModeType.general,
      ),
      subject: json['subject'],
    );
  }

  ChatSession copyWith({
    String? title,
    DateTime? updatedAt,
    List<ChatMessage>? messages,
    StudyModeType? studyMode,
    String? subject,
  }) {
    return ChatSession(
      id: id,
      title: title ?? this.title,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      messages: messages ?? this.messages,
      studyMode: studyMode ?? this.studyMode,
      subject: subject ?? this.subject,
    );
  }
}

class LearningProgress {
  int questionsAsked;
  int currentStreak;
  int longestStreak;
  DateTime? lastActiveDate;
  List<ConceptMastery> concepts;

  LearningProgress({
    this.questionsAsked = 0,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.lastActiveDate,
    this.concepts = const [],
  });

  Map<String, dynamic> toJson() => {
    'questionsAsked': questionsAsked,
    'currentStreak': currentStreak,
    'longestStreak': longestStreak,
    'lastActiveDate': lastActiveDate?.toIso8601String(),
    'concepts': concepts.map((c) => c.toJson()).toList(),
  };

  factory LearningProgress.fromJson(Map<String, dynamic> json) {
    return LearningProgress(
      questionsAsked: json['questionsAsked'] ?? 0,
      currentStreak: json['currentStreak'] ?? 0,
      longestStreak: json['longestStreak'] ?? 0,
      lastActiveDate: json['lastActiveDate'] != null
          ? DateTime.parse(json['lastActiveDate'])
          : null,
      concepts: (json['concepts'] as List?)
          ?.map((c) => ConceptMastery.fromJson(c))
          .toList() ?? [],
    );
  }
}

class ConceptMastery {
  final String name;
  final double masteryLevel;
  final int attempts;

  ConceptMastery({
    required this.name,
    required this.masteryLevel,
    required this.attempts,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'masteryLevel': masteryLevel,
    'attempts': attempts,
  };

  factory ConceptMastery.fromJson(Map<String, dynamic> json) {
    return ConceptMastery(
      name: json['name'],
      masteryLevel: json['masteryLevel'].toDouble(),
      attempts: json['attempts'],
    );
  }
}