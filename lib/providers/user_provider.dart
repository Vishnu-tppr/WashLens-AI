import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthUser;
import '../services/local_storage_service.dart';
import '../models/user_settings.dart';
import '../models/app_user.dart' as models;

/// User provider for managing user data and settings (supports both Supabase and Firebase auth)
class UserProvider with ChangeNotifier {
  models.AuthUser? _currentAuthUser;
  UserSettings? _userSettings;
  List<Map<String, dynamic>> _categories = [];
  bool _isCategoriesLoading = false;
  bool _isLoading = false;
  String? _error;
  String _authProvider = 'supabase'; // Track which auth provider is active

  UserProvider();

  // Getters
  models.AuthUser? get currentUser => _currentAuthUser;
  UserSettings? get userSettings => _userSettings;
  List<Map<String, dynamic>> get categories => _categories;
  bool get isCategoriesLoading => _isCategoriesLoading;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _currentAuthUser != null;
  String get authProvider => _authProvider;

  String get userName {
    // Priority 1: Display name from Supabase metadata
    if (_authProvider == 'supabase' &&
        _currentAuthUser?.displayName != null &&
        _currentAuthUser!.displayName!.isNotEmpty) {
      return _currentAuthUser!.displayName!;
    }

    // Priority 2: Display name from Firebase
    if (_authProvider == 'firebase' &&
        _currentAuthUser?.displayName != null &&
        _currentAuthUser!.displayName!.isNotEmpty) {
      return _currentAuthUser!.displayName!;
    }

    // Fallback: Email prefix
    return _currentAuthUser?.email?.split('@').first ?? 'User';
  }

  String get userEmail => _currentAuthUser?.email ?? '';

  /// Initialize the provider by checking for existing auth sessions
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      // First check Supabase
      final supabaseSession = Supabase.instance.client.auth.currentSession;
      final supabaseUser = supabaseSession?.user;
      if (supabaseUser != null) {
        debugPrint('✅ UserProvider: Found Supabase user');
        _currentAuthUser = models.SupabaseAuthUser(supabaseUser);
        _authProvider = 'supabase';
        await _loadUserSettings();
        debugPrint('✅ UserProvider: Supabase initialization complete');
        return;
      }

      // Then check Firebase
      final firebaseUser = firebase_auth.FirebaseAuth.instance.currentUser;
      if (firebaseUser != null) {
        debugPrint('✅ UserProvider: Found Firebase user');
        _currentAuthUser = models.FirebaseAuthUser(firebaseUser);
        _authProvider = 'firebase';
        await _loadUserSettings();
        debugPrint('✅ UserProvider: Firebase initialization complete');
        return;
      }

