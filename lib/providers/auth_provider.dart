import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// ✅ Core Imports
import '../data/models/user_model.dart';
import '../data/repositories/auth_repository.dart';
import '../data/repositories/user_repository.dart';
import '../data/services/notification_service_ENHANCED.dart';
import '../core/utils/notification_triggers.dart';
import '../utils/database_initializer.dart';

class AuthProvider with ChangeNotifier {
  final AuthRepository _authRepository = AuthRepository();
  final UserRepository _userRepository = UserRepository();
  final NotificationService _notificationService = NotificationService();

  UserModel? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isLoggedIn = false;
  bool _isInitialized = false;

  // ✅ FIXED: References to other providers for cleanup
  dynamic _resourceProvider;
  dynamic _chatProvider;
  dynamic _analyticsProvider; // ✅ ADDED

  // ═══════════════════════════════════════════════════════════════
  // GETTERS
  // ═══════════════════════════════════════════════════════════════
  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isLoggedIn => _isLoggedIn;
  bool get isInitialized => _isInitialized;

  /// 🔐 SECURE ADMIN CHECK
  bool get isAdmin => _currentUser?.role == 'admin';

  AuthProvider() {
    _initializeAuth();
  }

  // ═══════════════════════════════════════════════════════════════
  // ✅ SET PROVIDER REFERENCES - UPDATED
  // ═══════════════════════════════════════════════════════════════

  void setProviderReferences({
    dynamic resourceProvider,
    dynamic chatProvider,
    dynamic analyticsProvider, // ✅ ADDED
  }) {
    _resourceProvider = resourceProvider;
    _chatProvider = chatProvider;
    _analyticsProvider = analyticsProvider; // ✅ ADDED

    debugPrint('✅ Provider references connected for stream management');
  }

  /// ✅ Real-time listener for Auth State Changes
  Future<void> _initializeAuth() async {
    _authRepository.authStateChanges.listen((User? user) async {
      if (user != null) {
        if (kDebugMode) print('🔄 Auth State: User ${user.uid} detected');
        await _loadUserData(user.uid);
      } else {
        if (kDebugMode) print('🔄 Auth State: No user (Logged Out)');
        _currentUser = null;
        _isLoggedIn = false;
        _isInitialized = true;
        notifyListeners();
      }
    });
  }

