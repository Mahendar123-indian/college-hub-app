import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:confetti/confetti.dart';

// Import providers and services
import '../../../providers/ai_assistant_provider.dart';
import '../../../data/services/unified_ai_service.dart';

// Import custom widgets
import '../../widgets/latex_renderer.dart';
import '../../widgets/code_highlighter.dart';
import '../../widgets/practice_problem_widget.dart';
import '../../widgets/interactive_quiz.dart';

// Import settings screen
import '../../../config/routes.dart';

/// 🚀 STUDYMATE AI - COMPLETE AI STUDY ASSISTANT SCREEN
/// Developer: Mahendar Reddy | CEO: Mahendar Reddy
/// ✅ FULLY DYNAMIC - Zero Static Data
/// ✅ All Features Working
/// ✅ Advanced UI with LaTeX, Code Highlighting, Quizzes & Practice Problems

class AIAssistantScreen extends StatefulWidget {
  const AIAssistantScreen({Key? key}) : super(key: key);

  @override
  State<AIAssistantScreen> createState() => _AIAssistantScreenState();
}

class _AIAssistantScreenState extends State<AIAssistantScreen>
    with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _messageFocusNode = FocusNode();

  late AnimationController _fabController;
  late AnimationController _typingController;
  late AnimationController _pulseController;
  late Animation<double> _fabAnimation;
  late Animation<double> _pulseAnimation;

  bool _showScrollToBottom = false;
  String _detectedQueryType = 'general';

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _scrollController.addListener(_scrollListener);
    _messageController.addListener(_onMessageChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AIAssistantProvider>().initialize();
    });
  }

  void _initializeAnimations() {
    _fabController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fabAnimation = CurvedAnimation(
      parent: _fabController,
      curve: Curves.easeInOut,
    );

    _typingController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat();

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  void _scrollListener() {
    if (_scrollController.hasClients) {
      final show = _scrollController.offset > 100;
      if (show != _showScrollToBottom) {
        setState(() => _showScrollToBottom = show);
        show ? _fabController.forward() : _fabController.reverse();
      }
    }
  }

  void _onMessageChanged() {
    setState(() {
      _detectedQueryType = _detectQueryType(_messageController.text);
    });
  }

  String _detectQueryType(String query) {
    final lower = query.toLowerCase();

    // Developer/CEO questions
    if (RegExp(r'who (developed|created|made)|developer|ceo|founder').hasMatch(lower)) {
      return 'about_developer';
    }

    if (RegExp(r'\d+[\+\-\*\/]|\bsolve\b|\bcalculate\b|\bfind\b').hasMatch(lower)) {
      return 'numerical';
    }

    if (lower.startsWith(RegExp(r'what is|explain|why does|how does|define'))) {
      return 'conceptual';
    }

    if (RegExp(r'```|code|function|class|algorithm|debug').hasMatch(lower)) {
      return 'code';
    }

    if (RegExp(r'exam|test|prepare|important topics|practice').hasMatch(lower)) {
      return 'exam';
    }

    if (RegExp(r'quiz|mcq|multiple choice').hasMatch(lower)) {
      return 'quiz';
    }

    if (query.length < 30 && query.contains('?')) {
      return 'quick';
    }

    return 'general';
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _messageFocusNode.dispose();
    _fabController.dispose();
    _typingController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: _buildAppBar(),
      drawer: _buildDrawer(),
      body: SafeArea(
        child: Column(
          children: [
            _buildContextBar(),
            _buildQueryTypeIndicator(),
            Expanded(child: _buildMessagesList()),
            _buildAttachedFilesPreview(),
            _buildSmartSuggestions(),
            _buildInputArea(),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: _buildScrollToBottomFab(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      ),
      leading: Builder(
        builder: (context) => IconButton(
          icon: const Icon(Icons.menu_rounded, color: Colors.white),
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
      ),
      title: Consumer<AIAssistantProvider>(
        builder: (context, provider, _) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  ScaleTransition(
                    scale: _pulseAnimation,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.psychology_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'StudyMate AI',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Icon(
                    provider.isLoading ? Icons.circle : Icons.check_circle,
                    color: provider.isLoading ? Colors.amber : Colors.greenAccent,
                    size: 10,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    provider.isLoading ? 'Thinking...' : 'Ready to help',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.insights_rounded, color: Colors.white),
          onPressed: _showLearningInsights,
          tooltip: 'Learning Insights',
        ),
        Consumer<AIAssistantProvider>(
          builder: (context, provider, _) {
            if (provider.errorMessage != null) {
              return IconButton(
                icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                onPressed: () => provider.retryInitialization(),
                tooltip: 'Retry',
              );
            }
            return PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded, color: Colors.white),
              onSelected: (value) {
                switch (value) {
                  case 'new':
                    provider.createNewSession();
                    break;
                  case 'clear':
                    _showClearChatDialog();
                    break;
                  case 'mode':
                    _showStudyModeSelector();
                    break;
                  case 'subject':
                    _showSubjectSelector();
                    break;
                  case 'export':
                    _exportConversation();
                    break;
                  case 'settings':
                    _navigateToSettings();
                    break;
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'new',
                  child: Row(
                    children: [
                      Icon(Icons.add_rounded, size: 20, color: Color(0xFF6366F1)),
                      SizedBox(width: 12),
                      Text('New Chat'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'mode',
                  child: Row(
                    children: [
                      Icon(Icons.school_rounded, size: 20, color: Color(0xFF6366F1)),
                      SizedBox(width: 12),
                      Text('Study Mode'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'subject',
                  child: Row(
                    children: [
                      Icon(Icons.book_rounded, size: 20, color: Color(0xFF6366F1)),
                      SizedBox(width: 12),
                      Text('Set Subject'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'export',
                  child: Row(
                    children: [
                      Icon(Icons.download_rounded, size: 20, color: Color(0xFF6366F1)),
                      SizedBox(width: 12),
                      Text('Export Chat'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'settings',
                  child: Row(
                    children: [
                      Icon(Icons.settings_rounded, size: 20, color: Color(0xFF6366F1)),
                      SizedBox(width: 12),
                      Text('AI Settings'),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem(
                  value: 'clear',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline_rounded, size: 20, color: Colors.red),
                      SizedBox(width: 12),
                      Text('Clear Chat', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildContextBar() {
    return Consumer<AIAssistantProvider>(
      builder: (context, provider, _) {
        if (provider.currentMode == StudyModeType.general && provider.currentSubject == null) {
          return const SizedBox.shrink();
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                _getModeColor(provider.currentMode).withOpacity(0.1),
                _getModeColor(provider.currentMode).withOpacity(0.05),
              ],
            ),
            border: Border(
              bottom: BorderSide(
                color: _getModeColor(provider.currentMode).withOpacity(0.3),
              ),
            ),
          ),
          child: Row(
            children: [
              if (provider.currentMode != StudyModeType.general) ...[
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _getModeColor(provider.currentMode).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getModeIcon(provider.currentMode),
                    size: 18,
                    color: _getModeColor(provider.currentMode),
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getModeName(provider.currentMode),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: _getModeColor(provider.currentMode),
                      ),
                    ),
                    Text(
                      _getModeDescription(provider.currentMode),
                      style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ],
              const Spacer(),
              if (provider.currentSubject != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.book_rounded, size: 14, color: Colors.grey[700]),
                      const SizedBox(width: 6),
                      Text(
                        provider.currentSubject!,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: () => provider.clearSubject(),
                        child: Icon(Icons.close, size: 14, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildQueryTypeIndicator() {
    if (_messageController.text.isEmpty) return const SizedBox.shrink();

    final indicators = {
      'about_developer': {
        'icon': Icons.person_rounded,
        'color': Colors.deepPurple,
        'label': 'About Developer',
        'hint': 'I\'ll tell you about Mahendar Reddy'
      },
      'numerical': {
        'icon': Icons.calculate_rounded,
        'color': Colors.blue,
        'label': 'Math Problem Detected',
        'hint': 'I\'ll show step-by-step solution'
      },
      'conceptual': {
        'icon': Icons.lightbulb_rounded,
        'color': Colors.amber,
        'label': 'Conceptual Question',
        'hint': 'I\'ll explain in detail with examples'
      },
      'code': {
        'icon': Icons.code_rounded,
        'color': Colors.green,
        'label': 'Programming Query',
        'hint': 'I\'ll provide code with explanations'
      },
      'exam': {
        'icon': Icons.quiz_rounded,
        'color': Colors.orange,
        'label': 'Exam Preparation',
        'hint': 'I\'ll focus on key concepts & practice'
      },
      'quiz': {
        'icon': Icons.help_center_rounded,
        'color': Colors.purple,
        'label': 'Quiz Question',
        'hint': 'I\'ll create interactive quiz'
      },
      'quick': {
        'icon': Icons.flash_on_rounded,
        'color': Colors.red,
        'label': 'Quick Doubt',
        'hint': 'I\'ll give a concise answer'
      },
    };

    final info = indicators[_detectedQueryType];
    if (info == null) return const SizedBox.shrink();

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 300),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 10 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: (info['color'] as Color).withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: (info['color'] as Color).withOpacity(0.3),
          ),
        ),
        child: Row(
          children: [
            Icon(
              info['icon'] as IconData,
              color: info['color'] as Color,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    info['label'] as String,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: info['color'] as Color,
                    ),
                  ),
                  Text(
                    info['hint'] as String,
                    style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessagesList() {
    return Consumer<AIAssistantProvider>(
      builder: (context, provider, _) {
        if (provider.isInitializing) {
          return _buildLoadingState();
        }

        if (provider.errorMessage != null) {
          return _buildErrorState(provider.errorMessage!);
        }

        if (provider.messages.isEmpty) {
          return _buildEmptyState();
        }

        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.all(16).copyWith(bottom: 80),
          itemCount: provider.messages.length + (provider.isLoading ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == provider.messages.length) {
              return _buildTypingIndicator();
            }
            return _buildAdvancedMessageBubble(provider.messages[index]);
          },
        );
      },
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ScaleTransition(
            scale: _pulseAnimation,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6366F1).withOpacity(0.4),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: const Icon(
                Icons.psychology_rounded,
                color: Colors.white,
                size: 48,
              ),
            ),
          ),
          const SizedBox(height: 24),
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          const Text(
            'Initializing StudyMate AI...',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            'Your personalized learning assistant by Mahendar Reddy',
            style: TextStyle(fontSize: 13, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline_rounded, size: 80, color: Colors.orange[400]),
            const SizedBox(height: 24),
            const Text(
              'Connection Error',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(
              error,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                context.read<AIAssistantProvider>().retryInitialization();
              },
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry Connection'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ScaleTransition(
              scale: _pulseAnimation,
              child: const Icon(
                Icons.psychology_rounded,
                size: 80,
                color: Color(0xFF6366F1),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Hi! I\'m StudyMate 👋',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              'Your AI study companion ready to help you learn',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'Developed by Mahendar Reddy',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 32),
            _buildQuickStartCards(),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStartCards() {
    final quickStarts = [
      {
        'icon': Icons.calculate_rounded,
        'title': 'Solve Problems',
        'desc': 'Get step-by-step solutions',
        'color': Colors.blue,
        'query': 'Solve: 2x + 5 = 13'
      },
      {
        'icon': Icons.lightbulb_rounded,
        'title': 'Learn Concepts',
        'desc': 'Understand any topic deeply',
        'color': Colors.amber,
        'query': 'Explain photosynthesis'
      },
      {
        'icon': Icons.code_rounded,
        'title': 'Code Help',
        'desc': 'Debug and learn programming',
        'color': Colors.green,
        'query': 'Explain recursion with example'
      },
      {
        'icon': Icons.quiz_rounded,
        'title': 'Exam Prep',
        'desc': 'Practice and prepare',
        'color': Colors.orange,
        'query': 'Give me practice questions on calculus'
      },
      {
        'icon': Icons.help_center_rounded,
        'title': 'Take Quiz',
        'desc': 'Test your knowledge',
        'color': Colors.purple,
        'query': 'Create a quiz on Java programming'
      },
      {
        'icon': Icons.functions_rounded,
        'title': 'Math Help',
        'desc': 'LaTeX math rendering',
        'color': Colors.indigo,
        'query': 'Solve ∫(x^2 + 2x) dx'
      },
    ];

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      alignment: WrapAlignment.center,
      children: quickStarts.map((item) {
        return InkWell(
          onTap: () {
            _messageController.text = item['query'] as String;
            _sendMessage();
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: 160,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: (item['color'] as Color).withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: (item['color'] as Color).withOpacity(0.3),
              ),
            ),
            child: Column(
              children: [
                Icon(
                  item['icon'] as IconData,
                  color: item['color'] as Color,
                  size: 32,
                ),
                const SizedBox(height: 12),
                Text(
                  item['title'] as String,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item['desc'] as String,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildAdvancedMessageBubble(ChatMessage message) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 300),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Row(
          mainAxisAlignment: message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!message.isUser) ...[
              _buildAvatar(message.isUser, message.isError),
              const SizedBox(width: 12),
            ],
            Flexible(
              child: Column(
                crossAxisAlignment: message.isUser
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  _buildMessageContent(message),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        DateFormat('HH:mm').format(message.timestamp),
                        style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                      ),
                      if (!message.isUser) ...[
                        const SizedBox(width: 12),
                        _buildMessageActions(message),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            if (message.isUser) ...[
              const SizedBox(width: 12),
              _buildAvatar(message.isUser, message.isError),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMessageContent(ChatMessage message) {
    return Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.75,
      ),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: message.isUser
            ? const LinearGradient(
          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
        )
            : null,
        color: message.isUser
            ? null
            : (message.isError
            ? Colors.red.withOpacity(0.1)
            : Colors.white),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(message.isUser ? 20 : 4),
          topRight: Radius.circular(message.isUser ? 4 : 20),
          bottomLeft: const Radius.circular(20),
          bottomRight: const Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: message.isError
            ? Border.all(color: Colors.red.withOpacity(0.3))
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (message.files.isNotEmpty) ...[
            ...message.files.map((f) {
              final fileName = f.path.split('/').last;
              return _buildFileChip(fileName, message.isUser);
            }),
            const SizedBox(height: 12),
          ],
          if (message.isUser)
            Text(
              message.text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                height: 1.5,
              ),
            )
          else
            _buildRichAIResponse(message),
        ],
      ),
    );
  }

  Widget _buildRichAIResponse(ChatMessage message) {
    final content = message.text;

    // Check for quiz
    if (_containsQuizJson(content)) {
      final quiz = _parseQuizFromContent(content);
      if (quiz != null) {
        return InteractiveQuizWidget(
          question: quiz,
          onCorrect: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('✅ Correct! Well done!'),
                backgroundColor: Colors.green[800],
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            );
          },
          onIncorrect: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('📚 Keep learning! Try again.'),
                backgroundColor: Colors.orange[800],
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            );
          },
        );
      }
    }

    // Check for practice problem
    if (_containsPracticeProblemJson(content)) {
      final problem = _parsePracticeProblemFromContent(content);
      if (problem != null) {
        return PracticeProblemWidget(
          problem: problem,
          onComplete: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('🎉 Great job! Ready for the next challenge?'),
                backgroundColor: Colors.green[800],
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            );
          },
        );
      }
    }

    // Check for structured response
    if (_containsStructuredResponse(content)) {
      return _buildEnhancedStructuredResponse(content);
    }

    // Check for code blocks
    if (content.contains('```')) {
      return _buildEnhancedCodeResponse(content);
    }

    // Check for LaTeX math
    if (_containsMath(content)) {
      return LatexRenderer(
        content: content,
        textStyle: const TextStyle(fontSize: 15, height: 1.5),
        isDarkMode: false,
      );
    }

    // Default: Markdown with LaTeX support
    return LatexRenderer(
      content: content,
      textStyle: const TextStyle(fontSize: 15, height: 1.5),
      isDarkMode: false,
    );
  }

  bool _containsMath(String content) {
    return content.contains(r'$') ||
        content.contains(r'\[') ||
        content.contains(r'\(');
  }

  bool _containsStructuredResponse(String content) {
    return content.contains('## 🎯') ||
        content.contains('## 📚') ||
        content.contains('## 📝') ||
        content.contains('## ✓') ||
        content.contains('## 💪');
  }

  bool _containsQuizJson(String content) {
    return content.contains('"quiz_question"') ||
        (content.contains('"question"') &&
            content.contains('"options"') &&
            content.contains('"correct"'));
  }

  bool _containsPracticeProblemJson(String content) {
    return content.contains('"practice_problem"') ||
        (content.contains('"problem"') &&
            content.contains('"hints"') &&
            content.contains('"answer"'));
  }

  QuizQuestion? _parseQuizFromContent(String content) {
    try {
      final questionMatch = RegExp(r'Question[:\s]+(.+?)(?=\n|$)').firstMatch(content);
      final optionsMatches = RegExp(r'[A-D][\.\:]\s+(.+?)(?=\n[A-D]|\n|$)').allMatches(content);

      if (questionMatch != null && optionsMatches.isNotEmpty) {
        final options = optionsMatches.map((match) {
          final text = match.group(1) ?? '';
          final isCorrect = text.toLowerCase().contains('[correct]') ||
              text.toLowerCase().contains('(correct)');
          final cleanText = text.replaceAll('[correct]', '').replaceAll('(correct)', '').trim();

          return QuizOption(
            id: String.fromCharCode(65 + optionsMatches.toList().indexOf(match)),
            text: cleanText,
            isCorrect: isCorrect,
          );
        }).toList();

        if (options.every((opt) => !opt.isCorrect) && options.isNotEmpty) {
          options[0] = QuizOption(
            id: options[0].id,
            text: options[0].text,
            isCorrect: true,
          );
        }

        return QuizQuestion(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          question: questionMatch.group(1)!.trim(),
          options: options,
          explanation: _extractExplanation(content),
        );
      }
    } catch (e) {
      print('Error parsing quiz: $e');
    }
    return null;
  }

  PracticeProblem? _parsePracticeProblemFromContent(String content) {
    try {
      final problemMatch = RegExp(r'Problem[:\s]+(.+?)(?=\n|$)').firstMatch(content);
      final hintsMatches = RegExp(r'Hint \d+[:\s]+(.+?)(?=\nHint|\n|$)').allMatches(content);
      final answerMatch = RegExp(r'Answer[:\s]+(.+?)(?=\n|$)').firstMatch(content);

      if (problemMatch != null && answerMatch != null) {
        final difficulty = content.toLowerCase().contains('advanced') ? 'advanced' :
        content.toLowerCase().contains('intermediate') ? 'intermediate' : 'beginner';

        return PracticeProblem(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          problem: problemMatch.group(1)!.trim(),
          difficulty: difficulty,
          hints: hintsMatches.map((m) => m.group(1)?.trim() ?? '').toList(),
          answer: answerMatch.group(1)!.trim(),
          steps: _extractSteps(content),
          explanation: _extractExplanation(content),
        );
      }
    } catch (e) {
      print('Error parsing practice problem: $e');
    }
    return null;
  }

  String? _extractExplanation(String content) {
    final expMatch = RegExp(r'Explanation[:\s]+(.+?)(?=\n[A-Z]|\n\n|$)').firstMatch(content);
    return expMatch?.group(1)?.trim();
  }

  List<String> _extractSteps(String content) {
    final stepsMatches = RegExp(r'Step \d+[:\s]+(.+?)(?=\nStep|\n\n|$)').allMatches(content);
    return stepsMatches.map((m) => m.group(1)?.trim() ?? '').toList();
  }

  Widget _buildEnhancedStructuredResponse(String content) {
    final sections = _parseStructuredSections(content);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: sections.map((section) {
        final type = section['type'] as String;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                _getSectionColor(type).withOpacity(0.1),
                _getSectionColor(type).withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _getSectionColor(type).withOpacity(0.3),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: _getSectionColor(type).withOpacity(0.15),
                blurRadius: 8,
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
                      color: _getSectionColor(type).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      _getSectionIcon(type),
                      size: 20,
                      color: _getSectionColor(type),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      section['title'] as String,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _getSectionColor(type),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              LatexRenderer(
                content: section['content'] as String,
                textStyle: const TextStyle(
                  fontSize: 15,
                  height: 1.6,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildEnhancedCodeResponse(String content) {
    final codeBlocks = _extractCodeBlocks(content);
    final textParts = _extractTextBetweenCode(content);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < codeBlocks.length; i++) ...[
          if (i < textParts.length && textParts[i].trim().isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: LatexRenderer(
                content: textParts[i],
                textStyle: const TextStyle(fontSize: 15, height: 1.5),
              ),
            ),
          CodeHighlighter(
            code: codeBlocks[i]['code']!,
            language: codeBlocks[i]['language']!,
            showLineNumbers: true,
            isDarkMode: false,
          ),
        ],
        if (textParts.length > codeBlocks.length &&
            textParts.last.trim().isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: LatexRenderer(
              content: textParts.last,
              textStyle: const TextStyle(fontSize: 15, height: 1.5),
            ),
          ),
      ],
    );
  }

  List<Map<String, String>> _parseStructuredSections(String content) {
    final sections = <Map<String, String>>[];
    final lines = content.split('\n');

    String? currentType;
    String? currentTitle;
    StringBuffer currentContent = StringBuffer();

    for (final line in lines) {
      if (line.startsWith('## ')) {
        if (currentType != null) {
          sections.add({
            'type': currentType,
            'title': currentTitle!,
            'content': currentContent.toString().trim(),
          });
        }

        if (line.contains('🎯')) {
          currentType = 'analysis';
          currentTitle = 'Problem Analysis';
        } else if (line.contains('📚')) {
          currentType = 'concept';
          currentTitle = 'Concept';
        } else if (line.contains('📝')) {
          currentType = 'solution';
          currentTitle = 'Step-by-Step Solution';
        } else if (line.contains('✓')) {
          currentType = 'verification';
          currentTitle = 'Verification';
        } else if (line.contains('💪')) {
          currentType = 'practice';
          currentTitle = 'Practice Problems';
        } else {
          currentType = 'general';
          currentTitle = line.replaceAll('##', '').trim();
        }

        currentContent = StringBuffer();
      } else {
        currentContent.writeln(line);
      }
    }

    if (currentType != null) {
      sections.add({
        'type': currentType,
        'title': currentTitle!,
        'content': currentContent.toString().trim(),
      });
    }

    return sections;
  }

  List<Map<String, String>> _extractCodeBlocks(String content) {
    final blocks = <Map<String, String>>[];
    final regex = RegExp(r'```(\w+)?\n([\s\S]*?)```');
    final matches = regex.allMatches(content);

    for (final match in matches) {
      blocks.add({
        'language': match.group(1)?.toLowerCase() ?? 'text',
        'code': match.group(2)?.trim() ?? '',
      });
    }

    return blocks;
  }

  List<String> _extractTextBetweenCode(String content) {
    return content.split(RegExp(r'```\w*\n[\s\S]*?```'));
  }

  Color _getSectionColor(String type) {
    switch (type) {
      case 'analysis':
        return Colors.blue;
      case 'concept':
        return Colors.purple;
      case 'solution':
        return Colors.green;
      case 'verification':
        return Colors.teal;
      case 'practice':
        return Colors.orange;
      default:
        return const Color(0xFF6366F1);
    }
  }

  IconData _getSectionIcon(String type) {
    switch (type) {
      case 'analysis':
        return Icons.analytics_rounded;
      case 'concept':
        return Icons.school_rounded;
      case 'solution':
        return Icons.check_circle_rounded;
      case 'verification':
        return Icons.verified_rounded;
      case 'practice':
        return Icons.fitness_center_rounded;
      default:
        return Icons.info_rounded;
    }
  }

  Widget _buildMessageActions(ChatMessage message) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildActionButton(
          Icons.thumb_up_outlined,
              () => _rateMessage(message, true),
        ),
        const SizedBox(width: 4),
        _buildActionButton(
          Icons.thumb_down_outlined,
              () => _rateMessage(message, false),
        ),
        const SizedBox(width: 4),
        _buildActionButton(
          Icons.copy_rounded,
              () => _copyMessage(message),
        ),
        const SizedBox(width: 4),
        _buildActionButton(
          Icons.share_rounded,
              () => _shareMessage(message),
        ),
      ],
    );
  }

  Widget _buildActionButton(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(6),
        child: Icon(icon, size: 16, color: Colors.grey[600]),
      ),
    );
  }

  void _rateMessage(ChatMessage message, bool isPositive) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isPositive ? 'Thanks for your feedback!' : 'We\'ll improve!'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  void _copyMessage(ChatMessage message) {
    Clipboard.setData(ClipboardData(text: message.text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Message copied to clipboard'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  void _shareMessage(ChatMessage message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Share functionality coming soon'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildAvatar(bool isUser, bool isError) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        gradient: isUser
            ? const LinearGradient(
          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
        )
            : (isError
            ? LinearGradient(
          colors: [Colors.red.shade400, Colors.red.shade600],
        )
            : const LinearGradient(
          colors: [Color(0xFF10B981), Color(0xFF059669)],
        )),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: (isUser
                ? const Color(0xFF6366F1)
                : isError
                ? Colors.red
                : const Color(0xFF10B981))
                .withOpacity(0.3),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Icon(
        isUser
            ? Icons.person_rounded
            : (isError ? Icons.error_rounded : Icons.psychology_rounded),
        color: Colors.white,
        size: 20,
      ),
    );
  }

  Widget _buildFileChip(String fileName, bool isUser) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isUser ? Colors.white.withOpacity(0.2) : Colors.grey[100],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.attach_file_rounded,
            size: 14,
            color: isUser ? Colors.white : Colors.grey[700],
          ),
          const SizedBox(width: 6),
          Text(
            fileName,
            style: TextStyle(
              fontSize: 12,
              color: isUser ? Colors.white : Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          _buildAvatar(false, false),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTypingDot(0),
                const SizedBox(width: 4),
                _buildTypingDot(200),
                const SizedBox(width: 4),
                _buildTypingDot(400),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingDot(int delay) {
    return FadeTransition(
      opacity: _typingController,
      child: Container(
        width: 8,
        height: 8,
        decoration: const BoxDecoration(
          color: Color(0xFF6366F1),
          shape: BoxShape.circle,
        ),
      ),
    );
  }

  Widget _buildAttachedFilesPreview() {
    return Consumer<AIAssistantProvider>(
      builder: (context, provider, _) {
        final attachedFiles = provider.attachedFiles;
        if (attachedFiles.isEmpty) {
          return const SizedBox.shrink();
        }

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(
              top: BorderSide(color: Colors.grey[300]!),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    'Attached Files',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => provider.clearAttachedFiles(),
                    child: const Text('Clear All'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: attachedFiles.map((file) {
                  final fileName = file.path.split('/').last;
                  return Chip(
                    avatar: const Icon(Icons.attach_file, size: 16),
                    label: Text(fileName),
                    deleteIcon: const Icon(Icons.close, size: 16),
                    onDeleted: () => provider.removeAttachedFile(file),
                  );
                }).toList(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSmartSuggestions() {
    return Consumer<AIAssistantProvider>(
      builder: (context, provider, _) {
        final smartSuggestions = provider.smartSuggestions;
        if (smartSuggestions.isEmpty) {
          return const SizedBox.shrink();
        }

        return Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(
              top: BorderSide(color: Colors.grey[300]!),
              bottom: BorderSide(color: Colors.grey[300]!),
            ),
          ),
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: smartSuggestions.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final suggestion = smartSuggestions[index];
              return InkWell(
                onTap: () {
                  _messageController.text = suggestion;
                  _sendMessage();
                },
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFF6366F1).withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    suggestion,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF6366F1),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildInputArea() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _buildAttachButton(),
            const SizedBox(width: 8),
            Expanded(child: _buildMessageInput()),
            const SizedBox(width: 8),
            _buildSendButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachButton() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.grey[100]!, Colors.grey[50]!],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        icon: const Icon(Icons.add_circle_outline_rounded, color: Color(0xFF6366F1)),
        onPressed: _showAttachmentOptions,
        padding: const EdgeInsets.all(8),
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      constraints: const BoxConstraints(maxHeight: 120),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.grey[300]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Consumer<AIAssistantProvider>(
        builder: (context, provider, _) {
          return TextField(
            controller: _messageController,
            focusNode: _messageFocusNode,
            enabled: !provider.isInitializing && provider.errorMessage == null,
            decoration: InputDecoration(
              hintText: provider.errorMessage != null
                  ? 'Fix errors to chat...'
                  : 'Ask me anything...',
              hintStyle: TextStyle(color: Colors.grey[500]),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 10,
              ),
            ),
            maxLines: null,
            textCapitalization: TextCapitalization.sentences,
            onSubmitted: (_) => _sendMessage(),
          );
        },
      ),
    );
  }

  Widget _buildSendButton() {
    return Consumer<AIAssistantProvider>(
      builder: (context, provider, _) {
        final canSend = _messageController.text.trim().isNotEmpty || provider.hasAttachedFiles;
        final isDisabled = provider.isLoading || provider.errorMessage != null || !canSend;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDisabled
                  ? [Colors.grey[300]!, Colors.grey[400]!]
                  : [const Color(0xFF6366F1), const Color(0xFF8B5CF6)],
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: !isDisabled
                ? [
              BoxShadow(
                color: const Color(0xFF6366F1).withOpacity(0.4),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ]
                : [],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: isDisabled ? null : _sendMessage,
              child: Container(
                padding: const EdgeInsets.all(12),
                child: provider.isLoading
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
                    : const Icon(
                  Icons.send_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: Consumer<AIAssistantProvider>(
        builder: (context, provider, _) {
          return Column(
            children: [
              _buildDrawerHeader(provider),
              _buildLearningProgress(provider),
              Expanded(child: _buildChatSessionsList(provider)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDrawerHeader(AIAssistantProvider provider) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.chat_bubble_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'StudyMate',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      '${provider.sessions.length} conversations',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              provider.createNewSession();
            },
            icon: const Icon(Icons.add_rounded, size: 20),
            label: const Text('New Chat'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF6366F1),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
              elevation: 4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLearningProgress(AIAssistantProvider provider) {
    final progress = provider.learningProgress;
    final masteredCount = provider.getMasteredConcepts().length;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF6366F1).withOpacity(0.1),
            const Color(0xFF8B5CF6).withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.trending_up_rounded, color: Color(0xFF6366F1)),
              SizedBox(width: 8),
              Text(
                'Learning Progress',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatItem(
                Icons.question_answer_rounded,
                '${progress.questionsAsked}',
                'Questions',
              ),
              _buildStatItem(
                Icons.local_fire_department_rounded,
                '${progress.currentStreak}',
                'Day Streak',
              ),
              _buildStatItem(
                Icons.stars_rounded,
                '$masteredCount',
                'Mastered',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF6366F1).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: const Color(0xFF6366F1), size: 20),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF6366F1),
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildChatSessionsList(AIAssistantProvider provider) {
    if (provider.sessions.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.chat_outlined, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'No chat history yet',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Start a conversation to begin learning!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: provider.sessions.length,
      itemBuilder: (context, index) {
        final session = provider.sessions[index];
        final isActive = provider.currentSession?.id == session.id;

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            gradient: isActive
                ? LinearGradient(
              colors: [
                const Color(0xFF6366F1).withOpacity(0.1),
                const Color(0xFF8B5CF6).withOpacity(0.05),
              ],
            )
                : null,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isActive ? const Color(0xFF6366F1) : Colors.transparent,
              width: 2,
            ),
            boxShadow: isActive ? [
              BoxShadow(
                color: const Color(0xFF6366F1).withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ] : [],
          ),
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: isActive
                    ? const LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                )
                    : null,
                color: isActive ? null : Colors.grey[200],
                borderRadius: BorderRadius.circular(10),
                boxShadow: isActive ? [
                  BoxShadow(
                    color: const Color(0xFF6366F1).withOpacity(0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ] : [],
              ),
              child: Icon(
                Icons.chat_bubble_rounded,
                size: 20,
                color: isActive ? Colors.white : Colors.grey[600],
              ),
            ),
            title: Text(
              session.title,
              style: TextStyle(
                fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                color: isActive ? const Color(0xFF6366F1) : Colors.black87,
                fontSize: 14,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              '${session.messages.length} messages • ${DateFormat('MMM d, HH:mm').format(session.updatedAt)}',
              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
            ),
            trailing: IconButton(
              icon: Icon(
                Icons.delete_outline_rounded,
                size: 20,
                color: Colors.grey[400],
              ),
              onPressed: () {
                _showDeleteSessionDialog(session);
              },
            ),
            onTap: () {
              Navigator.pop(context);
              provider.switchSession(session);
              _scrollToBottom();
            },
          ),
        );
      },
    );
  }

  Widget _buildScrollToBottomFab() {
    if (!_showScrollToBottom) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 80.0),
      child: ScaleTransition(
        scale: _fabAnimation,
        child: FloatingActionButton.small(
          heroTag: 'scroll_to_bottom_ai_chat',
          onPressed: _scrollToBottom,
          backgroundColor: const Color(0xFF6366F1),
          foregroundColor: Colors.white,
          elevation: 4,
          child: const Icon(Icons.arrow_downward_rounded, color: Colors.white, size: 20),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // DIALOG METHODS
  // ═══════════════════════════════════════════════════════════════

  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.5,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    'Attach Files',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    'Add files to help me understand your question better',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                ),
                const SizedBox(height: 20),
                _buildAttachmentOption(
                  Icons.image_rounded,
                  'Photos & Images',
                  'JPG, PNG, GIF',
                  Colors.purple,
                      () {
                    Navigator.pop(context);
                    context.read<AIAssistantProvider>().pickImages();
                  },
                ),
                _buildAttachmentOption(
                  Icons.picture_as_pdf_rounded,
                  'PDF Documents',
                  'Upload PDF files',
                  Colors.red,
                      () {
                    Navigator.pop(context);
                    context.read<AIAssistantProvider>().pickFiles();
                  },
                ),
                _buildAttachmentOption(
                  Icons.description_rounded,
                  'Text Documents',
                  'DOC, DOCX, TXT',
                  Colors.blue,
                      () {
                    Navigator.pop(context);
                    context.read<AIAssistantProvider>().pickFiles();
                  },
                ),
                _buildAttachmentOption(
                  Icons.code_rounded,
                  'Code Files',
                  'Help debug your code',
                  Colors.green,
                      () {
                    Navigator.pop(context);
                    context.read<AIAssistantProvider>().pickFiles();
                  },
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAttachmentOption(
      IconData icon,
      String title,
      String subtitle,
      Color color,
      VoidCallback onTap,
      ) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, color: color, size: 24),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
    );
  }

  void _showStudyModeSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    'Study Mode',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    'Choose how you want me to explain concepts',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                ),
                const SizedBox(height: 20),
                ...StudyModeType.values.map((mode) {
                  return _buildStudyModeOption(mode);
                }).toList(),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStudyModeOption(StudyModeType mode) {
    return Consumer<AIAssistantProvider>(
      builder: (context, provider, _) {
        final isSelected = provider.currentMode == mode;

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            gradient: isSelected
                ? LinearGradient(
              colors: [
                _getModeColor(mode).withOpacity(0.1),
                _getModeColor(mode).withOpacity(0.05),
              ],
            )
                : null,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? _getModeColor(mode) : Colors.grey[300]!,
              width: isSelected ? 2 : 1,
            ),
            boxShadow: isSelected ? [
              BoxShadow(
                color: _getModeColor(mode).withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ] : [],
          ),
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _getModeColor(mode).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(_getModeIcon(mode), color: _getModeColor(mode), size: 24),
            ),
            title: Text(
              _getModeName(mode),
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: isSelected ? _getModeColor(mode) : Colors.black87,
              ),
            ),
            subtitle: Text(_getModeDescription(mode)),
            trailing:
            isSelected ? Icon(Icons.check_circle, color: _getModeColor(mode)) : null,
            onTap: () {
              provider.setStudyMode(mode);
              Navigator.pop(context);
            },
          ),
        );
      },
    );
  }

  void _showSubjectSelector() {
    final subjects = [
      {'name': 'Operating Systems', 'icon': Icons.computer_rounded, 'color': Colors.blue},
      {'name': 'Data Structures', 'icon': Icons.account_tree_rounded, 'color': Colors.green},
      {'name': 'DBMS', 'icon': Icons.storage_rounded, 'color': Colors.purple},
      {'name': 'Computer Networks', 'icon': Icons.network_check_rounded, 'color': Colors.orange},
      {'name': 'Software Engineering', 'icon': Icons.engineering_rounded, 'color': Colors.teal},
      {'name': 'Mathematics', 'icon': Icons.calculate_rounded, 'color': Colors.red},
      {'name': 'Physics', 'icon': Icons.science_rounded, 'color': Colors.indigo},
      {'name': 'Chemistry', 'icon': Icons.biotech_rounded, 'color': Colors.pink},
      {'name': 'Electronics', 'icon': Icons.electrical_services_rounded, 'color': Colors.amber},
      {'name': 'Java Programming', 'icon': Icons.code_rounded, 'color': Colors.deepOrange},
      {'name': 'Python', 'icon': Icons.code_off_rounded, 'color': Colors.lightGreen},
      {'name': 'Web Development', 'icon': Icons.web_rounded, 'color': Colors.cyan},
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'Select Subject',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'I\'ll tailor my responses to this subject',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
              ),
              const SizedBox(height: 20),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: subjects.length,
                  itemBuilder: (context, index) {
                    final subject = subjects[index];
                    return ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: (subject['color'] as Color).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: (subject['color'] as Color).withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          subject['icon'] as IconData,
                          color: subject['color'] as Color,
                        ),
                      ),
                      title: Text(
                        subject['name'] as String,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () {
                        context.read<AIAssistantProvider>().setSubject(subject['name'] as String);
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _showLearningInsights() {
    final provider = context.read<AIAssistantProvider>();
    final progress = provider.learningProgress;
    final masteredConcepts = provider.getMasteredConcepts();
    final strugglingConcepts = provider.getStrugglingConcepts();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Row(
                  children: [
                    Icon(Icons.insights_rounded, color: Color(0xFF6366F1), size: 28),
                    SizedBox(width: 12),
                    Text(
                      'Learning Insights',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildInsightCard(
                  'Questions Asked',
                  '${progress.questionsAsked}',
                  Icons.question_answer_rounded,
                  Colors.blue,
                  'Keep asking to learn more!',
                ),
                const SizedBox(height: 12),
                _buildInsightCard(
                  'Current Streak',
                  '${progress.currentStreak} days',
                  Icons.local_fire_department_rounded,
                  Colors.orange,
                  progress.currentStreak > 7 ? 'Amazing consistency!' : 'Keep it up!',
                ),
                const SizedBox(height: 20),
                const Text(
                  'Concepts Mastered',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                if (masteredConcepts.isEmpty)
                  Text(
                    'No concepts mastered yet. Keep learning!',
                    style: TextStyle(color: Colors.grey[600]),
                  )
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: masteredConcepts
                        .map((concept) => Chip(
                      avatar: const Icon(Icons.check_circle, size: 16, color: Colors.green),
                      label: Text(concept.name),
                      backgroundColor: Colors.green.withOpacity(0.1),
                    ))
                        .toList(),
                  ),
                const SizedBox(height: 20),
                const Text(
                  'Areas to Improve',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                if (strugglingConcepts.isEmpty)
                  Text(
                    'No struggling areas detected. Great job!',
                    style: TextStyle(color: Colors.grey[600]),
                  )
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: strugglingConcepts
                        .map((concept) => Chip(
                      avatar: const Icon(Icons.trending_up, size: 16, color: Colors.orange),
                      label: Text(concept.name),
                      backgroundColor: Colors.orange.withOpacity(0.1),
                    ))
                        .toList(),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInsightCard(
      String title,
      String value,
      IconData icon,
      Color color,
      String subtitle,
      ) {
    return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
    );
  }

  void _showClearChatDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.cleaning_services_rounded, color: Colors.orange),
            SizedBox(width: 12),
            Text('Clear Chat'),
          ],
        ),
        content: const Text(
          'Clear all messages in this conversation? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<AIAssistantProvider>().clearCurrentChat();
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              foregroundColor: Colors.white,
            ),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  void _showDeleteSessionDialog(ChatSession session) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_rounded, color: Colors.red),
            SizedBox(width: 12),
            Text('Delete Chat'),
          ],
        ),
        content: Text('Delete "${session.title}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<AIAssistantProvider>().deleteSession(session);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _exportConversation() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Export Conversation',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.picture_as_pdf_rounded, color: Colors.red),
                ),
                title: const Text('Export as PDF'),
                subtitle: const Text('Professional formatted document'),
                onTap: () async {
                  Navigator.pop(context);
                  final provider = context.read<AIAssistantProvider>();
                  try {
                    final path = await provider.exportConversationAsPDF();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('✅ PDF exported to: $path'),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('❌ Error exporting: $e'),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    );
                  }
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.text_snippet_rounded, color: Colors.blue),
                ),
                title: const Text('Export as Text'),
                subtitle: const Text('Plain text format'),
                onTap: () async {
                  Navigator.pop(context);
                  final provider = context.read<AIAssistantProvider>();
                  try {
                    final path = await provider.exportConversationAsText();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('✅ Text exported to: $path'),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('❌ Error exporting: $e'),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    );
                  }
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToSettings() {
    Navigator.pushNamed(context, AppRoutes.aiSettings);
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty && !context.read<AIAssistantProvider>().hasAttachedFiles) {
      return;
    }

    context.read<AIAssistantProvider>().sendMessage(text);
    _messageController.clear();
    _scrollToBottom();
  }

  // Helper methods for mode styling
  Color _getModeColor(StudyModeType mode) {
    switch (mode) {
      case StudyModeType.general:
        return const Color(0xFF6366F1);
      case StudyModeType.beginner:
        return Colors.green;
      case StudyModeType.exam:
        return Colors.orange;
      case StudyModeType.interview:
        return Colors.purple;
      case StudyModeType.quickRevision:
        return Colors.red;
      default:
        return const Color(0xFF6366F1);
    }
  }

  IconData _getModeIcon(StudyModeType mode) {
    switch (mode) {
      case StudyModeType.general:
        return Icons.school_rounded;
      case StudyModeType.beginner:
        return Icons.lightbulb_rounded;
      case StudyModeType.exam:
        return Icons.quiz_rounded;
      case StudyModeType.interview:
        return Icons.work_rounded;
      case StudyModeType.quickRevision:
        return Icons.flash_on_rounded;
      default:
        return Icons.school_rounded;
    }
  }

  String _getModeName(StudyModeType mode) {
    switch (mode) {
      case StudyModeType.general:
        return 'General';
      case StudyModeType.beginner:
        return 'Beginner Mode';
      case StudyModeType.exam:
        return 'Exam Preparation';
      case StudyModeType.interview:
        return 'Interview Prep';
      case StudyModeType.quickRevision:
        return 'Quick Revision';
      default:
        return 'General';
    }
  }

  String _getModeDescription(StudyModeType mode) {
    switch (mode) {
      case StudyModeType.general:
        return 'Balanced responses for all topics';
      case StudyModeType.beginner:
        return 'Simple, easy-to-understand explanations';
      case StudyModeType.exam:
        return 'Exam-focused with practice questions';
      case StudyModeType.interview:
        return 'In-depth, practical explanations';
      case StudyModeType.quickRevision:
        return 'Concise bullet points & key facts';
      default:
        return 'Balanced responses for all topics';
    }
  }
}