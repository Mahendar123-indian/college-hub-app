// lib/data/models/ai_settings_model.dart

import 'dart:convert';

/// 🎯 ADVANCED AI SETTINGS MODEL
/// Comprehensive configuration for AI behavior and responses
class AISettings {
  // ═══════════════════════════════════════════════════════════════
  // RESPONSE PREFERENCES
  // ═══════════════════════════════════════════════════════════════

  /// Response length: 'concise', 'balanced', 'detailed', 'comprehensive'
  String responseLength;

  /// Detail level: 'beginner', 'intermediate', 'advanced', 'expert'
  String detailLevel;

  /// Response style: 'casual', 'professional', 'academic', 'friendly'
  String responseStyle;

  /// Explanation depth: 0.0 (minimal) to 1.0 (maximum)
  double explanationDepth;

  // ═══════════════════════════════════════════════════════════════
  // CONTENT FEATURES
  // ═══════════════════════════════════════════════════════════════

  bool includeExamples;
  bool showPrerequisites;
  bool enableCheckpoints;
  bool includeVisualAids;
  bool showRelatedTopics;
  bool enableStepByStep;
  bool includeRealWorldApplications;
  bool showCommonMistakes;

  // ═══════════════════════════════════════════════════════════════
  // AI BEHAVIOR
  // ═══════════════════════════════════════════════════════════════

  /// Temperature: 0.0 (focused) to 1.0 (creative)
  double temperature;

  /// Max tokens per response
  int maxTokens;

  /// Enable streaming responses
  bool streamResponses;

  /// Auto-suggest follow-up questions
  bool autoSuggestQuestions;

  /// Context window size
  int contextWindowSize;

  // ═══════════════════════════════════════════════════════════════
  // LEARNING PREFERENCES
  // ═══════════════════════════════════════════════════════════════

  /// Preferred learning style: 'visual', 'auditory', 'kinesthetic', 'reading'
  String learningStyle;

  /// Enable adaptive difficulty
  bool adaptiveDifficulty;

  /// Show progress tracking
  bool showProgress;

  /// Enable spaced repetition
  bool spacedRepetition;

  /// Quiz frequency: 'never', 'occasional', 'frequent', 'always'
  String quizFrequency;

  // ═══════════════════════════════════════════════════════════════
  // NOTIFICATIONS
  // ═══════════════════════════════════════════════════════════════

  bool enableNotifications;
  bool streakAlerts;
  bool dailyReminders;
  bool achievementNotifications;
  bool studySessionReminders;

  /// Reminder time (hour of day, 0-23)
  int reminderTime;

  // ═══════════════════════════════════════════════════════════════
  // VOICE & LANGUAGE
  // ═══════════════════════════════════════════════════════════════

  bool enableVoice;
  String voiceLanguage;
  double voiceSpeed;
  String voicePitch; // 'low', 'normal', 'high'

  // ═══════════════════════════════════════════════════════════════
  // ADVANCED FEATURES
  // ═══════════════════════════════════════════════════════════════

  bool enableCodeExecution;
  bool enableLatex;
  bool enableMarkdown;
  bool enableDiagrams;
  bool enableInteractiveQuizzes;
  bool enablePracticProblems;

  /// Auto-save conversations
  bool autoSaveConversations;

  /// Export format preference: 'pdf', 'markdown', 'text'
  String exportFormat;

  // ═══════════════════════════════════════════════════════════════
  // PRIVACY & DATA
  // ═══════════════════════════════════════════════════════════════

  bool saveHistory;
  bool analyzeProgress;
  bool shareAnonymousData;

  // ═══════════════════════════════════════════════════════════════
  // UI PREFERENCES
  // ═══════════════════════════════════════════════════════════════

  bool darkMode;
  String fontSize; // 'small', 'medium', 'large', 'extra-large'
  bool compactMode;
  bool showTimestamps;
  bool showAvatars;

  // ═══════════════════════════════════════════════════════════════
  // CONSTRUCTOR
  // ═══════════════════════════════════════════════════════════════

