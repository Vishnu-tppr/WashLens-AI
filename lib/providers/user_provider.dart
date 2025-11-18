import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthUser;
import '../services/firebase_service.dart';
import '../services/supabase_service.dart';
import '../models/user_settings.dart';
import '../models/app_user.dart' as models;

/// User provider for managing user data and settings (supports both Supabase and Firebase auth)
class UserProvider with ChangeNotifier {
  models.AuthUser? _currentAuthUser;
  models.AppUser? _currentAppUser;
  UserSettings? _userSettings;
  bool _isLoading = false;
  String? _error;
  String _authProvider = 'supabase'; // Track which auth provider is active

  UserProvider();

  // Getters
  models.AuthUser? get currentUser => _currentAuthUser;
  UserSettings? get userSettings => _userSettings;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _currentAuthUser != null;
  String get authProvider => _authProvider;

  String get userName {
    // Priority 1: Display name from Supabase metadata
    if (_authProvider == 'supabase' && _currentAuthUser?.displayName != null && _currentAuthUser!.displayName!.isNotEmpty) {
      return _currentAuthUser!.displayName!;
    }

    // Priority 2: Display name from Firebase
    if (_authProvider == 'firebase' && _currentAuthUser?.displayName != null && _currentAuthUser!.displayName!.isNotEmpty) {
      return _currentAuthUser!.displayName!;
    }

    // Fallback: Email prefix
    return _currentAuthUser?.email?.split('@').first ?? 'User';
  }

  String get userEmail => _currentAuthUser?.email ?? '';

  /// Initialize provider with current user and settings (check Supabase first)
  Future<void> initialize() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // First check Supabase
      final supabaseUser = SupabaseService.currentUser;
      if (supabaseUser != null) {
        _currentAuthUser = models.SupabaseAuthUser(supabaseUser);
        _authProvider = 'supabase';
        await _loadUserSettings();
        return;
      }

      // Then check Firebase
      final firebaseUser = firebase_auth.FirebaseAuth.instance.currentUser;
      if (firebaseUser != null) {
        _currentAuthUser = models.FirebaseAuthUser(firebaseUser);
        _authProvider = 'firebase';
        await _loadUserSettings();
        return;
      }
    } catch (e) {
      _error = e.toString();
      debugPrint('Error initializing user provider: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load user settings from Firebase (both user types share the same settings)
  Future<void> _loadUserSettings() async {
    if (_currentAuthUser == null) return;

    try {
      final firebaseService = FirebaseService();
      final settings = await firebaseService.getUserSettings(_currentAuthUser!.id);

      if (settings != null) {
        _userSettings = settings;
      } else {
        // Create default settings if none exist
        _userSettings = UserSettings(
          userId: _currentAuthUser!.id,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        // Save default settings
        await firebaseService.saveUserSettings(_userSettings!);
      }
    } catch (e) {
      _error = e.toString();
      debugPrint('Error loading user settings: $e');
    }
  }

  /// Update user settings
  Future<bool> updateUserSettings(UserSettings newSettings) async {
    if (_currentAuthUser == null) return false;

    try {
      final firebaseService = FirebaseService();
      newSettings = newSettings.copyWith(
        updatedAt: DateTime.now(),
      );

      final success = await firebaseService.saveUserSettings(newSettings);
      if (success) {
        _userSettings = newSettings;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _error = e.toString();
      debugPrint('Error updating user settings: $e');
      return false;
    }
  }

  /// Set current user from Supabase auth
  void setCurrentSupabaseUser(User? user) {
    if (user != null) {
      _currentAuthUser = models.SupabaseAuthUser(user);
      _authProvider = 'supabase';
      _loadUserSettings();
    } else {
      _currentAuthUser = null;
      _authProvider = 'none';
      _userSettings = null;
    }
    notifyListeners();
  }

  /// Set current user from Firebase auth
  void setCurrentFirebaseUser(firebase_auth.User? user) {
    if (user != null) {
      _currentAuthUser = models.FirebaseAuthUser(user);
      _authProvider = 'firebase';
      _loadUserSettings();
    } else {
      _currentAuthUser = null;
      _authProvider = 'none';
      _userSettings = null;
    }
    notifyListeners();
  }

  /// Sign out from appropriate provider
  Future<void> signOut() async {
    try {
      if (_authProvider == 'firebase') {
        await firebase_auth.FirebaseAuth.instance.signOut();
      } else if (_authProvider == 'supabase') {
        await SupabaseService.signOut();
      }

      // Cleanup both providers
      await firebase_auth.FirebaseAuth.instance.signOut();
      await SupabaseService.signOut();
    } catch (e) {
      debugPrint('Error during sign out: $e');
    } finally {
      _currentAuthUser = null;
      _authProvider = 'none';
      _userSettings = null;
      _error = null;
      notifyListeners();
    }
  }

  /// Refresh current user data (useful after profile updates)
  Future<void> refreshCurrentUser() async {
    if (_authProvider == 'supabase') {
      final supabaseUser = SupabaseService.currentUser;
      if (supabaseUser != null) {
        _currentAuthUser = models.SupabaseAuthUser(supabaseUser);
        notifyListeners();
      }
    } else if (_authProvider == 'firebase') {
      final firebaseUser = firebase_auth.FirebaseAuth.instance.currentUser;
      if (firebaseUser != null) {
        _currentAuthUser = models.FirebaseAuthUser(firebaseUser);
        notifyListeners();
      }
    }
  }

  /// Start auth state listeners for both providers
  void startAuthListeners() {
    // Listen to Supabase auth changes
    Supabase.instance.client.auth.onAuthStateChange.listen((event) {
      final user = event.session?.user;
      setCurrentSupabaseUser(user);
    });

    // Listen to Firebase auth changes
    firebase_auth.FirebaseAuth.instance.authStateChanges().listen((firebase_auth.User? user) {
      setCurrentFirebaseUser(user);
    });
  }
}
