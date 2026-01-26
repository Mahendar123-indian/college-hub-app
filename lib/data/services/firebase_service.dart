import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

class FirebaseService {
  static FirebaseService? _instance;

  // ✅ FIXED: Initialize immediately instead of using 'late'
  FirebaseAuth get auth => FirebaseAuth.instance;
  FirebaseFirestore get firestore => FirebaseFirestore.instance;
  FirebaseStorage get storage => FirebaseStorage.instance;
  FirebaseMessaging get messaging => FirebaseMessaging.instance;
  FirebaseAnalytics get analytics => FirebaseAnalytics.instance;
  FirebaseCrashlytics get crashlytics => FirebaseCrashlytics.instance;

  // Private constructor
  FirebaseService._();

  // Singleton instance
  static FirebaseService get instance {
    _instance ??= FirebaseService._();
    return _instance!;
  }

  // Initialize Firebase (optional advanced configuration)
  Future<void> initialize() async {
    try {
      // Configure Firestore settings
      firestore.settings = const Settings(
        persistenceEnabled: true,
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
      );

      // Enable offline persistence (only for mobile platforms)
      if (!kIsWeb) {
        try {
          await firestore.enablePersistence(
            const PersistenceSettings(synchronizeTabs: true),
          );
        } catch (e) {
          if (kDebugMode) {
            print('Persistence error: $e');
          }
        }
      }

      if (kDebugMode) {
        print('Firebase initialized successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Failed to initialize Firebase: $e');
      }
      rethrow;
    }
  }

