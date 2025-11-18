import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Supabase service for backend operations
/// Add your Supabase URL and Anon Key in the initialize method
class SupabaseService {
  static SupabaseClient? _client;
  static bool _isInitialized = false;

  /// Initialize Supabase
  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Load credentials from .env file
      final supabaseUrl = dotenv.env['SUPABASE_URL'] ?? '';
      final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? '';

      if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
        throw Exception('Supabase credentials not found in .env file');
      }

      await Supabase.initialize(
        url: supabaseUrl,
        anonKey: supabaseAnonKey,
      );

      _client = Supabase.instance.client;
      _isInitialized = true;
      debugPrint('Supabase initialized successfully');
    } catch (e) {
      debugPrint('Supabase initialization failed: $e');
      debugPrint('App will run in demo mode without backend');
    }
  }

  /// Get Supabase client
  static SupabaseClient? get client => _client;

  /// Check if Supabase is available
  static bool get isAvailable => _isInitialized && _client != null;

  // ============================================================================
  // WASH ENTRIES
  // ============================================================================

  /// Save wash entry
  static Future<Map<String, dynamic>?> saveWashEntry(
    Map<String, dynamic> data,
  ) async {
    if (!isAvailable) return null;
    try {
      final response =
          await _client!.from('wash_entries').insert(data).select();
      return response.first;
    } catch (e) {
      debugPrint('Error saving wash entry: $e');
      return null;
    }
  }

  /// Get wash entries for user
  static Future<List<Map<String, dynamic>>> getWashEntries(
    String userId,
  ) async {
    if (!isAvailable) return [];
    try {
      final response = await _client!
          .from('wash_entries')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error fetching wash entries: $e');
      return [];
    }
  }

  /// Update wash entry
  static Future<bool> updateWashEntry(
    String id,
    Map<String, dynamic> data,
  ) async {
    if (!isAvailable) return false;
    try {
      await _client!.from('wash_entries').update(data).eq('id', id);
      return true;
    } catch (e) {
      debugPrint('Error updating wash entry: $e');
      return false;
    }
  }

  /// Delete wash entry
  static Future<bool> deleteWashEntry(String id) async {
    if (!isAvailable) return false;
    try {
      await _client!.from('wash_entries').delete().eq('id', id);
      return true;
    } catch (e) {
      debugPrint('Error deleting wash entry: $e');
      return false;
    }
  }

  // ============================================================================
  // DHOBIS
  // ============================================================================

  /// Save dhobi
  static Future<Map<String, dynamic>?> saveDhobi(
    Map<String, dynamic> data,
  ) async {
    if (!isAvailable) return null;
    try {
      final response = await _client!.from('dhobis').insert(data).select();
      return response.first;
    } catch (e) {
      debugPrint('Error saving dhobi: $e');
      return null;
    }
  }

  /// Get dhobis for user
  static Future<List<Map<String, dynamic>>> getDhobis(String userId) async {
    if (!isAvailable) return [];
    try {
      final response =
          await _client!.from('dhobis').select().eq('user_id', userId);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error fetching dhobis: $e');
      return [];
    }
  }

  // ============================================================================
  // CATEGORIES
  // ============================================================================

  /// Get categories for user
  static Future<List<Map<String, dynamic>>> getCategories(
    String userId,
  ) async {
    if (!isAvailable) return [];
    try {
      final response =
          await _client!.from('categories').select().eq('user_id', userId);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error fetching categories: $e');
      return [];
    }
  }

  /// Save category
  static Future<Map<String, dynamic>?> saveCategory(
    Map<String, dynamic> data,
  ) async {
    if (!isAvailable) return null;
    try {
      final response = await _client!.from('categories').insert(data).select();
      return response.first;
    } catch (e) {
      debugPrint('Error saving category: $e');
      return null;
    }
  }

  // ============================================================================
  // AUTHENTICATION
  // ============================================================================

  /// Sign in anonymously
  static Future<User?> signInAnonymously() async {
    if (!isAvailable) return null;
    try {
      final response = await _client!.auth.signInAnonymously();
      return response.user;
    } catch (e) {
      debugPrint('Error signing in anonymously: $e');
      return null;
    }
  }

  /// Sign in with email and password
  static Future<User?> signInWithPassword(String email, String password) async {
    if (!isAvailable) return null;
    try {
      final response = await _client!.auth.signInWithPassword(
        email: email,
        password: password,
      );
      return response.user;
    } catch (e) {
      debugPrint('Error signing in with email/password: $e');
      rethrow; // Re-throw to handle in UI
    }
  }

  /// Sign up with email and password
  static Future<User?> signUpWithPassword(String email, String password, {String? roomNumber}) async {
    if (!isAvailable) return null;
    try {
      final response = await _client!.auth.signUp(
        email: email,
        password: password,
        data: roomNumber != null ? {'room_number': roomNumber} : null,
      );
      return response.user;
    } catch (e) {
      debugPrint('Error signing up with email/password: $e');
      rethrow; // Re-throw to handle in UI
    }
  }

  /// Sign in with Google
  static Future<void> signInWithGoogle() async {
    if (!isAvailable) throw Exception('Supabase not available');
    try {
      await _client!.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: null, // Use default or set to your redirect URL
      );
      // OAuth sign-in will redirect or open browser. The user will be logged in
      // automatically when they return to the app via the auth state listener.
    } catch (e) {
      debugPrint('Error signing in with Google: $e');
      rethrow;
    }
  }

  /// Send password reset email
  static Future<void> resetPassword(String email) async {
    if (!isAvailable) throw Exception('Supabase not available');
    try {
      await _client!.auth.resetPasswordForEmail(email);
    } catch (e) {
      debugPrint('Error resetting password: $e');
      rethrow; // Re-throw to handle in UI
    }
  }

  /// Get current user
  static User? get currentUser => _client?.auth.currentUser;

  /// Sign out
  static Future<void> signOut() async {
    if (!isAvailable) return;
    try {
      await _client!.auth.signOut();
    } catch (e) {
      debugPrint('Error signing out: $e');
    }
  }

  // ============================================================================
  // STORAGE (for images)
  // ============================================================================

  /// Upload image
  static Future<String?> uploadImage(
    String bucket,
    String path,
    List<int> bytes,
  ) async {
    if (!isAvailable) return null;
    try {
      final uint8Bytes = Uint8List.fromList(bytes);
      await _client!.storage.from(bucket).uploadBinary(path, uint8Bytes);
      final url = _client!.storage.from(bucket).getPublicUrl(path);
      return url;
    } catch (e) {
      debugPrint('Error uploading image: $e');
      return null;
    }
  }

  /// Get public URL for image
  static String? getPublicUrl(String bucket, String path) {
    if (!isAvailable) return null;
    return _client!.storage.from(bucket).getPublicUrl(path);
  }
}