  /// ✅ Explicitly check auth state during splash/app start
  Future<void> checkAuthState() async {
    try {
      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser != null) {
        await _loadUserData(firebaseUser.uid);
      } else {
        _isLoggedIn = false;
        _currentUser = null;
        _isInitialized = true;
        Future.microtask(() => notifyListeners());
      }
    } catch (e) {
      _isLoggedIn = false;
      _isInitialized = true;
      Future.microtask(() => notifyListeners());
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // USER DATA LOADING & SYNC
  // ═══════════════════════════════════════════════════════════════

  Future<void> _loadUserData(String userId) async {
    try {
      UserModel? user = await _userRepository.getUserById(userId);

      if (user == null) {
        final firebaseUser = FirebaseAuth.instance.currentUser;
        if (firebaseUser != null) {
          user = UserModel(
            id: firebaseUser.uid,
            name: firebaseUser.displayName ?? 'User',
            email: firebaseUser.email ?? '',
            photoUrl: firebaseUser.photoURL,
            role: 'student',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            emailVerified: firebaseUser.emailVerified,
            isActive: true,
          );
          await _userRepository.createUser(user);
        }
      }

      if (user != null) {
        _currentUser = user;
        _isLoggedIn = true;
        _errorMessage = null;
        _isInitialized = true;

        unawaited(_syncNotificationToken(userId));

        if (isAdmin) {
          unawaited(DatabaseInitializer().initialize());
        }

        notifyListeners();
      }
    } catch (e) {
      _errorMessage = 'Failed to load user profile.';
      _isInitialized = true;
      notifyListeners();
    }
  }

  Future<void> _syncNotificationToken(String userId) async {
    try {
      String? token = await _notificationService.getDeviceToken();
      if (token != null) {
        await FirebaseFirestore.instance.collection('users').doc(userId).update({
          'fcmToken': token,
          'lastActive': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      if (kDebugMode) print('! Token sync failed: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // AUTHENTICATION METHODS WITH NOTIFICATIONS
  // ═══════════════════════════════════════════════════════════════

  /// ✅ Sign in with Google + Notification
  Future<bool> signInWithGoogle() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final userCredential = await _authRepository.signInWithGoogle();
      if (userCredential.user != null) {
        await _loadUserData(userCredential.user!.uid);

        // ✅ UPDATE NOTIFICATION SERVICE
        await _notificationService.updateUserId(userCredential.user!.uid);

        _isLoading = false;
        notifyListeners();
        return true;
      }
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      _errorMessage = _getErrorMessage(e);
      notifyListeners();
      return false;
    }
  }

  /// ✅ Sign in with Email + Notification
  Future<bool> signInWithEmail(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final cred = await _authRepository.signInWithEmail(email, password);
      if (cred.user != null) {
        await _loadUserData(cred.user!.uid);

        // ✅ UPDATE NOTIFICATION SERVICE
        await _notificationService.updateUserId(cred.user!.uid);

        _isLoading = false;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _isLoading = false;
      _errorMessage = _getErrorMessage(e);
      notifyListeners();
      return false;
    }
  }

  /// ✅ Sign up with Email + Welcome Notification
  Future<bool> signUpWithEmail({
    required String email,
    required String password,
    required String name,
    required String phone,
    required String college,
    required String department,
    required String semester,
    required String batchYear,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final cred = await _authRepository.signUpWithEmail(email, password);
      if (cred.user != null) {
        final newUser = UserModel(
          id: cred.user!.uid,
          name: name,
          email: email,
          phone: phone,
          role: 'student',
          college: college,
          department: department,
          semester: semester,
          batchYear: batchYear,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          emailVerified: false,
          isActive: true,
        );

        await _userRepository.createUser(newUser);
        await cred.user!.sendEmailVerification();

        _currentUser = newUser;
        _isLoggedIn = true;

        // ✅ WELCOME NOTIFICATION
        await NotificationTriggers.welcome(name);
        await NotificationTriggers.registrationSuccess(name);

        // ✅ UPDATE NOTIFICATION SERVICE
        await _notificationService.updateUserId(cred.user!.uid);

        _isLoading = false;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _isLoading = false;
      _errorMessage = _getErrorMessage(e);
      notifyListeners();
      return false;
    }
  }

  /// ✅ Reset Password + Notification
  Future<bool> resetPassword(String email) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authRepository.resetPassword(email);

      // ✅ PASSWORD RESET NOTIFICATION (if user is logged in)
      if (_currentUser != null) {
        await NotificationTriggers.passwordChanged();
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = _getErrorMessage(e);
      notifyListeners();
      return false;
    }
  }

  /// ✅ Update User Profile + Notification
  Future<bool> updateUserProfile(UserModel updatedUser) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Check if college changed
      bool collegeChanged = _currentUser?.college != updatedUser.college;
      String? newCollege = updatedUser.college;

      await _userRepository.updateUser(updatedUser);
      _currentUser = updatedUser;

      // ✅ PROFILE UPDATE NOTIFICATION
      await NotificationTriggers.profileUpdated();

      // ✅ COLLEGE CHANGE NOTIFICATION
      if (collegeChanged && newCollege != null) {
        await NotificationTriggers.collegeChanged(newCollege);
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = _getErrorMessage(e);
      notifyListeners();
      return false;
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // ✅ SIGN OUT WITH NOTIFICATIONS & STREAM CANCELLATION - FIXED
  // ═══════════════════════════════════════════════════════════════

  Future<void> signOut() async {
    if (kDebugMode) print('🔓 Signing out from Firebase and Google...');

    _isLoading = true;
    notifyListeners();

    try {
      // ✅ STEP 1: Clear notification service
      await _notificationService.clearUser();
      await NotificationTriggers.cancelAll();

      // ✅ STEP 2: Cancel ALL Firestore streams BEFORE signing out
      if (_resourceProvider != null) {
        try {
          await _resourceProvider.cancelStreams();
        } catch (e) {
          if (kDebugMode) print('⚠️ ResourceProvider stream cancellation warning: $e');
        }
      }

      if (_chatProvider != null) {
        try {
          await _chatProvider.cancelStreams();
        } catch (e) {
          if (kDebugMode) print('⚠️ ChatProvider stream cancellation warning: $e');
        }
      }

      // ✅ STEP 2.5: Cancel AnalyticsProvider streams - NEW
      if (_analyticsProvider != null) {
        try {
          await _analyticsProvider.cancelStreams();
          _analyticsProvider.reset(); // Clear all data
          if (kDebugMode) print('✅ AnalyticsProvider streams cancelled');
        } catch (e) {
          if (kDebugMode) print('⚠️ AnalyticsProvider stream cancellation warning: $e');
        }
      }

      // ✅ STEP 3: Remove FCM token from Firestore
      if (_currentUser != null) {
        try {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(_currentUser!.id)
              .update({
            'fcmToken': FieldValue.delete(),
          });
        } catch (e) {
          if (kDebugMode) print('⚠️ FCM token removal warning: $e');
        }
      }

      // ✅ STEP 4: Clear local user data
      _currentUser = null;
      _isLoggedIn = false;

      // ✅ STEP 5: Sign out from Firebase Auth & Google
      await _authRepository.signOut();

      if (kDebugMode) print('✅ Firebase sign out successful');

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      if (kDebugMode) print('❌ Sign out error: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // 🔥 NEW: APP RESUME HANDLER - CRITICAL FIX FOR WHITE SCREEN
  // ═══════════════════════════════════════════════════════════════

  /// Refresh authentication state when app resumes from background
  Future<void> refreshAuth() async {
    try {
      debugPrint('🔄 Refreshing auth state on app resume...');

      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Reload Firebase user to get latest data
        await user.reload();

        // Re-fetch user from Firestore
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (userDoc.exists) {
          _currentUser = UserModel.fromMap(userDoc.data()!);
          _isLoggedIn = true;
          _errorMessage = null;
          notifyListeners();
          debugPrint('✅ Auth refreshed successfully');
        }
      } else {
        // User logged out while app was in background
        _currentUser = null;
        _isLoggedIn = false;
        notifyListeners();
        debugPrint('ℹ️ No user found on resume');
      }
    } catch (e) {
      debugPrint('⚠️ Auth refresh error: $e');
      // Don't throw error, just log it
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  String _getErrorMessage(dynamic error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'user-not-found': return 'No account found with this email.';
        case 'wrong-password': return 'Incorrect password.';
        case 'email-already-in-use': return 'Email already registered.';
        default: return error.message ?? 'Authentication failed.';
      }
    }
    return error.toString();
  }
}