  // Request notification permissions
  Future<NotificationSettings> requestNotificationPermissions() async {
    try {
      return await messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Failed to request notification permissions: $e');
      }
      rethrow;
    }
  }

  // Get FCM token
  Future<String?> getFCMToken() async {
    try {
      return await messaging.getToken();
    } catch (e) {
      if (kDebugMode) {
        print('Failed to get FCM token: $e');
      }
      return null;
    }
  }

  // Subscribe to topic
  Future<void> subscribeToTopic(String topic) async {
    try {
      await messaging.subscribeToTopic(topic);
      if (kDebugMode) {
        print('Subscribed to topic: $topic');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Failed to subscribe to topic: $e');
      }
    }
  }

  // Unsubscribe from topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await messaging.unsubscribeFromTopic(topic);
      if (kDebugMode) {
        print('Unsubscribed from topic: $topic');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Failed to unsubscribe from topic: $e');
      }
    }
  }

  // Log analytics event
  Future<void> logEvent({
    required String name,
    Map<String, Object>? parameters,
  }) async {
    try {
      await analytics.logEvent(
        name: name,
        parameters: parameters,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Failed to log analytics event: $e');
      }
    }
  }

  // Helper method to convert dynamic map to Object map
  Map<String, Object>? _convertToObjectMap(Map<String, dynamic>? input) {
    if (input == null) return null;
    return input.map((key, value) => MapEntry(key, value as Object));
  }

  // Log analytics event with dynamic parameters (convenience method)
  Future<void> logEventDynamic({
    required String name,
    Map<String, dynamic>? parameters,
  }) async {
    await logEvent(
      name: name,
      parameters: _convertToObjectMap(parameters),
    );
  }

  // Set user properties
  Future<void> setUserProperties({
    required String userId,
    Map<String, String>? properties,
  }) async {
    try {
      await analytics.setUserId(id: userId);
      if (properties != null) {
        for (var entry in properties.entries) {
          await analytics.setUserProperty(
            name: entry.key,
            value: entry.value,
          );
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Failed to set user properties: $e');
      }
    }
  }

  // Log screen view
  Future<void> logScreenView({
    required String screenName,
    String? screenClass,
  }) async {
    try {
      await analytics.logScreenView(
        screenName: screenName,
        screenClass: screenClass,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Failed to log screen view: $e');
      }
    }
  }

  // Record error in Crashlytics
  Future<void> recordError(
      dynamic exception,
      StackTrace? stack, {
        dynamic reason,
        bool fatal = false,
      }) async {
    try {
      await crashlytics.recordError(
        exception,
        stack,
        reason: reason,
        fatal: fatal,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Failed to record error: $e');
      }
    }
  }

  // Set custom key in Crashlytics
  Future<void> setCrashlyticsKey(String key, dynamic value) async {
    try {
      await crashlytics.setCustomKey(key, value);
    } catch (e) {
      if (kDebugMode) {
        print('Failed to set crashlytics key: $e');
      }
    }
  }

  // Set user identifier in Crashlytics
  Future<void> setCrashlyticsUserId(String userId) async {
    try {
      await crashlytics.setUserIdentifier(userId);
    } catch (e) {
      if (kDebugMode) {
        print('Failed to set crashlytics user id: $e');
      }
    }
  }

  // Upload file to Firebase Storage
  Future<String> uploadFile({
    required String path,
    required String filePath,
    Function(double)? onProgress,
  }) async {
    try {
      final ref = storage.ref().child(path);
      final file = File(filePath);

      final uploadTask = ref.putFile(file);

      // Listen to upload progress
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        final progress = snapshot.bytesTransferred / snapshot.totalBytes;
        onProgress?.call(progress);
      });

      // Wait for upload to complete
      final snapshot = await uploadTask;

      // Get download URL
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      if (kDebugMode) {
        print('Failed to upload file: $e');
      }
      rethrow;
    }
  }

  // Upload file from bytes (for web compatibility)
  Future<String> uploadFileFromBytes({
    required String path,
    required Uint8List bytes,
    String? contentType,
    Function(double)? onProgress,
  }) async {
    try {
      final ref = storage.ref().child(path);

      final metadata = SettableMetadata(
        contentType: contentType,
      );

      final uploadTask = ref.putData(bytes, metadata);

      // Listen to upload progress
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        final progress = snapshot.bytesTransferred / snapshot.totalBytes;
        onProgress?.call(progress);
      });

      // Wait for upload to complete
      final snapshot = await uploadTask;

      // Get download URL
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      if (kDebugMode) {
        print('Failed to upload file from bytes: $e');
      }
      rethrow;
    }
  }

  // Delete file from Firebase Storage
  Future<void> deleteFile(String path) async {
    try {
      await storage.ref().child(path).delete();
    } catch (e) {
      if (kDebugMode) {
        print('Failed to delete file: $e');
      }
      rethrow;
    }
  }

  // Get download URL for a file
  Future<String> getDownloadUrl(String path) async {
    try {
      return await storage.ref().child(path).getDownloadURL();
    } catch (e) {
      if (kDebugMode) {
        print('Failed to get download URL: $e');
      }
      rethrow;
    }
  }

  // Batch write operation
  Future<void> batchWrite(
      List<Map<String, dynamic>> operations,
      ) async {
    try {
      final batch = firestore.batch();

      for (var operation in operations) {
        final type = operation['type'] as String;
        final collection = operation['collection'] as String;
        final docId = operation['docId'] as String;
        final data = operation['data'] as Map<String, dynamic>?;

        final docRef = firestore.collection(collection).doc(docId);

        switch (type) {
          case 'set':
            if (data != null) {
              batch.set(docRef, data);
            }
            break;
          case 'update':
            if (data != null) {
              batch.update(docRef, data);
            }
            break;
          case 'delete':
            batch.delete(docRef);
            break;
        }
      }

      await batch.commit();
    } catch (e) {
      if (kDebugMode) {
        print('Failed to perform batch write: $e');
      }
      rethrow;
    }
  }

  // Transaction operation
  Future<T> runTransaction<T>(
      Future<T> Function(Transaction) transactionHandler,
      ) async {
    try {
      return await firestore.runTransaction(transactionHandler);
    } catch (e) {
      if (kDebugMode) {
        print('Failed to run transaction: $e');
      }
      rethrow;
    }
  }

  // Check if user is authenticated
  bool isAuthenticated() {
    return auth.currentUser != null;
  }

  // Get current user ID
  String? getCurrentUserId() {
    return auth.currentUser?.uid;
  }

  // Listen to auth state changes
  Stream<User?> authStateChanges() {
    return auth.authStateChanges();
  }
}