import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_settings.dart';

/// Local storage service using SharedPreferences for user settings and categories
class LocalStorageService {
  static const String _userSettingsKey = 'user_settings_';
  static const String _categoriesKey = 'user_categories_';
  static const String _washesKey = 'user_washes_';

  /// Save user settings to local storage
  static Future<bool> saveUserSettings(UserSettings settings) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_userSettingsKey${settings.userId}';
      final jsonString = jsonEncode(settings.toJson());
      return await prefs.setString(key, jsonString);
    } catch (e) {
      print('❌ LocalStorage: Error saving settings: $e');
      return false;
    }
  }

  /// Load user settings from local storage
  static Future<UserSettings?> getUserSettings(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_userSettingsKey$userId';
      final jsonString = prefs.getString(key);

      if (jsonString == null) {
        print('📝 LocalStorage: No settings found for user $userId');
        return null;
      }

      final jsonMap = jsonDecode(jsonString) as Map<String, dynamic>;
      print('✅ LocalStorage: Settings loaded for user $userId');
      return UserSettings.fromJson(jsonMap);
    } catch (e) {
      print('❌ LocalStorage: Error loading settings: $e');
      return null;
    }
  }

  /// Delete user settings from local storage
  static Future<bool> deleteUserSettings(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_userSettingsKey$userId';
      return await prefs.remove(key);
    } catch (e) {
      print('❌ LocalStorage: Error deleting settings: $e');
      return false;
    }
  }

  /// Clear all user settings
  static Future<bool> clearAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys =
          prefs.getKeys().where((key) => key.startsWith(_userSettingsKey));
      for (final key in keys) {
        await prefs.remove(key);
      }
      return true;
    } catch (e) {
      print('❌ LocalStorage: Error clearing all: $e');
      return false;
    }
  }

  /// Save login state (persists user session)
  static Future<bool> saveLoginState(String userId, String authProvider) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('logged_in_user_id', userId);
      await prefs.setString('auth_provider', authProvider);
      await prefs.setBool('is_logged_in', true);
      print('✅ LocalStorage: Login state saved for user $userId');
      return true;
    } catch (e) {
      print('❌ LocalStorage: Error saving login state: $e');
      return false;
    }
  }

  /// Check if user is logged in
  static Future<Map<String, String>?> getLoginState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isLoggedIn = prefs.getBool('is_logged_in') ?? false;

      if (!isLoggedIn) {
        print('📝 LocalStorage: No active login session');
        return null;
      }

      final userId = prefs.getString('logged_in_user_id');
      final authProvider = prefs.getString('auth_provider');

      if (userId == null || authProvider == null) {
        print('⚠️ LocalStorage: Incomplete login state');
        return null;
      }

      print('✅ LocalStorage: Found active session for user $userId');
      return {'userId': userId, 'authProvider': authProvider};
    } catch (e) {
      print('❌ LocalStorage: Error checking login state: $e');
      return null;
    }
  }

  /// Clear login state (on logout)
  static Future<bool> clearLoginState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('logged_in_user_id');
      await prefs.remove('auth_provider');
      await prefs.setBool('is_logged_in', false);
      print('✅ LocalStorage: Login state cleared');
      return true;
    } catch (e) {
      print('❌ LocalStorage: Error clearing login state: $e');
      return false;
    }
  }

  // ==================== CATEGORY MANAGEMENT ====================

  /// Save categories to local storage
  static Future<bool> saveCategories(
      String userId, List<Map<String, dynamic>> categories) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_categoriesKey$userId';
      final jsonString = jsonEncode(categories);
      final result = await prefs.setString(key, jsonString);
      print(
          '✅ LocalStorage: Categories saved for user $userId (${categories.length} items)');
      return result;
    } catch (e) {
      print('❌ LocalStorage: Error saving categories: $e');
      return false;
    }
  }

  /// Load categories from local storage
  static Future<List<Map<String, dynamic>>> getCategories(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_categoriesKey$userId';
      final jsonString = prefs.getString(key);

      if (jsonString == null) {
        print('📝 LocalStorage: No categories found for user $userId');
        return [];
      }

      final jsonList = jsonDecode(jsonString) as List<dynamic>;
      final categories = jsonList
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();
      print(
          '✅ LocalStorage: Categories loaded for user $userId (${categories.length} items)');
      return categories;
    } catch (e) {
      print('❌ LocalStorage: Error loading categories: $e');
      return [];
    }
  }

  /// Delete all categories for a user
  static Future<bool> deleteCategories(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_categoriesKey$userId';
      return await prefs.remove(key);
    } catch (e) {
      print('❌ LocalStorage: Error deleting categories: $e');
      return false;
    }
  }

  /// Add a single category
  static Future<bool> addCategory(
      String userId, Map<String, dynamic> category) async {
    try {
      final categories = await getCategories(userId);

      // Generate a unique ID for the category
      final id = DateTime.now().millisecondsSinceEpoch.toString();
      category['id'] = id;

      categories.add(category);
      return await saveCategories(userId, categories);
    } catch (e) {
      print('❌ LocalStorage: Error adding category: $e');
      return false;
    }
  }

  /// Update a single category
  static Future<bool> updateCategory(
      String userId, String categoryId, Map<String, dynamic> updates) async {
    try {
      final categories = await getCategories(userId);
      final index = categories.indexWhere((cat) => cat['id'] == categoryId);

      if (index == -1) {
        print('⚠️ LocalStorage: Category not found: $categoryId');
        return false;
      }

      // Merge updates into existing category
      categories[index] = {...categories[index], ...updates};
      return await saveCategories(userId, categories);
    } catch (e) {
      print('❌ LocalStorage: Error updating category: $e');
      return false;
    }
  }

  /// Delete a single category
  static Future<bool> deleteCategory(String userId, String categoryId) async {
    try {
      final categories = await getCategories(userId);
      final initialLength = categories.length;

      categories.removeWhere((cat) => cat['id'] == categoryId);

      if (categories.length == initialLength) {
        print('⚠️ LocalStorage: Category not found: $categoryId');
        return false;
      }

      return await saveCategories(userId, categories);
    } catch (e) {
      print('❌ LocalStorage: Error deleting category: $e');
      return false;
    }
  }

  // ==================== WASH ENTRY MANAGEMENT ====================

  /// Save wash entries to local storage
  static Future<bool> saveWashes(
      String userId, List<Map<String, dynamic>> washes) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_washesKey$userId';
      final jsonString = jsonEncode(washes);
      final result = await prefs.setString(key, jsonString);
      print(
          '✅ LocalStorage: Washes saved for user $userId (${washes.length} items)');
      return result;
    } catch (e) {  
      print('❌ LocalStorage: Error saving washes: $e');
      return false;
    }
  }

  /// Load wash entries from local storage
  static Future<List<Map<String, dynamic>>> getWashes(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_washesKey$userId';
      final jsonString = prefs.getString(key);

      if (jsonString == null) {
        print('📝 LocalStorage: No washes found for user $userId');
        return [];
      }

      final jsonList = jsonDecode(jsonString) as List<dynamic>;
      final washes = jsonList
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();
      print(
          '✅ LocalStorage: Washes loaded for user $userId (${washes.length} items)');
      return washes;
    } catch (e) {
      print('❌ LocalStorage: Error loading washes: $e');
      return [];
    }
  }

  /// Add a single wash entry
  static Future<bool> addWash(String userId, Map<String, dynamic> wash) async {
    try {
      final washes = await getWashes(userId);

      // Generate a unique ID for the wash entry
      final id = DateTime.now().millisecondsSinceEpoch.toString();
      wash['id'] = id;

      washes.add(wash);
      return await saveWashes(userId, washes);
    } catch (e) {
      print('❌ LocalStorage: Error adding wash: $e');
      return false;
    }
  }

  /// Update a single wash entry
  static Future<bool> updateWash(
      String userId, String washId, Map<String, dynamic> updates) async {
    try {
      final washes = await getWashes(userId);
      final index = washes.indexWhere((wash) => wash['id'] == washId);

      if (index == -1) {
        print('⚠️ LocalStorage: Wash entry not found: $washId');
        return false;
      }

      // Merge updates into existing wash
      washes[index] = {...washes[index], ...updates};
      return await saveWashes(userId, washes);
    } catch (e) {
      print('❌ LocalStorage: Error updating wash: $e');
      return false;
    }
  }

  /// Delete a single wash entry
  static Future<bool> deleteWash(String userId, String washId) async {
    try {
      final washes = await getWashes(userId);
      final initialLength = washes.length;

      washes.removeWhere((wash) => wash['id'] == washId);

      if (washes.length == initialLength) {
        print('⚠️ LocalStorage: Wash entry not found: $washId');
        return false;
      }

      return await saveWashes(userId, washes);
    } catch (e) {
      print('❌ LocalStorage: Error deleting wash: $e');
      return false;
    }
  }
}
