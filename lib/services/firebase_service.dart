import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'dart:io';
import 'package:flutter/foundation.dart'; // Added for debugPrint
import '../models/wash_entry.dart';
import '../models/user_settings.dart';
import 'auth_error_handler.dart';

/// Firebase service for cloud operations
class FirebaseService {
  FirebaseAuth? _auth;
  FirebaseFirestore? _firestore;
  FirebaseStorage? _storage;
  bool _isAvailable = false;

  FirebaseService() {
    try {
      _auth = FirebaseAuth.instance;
      _firestore = FirebaseFirestore.instance;
      _storage = FirebaseStorage.instance;
      _isAvailable = true;
    } catch (e) {
      // Use debugPrint instead of print for Flutter
      debugPrint('Firebase not initialized, running in offline mode: $e');
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

    return AuthErrorHandler.executeWithRetry<User?>(
      () async {
        // Trigger the authentication flow
        final GoogleSignIn googleSignIn = GoogleSignIn();
        final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

        if (googleUser == null) {
          // User cancelled the sign-in
          throw AuthError.userCancelled;
        }

        // Obtain the auth details from the request
        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

        if (googleAuth.idToken == null || googleAuth.accessToken == null) {
          throw AuthError.googleSignInFailed;
        }

        // Create a new credential
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        // Once signed in, return the User object
        final userCredential = await _auth!.signInWithCredential(credential);
        debugPrint('Google sign-in successful for user: ${userCredential.user?.displayName}');
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

  /// Save wash entry to Firestore
  Future<void> saveWashEntry(WashEntry entry) async {
    if (!_isAvailable || _firestore == null) return;
    await _firestore!
        .collection('users')
        .doc(entry.userId)
        .collection('wash_entries')
        .doc(entry.id)
        .set(entry.toJson());
  }

  /// Get wash entries for user
  Stream<List<WashEntry>> getWashEntriesStream(String userId) {
    if (!_isAvailable || _firestore == null) {
      return Stream.value([]);
    }
    return _firestore!
        .collection('users')
        .doc(userId)
        .collection('wash_entries')
        .orderBy('givenAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => WashEntry.fromJson(doc.data()))
              .toList(),
        );
  }

  /// Update wash entry
  Future<void> updateWashEntry(WashEntry entry) async {
    if (!_isAvailable || _firestore == null) return;
    await _firestore!
        .collection('users')
        .doc(entry.userId)
        .collection('wash_entries')
        .doc(entry.id)
        .update(entry.toJson());
  }

  /// Delete wash entry
  Future<void> deleteWashEntry(String userId, String entryId) async {
    if (!_isAvailable || _firestore == null) return;
    await _firestore!
        .collection('users')
        .doc(userId)
        .collection('wash_entries')
        .doc(entryId)
        .delete();
  }

  /// Save user settings
  Future<bool> saveUserSettings(UserSettings settings) async {
    if (!_isAvailable || _firestore == null) return false;
    try {
      await _firestore!
          .collection('users')
          .doc(settings.userId)
          .set(settings.toJson());
      return true;
    } catch (e) {
      debugPrint('Error saving user settings: $e');
      return false;
    }
  }

  /// Get user settings
  Future<UserSettings?> getUserSettings(String userId) async {
    if (!_isAvailable || _firestore == null) return null;
    final doc = await _firestore!.collection('users').doc(userId).get();
    if (!doc.exists) return null;
    return UserSettings.fromJson(doc.data()!);
  }

  /// Stream user settings
  Stream<UserSettings?> getUserSettingsStream(String userId) {
    if (!_isAvailable || _firestore == null) {
      return Stream.value(null);
    }
    return _firestore!.collection('users').doc(userId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return UserSettings.fromJson(doc.data()!);
    });
  }
}