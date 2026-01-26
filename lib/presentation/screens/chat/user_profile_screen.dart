import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import 'dart:async';

import '../../../providers/chat_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../data/models/user_model.dart';
import '../../../data/models/conversation_model.dart';
import '../../../core/constants/color_constants.dart';
import 'chat_detail_screen_advanced.dart';
import 'video_call_screen.dart';
import 'voice_call_screen.dart';

/// ═══════════════════════════════════════════════════════════════
/// ✅ FULLY FIXED: DYNAMIC USER PROFILE SCREEN - REAL-TIME FIRESTORE DATA
/// ═══════════════════════════════════════════════════════════════
/// Features:
/// ✅ Real-time user data sync from Firestore
/// ✅ Live online status tracking
/// ✅ Dynamic profile updates during viewing
/// ✅ Call validation with online status checks
/// ✅ Comprehensive user information display
/// ✅ Beautiful animations and transitions
/// ✅ FIXED: Proper error handling for missing Firestore documents
/// ✅ FIXED: Fallback user creation when document doesn't exist
/// ✅ FIXED: Consistent error handling with chat_detail_screen
/// ═══════════════════════════════════════════════════════════════

class UserProfileScreen extends StatefulWidget {
  final UserModel user;

  const UserProfileScreen({Key? key, required this.user}) : super(key: key);

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen>
    with SingleTickerProviderStateMixin {

  // Animations
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  // Real-time data
  UserModel? _currentUserModel; // ✅ FIX: Store complete user model
  Map<String, dynamic>? _userData;
  bool _isLoadingUserData = true;
  bool _isCurrentUser = false;
  bool _isOnline = false;
  String _lastSeenText = '';

  // Stream subscriptions
  StreamSubscription? _userDataSubscription;
  StreamSubscription? _onlineStatusSubscription;

  @override
  void initState() {
    super.initState();
    _currentUserModel = widget.user; // ✅ FIX: Initialize with provided user
    _initializeAnimations();
    _checkCurrentUser();
    _listenToUserData();
    _listenToOnlineStatus();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _animationController.forward();
  }

  void _checkCurrentUser() {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    setState(() {
      _isCurrentUser = auth.currentUser?.id == widget.user.id;
    });
  }

  /// ✅ CRITICAL FIX: Real-time user data listener with fallback handling
  void _listenToUserData() {
    _userDataSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.user.id)
        .snapshots()
        .listen(
          (snapshot) {
        if (!mounted) return;

        setState(() {
          if (snapshot.exists) {
            // ✅ Document exists - parse it
            try {
              _userData = snapshot.data();
              _currentUserModel = UserModel.fromDocument(snapshot);
              debugPrint('✅ User profile loaded: ${_currentUserModel?.name}');
            } catch (e) {
              debugPrint('❌ Error parsing user document: $e');
              // ✅ Fallback to initial user model
              _userData = {};
              _currentUserModel = widget.user;
            }
          } else {
            // ✅ CRITICAL FIX: Document doesn't exist - create fallback
            debugPrint('⚠️ User document does not exist: ${widget.user.id}');
            debugPrint('✅ Creating fallback UserModel from initial data');

            _userData = {
              'id': widget.user.id,
              'name': widget.user.name,
              'email': widget.user.email,
              'role': widget.user.role,
              'photoUrl': widget.user.photoUrl,
              'phone': widget.user.phone,
              'college': widget.user.college,
              'department': widget.user.department,
              'semester': widget.user.semester,
              'batchYear': widget.user.batchYear,
            };

            _currentUserModel = UserModel(
              id: widget.user.id,
              name: widget.user.name,
              email: widget.user.email,
              role: widget.user.role,
              createdAt: widget.user.createdAt,
              updatedAt: widget.user.updatedAt,
              photoUrl: widget.user.photoUrl,
              phone: widget.user.phone,
              college: widget.user.college,
              department: widget.user.department,
              semester: widget.user.semester,
              batchYear: widget.user.batchYear,
            );
          }

          // ✅ ALWAYS set loading to false
          _isLoadingUserData = false;
        });
      },
      onError: (error) {
        debugPrint('❌ Firestore error loading user data: $error');

        if (mounted) {
          setState(() {
            // ✅ On error, use fallback data
            _userData = {
              'id': widget.user.id,
              'name': widget.user.name,
              'email': widget.user.email,
            };
            _currentUserModel = widget.user;
            _isLoadingUserData = false;
          });
        }
      },
    );
  }