  AISettings({
    // Response preferences
    this.responseLength = 'balanced',
    this.detailLevel = 'intermediate',
    this.responseStyle = 'friendly',
    this.explanationDepth = 0.7,

    // Content features
    this.includeExamples = true,
    this.showPrerequisites = true,
    this.enableCheckpoints = true,
    this.includeVisualAids = true,
    this.showRelatedTopics = true,
    this.enableStepByStep = true,
    this.includeRealWorldApplications = true,
    this.showCommonMistakes = true,

    // AI behavior
    this.temperature = 0.7,
    this.maxTokens = 2048,
    this.streamResponses = true,
    this.autoSuggestQuestions = true,
    this.contextWindowSize = 10,

    // Learning preferences
    this.learningStyle = 'visual',
    this.adaptiveDifficulty = true,
    this.showProgress = true,
    this.spacedRepetition = true,
    this.quizFrequency = 'occasional',

    // Notifications
    this.enableNotifications = true,
    this.streakAlerts = true,
    this.dailyReminders = true,
    this.achievementNotifications = true,
    this.studySessionReminders = true,
    this.reminderTime = 20, // 8 PM

    // Voice & Language
    this.enableVoice = false,
    this.voiceLanguage = 'en-US',
    this.voiceSpeed = 1.0,
    this.voicePitch = 'normal',

    // Advanced features
    this.enableCodeExecution = true,
    this.enableLatex = true,
    this.enableMarkdown = true,
    this.enableDiagrams = true,
    this.enableInteractiveQuizzes = true,
    this.enablePracticProblems = true,
    this.autoSaveConversations = true,
    this.exportFormat = 'pdf',

    // Privacy & Data
    this.saveHistory = true,
    this.analyzeProgress = true,
    this.shareAnonymousData = false,

    // UI Preferences
    this.darkMode = false,
    this.fontSize = 'medium',
    this.compactMode = false,
    this.showTimestamps = true,
    this.showAvatars = true,
  });

  // ═══════════════════════════════════════════════════════════════
  // DEFAULTS
  // ═══════════════════════════════════════════════════════════════

  factory AISettings.defaults() => AISettings();

  // ═══════════════════════════════════════════════════════════════
  // PRESETS
  // ═══════════════════════════════════════════════════════════════

  factory AISettings.beginner() => AISettings(
    responseLength: 'detailed',
    detailLevel: 'beginner',
    explanationDepth: 1.0,
    includeExamples: true,
    showPrerequisites: true,
    enableStepByStep: true,
    showCommonMistakes: true,
    temperature: 0.5,
  );

  factory AISettings.advanced() => AISettings(
    responseLength: 'concise',
    detailLevel: 'advanced',
    explanationDepth: 0.5,
    includeExamples: false,
    showPrerequisites: false,
    enableStepByStep: false,
    temperature: 0.8,
  );

  factory AISettings.exam() => AISettings(
    responseLength: 'balanced',
    detailLevel: 'intermediate',
    quizFrequency: 'frequent',
    enableInteractiveQuizzes: true,
    enablePracticProblems: true,
    showCommonMistakes: true,
    temperature: 0.6,
  );

  factory AISettings.quickLearn() => AISettings(
    responseLength: 'concise',
    detailLevel: 'intermediate',
    explanationDepth: 0.5,
    includeExamples: true,
    enableCheckpoints: true,
    temperature: 0.7,
  );

  // ═══════════════════════════════════════════════════════════════
  // SERIALIZATION
  // ═══════════════════════════════════════════════════════════════

  Map<String, dynamic> toJson() => {
    // Response preferences
    'responseLength': responseLength,
    'detailLevel': detailLevel,
    'responseStyle': responseStyle,
    'explanationDepth': explanationDepth,

    // Content features
    'includeExamples': includeExamples,
    'showPrerequisites': showPrerequisites,
    'enableCheckpoints': enableCheckpoints,
    'includeVisualAids': includeVisualAids,
    'showRelatedTopics': showRelatedTopics,
    'enableStepByStep': enableStepByStep,
    'includeRealWorldApplications': includeRealWorldApplications,
    'showCommonMistakes': showCommonMistakes,

    // AI behavior
    'temperature': temperature,
    'maxTokens': maxTokens,
    'streamResponses': streamResponses,
    'autoSuggestQuestions': autoSuggestQuestions,
    'contextWindowSize': contextWindowSize,

    // Learning preferences
    'learningStyle': learningStyle,
    'adaptiveDifficulty': adaptiveDifficulty,
    'showProgress': showProgress,
    'spacedRepetition': spacedRepetition,
    'quizFrequency': quizFrequency,

    // Notifications
    'enableNotifications': enableNotifications,
    'streakAlerts': streakAlerts,
    'dailyReminders': dailyReminders,
    'achievementNotifications': achievementNotifications,
    'studySessionReminders': studySessionReminders,
    'reminderTime': reminderTime,

    // Voice & Language
    'enableVoice': enableVoice,
    'voiceLanguage': voiceLanguage,
    'voiceSpeed': voiceSpeed,
    'voicePitch': voicePitch,

    // Advanced features
    'enableCodeExecution': enableCodeExecution,
    'enableLatex': enableLatex,
    'enableMarkdown': enableMarkdown,
    'enableDiagrams': enableDiagrams,
    'enableInteractiveQuizzes': enableInteractiveQuizzes,
    'enablePracticProblems': enablePracticProblems,
    'autoSaveConversations': autoSaveConversations,
    'exportFormat': exportFormat,

    // Privacy & Data
    'saveHistory': saveHistory,
    'analyzeProgress': analyzeProgress,
    'shareAnonymousData': shareAnonymousData,

    // UI Preferences
    'darkMode': darkMode,
    'fontSize': fontSize,
    'compactMode': compactMode,
    'showTimestamps': showTimestamps,
    'showAvatars': showAvatars,
  };

