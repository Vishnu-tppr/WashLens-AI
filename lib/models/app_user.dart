import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

/// Abstract interface for authentication users (unified for Supabase/Firebase)
abstract class AuthUser {
  String get id;
  String? get email;
  String? get displayName;
  Map<String, dynamic>? get metadata;
}

/// Firebase User wrapper implementing AuthUser interface
class FirebaseAuthUser implements AuthUser {
  final firebase_auth.User _user;

  FirebaseAuthUser(this._user);

  @override
  String get id => _user.uid;

  @override
  String? get email => _user.email;

  @override
  String? get displayName => _user.displayName;

  @override
  Map<String, dynamic>? get metadata => null; // Firebase doesn't have userMetadata like Supabase
}

/// Supabase User wrapper implementing AuthUser interface
class SupabaseAuthUser implements AuthUser {
  final User _user;

  SupabaseAuthUser(this._user);

  /// Get the underlying Supabase User object
  User get user => _user;

  @override
  String get id => _user.id;

  @override
  String? get email => _user.email;

  @override
  String? get displayName => _user.userMetadata?['full_name'] ?? _user.userMetadata?['name'];

  @override
  Map<String, dynamic>? get metadata => _user.userMetadata;
}

/// App user model that wraps authentication user for UI consumption
class AppUser {
  final String id;
  final String? email;
  final String? name;
  final bool emailConfirmed;
  final String? roomNumber;

  AppUser({
    required this.id,
    this.email,
    this.name,
    this.emailConfirmed = false,
    this.roomNumber,
  });

  /// Create from Supabase User
  factory AppUser.fromSupabase(User user) {
    return AppUser(
      id: user.id,
      email: user.email,
      name: user.userMetadata?['full_name'] ?? user.userMetadata?['name'],
      emailConfirmed: user.emailConfirmedAt != null,
      roomNumber: user.userMetadata?['room_number'],
    );
  }

  /// Create from Firebase User (for legacy compatibility)
  factory AppUser.fromFirebase(Object firebaseUser) {
    // This is a fallback that currently only supports supabase users
    // You might need to adjust this if you're still using Firebase auth
    throw UnsupportedError('Firebase auth is deprecated. Use Supabase auth instead.');
  }

  /// Convert to JSON (for debugging/storage)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'email_confirmed': emailConfirmed,
      'room_number': roomNumber,
    };
  }

  /// Get display name
  String get displayName {
    if (name != null && name!.isNotEmpty) {
      return name!;
    }
    if (email != null) {
      return email!.split('@').first;
    }
    return 'User';
  }

  /// Get initials for avatar
  String get initials {
    if (name != null && name!.isNotEmpty) {
      return name!.split(' ').map((part) => part.isNotEmpty ? part[0] : '').join('').toUpperCase();
    }
    if (email != null) {
      return email![0].toUpperCase();
    }
    return '?';
  }

  @override
  String toString() {
    return 'AppUser(id: $id, email: $email, name: $name, roomNumber: $roomNumber)';
  }
}
