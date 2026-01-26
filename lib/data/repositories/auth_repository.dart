import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';

class AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email'],
  );

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Auth state stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign in with email and password
  Future<UserCredential> signInWithEmail(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      rethrow;
    }
  }

  // Sign up with email and password
  Future<UserCredential> signUpWithEmail(String email, String password) async {
    try {
      return await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      rethrow;
    }
  }

  // Sign in with Google - FIXED VERSION
  Future<UserCredential> signInWithGoogle() async {
    try {
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      // If user cancels the sign-in
      if (googleUser == null) {
        throw FirebaseAuthException(
          code: 'sign-in-cancelled',
          message: 'Google sign-in was cancelled',
        );
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth =
      await googleUser.authentication;

      // Verify we have the required tokens
      if (googleAuth.accessToken == null || googleAuth.idToken == null) {
        throw FirebaseAuthException(
          code: 'missing-auth-token',
          message: 'Missing Google Auth Token',
        );
      }

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      return await _auth.signInWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      // Clean up on Firebase auth error
      await _googleSignIn.signOut();
      if (kDebugMode) {
        print('FirebaseAuthException: ${e.code} - ${e.message}');
      }
      rethrow;
    } catch (e) {
      // Clean up on any other error
      await _googleSignIn.signOut();
      if (kDebugMode) {
        print('Google Sign In Error: $e');
      }
      throw FirebaseAuthException(
        code: 'google-sign-in-failed',
        message: 'Failed to sign in with Google: ${e.toString()}',
      );
    }
  }

  // Sign in with phone number
  Future<void> signInWithPhone(
      String phoneNumber, {
        required Function(String) onCodeSent,
        required Function(UserCredential) onVerificationCompleted,
        required Function(String) onVerificationFailed,
      }) async {
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          final userCredential = await _auth.signInWithCredential(credential);
          onVerificationCompleted(userCredential);
        },
        verificationFailed: (FirebaseAuthException e) {
          onVerificationFailed(e.message ?? 'Verification failed');
        },
        codeSent: (String verificationId, int? resendToken) {
          onCodeSent(verificationId);
        },
        codeAutoRetrievalTimeout: (String verificationId) {},
        timeout: const Duration(seconds: 60),
      );
    } catch (e) {
      rethrow;
    }
  }

  // Verify phone OTP
  Future<UserCredential> verifyPhoneOtp(String verificationId, String otp) async {
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: otp,
      );
      return await _auth.signInWithCredential(credential);
    } catch (e) {
      rethrow;
    }
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      rethrow;
    }
  }

  // Change password
  Future<void> changePassword(String newPassword) async {
    try {
      await _auth.currentUser?.updatePassword(newPassword);
    } catch (e) {
      rethrow;
    }
  }

  // Send email verification
  Future<void> sendEmailVerification() async {
    try {
      await _auth.currentUser?.sendEmailVerification();
    } catch (e) {
      rethrow;
    }
  }

  // Reload user
  Future<void> reloadUser() async {
    try {
      await _auth.currentUser?.reload();
    } catch (e) {
      rethrow;
    }
  }

  // ✅ FIXED: Sign out with better cleanup and error handling
  Future<void> signOut() async {
    try {
      if (kDebugMode) print('🔓 Signing out from Firebase and Google...');

      // Check if signed in with Google
      final isGoogleUser = _auth.currentUser?.providerData.any(
            (provider) => provider.providerId == 'google.com',
      ) ?? false;

      // Sign out from Firebase first
      await _auth.signOut();

      // Then sign out from Google if applicable
      if (isGoogleUser) {
        try {
          await _googleSignIn.signOut();
          if (kDebugMode) print('✅ Google sign out successful');
        } catch (e) {
          if (kDebugMode) print('⚠️ Google sign out warning: $e');
          // Continue even if Google sign out fails
        }
      }

      // ✅ Additional cleanup: disconnect Google account
      try {
        await _googleSignIn.disconnect();
      } catch (e) {
        // Ignore disconnect errors
        if (kDebugMode) print('⚠️ Google disconnect warning: $e');
      }

      if (kDebugMode) print('✅ Firebase sign out successful');
    } catch (e) {
      if (kDebugMode) print('❌ Sign out error: $e');

      // ✅ Force cleanup even if errors occur
      try {
        await _googleSignIn.signOut();
        await _googleSignIn.disconnect();
      } catch (cleanupError) {
        if (kDebugMode) print('⚠️ Cleanup error: $cleanupError');
      }

      rethrow;
    }
  }

  // Delete account
  Future<void> deleteAccount() async {
    try {
      await _auth.currentUser?.delete();
    } catch (e) {
      rethrow;
    }
  }

  // Check if user is signed in with Google
  bool isSignedInWithGoogle() {
    final user = _auth.currentUser;
    if (user == null) return false;

    return user.providerData.any(
          (provider) => provider.providerId == 'google.com',
    );
  }
}