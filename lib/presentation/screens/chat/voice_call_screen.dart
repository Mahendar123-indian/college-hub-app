import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';

import '../../../core/constants/color_constants.dart';

/// ═══════════════════════════════════════════════════════════════
/// FULLY DYNAMIC VOICE CALL SCREEN - REAL-TIME FIRESTORE DATA
/// ═══════════════════════════════════════════════════════════════
/// Features:
/// ✅ Real-time user data sync from Firestore
/// ✅ Live online status tracking
/// ✅ Dynamic profile updates during call
/// ✅ Proper error handling
/// ✅ Beautiful animations
/// ✅ Call duration tracking
/// ═══════════════════════════════════════════════════════════════

class VoiceCallScreen extends StatefulWidget {
  final String calleeId;
  final String calleeName;
  final String? calleePhoto;
  final bool isIncoming;

  const VoiceCallScreen({
    Key? key,
    required this.calleeId,
    required this.calleeName,
    this.calleePhoto,
    this.isIncoming = false,
  }) : super(key: key);

  @override
  State<VoiceCallScreen> createState() => _VoiceCallScreenState();
}

class _VoiceCallScreenState extends State<VoiceCallScreen>
    with TickerProviderStateMixin {

  // Call state
  bool _isConnected = false;
  bool _isMuted = false;
  bool _isSpeakerOn = false;
  int _callDuration = 0;

  // Real-time user data
  Map<String, dynamic>? _calleeData;
  String _calleeStatus = 'Connecting...';
  bool _calleeIsOnline = false;
  bool _isLoadingUserData = true;

  Timer? _callTimer;
  StreamSubscription? _userDataSubscription;

  late AnimationController _pulseController;
  late AnimationController _rotationController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _listenToCalleeData();
    _startCall();
  }

  void _initializeAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat();

    _rotationController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );

    _rotationAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      _rotationController,
    );
  }

  /// ✅ REAL-TIME USER DATA LISTENER
  void _listenToCalleeData() {
    _userDataSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.calleeId)
        .snapshots()
        .listen(
          (snapshot) {
        if (snapshot.exists && mounted) {
          setState(() {
            _calleeData = snapshot.data();
            _isLoadingUserData = false;

            // Check online status
            final lastActive = _calleeData?['lastActive'] as Timestamp?;
            if (lastActive != null) {
              final lastActiveDate = lastActive.toDate();
              final difference = DateTime.now().difference(lastActiveDate);
              _calleeIsOnline = difference.inMinutes < 2;
            }

            // Update status based on connection
            if (_isConnected) {
              _calleeStatus = 'Connected';
            } else {
              _calleeStatus = _calleeIsOnline ? 'Calling...' : 'User Offline';
            }
          });
        }
      },
      onError: (error) {
        debugPrint('❌ Error listening to user data: $error');
        if (mounted) {
          setState(() {
            _isLoadingUserData = false;
            _calleeStatus = 'Connection Error';
          });
        }
      },
    );
  }

  void _startCall() {
    // Simulate connection delay
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _isConnected = true;
          _calleeStatus = 'Connected';
        });
        _startCallTimer();
      }
    });
  }

  void _startCallTimer() {
    _callTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() => _callDuration++);
      }
    });
  }

  @override
  void dispose() {
    _callTimer?.cancel();
    _userDataSubscription?.cancel();
    _pulseController.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  String _formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  void _endCall() {
    HapticFeedback.heavyImpact();
    Navigator.pop(context);
  }

  /// ✅ DYNAMIC DATA GETTERS - REAL-TIME UPDATES
  String get _displayName => _calleeData?['name'] ?? widget.calleeName;
  String? get _displayPhoto => _calleeData?['photoUrl'] ?? widget.calleePhoto;
  String get _displayRole => _calleeData?['role'] == 'admin' ? 'Admin' : 'Student';

  @override
  Widget build(BuildContext context) {
    if (_isLoadingUserData) {
      return _buildLoadingScreen();
    }

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primaryColor,
              AppColors.primaryColor.withValues(alpha: 0.8),
              const Color(0xFF8B5CF6),
              const Color(0xFFEC4899),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildTopBar(),
              const Spacer(),
              _buildCallerInfo(),
              const Spacer(),
              _buildControls(),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primaryColor,
              AppColors.primaryColor.withValues(alpha: 0.8),
              const Color(0xFF8B5CF6),
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 3,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Loading call...',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _isConnected ? _formatDuration(_callDuration) : _calleeStatus,
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              if (_calleeData?['college'] != null) ...[
                const SizedBox(height: 4),
                Text(
                  _calleeData!['college'],
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: _isConnected
                  ? Colors.green.withValues(alpha: 0.3)
                  : _calleeIsOnline
                  ? Colors.orange.withValues(alpha: 0.3)
                  : Colors.red.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _isConnected
                        ? Colors.green
                        : _calleeIsOnline
                        ? Colors.orange
                        : Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _isConnected
                      ? 'Connected'
                      : _calleeIsOnline
                      ? 'Calling'
                      : 'Offline',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCallerInfo() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Animated Avatar with pulse rings
        Stack(
          alignment: Alignment.center,
          children: [
            // Outer pulse rings
            for (var i = 0; i < 3; i++)
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  final delay = i * 0.2;
                  final animation = Tween<double>(
                    begin: 1.0,
                    end: 1.5 + (i * 0.3),
                  ).animate(
                    CurvedAnimation(
                      parent: _pulseController,
                      curve: Interval(
                        delay,
                        1.0,
                        curve: Curves.easeOut,
                      ),
                    ),
                  );

                  return Transform.scale(
                    scale: animation.value,
                    child: Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(
                            alpha: (1.0 - animation.value + 1.0) * 0.3,
                          ),
                          width: 2,
                        ),
                      ),
                    ),
                  );
                },
              ),

            // Avatar with rotation
            ScaleTransition(
              scale: _pulseAnimation,
              child: RotationTransition(
                turns: _rotationAnimation,
                child: Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withValues(alpha: 0.3),
                        Colors.white.withValues(alpha: 0.1),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 30,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Container(
                    margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                    ),
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 70,
                          backgroundColor: Colors.white.withValues(alpha: 0.2),
                          backgroundImage: _displayPhoto != null && _displayPhoto!.isNotEmpty
                              ? CachedNetworkImageProvider(_displayPhoto!)
                              : null,
                          child: _displayPhoto == null || _displayPhoto!.isEmpty
                              ? Text(
                            _displayName[0].toUpperCase(),
                            style: GoogleFonts.poppins(
                              fontSize: 64,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          )
                              : null,
                        ),
                        // Online indicator
                        if (_calleeIsOnline)
                          Positioned(
                            bottom: 5,
                            right: 5,
                            child: Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                color: Colors.green,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 3),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 40),

        // Caller name
        Text(
          _displayName,
          style: GoogleFonts.poppins(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 8),

        // Role badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _calleeData?['role'] == 'admin'
                    ? Icons.admin_panel_settings
                    : Icons.school,
                size: 16,
                color: Colors.white,
              ),
              const SizedBox(width: 8),
              Text(
                _displayRole,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Call status
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            _isConnected ? 'Voice Call' : _calleeStatus,
            style: GoogleFonts.inter(
              fontSize: 16,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildControls() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildControlButton(
              icon: _isMuted ? Icons.mic_off : Icons.mic,
              label: _isMuted ? 'Unmute' : 'Mute',
              isActive: !_isMuted,
              onTap: () {
                setState(() => _isMuted = !_isMuted);
                HapticFeedback.lightImpact();
              },
            ),
            const SizedBox(width: 40),
            _buildControlButton(
              icon: _isSpeakerOn ? Icons.volume_up : Icons.volume_off,
              label: 'Speaker',
              isActive: _isSpeakerOn,
              onTap: () {
                setState(() => _isSpeakerOn = !_isSpeakerOn);
                HapticFeedback.lightImpact();
              },
            ),
          ],
        ),

        const SizedBox(height: 40),

        // End call button
        GestureDetector(
          onTap: _endCall,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.red,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.red.withValues(alpha: 0.5),
                  blurRadius: 30,
                  spreadRadius: 10,
                ),
              ],
            ),
            child: const Icon(
              Icons.call_end_rounded,
              color: Colors.white,
              size: 36,
            ),
          ),
        ),

        const SizedBox(height: 16),

        Text(
          'End Call',
          style: GoogleFonts.inter(
            fontSize: 16,
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isActive
                  ? Colors.white.withValues(alpha: 0.3)
                  : Colors.white.withValues(alpha: 0.1),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.5),
                width: 2,
              ),
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}