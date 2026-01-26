// lib/presentation/screens/ai/ai_settings_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../providers/ai_assistant_provider.dart';
import '../../../data/models/ai_settings_model.dart';

/// 🎯 ADVANCED AI SETTINGS SCREEN
/// Comprehensive configuration interface for AI behavior
/// Developer: Mahendar Reddy | CEO: Mahendar Reddy
class AISettingsScreen extends StatefulWidget {
  const AISettingsScreen({Key? key}) : super(key: key);

  @override
  State<AISettingsScreen> createState() => _AISettingsScreenState();
}

class _AISettingsScreenState extends State<AISettingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late AISettings _tempSettings;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    _tempSettings = context.read<AIAssistantProvider>().settings.copyWith();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _updateTempSettings(AISettings newSettings) {
    setState(() {
      _tempSettings = newSettings;
      _hasChanges = true;
    });
  }

  void _saveSettings() {
    context.read<AIAssistantProvider>().updateSettings(_tempSettings);
    setState(() => _hasChanges = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 12),
            Text('Settings saved successfully!'),
          ],
        ),
        backgroundColor: Colors.green[700],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _resetSettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.restart_alt_rounded, color: Colors.orange),
            SizedBox(width: 12),
            Text('Reset Settings'),
          ],
        ),
        content: const Text(
          'Reset all AI settings to default values? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _tempSettings = AISettings.defaults();
                _hasChanges = true;
              });
              Navigator.pop(context);
              _saveSettings();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  void _loadPreset(String preset) {
    setState(() {
      switch (preset) {
        case 'beginner':
          _tempSettings = AISettings.beginner();
          break;
        case 'advanced':
          _tempSettings = AISettings.advanced();
          break;
        case 'exam':
          _tempSettings = AISettings.exam();
          break;
        case 'quick':
          _tempSettings = AISettings.quickLearn();
          break;
      }
      _hasChanges = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Loaded $preset preset'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_hasChanges) {
          final result = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Text('Unsaved Changes'),
              content: const Text('You have unsaved changes. Save before leaving?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Discard'),
                ),
                ElevatedButton(
                  onPressed: () {
                    _saveSettings();
                    Navigator.pop(context, true);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Save'),
                ),
              ],
            ),
          );
          return result ?? false;
        }
        return true;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        appBar: _buildAppBar(),
        body: Column(
          children: [
            _buildTabBar(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildResponseTab(),
                  _buildLearningTab(),
                  _buildAIBehaviorTab(),
                  _buildNotificationsTab(),
                  _buildAdvancedTab(),
                  _buildUITab(),
                ],
              ),
            ),
          ],
        ),
        bottomNavigationBar: _buildBottomBar(),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
          ),
        ),
      ),
      title: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'AI Settings',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            'Customize your learning experience',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
        ],
      ),
      actions: [
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert_rounded, color: Colors.white),
          onSelected: (value) {
            switch (value) {
              case 'presets':
                _showPresetsDialog();
                break;
              case 'reset':
                _resetSettings();
                break;
              case 'export':
                _exportSettings();
                break;
              case 'import':
                _importSettings();
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'presets',
              child: Row(
                children: [
                  Icon(Icons.tune_rounded, size: 20, color: Color(0xFF6366F1)),
                  SizedBox(width: 12),
                  Text('Load Preset'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'export',
              child: Row(
                children: [
                  Icon(Icons.upload_rounded, size: 20, color: Color(0xFF6366F1)),
                  SizedBox(width: 12),
                  Text('Export Settings'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'import',
              child: Row(
                children: [
                  Icon(Icons.download_rounded, size: 20, color: Color(0xFF6366F1)),
                  SizedBox(width: 12),
                  Text('Import Settings'),
                ],
              ),
            ),
            const PopupMenuDivider(),
            const PopupMenuItem(
              value: 'reset',
              child: Row(
                children: [
                  Icon(Icons.restart_alt_rounded, size: 20, color: Colors.orange),
                  SizedBox(width: 12),
                  Text('Reset to Default'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        labelColor: const Color(0xFF6366F1),
        unselectedLabelColor: Colors.grey,
        indicatorColor: const Color(0xFF6366F1),
        indicatorWeight: 3,
        tabs: const [
          Tab(icon: Icon(Icons.chat_bubble_outline), text: 'Response'),
          Tab(icon: Icon(Icons.school_outlined), text: 'Learning'),
          Tab(icon: Icon(Icons.psychology_outlined), text: 'AI Behavior'),
          Tab(icon: Icon(Icons.notifications_outlined), text: 'Notifications'),
          Tab(icon: Icon(Icons.settings_outlined), text: 'Advanced'),
          Tab(icon: Icon(Icons.palette_outlined), text: 'UI'),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    if (!_hasChanges) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  setState(() {
                    _tempSettings = context.read<AIAssistantProvider>().settings.copyWith();
                    _hasChanges = false;
                  });
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: const BorderSide(color: Color(0xFF6366F1)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Discard'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: _saveSettings,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: const Color(0xFF6366F1),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle, size: 20),
                    SizedBox(width: 8),
                    Text('Save Changes'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // RESPONSE TAB
  // ═══════════════════════════════════════════════════════════════

  Widget _buildResponseTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionCard(
          'Response Style',
          Icons.style_rounded,
          Colors.blue,
          [
            _buildDropdownTile(
              'Response Length',
              _tempSettings.responseLength,
              ['concise', 'balanced', 'detailed', 'comprehensive'],
                  (value) => _updateTempSettings(_tempSettings.copyWith(responseLength: value)),
            ),
            _buildDropdownTile(
              'Detail Level',
              _tempSettings.detailLevel,
              ['beginner', 'intermediate', 'advanced', 'expert'],
                  (value) => _updateTempSettings(_tempSettings.copyWith(detailLevel: value)),
            ),
            _buildDropdownTile(
              'Response Style',
              _tempSettings.responseStyle,
              ['casual', 'professional', 'academic', 'friendly'],
                  (value) => _updateTempSettings(_tempSettings.copyWith(responseStyle: value)),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildSectionCard(
          'Content Features',
          Icons.featured_play_list_rounded,
          Colors.green,
          [
            _buildSwitchTile(
              'Include Examples',
              'Show practical examples in explanations',
              _tempSettings.includeExamples,
                  (value) => _updateTempSettings(_tempSettings.copyWith(includeExamples: value)),
            ),
            _buildSwitchTile(
              'Show Prerequisites',
              'Display required knowledge before topics',
              _tempSettings.showPrerequisites,
                  (value) => _updateTempSettings(_tempSettings.copyWith(showPrerequisites: value)),
            ),
            _buildSwitchTile(
              'Enable Checkpoints',
              'Add understanding checkpoints',
              _tempSettings.enableCheckpoints,
                  (value) => _updateTempSettings(_tempSettings.copyWith(enableCheckpoints: value)),
            ),
            _buildSwitchTile(
              'Include Visual Aids',
              'Use diagrams and illustrations',
              _tempSettings.includeVisualAids,
                  (value) => _updateTempSettings(_tempSettings.copyWith(includeVisualAids: value)),
            ),
            _buildSwitchTile(
              'Show Related Topics',
              'Suggest related learning paths',
              _tempSettings.showRelatedTopics,
                  (value) => _updateTempSettings(_tempSettings.copyWith(showRelatedTopics: value)),
            ),
            _buildSwitchTile(
              'Step-by-Step Solutions',
              'Break down solutions into steps',
              _tempSettings.enableStepByStep,
                  (value) => _updateTempSettings(_tempSettings.copyWith(enableStepByStep: value)),
            ),
            _buildSwitchTile(
              'Real-World Applications',
              'Include practical applications',
              _tempSettings.includeRealWorldApplications,
                  (value) => _updateTempSettings(_tempSettings.copyWith(includeRealWorldApplications: value)),
            ),
            _buildSwitchTile(
              'Show Common Mistakes',
              'Highlight typical errors to avoid',
              _tempSettings.showCommonMistakes,
                  (value) => _updateTempSettings(_tempSettings.copyWith(showCommonMistakes: value)),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildSliderCard(
          'Explanation Depth',
          'Adjust how detailed explanations should be',
          _tempSettings.explanationDepth,
              (value) => _updateTempSettings(_tempSettings.copyWith(explanationDepth: value)),
          Icons.layers_rounded,
          Colors.purple,
          min: 0.0,
          max: 1.0,
          divisions: 10,
          labels: ['Minimal', 'Moderate', 'Maximum'],
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // LEARNING TAB
  // ═══════════════════════════════════════════════════════════════

  Widget _buildLearningTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionCard(
          'Learning Preferences',
          Icons.psychology_rounded,
          Colors.orange,
          [
            _buildDropdownTile(
              'Learning Style',
              _tempSettings.learningStyle,
              ['visual', 'auditory', 'kinesthetic', 'reading'],
                  (value) => _updateTempSettings(_tempSettings.copyWith(learningStyle: value)),
            ),
            _buildDropdownTile(
              'Quiz Frequency',
              _tempSettings.quizFrequency,
              ['never', 'occasional', 'frequent', 'always'],
                  (value) => _updateTempSettings(_tempSettings.copyWith(quizFrequency: value)),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildSectionCard(
          'Learning Features',
          Icons.auto_awesome_rounded,
          Colors.teal,
          [
            _buildSwitchTile(
              'Adaptive Difficulty',
              'Adjust complexity based on performance',
              _tempSettings.adaptiveDifficulty,
                  (value) => _updateTempSettings(_tempSettings.copyWith(adaptiveDifficulty: value)),
            ),
            _buildSwitchTile(
              'Show Progress',
              'Track and display learning progress',
              _tempSettings.showProgress,
                  (value) => _updateTempSettings(_tempSettings.copyWith(showProgress: value)),
            ),
            _buildSwitchTile(
              'Spaced Repetition',
              'Optimize review timing',
              _tempSettings.spacedRepetition,
                  (value) => _updateTempSettings(_tempSettings.copyWith(spacedRepetition: value)),
            ),
            _buildSwitchTile(
              'Interactive Quizzes',
              'Enable quiz widgets in responses',
              _tempSettings.enableInteractiveQuizzes,
                  (value) => _updateTempSettings(_tempSettings.copyWith(enableInteractiveQuizzes: value)),
            ),
            _buildSwitchTile(
              'Practice Problems',
              'Generate practice exercises',
              _tempSettings.enablePracticProblems,
                  (value) => _updateTempSettings(_tempSettings.copyWith(enablePracticProblems: value)),
            ),
          ],
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // AI BEHAVIOR TAB
  // ═══════════════════════════════════════════════════════════════

  Widget _buildAIBehaviorTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSliderCard(
          'Temperature',
          'Controls AI creativity: Lower = focused, Higher = creative',
          _tempSettings.temperature,
              (value) => _updateTempSettings(_tempSettings.copyWith(temperature: value)),
          Icons.thermostat_rounded,
          Colors.red,
          min: 0.0,
          max: 1.0,
          divisions: 20,
          labels: ['Focused', 'Balanced', 'Creative'],
        ),
        const SizedBox(height: 16),
        _buildSectionCard(
          'Response Settings',
          Icons.settings_suggest_rounded,
          Colors.indigo,
          [
            _buildNumberTile(
              'Max Tokens',
              'Maximum response length (512-4096)',
              _tempSettings.maxTokens,
                  (value) => _updateTempSettings(_tempSettings.copyWith(maxTokens: value)),
              min: 512,
              max: 4096,
              step: 256,
            ),
            _buildNumberTile(
              'Context Window',
              'Number of previous messages to remember (5-20)',
              _tempSettings.contextWindowSize,
                  (value) => _updateTempSettings(_tempSettings.copyWith(contextWindowSize: value)),
              min: 5,
              max: 20,
              step: 1,
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildSectionCard(
          'Behavior Features',
          Icons.smart_toy_rounded,
          Colors.cyan,
          [
            _buildSwitchTile(
              'Stream Responses',
              'Show responses as they generate',
              _tempSettings.streamResponses,
                  (value) => _updateTempSettings(_tempSettings.copyWith(streamResponses: value)),
            ),
            _buildSwitchTile(
              'Auto-suggest Questions',
              'Generate follow-up question suggestions',
              _tempSettings.autoSuggestQuestions,
                  (value) => _updateTempSettings(_tempSettings.copyWith(autoSuggestQuestions: value)),
            ),
          ],
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // NOTIFICATIONS TAB
  // ═══════════════════════════════════════════════════════════════

  Widget _buildNotificationsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionCard(
          'Notification Settings',
          Icons.notifications_active_rounded,
          Colors.amber,
          [
            _buildSwitchTile(
              'Enable Notifications',
              'Receive all notifications',
              _tempSettings.enableNotifications,
                  (value) => _updateTempSettings(_tempSettings.copyWith(enableNotifications: value)),
            ),
            _buildSwitchTile(
              'Streak Alerts',
              'Get notified about learning streaks',
              _tempSettings.streakAlerts,
                  (value) => _updateTempSettings(_tempSettings.copyWith(streakAlerts: value)),
              enabled: _tempSettings.enableNotifications,
            ),
            _buildSwitchTile(
              'Daily Reminders',
              'Daily study reminders',
              _tempSettings.dailyReminders,
                  (value) => _updateTempSettings(_tempSettings.copyWith(dailyReminders: value)),
              enabled: _tempSettings.enableNotifications,
            ),
            _buildSwitchTile(
              'Achievement Notifications',
              'Celebrate your milestones',
              _tempSettings.achievementNotifications,
                  (value) => _updateTempSettings(_tempSettings.copyWith(achievementNotifications: value)),
              enabled: _tempSettings.enableNotifications,
            ),
            _buildSwitchTile(
              'Study Session Reminders',
              'Reminders for scheduled study time',
              _tempSettings.studySessionReminders,
                  (value) => _updateTempSettings(_tempSettings.copyWith(studySessionReminders: value)),
              enabled: _tempSettings.enableNotifications,
            ),
          ],
        ),
        if (_tempSettings.enableNotifications) ...[
          const SizedBox(height: 16),
          _buildTimePickerCard(
            'Daily Reminder Time',
            'When should we send daily reminders?',
            _tempSettings.reminderTime,
                (value) => _updateTempSettings(_tempSettings.copyWith(reminderTime: value)),
          ),
        ],
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // ADVANCED TAB
  // ═══════════════════════════════════════════════════════════════

  Widget _buildAdvancedTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionCard(
          'Advanced Features',
          Icons.code_rounded,
          Colors.deepPurple,
          [
            _buildSwitchTile(
              'Enable Code Execution',
              'Run code examples in responses',
              _tempSettings.enableCodeExecution,
                  (value) => _updateTempSettings(_tempSettings.copyWith(enableCodeExecution: value)),
            ),
            _buildSwitchTile(
              'Enable LaTeX',
              'Render mathematical formulas',
              _tempSettings.enableLatex,
                  (value) => _updateTempSettings(_tempSettings.copyWith(enableLatex: value)),
            ),
            _buildSwitchTile(
              'Enable Markdown',
              'Rich text formatting in responses',
              _tempSettings.enableMarkdown,
                  (value) => _updateTempSettings(_tempSettings.copyWith(enableMarkdown: value)),
            ),
            _buildSwitchTile(
              'Enable Diagrams',
              'Generate visual diagrams',
              _tempSettings.enableDiagrams,
                  (value) => _updateTempSettings(_tempSettings.copyWith(enableDiagrams: value)),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildSectionCard(
          'Voice Settings',
          Icons.record_voice_over_rounded,
          Colors.pink,
          [
            _buildSwitchTile(
              'Enable Voice',
              'Voice input and output',
              _tempSettings.enableVoice,
                  (value) => _updateTempSettings(_tempSettings.copyWith(enableVoice: value)),
            ),
            if (_tempSettings.enableVoice) ...[
              _buildDropdownTile(
                'Voice Language',
                _tempSettings.voiceLanguage,
                ['en-US', 'en-GB', 'es-ES', 'fr-FR', 'de-DE', 'hi-IN'],
                    (value) => _updateTempSettings(_tempSettings.copyWith(voiceLanguage: value)),
              ),
              _buildDropdownTile(
                'Voice Pitch',
                _tempSettings.voicePitch,
                ['low', 'normal', 'high'],
                    (value) => _updateTempSettings(_tempSettings.copyWith(voicePitch: value)),
              ),
            ],
          ],
        ),
        if (_tempSettings.enableVoice) ...[
          const SizedBox(height: 16),
          _buildSliderCard(
            'Voice Speed',
            'Adjust speaking rate',
            _tempSettings.voiceSpeed,
                (value) => _updateTempSettings(_tempSettings.copyWith(voiceSpeed: value)),
            Icons.speed_rounded,
            Colors.brown,
            min: 0.5,
            max: 2.0,
            divisions: 15,
            labels: ['Slow', 'Normal', 'Fast'],
          ),
        ],
        const SizedBox(height: 16),
        _buildSectionCard(
          'Data & Privacy',
          Icons.security_rounded,
          Colors.red,
          [
            _buildSwitchTile(
              'Save History',
              'Keep conversation history',
              _tempSettings.saveHistory,
                  (value) => _updateTempSettings(_tempSettings.copyWith(saveHistory: value)),
            ),
            _buildSwitchTile(
              'Analyze Progress',
              'Track learning analytics',
              _tempSettings.analyzeProgress,
                  (value) => _updateTempSettings(_tempSettings.copyWith(analyzeProgress: value)),
            ),
            _buildSwitchTile(
              'Share Anonymous Data',
              'Help improve AI performance',
              _tempSettings.shareAnonymousData,
                  (value) => _updateTempSettings(_tempSettings.copyWith(shareAnonymousData: value)),
            ),
            _buildSwitchTile(
              'Auto-save Conversations',
              'Automatically save chats',
              _tempSettings.autoSaveConversations,
                  (value) => _updateTempSettings(_tempSettings.copyWith(autoSaveConversations: value)),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildSectionCard(
          'Export Preferences',
          Icons.file_download_rounded,
          Colors.blueGrey,
          [
            _buildDropdownTile(
              'Export Format',
              _tempSettings.exportFormat,
              ['pdf', 'markdown', 'text'],
                  (value) => _updateTempSettings(_tempSettings.copyWith(exportFormat: value)),
            ),
          ],
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // UI TAB
  // ═══════════════════════════════════════════════════════════════

  Widget _buildUITab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionCard(
          'Appearance',
          Icons.palette_rounded,
          Colors.deepOrange,
          [
            _buildSwitchTile(
              'Dark Mode',
              'Use dark theme',
              _tempSettings.darkMode,
                  (value) => _updateTempSettings(_tempSettings.copyWith(darkMode: value)),
            ),
            _buildDropdownTile(
              'Font Size',
              _tempSettings.fontSize,
              ['small', 'medium', 'large', 'extra-large'],
                  (value) => _updateTempSettings(_tempSettings.copyWith(fontSize: value)),
            ),
            _buildSwitchTile(
              'Compact Mode',
              'Reduce spacing and padding',
              _tempSettings.compactMode,
                  (value) => _updateTempSettings(_tempSettings.copyWith(compactMode: value)),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildSectionCard(
          'Chat Display',
          Icons.chat_rounded,
          Colors.lightBlue,
          [
            _buildSwitchTile(
              'Show Timestamps',
              'Display message times',
              _tempSettings.showTimestamps,
                  (value) => _updateTempSettings(_tempSettings.copyWith(showTimestamps: value)),
            ),
            _buildSwitchTile(
              'Show Avatars',
              'Display user and AI avatars',
              _tempSettings.showAvatars,
                  (value) => _updateTempSettings(_tempSettings.copyWith(showAvatars: value)),
            ),
          ],
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // REUSABLE COMPONENTS
  // ═══════════════════════════════════════════════════════════════

  Widget _buildSectionCard(
      String title,
      IconData icon,
      Color color,
      List<Widget> children,
      ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSwitchTile(
      String title,
      String subtitle,
      bool value,
      ValueChanged<bool> onChanged, {
        bool enabled = true,
      }) {
    return SwitchListTile(
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: enabled ? Colors.black87 : Colors.grey,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 12,
          color: enabled ? Colors.grey[600] : Colors.grey[400],
        ),
      ),
      value: value,
      onChanged: enabled ? onChanged : null,
      activeColor: const Color(0xFF6366F1),
    );
  }

  Widget _buildDropdownTile(
      String title,
      String value,
      List<String> options,
      ValueChanged<String?> onChanged,
      ) {
    return ListTile(
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      trailing: DropdownButton<String>(
        value: value,
        items: options
            .map((option) => DropdownMenuItem(
          value: option,
          child: Text(_capitalizeFirst(option)),
        ))
            .toList(),
        onChanged: onChanged,
        underline: Container(),
      ),
    );
  }

  Widget _buildSliderCard(
      String title,
      String subtitle,
      double value,
      ValueChanged<double> onChanged,
      IconData icon,
      Color color, {
        double min = 0.0,
        double max = 1.0,
        int divisions = 10,
        required List<String> labels,
      }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                value.toStringAsFixed(2),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            activeColor: color,
            inactiveColor: color.withOpacity(0.2),
            onChanged: onChanged,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: labels
                .map((label) => Text(
              label,
              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
            ))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildNumberTile(
      String title,
      String subtitle,
      int value,
      ValueChanged<int> onChanged, {
        required int min,
        required int max,
        required int step,
      }) {
    return ListTile(
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        '$subtitle\nCurrent: $value',
        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.remove_circle_outline),
            onPressed: value > min ? () => onChanged(value - step) : null,
            color: const Color(0xFF6366F1),
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: value < max ? () => onChanged(value + step) : null,
            color: const Color(0xFF6366F1),
          ),
        ],
      ),
    );
  }

  Widget _buildTimePickerCard(
      String title,
      String subtitle,
      int hour,
      ValueChanged<int> onChanged,
      ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.access_time, color: Colors.amber, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Center(
            child: InkWell(
              onTap: () async {
                final time = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay(hour: hour, minute: 0),
                );
                if (time != null) {
                  onChanged(time.hour);
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _formatHour(hour),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // DIALOGS
  // ═══════════════════════════════════════════════════════════════

  void _showPresetsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Load Preset Configuration'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildPresetOption(
              'Beginner',
              'Detailed explanations with examples',
              Icons.school_rounded,
              Colors.green,
                  () => _loadPreset('beginner'),
            ),
            const SizedBox(height: 12),
            _buildPresetOption(
              'Advanced',
              'Concise, technical responses',
              Icons.trending_up_rounded,
              Colors.blue,
                  () => _loadPreset('advanced'),
            ),
            const SizedBox(height: 12),
            _buildPresetOption(
              'Exam Mode',
              'Practice questions and quizzes',
              Icons.quiz_rounded,
              Colors.orange,
                  () => _loadPreset('exam'),
            ),
            const SizedBox(height: 12),
            _buildPresetOption(
              'Quick Learn',
              'Fast, focused learning',
              Icons.flash_on_rounded,
              Colors.red,
                  () => _loadPreset('quick'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Widget _buildPresetOption(
      String title,
      String description,
      IconData icon,
      Color color,
      VoidCallback onTap,
      ) {
    return InkWell(
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: color.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  void _exportSettings() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Export feature coming soon!'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _importSettings() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Import feature coming soon!'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // HELPERS
  // ═══════════════════════════════════════════════════════════════

  String _capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  String _formatHour(int hour) {
    if (hour == 0) return '12:00 AM';
    if (hour < 12) return '$hour:00 AM';
    if (hour == 12) return '12:00 PM';
    return '${hour - 12}:00 PM';
  }
}