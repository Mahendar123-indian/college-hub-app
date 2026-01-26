import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../config/routes.dart';

/// 🔔 PROFESSIONAL NOTIFICATION SERVICE
/// Handles ALL app notifications: Welcome, Downloads, Chats, Profile, Resources, System
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint("📩 Background message: ${message.messageId}");
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  GlobalKey<NavigatorState>? _navigatorKey;
  String? _currentUserId;

  // ═══════════════════════════════════════════════════════════════
  // NOTIFICATION CHANNELS (Android 8.0+)
  // ═══════════════════════════════════════════════════════════════

  static const AndroidNotificationChannel _chatChannel = AndroidNotificationChannel(
    'chat_channel',
    'Chat Messages',
    description: 'Notifications for new messages and chat activity',
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
    showBadge: true,
  );

  static const AndroidNotificationChannel _downloadChannel = AndroidNotificationChannel(
    'download_channel',
    'Downloads',
    description: 'Notifications for download progress and completion',
    importance: Importance.high,
    playSound: true,
    enableVibration: false,
    showBadge: false,
  );

  static const AndroidNotificationChannel _profileChannel = AndroidNotificationChannel(
    'profile_channel',
    'Profile Updates',
    description: 'Notifications for profile and account changes',
    importance: Importance.defaultImportance,
    playSound: true,
    showBadge: false,
  );

  static const AndroidNotificationChannel _resourceChannel = AndroidNotificationChannel(
    'resource_channel',
    'Resources',
    description: 'Notifications for new resources and updates',
    importance: Importance.high,
    playSound: true,
    showBadge: true,
  );

  static const AndroidNotificationChannel _systemChannel = AndroidNotificationChannel(
    'system_channel',
    'System Alerts',
    description: 'Important system notifications and updates',
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
  );

  // ═══════════════════════════════════════════════════════════════
  // INITIALIZATION
  // ═══════════════════════════════════════════════════════════════

  Future<void> initialize(GlobalKey<NavigatorState> navigatorKey, {String? userId}) async {
    _navigatorKey = navigatorKey;
    _currentUserId = userId;

    try {
      await _requestPermissions();
      await _configureLocalNotifications();
      await _createChannels();
      await _setupHandlers();
      if (userId != null) {
        await _subscribeToTopics(userId);
      }
      debugPrint('✅ NotificationService initialized');
    } catch (e) {
      debugPrint('❌ NotificationService init error: $e');
    }
  }

  Future<void> _requestPermissions() async {
    if (Platform.isAndroid) {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
      _localNotifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await androidImplementation?.requestNotificationsPermission();
    }

    await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    await _fcm.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  Future<void> _configureLocalNotifications() async {
    const AndroidInitializationSettings androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _localNotifications.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
      onDidReceiveNotificationResponse: (details) {
        _handleNotificationTap(details.payload);
      },
      onDidReceiveBackgroundNotificationResponse: _handleBackgroundNotificationTap,
    );
  }

  @pragma('vm:entry-point')
  static void _handleBackgroundNotificationTap(NotificationResponse details) {
    debugPrint('📱 Background notification tapped: ${details.payload}');
  }

  Future<void> _createChannels() async {
    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
    _localNotifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    if (androidImplementation != null) {
      await androidImplementation.createNotificationChannel(_chatChannel);
      await androidImplementation.createNotificationChannel(_downloadChannel);
      await androidImplementation.createNotificationChannel(_profileChannel);
      await androidImplementation.createNotificationChannel(_resourceChannel);
      await androidImplementation.createNotificationChannel(_systemChannel);
    }
  }

  Future<void> _setupHandlers() async {
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    RemoteMessage? initialMessage = await _fcm.getInitialMessage();
    if (initialMessage != null) {
      _handleFCMMessage(initialMessage);
    }

    FirebaseMessaging.onMessageOpenedApp.listen(_handleFCMMessage);

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('📬 Foreground message: ${message.notification?.title}');
      _showLocalNotificationFromFCM(message);
    });
  }

  Future<void> _subscribeToTopics(String userId) async {
    try {
      await _fcm.subscribeToTopic('all_users');
      await _fcm.subscribeToTopic('user_$userId');
      debugPrint('✅ Subscribed to notification topics');
    } catch (e) {
      debugPrint('❌ Topic subscription error: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // 🎉 WELCOME & ONBOARDING NOTIFICATIONS
  // ═══════════════════════════════════════════════════════════════

  Future<void> showWelcomeNotification(String userName) async {
    await _showNotification(
      id: 1,
      title: '🎉 Welcome to College Hub!',
      body: 'Hi $userName! Start exploring resources, connect with classmates, and ace your exams.',
      payload: 'home',
      channel: _systemChannel,
      priority: Priority.max,
      importance: Importance.max,
    );

    if (_currentUserId != null) {
      await _saveNotificationToFirestore(
        userId: _currentUserId!,
        title: 'Welcome to College Hub',
        body: 'Your academic resource hub is ready!',
        type: 'welcome',
      );
    }
  }

  Future<void> showRegistrationSuccessNotification(String userName) async {
    await _showNotification(
      id: 2,
      title: '✅ Registration Successful',
      body: 'Welcome aboard, $userName! Your account has been created successfully.',
      payload: 'profile',
      channel: _profileChannel,
    );

    if (_currentUserId != null) {
      await _saveNotificationToFirestore(
        userId: _currentUserId!,
        title: 'Account Created',
        body: 'Your College Hub account is ready to use',
        type: 'registration',
      );
    }
  }

  Future<void> showEmailVerificationNotification() async {
    await _showNotification(
      id: 3,
      title: '📧 Verify Your Email',
      body: 'Please verify your email address to access all features',
      payload: 'profile',
      channel: _profileChannel,
      priority: Priority.high,
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // 📥 DOWNLOAD NOTIFICATIONS
  // ═══════════════════════════════════════════════════════════════

  Future<void> showDownloadStartedNotification(String fileName, int notificationId) async {
    await _showNotification(
      id: notificationId,
      title: '📥 Download Started',
      body: 'Downloading $fileName...',
      payload: 'downloads',
      channel: _downloadChannel,
      showProgress: true,
      progress: 0,
      maxProgress: 100,
      ongoing: true,
    );
  }

  Future<void> updateDownloadProgressNotification(
      int notificationId,
      String fileName,
      int progress,
      ) async {
    await _showNotification(
      id: notificationId,
      title: '📥 Downloading',
      body: '$fileName - $progress%',
      payload: 'downloads',
      channel: _downloadChannel,
      showProgress: true,
      progress: progress,
      maxProgress: 100,
      ongoing: true,
    );
  }

  Future<void> showDownloadCompleteNotification(String fileName, String filePath) async {
    await _showNotification(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: '✅ Download Complete',
      body: '$fileName is ready to view',
      payload: 'open_file:$filePath',
      channel: _downloadChannel,
      priority: Priority.high,
      actions: [
        const AndroidNotificationAction('open', 'Open'),
        const AndroidNotificationAction('share', 'Share'),
      ],
    );

    if (_currentUserId != null) {
      await _saveNotificationToFirestore(
        userId: _currentUserId!,
        title: 'Download Complete',
        body: fileName,
        type: 'download_complete',
        data: {'filePath': filePath},
      );
    }
  }

  Future<void> showDownloadFailedNotification(String fileName, String error) async {
    await _showNotification(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: '❌ Download Failed',
      body: '$fileName - $error',
      payload: 'downloads',
      channel: _downloadChannel,
      priority: Priority.high,
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // 💬 CHAT NOTIFICATIONS - FIXED WITH COMPLETE DATA
  // ═══════════════════════════════════════════════════════════════

  Future<void> showNewMessageNotification({
    required String senderName,
    required String message,
    required String conversationId,
    String? senderPhotoUrl,
    bool isGroup = false,
    String? groupName,
  }) async {
    final title = isGroup ? '💬 $groupName' : '💬 $senderName';
    final body = isGroup ? '$senderName: $message' : message;

    // ✅ FIXED: Create enhanced payload with ALL required data separated by pipes
    final displayName = isGroup ? (groupName ?? 'Group') : senderName;
    final photoUrl = senderPhotoUrl ?? '';
    final payload = 'chat:$conversationId|$displayName|$photoUrl|$isGroup';

    await _showNotification(
      id: conversationId.hashCode,
      title: title,
      body: body,
      payload: payload,
      channel: _chatChannel,
      priority: Priority.max,
      importance: Importance.max,
      largeIcon: senderPhotoUrl,
      actions: [
        const AndroidNotificationAction('reply', 'Reply', showsUserInterface: true),
        const AndroidNotificationAction('mark_read', 'Mark as Read'),
      ],
      category: AndroidNotificationCategory.message,
    );

    if (_currentUserId != null) {
      await _saveNotificationToFirestore(
        userId: _currentUserId!,
        title: 'New Message',
        body: '$senderName sent you a message',
        type: 'chat_message',
        data: {
          'conversationId': conversationId,
          'senderName': senderName,
          'senderPhotoUrl': senderPhotoUrl,
          'isGroup': isGroup,
          'groupName': groupName,
        },
      );
    }
  }

  Future<void> showGroupInviteNotification({
    required String groupName,
    required String inviterName,
    required String groupId,
  }) async {
    await _showNotification(
      id: groupId.hashCode,
      title: '👥 Group Invitation',
      body: '$inviterName invited you to join "$groupName"',
      payload: 'group:$groupId',
      channel: _chatChannel,
      priority: Priority.high,
      actions: [
        const AndroidNotificationAction('accept', 'Accept'),
        const AndroidNotificationAction('decline', 'Decline'),
      ],
    );

    if (_currentUserId != null) {
      await _saveNotificationToFirestore(
        userId: _currentUserId!,
        title: 'Group Invitation',
        body: 'You were invited to $groupName',
        type: 'group_invite',
        data: {
          'groupId': groupId,
          'groupName': groupName,
        },
      );
    }
  }

  Future<void> showFriendRequestNotification({
    required String senderName,
    required String senderId,
    String? senderPhotoUrl,
  }) async {
    await _showNotification(
      id: senderId.hashCode,
      title: '👤 Friend Request',
      body: '$senderName wants to connect with you',
      payload: 'friend_request:$senderId',
      channel: _chatChannel,
      largeIcon: senderPhotoUrl,
      actions: [
        const AndroidNotificationAction('accept', 'Accept'),
        const AndroidNotificationAction('decline', 'Decline'),
      ],
    );

    if (_currentUserId != null) {
      await _saveNotificationToFirestore(
        userId: _currentUserId!,
        title: 'Friend Request',
        body: '$senderName sent you a friend request',
        type: 'friend_request',
        data: {'senderId': senderId},
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // 👤 PROFILE UPDATE NOTIFICATIONS
  // ═══════════════════════════════════════════════════════════════

  Future<void> showProfileUpdatedNotification() async {
    await _showNotification(
      id: 101,
      title: '✅ Profile Updated',
      body: 'Your profile information has been updated successfully',
      payload: 'profile',
      channel: _profileChannel,
    );

    if (_currentUserId != null) {
      await _saveNotificationToFirestore(
        userId: _currentUserId!,
        title: 'Profile Updated',
        body: 'Your changes have been saved',
        type: 'profile_update',
      );
    }
  }

  Future<void> showPasswordChangedNotification() async {
    await _showNotification(
      id: 102,
      title: '🔒 Password Changed',
      body: 'Your password has been changed successfully',
      payload: 'profile',
      channel: _profileChannel,
      priority: Priority.high,
    );

    if (_currentUserId != null) {
      await _saveNotificationToFirestore(
        userId: _currentUserId!,
        title: 'Password Changed',
        body: 'Your account password was updated',
        type: 'password_change',
      );
    }
  }

  Future<void> showCollegeChangedNotification(String newCollege) async {
    await _showNotification(
      id: 103,
      title: '🏫 College Updated',
      body: 'Your college has been changed to $newCollege',
      payload: 'profile',
      channel: _profileChannel,
    );

    if (_currentUserId != null) {
      await _saveNotificationToFirestore(
        userId: _currentUserId!,
        title: 'College Updated',
        body: 'College changed to $newCollege',
        type: 'college_change',
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // 📚 RESOURCE NOTIFICATIONS
  // ═══════════════════════════════════════════════════════════════

  Future<void> showResourceSavedNotification(String resourceTitle) async {
    await _showNotification(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: '💾 Resource Saved',
      body: '"$resourceTitle" has been saved to your bookmarks',
      payload: 'bookmarks',
      channel: _resourceChannel,
    );
  }

  Future<void> showNewResourceNotification({
    required String resourceTitle,
    required String resourceType,
    required String department,
    required String resourceId,
  }) async {
    await _showNotification(
      id: resourceId.hashCode,
      title: '📚 New $resourceType Available',
      body: '$resourceTitle - $department',
      payload: 'resource:$resourceId',
      channel: _resourceChannel,
      priority: Priority.high,
    );

    if (_currentUserId != null) {
      await _saveNotificationToFirestore(
        userId: _currentUserId!,
        title: 'New Resource',
        body: '$resourceTitle is now available',
        type: 'new_resource',
        data: {'resourceId': resourceId},
      );
    }
  }

  Future<void> showResourceUploadSuccessNotification(String resourceTitle) async {
    await _showNotification(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: '✅ Upload Successful',
      body: '"$resourceTitle" has been uploaded successfully',
      payload: 'manage_resources',
      channel: _resourceChannel,
      priority: Priority.high,
    );

    if (_currentUserId != null) {
      await _saveNotificationToFirestore(
        userId: _currentUserId!,
        title: 'Resource Uploaded',
        body: resourceTitle,
        type: 'resource_upload',
      );
    }
  }

  Future<void> showResourceApprovedNotification(String resourceTitle) async {
    await _showNotification(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: '✅ Resource Approved',
      body: 'Your resource "$resourceTitle" has been approved and is now live',
      payload: 'manage_resources',
      channel: _resourceChannel,
      priority: Priority.high,
    );

    if (_currentUserId != null) {
      await _saveNotificationToFirestore(
        userId: _currentUserId!,
        title: 'Resource Approved',
        body: resourceTitle,
        type: 'resource_approved',
      );
    }
  }

  Future<void> showResourceRejectedNotification(String resourceTitle, String reason) async {
    await _showNotification(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: '❌ Resource Rejected',
      body: '"$resourceTitle" - $reason',
      payload: 'manage_resources',
      channel: _resourceChannel,
      priority: Priority.high,
    );

    if (_currentUserId != null) {
      await _saveNotificationToFirestore(
        userId: _currentUserId!,
        title: 'Resource Rejected',
        body: '$resourceTitle - $reason',
        type: 'resource_rejected',
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // ⚙️ SYSTEM NOTIFICATIONS
  // ═══════════════════════════════════════════════════════════════

  Future<void> showAppUpdateNotification(String version) async {
    await _showNotification(
      id: 200,
      title: '🔄 Update Available',
      body: 'Version $version is now available with new features',
      payload: 'update',
      channel: _systemChannel,
      priority: Priority.max,
      actions: [
        const AndroidNotificationAction('update', 'Update Now'),
        const AndroidNotificationAction('later', 'Later'),
      ],
    );
  }

  Future<void> showMaintenanceNotification(String message) async {
    await _showNotification(
      id: 201,
      title: '🔧 Maintenance Mode',
      body: message,
      payload: 'home',
      channel: _systemChannel,
      priority: Priority.max,
    );
  }

  Future<void> showNetworkErrorNotification() async {
    await _showNotification(
      id: 202,
      title: '📡 No Internet Connection',
      body: 'Please check your internet connection',
      payload: 'home',
      channel: _systemChannel,
    );
  }

  Future<void> showStorageWarningNotification() async {
    await _showNotification(
      id: 203,
      title: '⚠️ Storage Space Low',
      body: 'Your device is running low on storage space',
      payload: 'settings',
      channel: _systemChannel,
      priority: Priority.high,
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // 🔔 CORE NOTIFICATION DISPLAY
  // ═══════════════════════════════════════════════════════════════

  Future<void> _showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
    required AndroidNotificationChannel channel,
    Priority priority = Priority.defaultPriority,
    Importance importance = Importance.defaultImportance,
    bool showProgress = false,
    int progress = 0,
    int maxProgress = 100,
    bool ongoing = false,
    String? largeIcon,
    List<AndroidNotificationAction>? actions,
    AndroidNotificationCategory? category,
  }) async {
    try {
      await _localNotifications.show(
        id,
        title,
        body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            channel.id,
            channel.name,
            channelDescription: channel.description,
            importance: importance,
            priority: priority,
            showProgress: showProgress,
            progress: progress,
            maxProgress: maxProgress,
            ongoing: ongoing,
            icon: '@mipmap/ic_launcher',
            largeIcon: largeIcon != null ? FilePathAndroidBitmap(largeIcon) : null,
            actions: actions,
            category: category,
            playSound: channel.playSound,
            enableVibration: channel.enableVibration,
            showWhen: true,
            styleInformation: const BigTextStyleInformation(''),
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
            subtitle: body,
          ),
        ),
        payload: payload,
      );
    } catch (e) {
      debugPrint('❌ Show notification error: $e');
    }
  }

  Future<void> _showLocalNotificationFromFCM(RemoteMessage message) async {
    RemoteNotification? notification = message.notification;
    if (notification != null) {
      await _showNotification(
        id: notification.hashCode,
        title: notification.title ?? 'College Hub',
        body: notification.body ?? '',
        payload: message.data['screen'],
        channel: _systemChannel,
        priority: Priority.max,
        importance: Importance.max,
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // 🗄️ FIRESTORE NOTIFICATION STORAGE
  // ═══════════════════════════════════════════════════════════════

  Future<void> _saveNotificationToFirestore({
    required String userId,
    required String title,
    required String body,
    required String type,
    Map<String, dynamic>? data,
  }) async {
    try {
      await FirebaseFirestore.instance.collection('notifications').add({
        'userId': userId,
        'title': title,
        'body': body,
        'type': type,
        'data': data ?? {},
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('❌ Save notification error: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // 🎯 NAVIGATION HANDLING - PROPERLY FIXED FOR CHAT
  // ═══════════════════════════════════════════════════════════════

  void _handleFCMMessage(RemoteMessage message) {
    final String? screen = message.data['screen'];
    _handleNotificationTap(screen);
  }

  void _handleNotificationTap(String? payload) {
    if (payload == null || _navigatorKey == null) return;

    final context = _navigatorKey!.currentContext;
    if (context == null) return;

    debugPrint('🔔 Notification tapped with payload: $payload');

    // ✅ PROPERLY FIXED: Parse chat payload with all 4 required parameters
    if (payload.startsWith('chat:')) {
      try {
        // Payload format: "chat:conversationId|conversationName|conversationPhoto|isGroup"
        final parts = payload.substring(5).split('|'); // Remove 'chat:' prefix

        final conversationId = parts.isNotEmpty ? parts[0] : '';
        final conversationName = parts.length > 1 && parts[1].isNotEmpty ? parts[1] : 'Chat';
        final conversationPhoto = parts.length > 2 && parts[2].isNotEmpty ? parts[2] : null;
        final isGroup = parts.length > 3 && parts[3].toLowerCase() == 'true';

        debugPrint('✅ Parsed chat data:');
        debugPrint('   conversationId: $conversationId');
        debugPrint('   conversationName: $conversationName');
        debugPrint('   conversationPhoto: $conversationPhoto');
        debugPrint('   isGroup: $isGroup');

        if (conversationId.isEmpty) {
          debugPrint('❌ Empty conversationId, cannot navigate');
          return;
        }

        Navigator.pushNamed(
          context,
          AppRoutes.chatDetail,
          arguments: {
            'conversationId': conversationId,
            'conversationName': conversationName,
            'conversationPhoto': conversationPhoto,
            'isGroup': isGroup,
          },
        );
      } catch (e) {
        debugPrint('❌ Chat navigation error: $e');
        // Fallback: Try to extract just conversationId
        try {
          final conversationId = payload.split(':')[1].split('|')[0];
          if (conversationId.isNotEmpty) {
            Navigator.pushNamed(
              context,
              AppRoutes.chatDetail,
              arguments: {
                'conversationId': conversationId,
                'conversationName': 'Chat',
                'conversationPhoto': null,
                'isGroup': false,
              },
            );
          }
        } catch (e2) {
          debugPrint('❌ Fallback navigation also failed: $e2');
        }
      }
    } else if (payload.startsWith('resource:')) {
      final resourceId = payload.split(':')[1];
      AppRoutes.navigateToResourceDetail(context, resourceId);
    } else if (payload.startsWith('open_file:')) {
      final filePath = payload.split(':')[1];
      // Open file logic here
    } else {
      // Navigate to named routes
      final routeMap = {
        'home': AppRoutes.home,
        'profile': AppRoutes.profile,
        'downloads': AppRoutes.downloads,
        'bookmarks': AppRoutes.bookmarks,
        'settings': AppRoutes.settings,
      };

      final route = routeMap[payload];
      if (route != null) {
        Navigator.pushNamed(context, route);
      }
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // 🧹 CLEANUP & UTILITIES
  // ═══════════════════════════════════════════════════════════════

  Future<void> cancelNotification(int id) async {
    await _localNotifications.cancel(id);
  }

  Future<void> cancelAllNotifications() async {
    await _localNotifications.cancelAll();
  }

  Future<String?> getDeviceToken() async {
    try {
      return await _fcm.getToken();
    } catch (e) {
      debugPrint('❌ Get token error: $e');
      return null;
    }
  }

  Future<void> updateUserId(String userId) async {
    _currentUserId = userId;
    await _subscribeToTopics(userId);
  }

  Future<void> clearUser() async {
    if (_currentUserId != null) {
      await _fcm.unsubscribeFromTopic('user_$_currentUserId');
    }
    _currentUserId = null;
  }
}