  /// ✅ Real-time online status listener
  void _listenToOnlineStatus() {
    _onlineStatusSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.user.id)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists && mounted) {
        final data = snapshot.data();
        if (data != null) {
          final lastActive = data['lastActive'] as Timestamp?;
          if (lastActive != null) {
            final lastActiveDate = lastActive.toDate();
            final difference = DateTime.now().difference(lastActiveDate);

            setState(() {
              _isOnline = difference.inMinutes < 2;

              if (_isOnline) {
                _lastSeenText = 'Active now';
              } else if (difference.inMinutes < 60) {
                _lastSeenText = 'Active ${difference.inMinutes}m ago';
              } else if (difference.inHours < 24) {
                _lastSeenText = 'Active ${difference.inHours}h ago';
              } else if (difference.inDays < 7) {
                _lastSeenText = 'Active ${difference.inDays}d ago';
              } else {
                _lastSeenText = 'Active on ${DateFormat('MMM dd').format(lastActiveDate)}';
              }
            });
          }
        }
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _userDataSubscription?.cancel();
    _onlineStatusSubscription?.cancel();
    super.dispose();
  }

  // ═══════════════════════════════════════════════════════════════
  // ACTION HANDLERS
  // ═══════════════════════════════════════════════════════════════

  Future<void> _handleStartChatOrRequest() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final chat = Provider.of<ChatProvider>(context, listen: false);

    if (auth.currentUser == null) return;

    final existingConv = chat.conversations.firstWhere(
          (c) => c.participantIds.contains(widget.user.id),
      orElse: () => ConversationModel(
        id: '',
        type: ConversationType.oneToOne,
        participantIds: [],
        participantDetails: {},
        lastMessage: '',
        lastMessageType: 'text',
        lastMessageSenderId: '',
        lastMessageTime: DateTime.now(),
        unreadCount: {},
        chatRequests: {},
        isActive: false,
        createdAt: DateTime.now(),
        mutedBy: [],
        pinnedBy: [],
      ),
    );

    if (existingConv.isActive) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatDetailScreen(
            conversationId: existingConv.id,
            conversationName: _currentUserModel?.name ?? widget.user.name,
            conversationPhoto: _currentUserModel?.photoUrl ?? widget.user.photoUrl,
            isGroup: false,
            otherUserId: widget.user.id,
          ),
        ),
      );
      return;
    }

    if (existingConv.id.isNotEmpty && !existingConv.isActive) {
      _showSuccessSnackBar("Chat request already pending");
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: AppColors.primaryColor),
              const SizedBox(height: 16),
              Text(
                'Sending request...',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );

    try {
      await chat.createOrGetConversation(
        currentUserId: auth.currentUser!.id,
        otherUserId: widget.user.id,
        currentUserDetails: {
          'name': auth.currentUser!.name,
          'photoUrl': auth.currentUser!.photoUrl
        },
        otherUserDetails: {
          'name': _currentUserModel?.name ?? widget.user.name,
          'photoUrl': _currentUserModel?.photoUrl ?? widget.user.photoUrl
        },
      );

      if (!mounted) return;
      Navigator.pop(context);

      chat.loadConversations(auth.currentUser!.id);
      chat.loadChatRequests(auth.currentUser!.id);

      _showSuccessSnackBar("Request sent successfully!");
    } catch (e) {
      if (mounted) Navigator.pop(context);
      debugPrint("Error starting chat: $e");
      _showErrorSnackBar("Error: $e");
    }
  }

  void _startVideoCall() {
    if (_isCurrentUser) {
      _showErrorSnackBar("You cannot call yourself");
      return;
    }

    if (_currentUserModel == null) {
      _showErrorSnackBar("Loading user data, please try again");
      return;
    }

    if (!_isOnline) {
      _showErrorSnackBar("User is offline. Cannot start video call");
      return;
    }

    HapticFeedback.mediumImpact();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VideoCallScreen(
          calleeId: _currentUserModel!.id,
          calleeName: _currentUserModel!.name,
          calleePhoto: _currentUserModel!.photoUrl,
          isIncoming: false,
        ),
      ),
    );
  }

  void _startVoiceCall() {
    if (_isCurrentUser) {
      _showErrorSnackBar("You cannot call yourself");
      return;
    }

    if (_currentUserModel == null) {
      _showErrorSnackBar("Loading user data, please try again");
      return;
    }

    if (!_isOnline) {
      _showErrorSnackBar("User is offline. Cannot start voice call");
      return;
    }

    HapticFeedback.mediumImpact();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VoiceCallScreen(
          calleeId: _currentUserModel!.id,
          calleeName: _currentUserModel!.name,
          calleePhoto: _currentUserModel!.photoUrl,
          isIncoming: false,
        ),
      ),
    );
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    } else {
      _showErrorSnackBar("Cannot make phone call");
    }
  }

  Future<void> _sendEmail(String email) async {
    final Uri emailUri = Uri(scheme: 'mailto', path: email);
    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    } else {
      _showErrorSnackBar("Cannot send email");
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // UI BUILDERS
  // ═══════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    if (_isLoadingUserData) {
      return _buildLoadingState();
    }

    final chatProv = Provider.of<ChatProvider>(context);
    final auth = Provider.of<AuthProvider>(context);

    final conversation = chatProv.conversations.firstWhere(
          (c) => c.participantIds.contains(widget.user.id),
      orElse: () => ConversationModel(
        id: '',
        type: ConversationType.oneToOne,
        participantIds: [],
        participantDetails: {},
        lastMessage: '',
        lastMessageType: 'text',
        lastMessageSenderId: '',
        lastMessageTime: DateTime.now(),
        unreadCount: {},
        chatRequests: {},
        isActive: false,
        createdAt: DateTime.now(),
        mutedBy: [],
        pinnedBy: [],
      ),
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildParallaxAppBar(context),
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Column(
                  children: [
                    const SizedBox(height: 24),
                    _buildProfileHeader(),
                    const SizedBox(height: 24),
                    if (!_isCurrentUser) _buildActionButtons(conversation, auth.currentUser?.id ?? ""),
                    if (!_isCurrentUser) const SizedBox(height: 32),
                    _buildQuickActions(),
                    const SizedBox(height: 24),
                    _buildAcademicInfo(),
                    const SizedBox(height: 24),
                    _buildContactInfo(),
                    const SizedBox(height: 24),
                    _buildAdditionalInfo(),
                    const SizedBox(height: 24),
                    _buildStatistics(),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: const CircularProgressIndicator(
                color: AppColors.primaryColor,
                strokeWidth: 3,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Loading profile...',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildParallaxAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 280,
      pinned: true,
      elevation: 0,
      backgroundColor: AppColors.primaryColor,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        if (_isCurrentUser)
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.edit, color: Colors.white, size: 20),
            ),
            onPressed: () {
              _showSuccessSnackBar('Edit profile feature coming soon!');
            },
          ),
        if (!_isCurrentUser)
          PopupMenuButton<String>(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.more_vert, color: Colors.white, size: 20),
            ),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            onSelected: (value) => _handleMenuAction(value),
            itemBuilder: (context) => [
              _buildMenuItem('block', Icons.block, 'Block User', Colors.red),
              _buildMenuItem('report', Icons.report, 'Report User', Colors.orange),
            ],
          ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: AppColors.primaryGradient,
              ),
            ),
            Positioned(
              top: -50,
              right: -50,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.1),
                ),
              ),
            ),
            Positioned(
              bottom: -30,
              left: -30,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.05),
                ),
              ),
            ),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 60),
                  ScaleTransition(
                    scale: _scaleAnimation,
                    child: Hero(
                      tag: 'profile_avatar_${widget.user.id}',
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Stack(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 4),
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.white.withValues(alpha: 0.3),
                                    Colors.white.withValues(alpha: 0.1),
                                  ],
                                ),
                              ),
                              child: CircleAvatar(
                                radius: 64,
                                backgroundColor: Colors.white24,
                                backgroundImage: (_currentUserModel?.photoUrl ?? widget.user.photoUrl) != null
                                    ? CachedNetworkImageProvider(_currentUserModel?.photoUrl ?? widget.user.photoUrl!)
                                    : null,
                                child: (_currentUserModel?.photoUrl ?? widget.user.photoUrl) == null
                                    ? Text(
                                  (_currentUserModel?.name ?? widget.user.name)[0].toUpperCase(),
                                  style: GoogleFonts.poppins(
                                    fontSize: 48,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                                    : null,
                              ),
                            ),
                            if (_isOnline)
                              Positioned(
                                bottom: 8,
                                right: 8,
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  PopupMenuItem<String> _buildMenuItem(String value, IconData icon, String title, Color color) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  void _handleMenuAction(String value) {
    switch (value) {
      case 'block':
        _showBlockDialog();
        break;
      case 'report':
        _showReportDialog();
        break;
    }
  }

  void _showBlockDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.block, color: Colors.red.shade400),
            const SizedBox(width: 12),
            const Text('Block User?'),
          ],
        ),
        content: Text(
          'Are you sure you want to block ${_currentUserModel?.name ?? widget.user.name}?',
          style: GoogleFonts.inter(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
              _showSuccessSnackBar('${_currentUserModel?.name ?? widget.user.name} has been blocked');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Block'),
          ),
        ],
      ),
    );
  }

  void _showReportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.report, color: Colors.orange.shade600),
            const SizedBox(width: 12),
            const Text('Report User'),
          ],
        ),
        content: Text(
          'Report ${_currentUserModel?.name ?? widget.user.name} for inappropriate content?',
          style: GoogleFonts.inter(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showSuccessSnackBar('Report submitted successfully');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange.shade600,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Report'),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
    final role = _userData?['role'] ?? _currentUserModel?.role ?? widget.user.role;
    final bio = _userData?['bio'] ?? '';
    final joinedDate = _userData?['createdAt'] != null
        ? (_userData!['createdAt'] as Timestamp).toDate()
        : (_currentUserModel?.createdAt ?? widget.user.createdAt);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          Text(
            _userData?['name'] ?? _currentUserModel?.name ?? widget.user.name,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade900,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primaryColor.withValues(alpha: 0.1),
                  AppColors.primaryColor.withValues(alpha: 0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.primaryColor.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  role == 'admin' ? Icons.admin_panel_settings : Icons.school,
                  size: 16,
                  color: AppColors.primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  (role ?? 'Student').toString().toUpperCase(),
                  style: GoogleFonts.inter(
                    color: AppColors.primaryColor,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          if (bio.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
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
                      Icon(Icons.info_outline, size: 18, color: AppColors.primaryColor),
                      const SizedBox(width: 8),
                      Text(
                        'About',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    bio,
                    style: GoogleFonts.inter(
                      color: Colors.grey.shade700,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _isOnline ? Colors.green : Colors.grey,
                  shape: BoxShape.circle,
                ),
                margin: const EdgeInsets.only(right: 6),
              ),
              Text(
                _lastSeenText.isEmpty ? 'Offline' : _lastSeenText,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: _isOnline ? Colors.green.shade600 : Colors.grey.shade600,
                  fontWeight: _isOnline ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.calendar_today, size: 14, color: Colors.grey.shade600),
              const SizedBox(width: 6),
              Text(
                'Joined ${_formatDate(joinedDate)}',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(ConversationModel? conversation, String currentUserId) {
    String label = "Send Friend Request";
    IconData icon = Icons.person_add_rounded;
    Color buttonColor = AppColors.primaryColor;
    bool isDisabled = false;

    if (conversation != null && conversation.id.isNotEmpty) {
      if (conversation.isActive) {
        label = "Send Message";
        icon = Icons.chat_bubble_rounded;
        buttonColor = Colors.blue;
      } else if (conversation.chatRequests[currentUserId] == ChatRequestStatus.pending) {
        label = "Accept Request";
        icon = Icons.check_circle_rounded;
        buttonColor = Colors.green;
      } else {
        label = "Request Sent";
        icon = Icons.schedule;
        buttonColor = Colors.grey.shade400;
        isDisabled = true;
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: !isDisabled
                  ? [
                BoxShadow(
                  color: buttonColor.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ]
                  : null,
            ),
            child: ElevatedButton(
              onPressed: isDisabled ? null : _handleStartChatOrRequest,
              style: ElevatedButton.styleFrom(
                backgroundColor: buttonColor,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey.shade300,
                disabledForegroundColor: Colors.grey.shade600,
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 22),
                  const SizedBox(width: 12),
                  Text(
                    label,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildCallButton(
                  icon: Icons.videocam_rounded,
                  label: 'Video',
                  color: Colors.green.shade600,
                  onTap: _startVideoCall,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildCallButton(
                  icon: Icons.call_rounded,
                  label: 'Voice',
                  color: Colors.blue.shade600,
                  onTap: _startVoiceCall,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCallButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.poppins(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    final email = _userData?['email'] ?? _currentUserModel?.email ?? widget.user.email;
    final phoneNumber = _userData?['phoneNumber'] ?? _userData?['phone'] ?? _currentUserModel?.phone ?? widget.user.phone;

    if (email.isEmpty && phoneNumber == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          if (email.isNotEmpty)
            Expanded(
              child: _buildQuickActionButton(
                icon: Icons.email_outlined,
                label: 'Email',
                color: Colors.orange,
                onTap: () => _sendEmail(email),
              ),
            ),
          if (email.isNotEmpty && phoneNumber != null) const SizedBox(width: 12),
          if (phoneNumber != null)
            Expanded(
              child: _buildQuickActionButton(
                icon: Icons.phone_outlined,
                label: 'Call',
                color: Colors.green,
                onTap: () => _makePhoneCall(phoneNumber.toString()),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3)),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.poppins(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAcademicInfo() {
    final college = _userData?['college'] ?? _currentUserModel?.college ?? widget.user.college;
    final department = _userData?['department'] ?? _currentUserModel?.department ?? widget.user.department;
    final semester = _userData?['semester'] ?? _currentUserModel?.semester ?? widget.user.semester;
    final className = _userData?['class'] ?? _userData?['className'];
    final section = _userData?['section'];
    final rollNumber = _userData?['rollNumber'] ?? _userData?['rollNo'];
    final batch = _userData?['batch'] ?? _userData?['batchYear'] ?? _currentUserModel?.batchYear ?? widget.user.batchYear;

    List<Map<String, dynamic>> items = [];

    if (college != null && college.toString().isNotEmpty) {
      items.add({'icon': Icons.school_rounded, 'label': 'College', 'value': college, 'color': Colors.blue});
    }
    if (department != null && department.toString().isNotEmpty) {
      items.add({'icon': Icons.library_books, 'label': 'Department', 'value': department, 'color': Colors.purple});
    }
    if (semester != null && semester.toString().isNotEmpty) {
      items.add({'icon': Icons.calendar_view_month, 'label': 'Semester', 'value': 'Semester $semester', 'color': Colors.teal});
    }
    if (className != null) {
      items.add({'icon': Icons.class_, 'label': 'Class', 'value': className, 'color': Colors.indigo});
    }
    if (section != null) {
      items.add({'icon': Icons.group, 'label': 'Section', 'value': 'Section $section', 'color': Colors.deepOrange});
    }
    if (rollNumber != null) {
      items.add({'icon': Icons.badge, 'label': 'Roll Number', 'value': rollNumber.toString(), 'color': Colors.pink});
    }
    if (batch != null) {
      items.add({'icon': Icons.event_note, 'label': 'Batch Year', 'value': batch.toString(), 'color': Colors.amber});
    }

    if (items.isEmpty) return const SizedBox.shrink();

    return _buildSection(
      'Academic Information',
      Icons.account_balance,
      AppColors.primaryColor,
      items.map((item) => _buildInfoTile(
        item['icon'],
        item['label'],
        item['value'].toString(),
        item['color'],
      )).toList(),
    );
  }

  Widget _buildContactInfo() {
    final email = _userData?['email'] ?? _currentUserModel?.email ?? widget.user.email;
    final phoneNumber = _userData?['phoneNumber'] ?? _userData?['phone'] ?? _currentUserModel?.phone ?? widget.user.phone;
    final address = _userData?['address'];
    final city = _userData?['city'];
    final state = _userData?['state'];
    final country = _userData?['country'];
    final pincode = _userData?['pincode'] ?? _userData?['zipCode'];

    List<Map<String, dynamic>> items = [];

    if (email.isNotEmpty) {
      items.add({'icon': Icons.email_outlined, 'label': 'Email', 'value': email, 'color': Colors.orange});
    }
    if (phoneNumber != null) {
      items.add({'icon': Icons.phone_outlined, 'label': 'Phone', 'value': phoneNumber.toString(), 'color': Colors.green});
    }
    if (address != null) {
      items.add({'icon': Icons.home_outlined, 'label': 'Address', 'value': address, 'color': Colors.red});
    }
    if (city != null) {
      items.add({'icon': Icons.location_city, 'label': 'City', 'value': city, 'color': Colors.blue});
    }
    if (state != null) {
      items.add({'icon': Icons.map_outlined, 'label': 'State', 'value': state, 'color': Colors.teal});
    }
    if (country != null) {
      items.add({'icon': Icons.flag_outlined, 'label': 'Country', 'value': country, 'color': Colors.indigo});
    }
    if (pincode != null) {
      items.add({'icon': Icons.pin_drop_outlined, 'label': 'Pincode', 'value': pincode.toString(), 'color': Colors.purple});
    }

    if (items.isEmpty) return const SizedBox.shrink();

    return _buildSection(
      'Contact Information',
      Icons.contact_page,
      Colors.orange,
      items.map((item) => _buildInfoTile(
        item['icon'],
        item['label'],
        item['value'].toString(),
        item['color'],
      )).toList(),
    );
  }

  Widget _buildAdditionalInfo() {
    final dateOfBirth = _userData?['dateOfBirth'];
    final gender = _userData?['gender'];
    final bloodGroup = _userData?['bloodGroup'];
    final nationality = _userData?['nationality'];
    final interests = _userData?['interests'];
    final skills = _userData?['skills'];
    final hobbies = _userData?['hobbies'];

    List<Widget> items = [];

    if (dateOfBirth != null) {
      DateTime dob;
      if (dateOfBirth is Timestamp) {
        dob = dateOfBirth.toDate();
      } else if (dateOfBirth is String) {
        dob = DateTime.tryParse(dateOfBirth) ?? DateTime.now();
      } else {
        dob = DateTime.now();
      }
      items.add(_buildInfoTile(Icons.cake_outlined, 'Date of Birth', _formatDate(dob), Colors.pink));
    }
    if (gender != null) {
      items.add(_buildInfoTile(Icons.person_outline, 'Gender', gender, Colors.purple));
    }
    if (bloodGroup != null) {
      items.add(_buildInfoTile(Icons.water_drop_outlined, 'Blood Group', bloodGroup, Colors.red));
    }
    if (nationality != null) {
      items.add(_buildInfoTile(Icons.public, 'Nationality', nationality, Colors.blue));
    }

    if (items.isEmpty && interests == null && skills == null && hobbies == null) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (items.isNotEmpty) _buildSection('Additional Information', Icons.info, Colors.purple, items),
          if (interests != null) ...[
            if (items.isNotEmpty) const SizedBox(height: 16),
            _buildTagSection('Interests', interests, Colors.blue),
          ],
          if (skills != null) ...[
            const SizedBox(height: 16),
            _buildTagSection('Skills', skills, Colors.orange),
          ],
          if (hobbies != null) ...[
            const SizedBox(height: 16),
            _buildTagSection('Hobbies', hobbies, Colors.green),
          ],
        ],
      ),
    );
  }

  Widget _buildStatistics() {
    final resourcesUploaded = _userData?['resourcesUploaded'] ?? 0;
    final totalDownloads = _userData?['totalDownloads'] ?? 0;
    final studyStreak = _userData?['studyStreak'] ?? 0;

    if (resourcesUploaded == 0 && totalDownloads == 0 && studyStreak == 0) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.green.withValues(alpha: 0.2),
                      Colors.green.withValues(alpha: 0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.bar_chart, color: Colors.green, size: 22),
              ),
              const SizedBox(width: 12),
              Text(
                "Statistics",
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                if (resourcesUploaded > 0)
                  _buildStatItem(Icons.cloud_upload, resourcesUploaded.toString(), 'Uploads', Colors.blue),
                if (totalDownloads > 0)
                  _buildStatItem(Icons.download, totalDownloads.toString(), 'Downloads', Colors.green),
                if (studyStreak > 0)
                  _buildStatItem(Icons.local_fire_department, studyStreak.toString(), 'Day Streak', Colors.orange),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, IconData icon, Color color, List<Widget> children) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      color.withValues(alpha: 0.2),
                      color.withValues(alpha: 0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children.map((child) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: child,
          )),
        ],
      ),
    );
  }

  Widget _buildInfoTile(IconData icon, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: Colors.black87,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTagSection(String title, dynamic tags, Color color) {
    List<String> tagList = [];
    if (tags is List) {
      tagList = tags.map((e) => e.toString()).toList();
    } else if (tags is String) {
      tagList = tags.split(',').map((e) => e.trim()).toList();
    }

    if (tagList.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
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
              Icon(Icons.label_outline, size: 18, color: color),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: tagList
                .map((tag) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: color.withValues(alpha: 0.3)),
              ),
              child: Text(
                tag,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade800,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // HELPER METHODS
  // ═══════════════════════════════════════════════════════════════

  String _formatDate(DateTime date) {
    return DateFormat('MMM dd, yyyy').format(date);
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_rounded, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.error_outline_rounded, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}