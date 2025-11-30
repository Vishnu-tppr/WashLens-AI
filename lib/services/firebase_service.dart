import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'dart:io';
import 'package:flutter/foundation.dart'; // Added for debugPrint
import '../models/wash_entry.dart';
import '../models/user_settings.dart';
import 'auth_error_handler.dart';

/// Firebase service for Auth and Storage operations only (NO Firestore - using Supabase + local storage)
class FirebaseService {
  FirebaseAuth? _auth;
  // FirebaseFirestore removed - we use Supabase for database and SharedPreferences for local settings
  FirebaseStorage? _storage;
  bool _isAvailable = false;

  FirebaseService() {
    try {
      _auth = FirebaseAuth.instance;
      _storage = FirebaseStorage.instance;
      _isAvailable = true;
      debugPrint(
          '✅ FirebaseService initialized (Auth + Storage only, NO Firestore)');
    } catch (e) {
      debugPrint('⚠️ Firebase not initialized, running in offline mode: $e');
      _isAvailable = false;
    }
  }

  /// Check if Firebase is available
  bool get isAvailable => _isAvailable;

  /// Get current user
  User? get currentUser => _auth?.currentUser;

  /// Sign in anonymously
  Future<User?> signInAnonymously() async {
    if (!_isAvailable || _auth == null) return null;
    final credential = await _auth!.signInAnonymously();
    return credential.user;
  }

  /// Sign in with email and password
  /// Now returns the User object directly
  Future<User?> signInWithEmailPassword(
    String email,
    String password,
  ) async {
    if (!_isAvailable || _auth == null) return null;
    final credential = await _auth!.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return credential.user;
  }

  /// Sign up with email and password
  /// Now returns the User object directly
  Future<User?> signUpWithEmailPassword(
    String email,
    String password,
  ) async {
    if (!_isAvailable || _auth == null) return null;
    final credential = await _auth!.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    return credential.user;
  }

  /// Sign out
  Future<void> signOut() async {
    if (!_isAvailable || _auth == null) return;
    await _auth!.signOut();
    // Also sign out from Google
    final GoogleSignIn googleSignIn = GoogleSignIn();
    try {
      await googleSignIn.signOut();
    } catch (e) {
      debugPrint('Google Sign-Out failed: $e');
    }
  }



  /// Sign in with Google (enhanced with error handling and retry logic)
  /// Now returns the User object directly
  Future<User?> signInWithGoogle() async {
    if (!_isAvailable || _auth == null) return null;

    // Proceed directly to sign in with retry logic
    return AuthErrorHandler.executeWithRetry<User?>(
      () async {
        // Initialize GoogleSignIn with proper scopes
        final GoogleSignIn googleSignIn = GoogleSignIn(
          scopes: ['email', 'profile'],
        );

        try {
          // Sign out first to clear any stale session and force account picker
          await googleSignIn.signOut();
          debugPrint('🔄 Cleared previous Google Sign-In session');
        } catch (e) {
          debugPrint('⚠️ Sign-out before sign-in failed (expected): $e');
        }

        // Trigger the authentication flow
        debugPrint('📱 Initiating Google Sign-In...');
        final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

        if (googleUser == null) {
          debugPrint('❌ User cancelled Google Sign-In');
          throw AuthError.userCancelled;
        }

        debugPrint('✅ Google account selected: ${googleUser.email}');

        // Obtain the auth details from the request
        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;

        if (googleAuth.idToken == null || googleAuth.accessToken == null) {
          debugPrint('❌ Failed to get Google auth tokens');
          throw AuthError.googleSignInFailed;
        }

        debugPrint('🔑 Google auth tokens obtained');

        // Create a new credential
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        debugPrint('🔐 Signing in to Firebase with Google credentials...');

        // Once signed in, return the User object
        final userCredential = await _auth!.signInWithCredential(credential);
        
        debugPrint('✅ Google sign-in successful for user: ${userCredential.user?.displayName} (${userCredential.user?.email})');
        
        return userCredential.user;
      },
    );
  }

  /// Upload image to Firebase Storage
  Future<String?> uploadImage(File imageFile, String path) async {
    if (!_isAvailable || _storage == null) return null;
    final ref = _storage!.ref().child(path);
    final uploadTask = await ref.putFile(imageFile);
    return await uploadTask.ref.getDownloadURL();
  }

  // NOTE: All Firestore methods removed - we use Supabase for database operations
  // These methods are no longer supported and will do nothing if called
  @Deprecated('Use Supabase for database operations')
  Future<void> saveWashEntry(WashEntry entry) async {
    debugPrint(
        '⚠️ saveWashEntry called but Firestore is disabled - use Supabase');
    return;
  }

  @Deprecated('Use Supabase for database operations')
  Stream<List<WashEntry>> getWashEntriesStream(String userId) {
    debugPrint(
        '⚠️ getWashEntriesStream called but Firestore is disabled - use Supabase');
    return Stream.value([]);
  }

  @Deprecated('Use Supabase for database operations')
  Future<void> updateWashEntry(WashEntry entry) async {
    debugPrint(
        '⚠️ updateWashEntry called but Firestore is disabled - use Supabase');
    return;
  }

  @Deprecated('Use Supabase for database operations')
  Future<void> deleteWashEntry(String userId, String entryId) async {
    debugPrint(
        '⚠️ deleteWashEntry called but Firestore is disabled - use Supabase');
    return;
  }

  // User settings methods - DISABLED (use LocalStorageService instead)
  @Deprecated('Use LocalStorageService for user settings')
  Future<bool> saveUserSettings(UserSettings settings) async {
    debugPrint(
        '⚠️ saveUserSettings called but Firestore is disabled - use LocalStorageService');
    return false;
  }

  @Deprecated('Use LocalStorageService for user settings')
  Future<UserSettings?> getUserSettings(String userId) async {
    debugPrint(
        '⚠️ getUserSettings called but Firestore is disabled - use LocalStorageService');
    return null;
  }

  @Deprecated('Use LocalStorageService for user settings')
  Stream<UserSettings?> getUserSettingsStream(String userId) {
    debugPrint(
        '⚠️ getUserSettingsStream called but Firestore is disabled - use LocalStorageService');
    return Stream.value(null);
  }

  // FCM token methods - DISABLED (tokens stored in local settings now)
  @Deprecated('FCM tokens stored in LocalStorageService now')
  Future<bool> saveFCMToken(String userId, String fcmToken) async {
    debugPrint(
        '⚠️ saveFCMToken called but Firestore is disabled - tokens in local settings');
    return false;
  }

  @Deprecated('FCM tokens stored in LocalStorageService now')
  Future<String?> getFCMToken(String userId) async {
    debugPrint(
        '⚠️ getFCMToken called but Firestore is disabled - tokens in local settings');
    return null;
  }

  @Deprecated('FCM tokens stored in LocalStorageService now')
  Future<bool> removeFCMToken(String userId) async {
    debugPrint(
        '⚠️ removeFCMToken called but Firestore is disabled - tokens in local settings');
    return false;
  }
}
