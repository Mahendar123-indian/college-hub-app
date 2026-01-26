import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';

import '../../../core/constants/color_constants.dart';

/// ═══════════════════════════════════════════════════════════════
/// FULLY DYNAMIC VIDEO CALL SCREEN - REAL-TIME FIRESTORE DATA
/// ═══════════════════════════════════════════════════════════════

class VideoCallScreen extends StatefulWidget {
  final String calleeId;
  final String calleeName;
  final String? calleePhoto;
  final bool isIncoming;

  const VideoCallScreen({
    Key? key,
    required this.calleeId,
    required this.calleeName,
    this.calleePhoto,
    this.isIncoming = false,
  }) : super(key: key);

  @override
  State<VideoCallScreen> createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends State<VideoCallScreen>
    with TickerProviderStateMixin {

  // Call state
  bool _isConnected = false;
  bool _isMuted = false;
  bool _isVideoEnabled = true;
  bool _isFrontCamera = true;
  bool _isSpeakerOn = true;
  bool _showControls = true;
  int _callDuration = 0;

  // Real-time user data
  Map<String, dynamic>? _calleeData;
  String _calleeStatus = 'Connecting...';
  bool _calleeIsOnline = false;

  Timer? _callTimer;
  Timer? _controlsTimer;
  StreamSubscription? _userDataSubscription;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _initializeAnimations();
    _listenToCalleeData();
    _startCall();
    _hideControlsAfterDelay();
  }

  void _initializeAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  void _listenToCalleeData() {
    _userDataSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.calleeId)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists && mounted) {
        setState(() {
          _calleeData = snapshot.data();

          final lastActive = _calleeData?['lastActive'] as Timestamp?;
          if (lastActive != null) {
            final lastActiveDate = lastActive.toDate();
            final difference = DateTime.now().difference(lastActiveDate);
            _calleeIsOnline = difference.inMinutes < 2;
          }

          if (_isConnected) {
            _calleeStatus = _calleeIsOnline ? 'Connected' : 'Connecting...';
          }
        });
      }
    });
  }

  void _startCall() {
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _isConnected = true;
          _calleeStatus = _calleeIsOnline ? 'Connected' : 'No Answer';
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

  void _hideControlsAfterDelay() {
    _controlsTimer?.cancel();
    _controlsTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && _showControls) {
        setState(() => _showControls = false);
      }
    });
  }

  void _toggleControls() {
    setState(() => _showControls = !_showControls);
    if (_showControls) {
      _hideControlsAfterDelay();
    }
  }

  @override
  void dispose() {
    _callTimer?.cancel();
    _controlsTimer?.cancel();
    _userDataSubscription?.cancel();
    _pulseController.dispose();
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );
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
    Navigator.pop(context);
  }

  String get _displayName => _calleeData?['name'] ?? widget.calleeName;
  String? get _displayPhoto => _calleeData?['photoUrl'] ?? widget.calleePhoto;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: _toggleControls,
        child: Stack(
          children: [
            _buildRemoteVideo(),
            if (_isVideoEnabled) _buildLocalVideo(),
            if (!_isConnected) _buildConnectingOverlay(),
            if (_showControls) _buildControlsOverlay(),
          ],
        ),
      ),
    );
  }

  Widget _buildRemoteVideo() {
    return SizedBox.expand(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withValues(alpha: 0.8),
              Colors.black.withValues(alpha: 0.3),
              Colors.black.withValues(alpha: 0.8),
            ],
          ),
        ),
        child: Center(
          child: _isConnected
              ? Image.network(
            'https://picsum.photos/800/1200?random=${widget.calleeId}',
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            errorBuilder: (context, error, stackTrace) => _buildAvatarFallback(),
          )
              : _buildAvatarFallback(),
        ),
      ),
    );
  }

  Widget _buildAvatarFallback() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: CircleAvatar(
            radius: 60,
            backgroundColor: AppColors.primaryColor.withValues(alpha: 0.2),
            backgroundImage: _displayPhoto != null && _displayPhoto!.isNotEmpty
                ? CachedNetworkImageProvider(_displayPhoto!)
                : null,
            child: _displayPhoto == null || _displayPhoto!.isEmpty
                ? Text(
              _displayName[0].toUpperCase(),
              style: GoogleFonts.poppins(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            )
                : null,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          _displayName,
          style: GoogleFonts.poppins(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            _calleeStatus,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLocalVideo() {
    return Positioned(
      top: 60,
      right: 20,
      child: GestureDetector(
        onTap: () {
          // Switch to full screen
        },
        child: Container(
          width: 120,
          height: 160,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Image.network(
              'https://picsum.photos/200/300?random=self',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                color: Colors.grey.shade800,
                child: const Icon(Icons.person, color: Colors.white, size: 40),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildConnectingOverlay() {
    return Container(
      color: Colors.black.withValues(alpha: 0.8),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ScaleTransition(
              scale: _pulseAnimation,
              child: Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryColor.withValues(alpha: 0.5),
                      blurRadius: 30,
                      spreadRadius: 10,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.videocam_rounded,
                  size: 60,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Connecting...',
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _calleeIsOnline ? 'User is online' : 'Waiting for response',
              style: GoogleFonts.inter(
                fontSize: 16,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlsOverlay() {
    return Column(
      children: [
        SafeArea(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.7),
                  Colors.transparent,
                ],
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _displayName,
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if (_calleeIsOnline)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Colors.green,
                                shape: BoxShape.circle,
                              ),
                              margin: const EdgeInsets.only(right: 6),
                            ),
                          Text(
                            _isConnected ? _formatDuration(_callDuration) : _calleeStatus,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: _isConnected && _calleeIsOnline ? Colors.green : Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(
                    _isFrontCamera ? Icons.camera_front : Icons.camera_rear,
                    color: Colors.white,
                  ),
                  onPressed: () {
                    setState(() => _isFrontCamera = !_isFrontCamera);
                    HapticFeedback.lightImpact();
                  },
                ),
              ],
            ),
          ),
        ),
        const Spacer(),
        SafeArea(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.9),
                  Colors.transparent,
                ],
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
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
                    _buildControlButton(
                      icon: _isVideoEnabled ? Icons.videocam : Icons.videocam_off,
                      label: _isVideoEnabled ? 'Stop Video' : 'Start Video',
                      isActive: _isVideoEnabled,
                      onTap: () {
                        setState(() => _isVideoEnabled = !_isVideoEnabled);
                        HapticFeedback.lightImpact();
                      },
                    ),
                    _buildControlButton(
                      icon: _isSpeakerOn ? Icons.volume_up : Icons.volume_off,
                      label: _isSpeakerOn ? 'Speaker On' : 'Speaker Off',
                      isActive: _isSpeakerOn,
                      onTap: () {
                        setState(() => _isSpeakerOn = !_isSpeakerOn);
                        HapticFeedback.lightImpact();
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                GestureDetector(
                  onTap: () {
                    HapticFeedback.heavyImpact();
                    _endCall();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red.withValues(alpha: 0.5),
                          blurRadius: 20,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.call_end_rounded, color: Colors.white, size: 28),
                        const SizedBox(width: 12),
                        Text(
                          'End Call',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
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
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isActive
                  ? Colors.white.withValues(alpha: 0.2)
                  : Colors.red.withValues(alpha: 0.3),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.3),
                width: 2,
              ),
            ),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.inter(fontSize: 12, color: Colors.white),
          ),
        ],
      ),
    );
  }
}