      debugPrint('⚠️ UserProvider: No authenticated user found');
    } catch (e) {
      _error = e.toString();
      debugPrint('❌ UserProvider: Error during initialization: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
      debugPrint(
          '🏁 UserProvider: Initialization finished (loading: $_isLoading, hasSettings: ${_userSettings != null})');
    }
  }

  /// Load user settings from local storage
  Future<void> _loadUserSettings() async {
    if (_currentAuthUser == null) {
      debugPrint('⚠️ UserProvider: Cannot load settings - no current user');
      _userSettings = null;
      return;
    }

    debugPrint(
        '📊 UserProvider: Loading settings from local storage for user ${_currentAuthUser!.id}');
    try {
      final settings =
          await LocalStorageService.getUserSettings(_currentAuthUser!.id);

      if (settings != null) {
        debugPrint('✅ UserProvider: Found existing settings in local storage');
        _userSettings = settings;
      } else {
        debugPrint('📝 UserProvider: Creating new default settings');
        final now = DateTime.now();
        _userSettings = UserSettings(
          userId: _currentAuthUser!.id,
          enableNotifications: true,
          enablePushNotifications: true,
          createdAt: now,
          updatedAt: now,
        );
        try {
          await LocalStorageService.saveUserSettings(_userSettings!);
          debugPrint('✅ UserProvider: Default settings saved to local storage');
        } catch (e) {
          debugPrint(
              '⚠️ UserProvider: Failed to save default settings, using in-memory: $e');
        }
      }

      debugPrint('✅ UserProvider: Settings loaded successfully');
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      debugPrint('❌ UserProvider: Error loading user settings: $e');
      // Create emergency fallback settings if we can't load
      debugPrint('🆘 UserProvider: Creating emergency fallback settings');
      final now = DateTime.now();
      _userSettings = UserSettings(
        userId: _currentAuthUser!.id,
        enableNotifications: true,
        createdAt: now,
        updatedAt: now,
      );
      notifyListeners();
    }
  }

  /// Update user settings (local storage)
  Future<bool> updateUserSettings(UserSettings newSettings) async {
    if (_currentAuthUser == null) return false;

    try {
      final success =
          await LocalStorageService.saveUserSettings(newSettings);

      if (success) {
        _userSettings = newSettings;
        notifyListeners();
        debugPrint('✅ UserProvider: Settings updated in local storage');
        return true;
      }
      return false;
    } catch (e) {
      _error = e.toString();
      debugPrint('❌ UserProvider: Error updating user settings: $e');
      return false;
    }
  }

  /// Set current user from Supabase (async to load settings immediately)
  Future<void> setCurrentSupabaseUser(User? user) async {
    if (user != null) {
      _currentAuthUser = models.SupabaseAuthUser(user);
      _authProvider = 'supabase';
      debugPrint('✅ UserProvider: Supabase user set - ${user.email}');
      // Load user settings immediately so profile updates right away
      await _loadUserSettings();
      await loadCategories();
    } else {
      _currentAuthUser = null;
      _authProvider = 'none';
      _userSettings = null;
    }
    notifyListeners();
  }

  /// Set current user from Firebase (async to load settings immediately)
  Future<void> setCurrentFirebaseUser(firebase_auth.User? user) async {
    if (user != null) {
      _currentAuthUser = models.FirebaseAuthUser(user);
      _authProvider = 'firebase';
      debugPrint('✅ UserProvider: Firebase user set - ${user.displayName} (${user.email})');
      // Load user settings immediately so profile updates right away
      await _loadUserSettings();
      await loadCategories();
    } else {
      _currentAuthUser = null;
      _authProvider = 'none';
      _userSettings = null;
    }
    notifyListeners();
  }

  /// Sign out from current auth provider
  Future<void> signOut() async {
    try {
      if (_authProvider == 'firebase') {
        await firebase_auth.FirebaseAuth.instance.signOut();
      } else if (_authProvider == 'supabase') {
        await Supabase.instance.client.auth.signOut();
      }
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

  /// Refresh current user data from auth provider
  Future<void> refreshCurrentUser() async {
    if (_authProvider == 'supabase') {
      final supabaseUser =
          Supabase.instance.client.auth.currentSession?.user;
      if (supabaseUser != null) {
        _currentAuthUser = models.SupabaseAuthUser(supabaseUser);
        notifyListeners();
        debugPrint('User data refreshed: ${supabaseUser.userMetadata}');
      }
    } else if (_authProvider == 'firebase') {
      final firebaseUser = firebase_auth.FirebaseAuth.instance.currentUser;
      if (firebaseUser != null) {
        await firebaseUser.reload();
        final refreshedUser = firebase_auth.FirebaseAuth.instance.currentUser;
        if (refreshedUser != null) {
          _currentAuthUser = models.FirebaseAuthUser(refreshedUser);
          notifyListeners();
        }
      }
    }
  }

  /// Load categories from local storage
  Future<void> loadCategories() async {
    if (_currentAuthUser == null) return;

    _isCategoriesLoading = true;
    notifyListeners();

    try {
      final categoryData =
          await LocalStorageService.getCategories(_currentAuthUser!.id);

      if (categoryData.isEmpty) {
        // Seed default categories
        await _seedDefaultCategories();
        final newCategoryData =
            await LocalStorageService.getCategories(_currentAuthUser!.id);
        _categories = newCategoryData
            .map((cat) => Map<String, dynamic>.from(cat))
            .toList();
      } else {
        _categories =
            categoryData.map((cat) => Map<String, dynamic>.from(cat)).toList();
      }

      _categories.sort(
          (a, b) => (a['sort_order'] as int).compareTo(b['sort_order'] as int));
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      debugPrint('❌ UserProvider: Error loading categories: $e');
    } finally {
      _isCategoriesLoading = false;
      notifyListeners();
    }
  }

  /// Seed default categories on first launch
  Future<void> _seedDefaultCategories() async {
    if (_currentAuthUser == null) return;

    debugPrint('🌱 UserProvider: Seeding default categories');

    final defaultCategories = [
      {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'name': 'Shirts',
        'icon': 'checkroom',
        'is_active': true,
        'sort_order': 0,
      },
      {
        'id': (DateTime.now().millisecondsSinceEpoch + 1).toString(),
        'name': 'T-shirts',
        'icon': 'checkroom_outlined',
        'is_active': true,
        'sort_order': 1,
      },
      {
        'id': (DateTime.now().millisecondsSinceEpoch + 2).toString(),
        'name': 'Pants',
        'icon': 'airline_seat_legroom_normal',
        'is_active': true,
        'sort_order': 2,
      },
      {
        'id': (DateTime.now().millisecondsSinceEpoch + 3).toString(),
        'name': 'Shorts',
        'icon': 'fitness_center_outlined',
        'is_active': true,
        'sort_order': 3,
      },
      {
        'id': (DateTime.now().millisecondsSinceEpoch + 4).toString(),
        'name': 'Towels',
        'icon': 'dry_cleaning_outlined',
        'is_active': true,
        'sort_order': 4,
      },
      {
        'id': (DateTime.now().millisecondsSinceEpoch + 5).toString(),
        'name': 'Socks',
        'icon': 'local_offer_outlined',
        'is_active': true,
        'sort_order': 5,
      },
      {
        'id': (DateTime.now().millisecondsSinceEpoch + 6).toString(),
        'name': 'Bedsheets',
        'icon': 'bed_outlined',
        'is_active': true,
        'sort_order': 6,
      },
    ];

    await LocalStorageService.saveCategories(
        _currentAuthUser!.id, defaultCategories);
    debugPrint('✅ UserProvider: Default categories seeded');
  }

  /// Add a new category (local storage)
  Future<bool> addCategory(String name, {String? iconName}) async {
    if (_currentAuthUser == null) return false;

    try {
      // Check for duplicates
      final exists = _categories.any(
        (cat) => cat['name'].toString().toLowerCase() == name.toLowerCase(),
      );

      if (exists) {
        debugPrint('⚠️ UserProvider: Category "$name" already exists');
        return false;
      }

      // Add optimistically with unique ID
      final newCategory = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'name': name,
        'icon': iconName ?? 'checkroom_outlined',
        'is_active': true,
        'sort_order': _categories.length,
      };

      _categories.add(newCategory);
      notifyListeners();

      final success = await LocalStorageService.saveCategories(
          _currentAuthUser!.id, _categories);

      if (!success) {
        // Revert if failed
        _categories.removeLast();
        notifyListeners();
        return false;
      }

      debugPrint('✅ UserProvider: Category added successfully');
      return true;
    } catch (e) {
      _error = e.toString();
      debugPrint('❌ UserProvider: Error adding category: $e');
      // Revert if failed
      if (_categories.isNotEmpty && _categories.last['name'] == name) {
        _categories.removeLast();
        notifyListeners();
      }
      return false;
    }
  }

  /// Delete category (local storage)
  Future<bool> deleteCategory(String categoryId) async {
    if (_currentAuthUser == null) return false;

    try {
      final index = _categories.indexWhere((c) => c['id'] == categoryId);
      Map<String, dynamic>? removedItem;
      if (index != -1) {
        removedItem = _categories.removeAt(index);
        notifyListeners();
      } else {
        return false;
      }

      final success = await LocalStorageService.saveCategories(
          _currentAuthUser!.id, _categories);
      if (!success) {
        // Revert if failed
        _categories.insert(index, removedItem);
        notifyListeners();
        return false;
      }

      debugPrint('✅ UserProvider: Category deleted successfully');
      return true;
    } catch (e) {
      _error = e.toString();
      debugPrint('❌ UserProvider: Error deleting category: $e');
      return false;
    }
  }

  /// Update category name and/or icon (local storage)
  Future<bool> updateCategory(
    String categoryId, {
    String? name,
    String? iconName,
  }) async {
    if (_currentAuthUser == null) return false;

    try {
      // Find the category
      final index = _categories.indexWhere((c) => c['id'] == categoryId);
      if (index == -1) {
        debugPrint('⚠️ UserProvider: Category not found: $categoryId');
        return false;
      }

      // Keep old values for rollback
      final oldName = _categories[index]['name'];
      final oldIcon = _categories[index]['icon'];

      // Optimistic update
      if (name != null) {
        _categories[index]['name'] = name;
      }
      if (iconName != null) {
        _categories[index]['icon'] = iconName;
      }

      notifyListeners();

      final success = await LocalStorageService.saveCategories(
          _currentAuthUser!.id, _categories);

      if (!success) {
        // Revert if failed
        _categories[index]['name'] = oldName;
        _categories[index]['icon'] = oldIcon;
        notifyListeners();
        return false;
      }

      debugPrint('✅ UserProvider: Category updated successfully');
      return true;
    } catch (e) {
      _error = e.toString();
      debugPrint('❌ UserProvider: Error updating category: $e');
      return false;
    }
  }

  /// Update category order
  /// [oldIndex] and [newIndex] are the raw indices from ReorderableListView
  Future<bool> updateCategoryOrder(int oldIndex, int newIndex) async {
    if (_currentAuthUser == null) return false;

    try {
      // Adjust index if moving down
      if (newIndex > oldIndex) {
        newIndex--;
      }

      // Reorder locally
      final item = _categories.removeAt(oldIndex);
      _categories.insert(newIndex, item);

      // Update sort_order for all categories
      for (int i = 0; i < _categories.length; i++) {
        _categories[i]['sort_order'] = i;
      }

      // Optimistic UI update
      notifyListeners();

      final success = await LocalStorageService.saveCategories(
          _currentAuthUser!.id, _categories);

      if (success) {
        debugPrint(
            '✅ UserProvider: Category order updated (moved from $oldIndex to $newIndex)');
        return true;
      }
      return false;
    } catch (e) {
      _error = e.toString();
      debugPrint('❌ UserProvider: Error updating category order: $e');
      return false;
    }
  }

  /// Update category visibility (show/hide in QuickAdd)
  Future<bool> updateCategoryVisibility(
      String categoryId, bool isVisible) async {
    if (_currentAuthUser == null) return false;

    try {
      final index = _categories.indexWhere((c) => c['id'] == categoryId);
      if (index != -1) {
        _categories[index]['is_active'] = isVisible;
        notifyListeners();
      }

      final success = await LocalStorageService.saveCategories(
          _currentAuthUser!.id, _categories);

      if (!success) {
        _categories[index]['is_active'] = !isVisible;
        notifyListeners();
        return false;
      }

      debugPrint('✅ UserProvider: Category visibility updated successfully');
      return true;
    } catch (e) {
      _error = e.toString();
      debugPrint('❌ UserProvider: Error updating category visibility: $e');
      return false;
    }
  }

  /// Get sorted list of active category names for QuickAdd screen
  List<String> getCategoryNames() {
    final activeCategories = _categories
        .where((cat) => cat['is_active'] ?? true)
        .toList()
      ..sort((a, b) =>
          (a['sort_order'] as int).compareTo(b['sort_order'] as int));

    return activeCategories
        .map((cat) => cat['name'] as String)
        .toList()
      ..sort((a, b) {
      final catA = _categories.firstWhere((c) => c['name'] == a,
          orElse: () => {'sort_order': 999});
      final catB = _categories.firstWhere((c) => c['name'] == b,
          orElse: () => {'sort_order': 999});
      return (catA['sort_order'] as int).compareTo(catB['sort_order'] as int);
    });
  }

  /// Get full category data for active categories
  List<Map<String, dynamic>> getActiveCategories() {
    return _categories
        .where((cat) => cat['is_active'] ?? true)
        .toList();
  }

  /// Start auth state listeners for both providers
  void startAuthListeners() {
    // Listen to Supabase auth changes
    Supabase.instance.client.auth.onAuthStateChange.listen((event) async {
      final user = event.session?.user;
      await setCurrentSupabaseUser(user);
    });

    // Listen to Firebase auth changes
    firebase_auth.FirebaseAuth.instance
        .authStateChanges()
        .listen((firebase_auth.User? user) async {
      await setCurrentFirebaseUser(user);
    });
  }
}
