import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../providers/smart_learning_provider.dart';

class DistractionFreeModeScreen extends StatefulWidget {
  final String? resourceId;
  const DistractionFreeModeScreen({super.key, this.resourceId});

  @override
  State<DistractionFreeModeScreen> createState() => _DistractionFreeModeScreenState();
}

class _DistractionFreeModeScreenState extends State<DistractionFreeModeScreen>
    with TickerProviderStateMixin {
  bool _isFocusMode = false;
  Timer? _sessionTimer;
  int _elapsedSeconds = 0;
  final _notesController = TextEditingController();
  final _subjectController = TextEditingController();
  final _newAppController = TextEditingController();
  final List<Map<String, dynamic>> _blockedApps = [];
  bool _showNotes = false;
  bool _isPaused = false;
  int _totalPauseTime = 0;
  DateTime? _pauseStartTime;

  // Animation controllers
  late AnimationController _pulseController;
  late AnimationController _breatheController;
  late AnimationController _shimmerController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _breatheAnimation;

  // Focus metrics
  int _distractionCount = 0;
  List<Map<String, dynamic>> _sessionNotes = [];
  double _focusScore = 100.0;

  // Ambient features
  bool _ambientSoundsEnabled = false;
  String _selectedAmbientSound = 'None';
  final List<String> _ambientSounds = ['None', 'Rain', 'Ocean', 'Forest', 'Cafe', 'White Noise'];

  // Break reminders
  bool _breakRemindersEnabled = true;
  int _breakInterval = 25; // minutes
  Timer? _breakReminderTimer;

  // Performance tracking
  Map<String, dynamic> _sessionStats = {
    'startTime': null,
    'effectiveFocusTime': 0,
    'averageHeartRate': 0,
    'peakFocusTime': '',
  };

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadBlockedApps();
    _initializeSessionStats();
  }

  void _initializeAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _breatheController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat(reverse: true);

    _shimmerController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _breatheAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _breatheController, curve: Curves.easeInOut),
    );
  }

  void _initializeSessionStats() {
    _sessionStats = {
      'startTime': DateTime.now(),
      'effectiveFocusTime': 0,
      'distractions': 0,
      'notesCreated': 0,
      'peakFocusTime': '',
    };
  }

  void _loadBlockedApps() {
    final defaultApps = [
      {'name': 'Instagram', 'icon': Icons.photo_camera, 'color': Colors.purple},
      {'name': 'Facebook', 'icon': Icons.facebook, 'color': Colors.blue},
      {'name': 'Twitter', 'icon': Icons.message, 'color': Colors.lightBlue},
      {'name': 'YouTube', 'icon': Icons.play_circle, 'color': Colors.red},
      {'name': 'WhatsApp', 'icon': Icons.chat, 'color': Colors.green},
      {'name': 'TikTok', 'icon': Icons.music_note, 'color': Colors.black},
    ];
    setState(() => _blockedApps.addAll(defaultApps));
  }

  @override
  void dispose() {
    _sessionTimer?.cancel();
    _breakReminderTimer?.cancel();
    _notesController.dispose();
    _subjectController.dispose();
    _newAppController.dispose();
    _pulseController.dispose();
    _breatheController.dispose();
    _shimmerController.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  void _startFocusMode() {
    if (_subjectController.text.isEmpty) {
      _showSnackBar('Please enter a subject to begin', Colors.orange);
      return;
    }

    setState(() {
      _isFocusMode = true;
      _isPaused = false;
      _elapsedSeconds = 0;
      _distractionCount = 0;
      _focusScore = 100.0;
      _sessionNotes.clear();
      _initializeSessionStats();
    });

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    HapticFeedback.mediumImpact();

    context.read<SmartLearningProvider>().startStudySession(
      _subjectController.text,
    );

    _sessionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isPaused) {
        setState(() {
          _elapsedSeconds++;
          _updateFocusScore();
        });
      }
    });

    if (_breakRemindersEnabled) {
      _startBreakReminders();
    }

    _showSnackBar('Focus Mode Activated', Colors.green);
  }

  void _updateFocusScore() {
    // Dynamic focus score calculation
    final distractionPenalty = _distractionCount * 2.0;
    final pausePenalty = (_totalPauseTime / 60) * 0.5;
    _focusScore = math.max(0, 100 - distractionPenalty - pausePenalty);
  }

  void _togglePause() {
    setState(() {
      _isPaused = !_isPaused;
      if (_isPaused) {
        _pauseStartTime = DateTime.now();
        _distractionCount++;
      } else {
        if (_pauseStartTime != null) {
          _totalPauseTime += DateTime.now().difference(_pauseStartTime!).inSeconds;
        }
      }
    });
    HapticFeedback.lightImpact();
  }

  void _startBreakReminders() {
    _breakReminderTimer = Timer.periodic(
      Duration(minutes: _breakInterval),
          (timer) {
        if (_isFocusMode && !_isPaused) {
          _showBreakReminder();
        }
      },
    );
  }

  void _showBreakReminder() {
    HapticFeedback.heavyImpact();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Icon(Icons.free_breakfast, color: Colors.orange.shade600, size: 28),
            const SizedBox(width: 12),
            const Text('Time for a Break!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'You\'ve been focused for $_breakInterval minutes.',
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              'Take a 5-minute break to recharge.',
              style: TextStyle(fontSize: 14, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Continue'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _togglePause();
            },
            child: const Text('Take Break'),
          ),
        ],
      ),
    );
  }

  void _endFocusMode() {
    _sessionTimer?.cancel();
    _breakReminderTimer?.cancel();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    final effectiveFocusTime = _elapsedSeconds - _totalPauseTime;

    context.read<SmartLearningProvider>().endStudySession(
      focusScore: _focusScore.toInt(),
      notes: _sessionNotes.isNotEmpty
          ? {'notes': _sessionNotes, 'count': _sessionNotes.length}
          : null,
    );

    HapticFeedback.heavyImpact();

    _showSessionSummary(effectiveFocusTime);

    setState(() {
      _isFocusMode = false;
      _elapsedSeconds = 0;
      _totalPauseTime = 0;
      _isPaused = false;
    });
  }

  void _showSessionSummary(int effectiveTime) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.purple.shade50, Colors.blue.shade50],
            ),
            borderRadius: BorderRadius.circular(28),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.purple.withOpacity(0.3),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Icon(
                  Icons.emoji_events,
                  color: Colors.amber.shade600,
                  size: 48,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Session Complete!',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple,
                ),
              ),
              const SizedBox(height: 24),
              _buildStatCard('Total Time', _formatTime(_elapsedSeconds), Icons.timer),
              const SizedBox(height: 12),
              _buildStatCard('Effective Focus', _formatTime(effectiveTime), Icons.psychology),
              const SizedBox(height: 12),
              _buildStatCard('Focus Score', '${_focusScore.toStringAsFixed(1)}%', Icons.stars),
              const SizedBox(height: 12),
              _buildStatCard('Notes Created', '${_sessionNotes.length}', Icons.note),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _getFocusScoreColor().withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _getFocusScoreColor().withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(_getFocusScoreIcon(), color: _getFocusScoreColor()),
                    const SizedBox(width: 8),
                    Text(
                      _getFocusScoreMessage(),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _getFocusScoreColor(),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pop(context);
                  },
                  child: const Text(
                    'Done',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.deepPurple, size: 24),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.deepPurple,
            ),
          ),
        ],
      ),
    );
  }

  Color _getFocusScoreColor() {
    if (_focusScore >= 90) return Colors.green;
    if (_focusScore >= 70) return Colors.orange;
    return Colors.red;
  }

  IconData _getFocusScoreIcon() {
    if (_focusScore >= 90) return Icons.star;
    if (_focusScore >= 70) return Icons.thumb_up;
    return Icons.info;
  }

  String _getFocusScoreMessage() {
    if (_focusScore >= 90) return 'Outstanding Focus!';
    if (_focusScore >= 70) return 'Good Work!';
    return 'Room for Improvement';
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _addNewApp() {
    if (_newAppController.text.isNotEmpty) {
      setState(() {
        _blockedApps.add({
          'name': _newAppController.text,
          'icon': Icons.apps,
          'color': Colors.primaries[_blockedApps.length % Colors.primaries.length],
        });
        _newAppController.clear();
      });
      Navigator.pop(context);
      HapticFeedback.mediumImpact();
    }
  }

  void _saveQuickNote() {
    if (_notesController.text.isNotEmpty) {
      setState(() {
        _sessionNotes.add({
          'content': _notesController.text,
          'timestamp': DateTime.now(),
          'timeInSession': _elapsedSeconds,
        });
        _notesController.clear();
        _showNotes = false;
      });
      _showSnackBar('Note saved successfully', Colors.green);
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_isFocusMode) {
          final shouldExit = await _showExitConfirmation();
          return shouldExit ?? false;
        }
        return true;
      },
      child: _isFocusMode ? _buildFocusModeView() : _buildSetupView(),
    );
  }

  Future<bool?> _showExitConfirmation() {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Exit Focus Mode?'),
        content: const Text('Are you sure you want to end your focus session?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context, true);
              _endFocusMode();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Exit'),
          ),
        ],
      ),
    );
  }

  Widget _buildSetupView() {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.deepPurple.shade700,
              Colors.deepPurple.shade900,
              Colors.black,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildSetupHeader(),
              Expanded(child: _buildSetupContent()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSetupHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShaderMask(
                  shaderCallback: (bounds) => LinearGradient(
                    colors: [Colors.white, Colors.purple.shade200],
                  ).createShader(bounds),
                  child: const Text(
                    'Focus Mode',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Text(
                  'Eliminate distractions, maximize productivity',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
          AnimatedBuilder(
            animation: _breatheAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _breatheAnimation.value,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.purple.shade300, Colors.blue.shade300],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.purple.withOpacity(0.5),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.visibility_off, color: Colors.white, size: 32),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSetupContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFeatureCardsGrid(),
          const SizedBox(height: 32),
          _buildSessionSetupCard(),
          const SizedBox(height: 20),
          _buildAdvancedSettings(),
        ],
      ),
    );
  }

  Widget _buildFeatureCardsGrid() {
    final features = [
      {
        'title': 'Immersive Mode',
        'desc': 'Full screen experience',
        'icon': Icons.fullscreen,
        'color': Colors.blue.shade400
      },
      {
        'title': 'Smart Timer',
        'desc': 'Track your focus streak',
        'icon': Icons.timer,
        'color': Colors.green.shade400
      },
      {
        'title': 'Quick Notes',
        'desc': 'Capture ideas instantly',
        'icon': Icons.note_add,
        'color': Colors.orange.shade400
      },
      {
        'title': 'Break Alerts',
        'desc': 'Stay refreshed',
        'icon': Icons.notifications_active,
        'color': Colors.purple.shade400
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.3, // Increased from 1.2 to give more space
      ),
      itemCount: features.length,
      itemBuilder: (context, index) {
        final feature = features[index];
        return _buildAnimatedFeatureCard(
          feature['title'] as String,
          feature['desc'] as String,
          feature['icon'] as IconData,
          feature['color'] as Color,
          index,
        );
      },
    );
  }

  Widget _buildAnimatedFeatureCard(
      String title,
      String description,
      IconData icon,
      Color color,
      int index,
      ) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 500 + (index * 100)),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Opacity(
            opacity: value,
            child: Container(
              padding: const EdgeInsets.all(16), // Reduced from 20
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    color.withOpacity(0.2),
                    color.withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: color.withOpacity(0.3), width: 2),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.2),
                    blurRadius: 15,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                mainAxisSize: MainAxisSize.min, // Added to prevent overflow
                children: [
                  Container(
                    padding: const EdgeInsets.all(10), // Reduced from 12
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: color, size: 24), // Reduced from 28
                  ),
                  const SizedBox(height: 8), // Added spacing
                  Flexible( // Wrapped in Flexible to prevent overflow
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15, // Reduced from 16
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          description,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 11, // Reduced from 12
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSessionSetupCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withOpacity(0.3),
            blurRadius: 30,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.purple.shade400, Colors.blue.shade400],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.settings, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              const Text(
                'Session Setup',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _subjectController,
            style: const TextStyle(fontSize: 16),
            decoration: InputDecoration(
              labelText: 'What are you studying? *',
              labelStyle: TextStyle(color: Colors.purple.shade700),
              prefixIcon: Icon(Icons.school, color: Colors.purple.shade700),
              filled: true,
              fillColor: Colors.purple.shade50,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.purple.shade700, width: 2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              const Text(
                'Blocked Apps',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: _showAddAppDialog,
                icon: const Icon(Icons.add_circle, size: 20),
                label: const Text('Add App'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.purple.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _blockedApps.isEmpty
              ? Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Text(
                'No apps blocked yet',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          )
              : Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _blockedApps.map((app) => _buildAppChip(app)).toList(),
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                foregroundColor: Colors.white,
                elevation: 0,
                shadowColor: Colors.transparent,
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: _startFocusMode,
              child: Ink(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.purple.shade700, Colors.deepPurple.shade900],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.purple.withOpacity(0.5),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Container(
                  alignment: Alignment.center,
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.rocket_launch, size: 28),
                      SizedBox(width: 12),
                      Text(
                        'Start Focus Mode',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppChip(Map<String, dynamic> app) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      child: Chip(
        avatar: CircleAvatar(
          backgroundColor: app['color'].withOpacity(0.2),
          child: Icon(app['icon'], size: 18, color: app['color']),
        ),
        label: Text(
          app['name'],
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        deleteIcon: const Icon(Icons.close, size: 18),
        onDeleted: () {
          setState(() => _blockedApps.remove(app));
          HapticFeedback.lightImpact();
        },
        backgroundColor: app['color'].withOpacity(0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: app['color'].withOpacity(0.3)),
        ),
      ),
    );
  }

  void _showAddAppDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Add App to Block'),
        content: TextField(
          controller: _newAppController,
          autofocus: true,
          decoration: InputDecoration(
            labelText: 'App Name',
            prefixIcon: const Icon(Icons.apps),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onSubmitted: (_) => _addNewApp(),
        ),
        actions: [
          TextButton(
            onPressed: () {
              _newAppController.clear();
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: _addNewApp,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple.shade700,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Widget _buildAdvancedSettings() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.tune, color: Colors.white, size: 24),
              SizedBox(width: 12),
              Text(
                'Advanced Settings',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildSettingsTile(
            'Break Reminders',
            'Get notified to take breaks',
            Icons.access_time,
            _breakRemindersEnabled,
                (value) => setState(() => _breakRemindersEnabled = value),
          ),
          const SizedBox(height: 16),
          _buildSettingsTile(
            'Ambient Sounds',
            'Background focus music',
            Icons.music_note,
            _ambientSoundsEnabled,
                (value) => setState(() => _ambientSoundsEnabled = value),
          ),
          if (_breakRemindersEnabled) ...[
            const SizedBox(height: 16),
            _buildBreakIntervalSelector(),
          ],
          if (_ambientSoundsEnabled) ...[
            const SizedBox(height: 16),
            _buildAmbientSoundSelector(),
          ],
        ],
      ),
    );
  }

  Widget _buildSettingsTile(
      String title,
      String subtitle,
      IconData icon,
      bool value,
      Function(bool) onChanged,
      ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: Colors.purple.shade400,
          ),
        ],
      ),
    );
  }

  Widget _buildBreakIntervalSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Break Interval: $_breakInterval minutes',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Slider(
            value: _breakInterval.toDouble(),
            min: 15,
            max: 60,
            divisions: 9,
            activeColor: Colors.purple.shade400,
            inactiveColor: Colors.white.withOpacity(0.2),
            label: '$_breakInterval min',
            onChanged: (value) => setState(() => _breakInterval = value.toInt()),
          ),
        ],
      ),
    );
  }

  Widget _buildAmbientSoundSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Select Sound',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _ambientSounds.map((sound) {
              final isSelected = _selectedAmbientSound == sound;
              return GestureDetector(
                onTap: () {
                  setState(() => _selectedAmbientSound = sound);
                  HapticFeedback.selectionClick();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.purple.shade400
                        : Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? Colors.purple.shade400
                          : Colors.white.withOpacity(0.2),
                    ),
                  ),
                  child: Text(
                    sound,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.white70,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFocusModeView() {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            _buildAnimatedBackground(),
            _buildFocusModeContent(),
            if (_showNotes) _buildNotesOverlay(),
            if (_isPaused) _buildPauseOverlay(),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedBackground() {
    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.black,
                Colors.deepPurple.shade900.withOpacity(0.3),
                Colors.black,
              ],
              stops: [
                0.0,
                _shimmerController.value,
                1.0,
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFocusModeContent() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _pulseAnimation.value,
                child: Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        Colors.purple.withOpacity(0.3),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Icon(
                    _isPaused ? Icons.pause_circle : Icons.visibility_off,
                    color: Colors.white38,
                    size: 100,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 40),
          ShaderMask(
            shaderCallback: (bounds) => LinearGradient(
              colors: [Colors.white, Colors.purple.shade200],
            ).createShader(bounds),
            child: const Text(
              'FOCUS MODE',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
                letterSpacing: 6,
              ),
            ),
          ),
          const SizedBox(height: 24),
          TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 500),
            tween: Tween(begin: 0.0, end: 1.0),
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Text(
                  _formatTime(_elapsedSeconds),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 72,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(
                        color: Colors.purple.withOpacity(0.5),
                        blurRadius: 30,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: Text(
              _subjectController.text,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 20,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 32),
          _buildFocusScoreIndicator(),
          const SizedBox(height: 60),
          _buildFocusModeControls(),
        ],
      ),
    );
  }

  Widget _buildFocusScoreIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: _getFocusScoreColor().withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _getFocusScoreColor().withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.psychology, color: _getFocusScoreColor(), size: 20),
          const SizedBox(width: 8),
          Text(
            'Focus Score: ${_focusScore.toStringAsFixed(0)}%',
            style: TextStyle(
              color: _getFocusScoreColor(),
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFocusModeControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildFocusButton(
          Icons.note_add,
          'Quick Note',
              () {
            setState(() => _showNotes = true);
            HapticFeedback.mediumImpact();
          },
          Colors.orange.shade400,
        ),
        const SizedBox(width: 24),
        _buildFocusButton(
          _isPaused ? Icons.play_arrow : Icons.pause,
          _isPaused ? 'Resume' : 'Pause',
          _togglePause,
          Colors.blue.shade400,
        ),
        const SizedBox(width: 24),
        _buildFocusButton(
          Icons.stop_circle,
          'End Session',
          _endFocusMode,
          Colors.red.shade400,
        ),
      ],
    );
  }

  Widget _buildFocusButton(
      IconData icon,
      String label,
      VoidCallback onPressed,
      Color color,
      ) {
    return Column(
      children: [
        GestureDetector(
          onTap: onPressed,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [
                  color.withOpacity(0.4),
                  color.withOpacity(0.2),
                ],
              ),
              shape: BoxShape.circle,
              border: Border.all(color: color.withOpacity(0.5), width: 2),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 32),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildPauseOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.8),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.pause_circle, color: Colors.white, size: 100),
            const SizedBox(height: 24),
            const Text(
              'Session Paused',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Paused for ${_formatTime(DateTime.now().difference(_pauseStartTime ?? DateTime.now()).inSeconds)}',
              style: const TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              onPressed: _togglePause,
              icon: const Icon(Icons.play_arrow),
              label: const Text('Resume Session'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple.shade600,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotesOverlay() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withOpacity(0.95),
            Colors.deepPurple.shade900.withOpacity(0.95),
          ],
        ),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.note_add, color: Colors.white, size: 28),
                  SizedBox(width: 12),
                  Text(
                    'Quick Notes',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 28),
                onPressed: () => setState(() => _showNotes = false),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: TextField(
                controller: _notesController,
                maxLines: null,
                autofocus: true,
                style: const TextStyle(color: Colors.white, fontSize: 16),
                decoration: const InputDecoration(
                  hintText: 'Capture your thoughts...',
                  hintStyle: TextStyle(color: Colors.white38, fontSize: 16),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          if (_sessionNotes.isNotEmpty) ...[
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Previous Notes',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _sessionNotes.length,
                itemBuilder: (context, index) {
                  final note = _sessionNotes[index];
                  return Container(
                    width: 200,
                    margin: const EdgeInsets.only(right: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withOpacity(0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          note['content'],
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white, fontSize: 12),
                        ),
                        const Spacer(),
                        Text(
                          _formatTime(note['timeInSession']),
                          style: const TextStyle(color: Colors.white54, fontSize: 10),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
          ],
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: _saveQuickNote,
              icon: const Icon(Icons.save, size: 24),
              label: const Text(
                'Save Note',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple.shade600,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    if (h > 0) {
      return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
}