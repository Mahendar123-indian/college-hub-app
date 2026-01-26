import 'package:flutter/material.dart';
import '../../data/services/notification_service_ENHANCED.dart';

/// 🔔 NOTIFICATION TRIGGERS
/// Easy-to-use helper class to trigger notifications from anywhere in the app
/// Usage: NotificationTriggers.downloadComplete(fileName, filePath);
class NotificationTriggers {
  static final NotificationService _service = NotificationService();

  // ═══════════════════════════════════════════════════════════════
  // 🎉 WELCOME & ONBOARDING
  // ═══════════════════════════════════════════════════════════════

  /// Show welcome notification (call after first login/registration)
  static Future<void> welcome(String userName) async {
    await _service.showWelcomeNotification(userName);
  }

  /// Show registration success notification
  static Future<void> registrationSuccess(String userName) async {
    await _service.showRegistrationSuccessNotification(userName);
  }

  /// Show email verification reminder
  static Future<void> emailVerification() async {
    await _service.showEmailVerificationNotification();
  }

  // ═══════════════════════════════════════════════════════════════
  // 📥 DOWNLOADS
  // ═══════════════════════════════════════════════════════════════

  /// Show download started notification
  /// Returns notificationId for updating progress
  static Future<int> downloadStarted(String fileName) async {
    final notificationId = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    await _service.showDownloadStartedNotification(fileName, notificationId);
    return notificationId;
  }

  /// Update download progress notification
  static Future<void> downloadProgress(
      int notificationId,
      String fileName,
      int progress,
      ) async {
    await _service.updateDownloadProgressNotification(
      notificationId,
      fileName,
      progress,
    );
  }

  /// Show download complete notification
  static Future<void> downloadComplete(String fileName, String filePath) async {
    await _service.showDownloadCompleteNotification(fileName, filePath);
  }

  /// Show download failed notification
  static Future<void> downloadFailed(String fileName, String error) async {
    await _service.showDownloadFailedNotification(fileName, error);
  }

  // ═══════════════════════════════════════════════════════════════
  // 💬 CHAT & MESSAGES
  // ═══════════════════════════════════════════════════════════════

  /// Show new message notification
  static Future<void> newMessage({
    required String senderName,
    required String message,
    required String conversationId,
    String? senderPhotoUrl,
  }) async {
    await _service.showNewMessageNotification(
      senderName: senderName,
      message: message,
      conversationId: conversationId,
      senderPhotoUrl: senderPhotoUrl,
    );
  }

  /// Show new group message notification
  static Future<void> newGroupMessage({
    required String groupName,
    required String senderName,
    required String message,
    required String conversationId,
  }) async {
    await _service.showNewMessageNotification(
      senderName: senderName,
      message: message,
      conversationId: conversationId,
      isGroup: true,
      groupName: groupName,
    );
  }

  /// Show group invitation notification
  static Future<void> groupInvite({
    required String groupName,
    required String inviterName,
    required String groupId,
  }) async {
    await _service.showGroupInviteNotification(
      groupName: groupName,
      inviterName: inviterName,
      groupId: groupId,
    );
  }

  /// Show friend request notification
  static Future<void> friendRequest({
    required String senderName,
    required String senderId,
    String? senderPhotoUrl,
  }) async {
    await _service.showFriendRequestNotification(
      senderName: senderName,
      senderId: senderId,
      senderPhotoUrl: senderPhotoUrl,
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // 👤 PROFILE UPDATES
  // ═══════════════════════════════════════════════════════════════

  /// Show profile updated notification
  static Future<void> profileUpdated() async {
    await _service.showProfileUpdatedNotification();
  }

  /// Show password changed notification
  static Future<void> passwordChanged() async {
    await _service.showPasswordChangedNotification();
  }

  /// Show college changed notification
  static Future<void> collegeChanged(String newCollege) async {
    await _service.showCollegeChangedNotification(newCollege);
  }

  // ═══════════════════════════════════════════════════════════════
  // 📚 RESOURCES
  // ═══════════════════════════════════════════════════════════════

  /// Show resource saved notification
  static Future<void> resourceSaved(String resourceTitle) async {
    await _service.showResourceSavedNotification(resourceTitle);
  }

  /// Show new resource notification
  static Future<void> newResource({
    required String resourceTitle,
    required String resourceType,
    required String department,
    required String resourceId,
  }) async {
    await _service.showNewResourceNotification(
      resourceTitle: resourceTitle,
      resourceType: resourceType,
      department: department,
      resourceId: resourceId,
    );
  }

  /// Show resource upload success notification (admin)
  static Future<void> resourceUploadSuccess(String resourceTitle) async {
    await _service.showResourceUploadSuccessNotification(resourceTitle);
  }

  /// Show resource approved notification
  static Future<void> resourceApproved(String resourceTitle) async {
    await _service.showResourceApprovedNotification(resourceTitle);
  }

  /// Show resource rejected notification
  static Future<void> resourceRejected(String resourceTitle, String reason) async {
    await _service.showResourceRejectedNotification(resourceTitle, reason);
  }

  // ═══════════════════════════════════════════════════════════════
  // ⚙️ SYSTEM NOTIFICATIONS
  // ═══════════════════════════════════════════════════════════════

  /// Show app update available notification
  static Future<void> appUpdate(String version) async {
    await _service.showAppUpdateNotification(version);
  }

  /// Show maintenance mode notification
  static Future<void> maintenance(String message) async {
    await _service.showMaintenanceNotification(message);
  }

  /// Show network error notification
  static Future<void> networkError() async {
    await _service.showNetworkErrorNotification();
  }

  /// Show storage warning notification
  static Future<void> storageWarning() async {
    await _service.showStorageWarningNotification();
  }

  // ═══════════════════════════════════════════════════════════════
  // 🧹 UTILITIES
  // ═══════════════════════════════════════════════════════════════

  /// Cancel specific notification
  static Future<void> cancel(int notificationId) async {
    await _service.cancelNotification(notificationId);
  }

  /// Cancel all notifications
  static Future<void> cancelAll() async {
    await _service.cancelAllNotifications();
  }
}