  factory AISettings.fromJson(Map<String, dynamic> json) {
    return AISettings(
      // Response preferences
      responseLength: json['responseLength'] ?? 'balanced',
      detailLevel: json['detailLevel'] ?? 'intermediate',
      responseStyle: json['responseStyle'] ?? 'friendly',
      explanationDepth: (json['explanationDepth'] ?? 0.7).toDouble(),

      // Content features
      includeExamples: json['includeExamples'] ?? true,
      showPrerequisites: json['showPrerequisites'] ?? true,
      enableCheckpoints: json['enableCheckpoints'] ?? true,
      includeVisualAids: json['includeVisualAids'] ?? true,
      showRelatedTopics: json['showRelatedTopics'] ?? true,
      enableStepByStep: json['enableStepByStep'] ?? true,
      includeRealWorldApplications: json['includeRealWorldApplications'] ?? true,
      showCommonMistakes: json['showCommonMistakes'] ?? true,

      // AI behavior
      temperature: (json['temperature'] ?? 0.7).toDouble(),
      maxTokens: json['maxTokens'] ?? 2048,
      streamResponses: json['streamResponses'] ?? true,
      autoSuggestQuestions: json['autoSuggestQuestions'] ?? true,
      contextWindowSize: json['contextWindowSize'] ?? 10,

      // Learning preferences
      learningStyle: json['learningStyle'] ?? 'visual',
      adaptiveDifficulty: json['adaptiveDifficulty'] ?? true,
      showProgress: json['showProgress'] ?? true,
      spacedRepetition: json['spacedRepetition'] ?? true,
      quizFrequency: json['quizFrequency'] ?? 'occasional',

      // Notifications
      enableNotifications: json['enableNotifications'] ?? true,
      streakAlerts: json['streakAlerts'] ?? true,
      dailyReminders: json['dailyReminders'] ?? true,
      achievementNotifications: json['achievementNotifications'] ?? true,
      studySessionReminders: json['studySessionReminders'] ?? true,
      reminderTime: json['reminderTime'] ?? 20,

      // Voice & Language
      enableVoice: json['enableVoice'] ?? false,
      voiceLanguage: json['voiceLanguage'] ?? 'en-US',
      voiceSpeed: (json['voiceSpeed'] ?? 1.0).toDouble(),
      voicePitch: json['voicePitch'] ?? 'normal',

      // Advanced features
      enableCodeExecution: json['enableCodeExecution'] ?? true,
      enableLatex: json['enableLatex'] ?? true,
      enableMarkdown: json['enableMarkdown'] ?? true,
      enableDiagrams: json['enableDiagrams'] ?? true,
      enableInteractiveQuizzes: json['enableInteractiveQuizzes'] ?? true,
      enablePracticProblems: json['enablePracticProblems'] ?? true,
      autoSaveConversations: json['autoSaveConversations'] ?? true,
      exportFormat: json['exportFormat'] ?? 'pdf',

      // Privacy & Data
      saveHistory: json['saveHistory'] ?? true,
      analyzeProgress: json['analyzeProgress'] ?? true,
      shareAnonymousData: json['shareAnonymousData'] ?? false,

      // UI Preferences
      darkMode: json['darkMode'] ?? false,
      fontSize: json['fontSize'] ?? 'medium',
      compactMode: json['compactMode'] ?? false,
      showTimestamps: json['showTimestamps'] ?? true,
      showAvatars: json['showAvatars'] ?? true,
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // HELPERS
  // ═══════════════════════════════════════════════════════════════

  AISettings copyWith({
    String? responseLength,
    String? detailLevel,
    String? responseStyle,
    double? explanationDepth,
    bool? includeExamples,
    bool? showPrerequisites,
    bool? enableCheckpoints,
    bool? includeVisualAids,
    bool? showRelatedTopics,
    bool? enableStepByStep,
    bool? includeRealWorldApplications,
    bool? showCommonMistakes,
    double? temperature,
    int? maxTokens,
    bool? streamResponses,
    bool? autoSuggestQuestions,
    int? contextWindowSize,
    String? learningStyle,
    bool? adaptiveDifficulty,
    bool? showProgress,
    bool? spacedRepetition,
    String? quizFrequency,
    bool? enableNotifications,
    bool? streakAlerts,
    bool? dailyReminders,
    bool? achievementNotifications,
    bool? studySessionReminders,
    int? reminderTime,
    bool? enableVoice,
    String? voiceLanguage,
    double? voiceSpeed,
    String? voicePitch,
    bool? enableCodeExecution,
    bool? enableLatex,
    bool? enableMarkdown,
    bool? enableDiagrams,
    bool? enableInteractiveQuizzes,
    bool? enablePracticProblems,
    bool? autoSaveConversations,
    String? exportFormat,
    bool? saveHistory,
    bool? analyzeProgress,
    bool? shareAnonymousData,
    bool? darkMode,
    String? fontSize,
    bool? compactMode,
    bool? showTimestamps,
    bool? showAvatars,
  }) {
    return AISettings(
      responseLength: responseLength ?? this.responseLength,
      detailLevel: detailLevel ?? this.detailLevel,
      responseStyle: responseStyle ?? this.responseStyle,
      explanationDepth: explanationDepth ?? this.explanationDepth,
      includeExamples: includeExamples ?? this.includeExamples,
      showPrerequisites: showPrerequisites ?? this.showPrerequisites,
      enableCheckpoints: enableCheckpoints ?? this.enableCheckpoints,
      includeVisualAids: includeVisualAids ?? this.includeVisualAids,
      showRelatedTopics: showRelatedTopics ?? this.showRelatedTopics,
      enableStepByStep: enableStepByStep ?? this.enableStepByStep,
      includeRealWorldApplications: includeRealWorldApplications ?? this.includeRealWorldApplications,
      showCommonMistakes: showCommonMistakes ?? this.showCommonMistakes,
      temperature: temperature ?? this.temperature,
      maxTokens: maxTokens ?? this.maxTokens,
      streamResponses: streamResponses ?? this.streamResponses,
      autoSuggestQuestions: autoSuggestQuestions ?? this.autoSuggestQuestions,
      contextWindowSize: contextWindowSize ?? this.contextWindowSize,
      learningStyle: learningStyle ?? this.learningStyle,
      adaptiveDifficulty: adaptiveDifficulty ?? this.adaptiveDifficulty,
      showProgress: showProgress ?? this.showProgress,
      spacedRepetition: spacedRepetition ?? this.spacedRepetition,
      quizFrequency: quizFrequency ?? this.quizFrequency,
      enableNotifications: enableNotifications ?? this.enableNotifications,
      streakAlerts: streakAlerts ?? this.streakAlerts,
      dailyReminders: dailyReminders ?? this.dailyReminders,
      achievementNotifications: achievementNotifications ?? this.achievementNotifications,
      studySessionReminders: studySessionReminders ?? this.studySessionReminders,
      reminderTime: reminderTime ?? this.reminderTime,
      enableVoice: enableVoice ?? this.enableVoice,
      voiceLanguage: voiceLanguage ?? this.voiceLanguage,
      voiceSpeed: voiceSpeed ?? this.voiceSpeed,
      voicePitch: voicePitch ?? this.voicePitch,
      enableCodeExecution: enableCodeExecution ?? this.enableCodeExecution,
      enableLatex: enableLatex ?? this.enableLatex,
      enableMarkdown: enableMarkdown ?? this.enableMarkdown,
      enableDiagrams: enableDiagrams ?? this.enableDiagrams,
      enableInteractiveQuizzes: enableInteractiveQuizzes ?? this.enableInteractiveQuizzes,
      enablePracticProblems: enablePracticProblems ?? this.enablePracticProblems,
      autoSaveConversations: autoSaveConversations ?? this.autoSaveConversations,
      exportFormat: exportFormat ?? this.exportFormat,
      saveHistory: saveHistory ?? this.saveHistory,
      analyzeProgress: analyzeProgress ?? this.analyzeProgress,
      shareAnonymousData: shareAnonymousData ?? this.shareAnonymousData,
      darkMode: darkMode ?? this.darkMode,
      fontSize: fontSize ?? this.fontSize,
      compactMode: compactMode ?? this.compactMode,
      showTimestamps: showTimestamps ?? this.showTimestamps,
      showAvatars: showAvatars ?? this.showAvatars,
    );
  }
}