import 'dart:async';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

/// Comprehensive error handler for authentication operations
class AuthErrorHandler {
  static const int _maxRetries = 3;
  static const Duration _timeoutDuration = Duration(seconds: 30);

  /// Check network connectivity
  static Future<bool> _isConnected() async {
    try {
      final connectivity = Connectivity();
      final result = await connectivity.checkConnectivity();
      return result != ConnectivityResult.none;
    } catch (e) {
      return false;
    }
  }

  /// Parse Firebase Auth errors into user-friendly messages
  static AuthError parseFirebaseError(dynamic error) {
    print('AuthErrorHandler: Parsing error: $error (type: ${error.runtimeType})');
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'user-not-found':
          return AuthError.userNotFound;
        case 'wrong-password':
          return AuthError.invalidCredentials;
        case 'invalid-email':
          return AuthError.invalidEmail;
        case 'user-disabled':
          return AuthError.accountDisabled;
        case 'email-already-in-use':
          return AuthError.emailAlreadyExists;
        case 'weak-password':
          return AuthError.weakPassword;
        case 'operation-not-allowed':
          return AuthError.serviceDisabled;
        case 'too-many-requests':
          return AuthError.tooManyRequests;
        case 'network-request-failed':
          return AuthError.networkError;
        case 'invalid-credential':
          return AuthError.invalidCredentials;
        case 'account-exists-with-different-credential':
          return AuthError.accountExistsWithDifferentCredential;
        default:
          return AuthError.firebaseError(error.message ?? error.code);
      }
    }

    if (error is PlatformException) {
      // Handle Google Sign-In specific errors
      switch (error.code) {
        case 'sign_in_canceled':
          return AuthError.userCancelled;
        case 'sign_in_failed':
          return AuthError.googleSignInFailed;
        case 'sign_in_required':
          return AuthError.googleSignInRequired;
        case 'network_error':
          return AuthError.networkError;
        default:
          return AuthError.platformError(error.message ?? error.code);
      }
    }

    if (error is SocketException || error is TimeoutException) {
      return AuthError.networkError;
    }

    return AuthError.unknownError(error.toString());
  }

  /// Execute auth operation with retry logic and timeout
  static Future<T?> executeWithRetry<T>(
    Future<T?> Function() operation, {
    int maxRetries = _maxRetries,
    Duration timeout = _timeoutDuration,
  }) async {
    // Check connectivity first
    if (!await _isConnected()) {
      throw AuthError.noNetwork;
    }

    int attempts = 0;
    while (attempts <= maxRetries) {
      try {
        return await operation().timeout(timeout);
      } catch (e) {
        final authError = parseFirebaseError(e);

        // Don't retry for certain errors
        if (authError.type == AuthErrorType.userCancelled ||
            authError.type == AuthErrorType.invalidCredentials ||
            authError.type == AuthErrorType.userNotFound ||
            authError.type == AuthErrorType.accountDisabled ||
            authError.type == AuthErrorType.emailAlreadyExists) {
          throw authError;
        }

        attempts++;
        if (attempts > maxRetries) {
          throw authError;
        }

        // Exponential backoff
        await Future.delayed(Duration(seconds: attempts * 2));
      }
    }

    throw AuthError.maxRetriesExceeded;
  }

  /// Show user-friendly error snackbar
  static void showErrorSnackbar(BuildContext context, AuthError error, {
    VoidCallback? onRetry,
  }) {
    final snackBar = SnackBar(
      content: Row(
        children: [
          Icon(
            error.icon,
            color: Colors.white,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              error.message,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      backgroundColor: error.color,
      duration: const Duration(seconds: 5),
      action: onRetry != null ? SnackBarAction(
        label: 'Retry',
        textColor: Colors.white,
        onPressed: onRetry,
      ) : null,
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }
}

/// Authentication error types and messages
class AuthError {
  final AuthErrorType type;
  final String message;
  final IconData icon;
  final Color color;

  const AuthError._({
    required this.type,
    required this.message,
    required this.icon,
    required this.color,
  });

  /// Override toString to return the user-friendly message instead of "Instance of AuthError"
  @override
  String toString() => message;

  // Predefined error instances
  static const AuthError noNetwork = AuthError._(
    type: AuthErrorType.noNetwork,
    message: 'No internet connection. Please check your network and try again.',
    icon: Icons.wifi_off,
    color: Colors.orange,
  );

  static const AuthError userNotFound = AuthError._(
    type: AuthErrorType.userNotFound,
    message: 'No account found with this email address.',
    icon: Icons.account_circle,
    color: Colors.blue,
  );

  static const AuthError invalidCredentials = AuthError._(
    type: AuthErrorType.invalidCredentials,
    message: 'Invalid email or password. Please check your credentials.',
    icon: Icons.lock,
    color: Colors.red,
  );

  static const AuthError invalidEmail = AuthError._(
    type: AuthErrorType.invalidEmail,
    message: 'Please enter a valid email address.',
    icon: Icons.email,
    color: Colors.red,
  );

  static const AuthError accountDisabled = AuthError._(
    type: AuthErrorType.accountDisabled,
    message: 'This account has been disabled. Please contact support.',
    icon: Icons.block,
    color: Colors.red,
  );

  static const AuthError emailAlreadyExists = AuthError._(
    type: AuthErrorType.emailAlreadyExists,
    message: 'An account with this email already exists.',
    icon: Icons.email,
    color: Colors.orange,
  );

  static const AuthError weakPassword = AuthError._(
    type: AuthErrorType.weakPassword,
    message: 'Password is too weak. Please choose a stronger password.',
    icon: Icons.security,
    color: Colors.orange,
  );

  static const AuthError serviceDisabled = AuthError._(
    type: AuthErrorType.serviceDisabled,
    message: 'This sign-in method is currently unavailable.',
    icon: Icons.settings,
    color: Colors.red,
  );

  static const AuthError tooManyRequests = AuthError._(
    type: AuthErrorType.tooManyRequests,
    message: 'Too many failed attempts. Please try again later.',
    icon: Icons.timer,
    color: Colors.red,
  );

  static const AuthError userCancelled = AuthError._(
    type: AuthErrorType.userCancelled,
    message: 'Sign-in was cancelled.',
    icon: Icons.cancel,
    color: Colors.grey,
  );

  static const AuthError googleSignInFailed = AuthError._(
    type: AuthErrorType.googleSignInFailed,
    message: 'Google sign-in failed. Please try again or use email/password.',
    icon: Icons.g_mobiledata,
    color: Colors.red,
  );

  static const AuthError googleSignInRequired = AuthError._(
    type: AuthErrorType.googleSignInRequired,
    message: 'Google sign-in is required for this operation.',
    icon: Icons.g_mobiledata,
    color: Colors.orange,
  );

  static const AuthError networkError = AuthError._(
    type: AuthErrorType.networkError,
    message: 'Network error. Please check your connection and try again.',
    icon: Icons.wifi_off,
    color: Colors.red,
  );

  static const AuthError maxRetriesExceeded = AuthError._(
    type: AuthErrorType.maxRetriesExceeded,
    message: 'Unable to complete sign-in. Please try again later.',
    icon: Icons.refresh,
    color: Colors.red,
  );

  static const AuthError accountExistsWithDifferentCredential = AuthError._(
    type: AuthErrorType.accountExistsWithDifferentCredential,
    message: 'An account already exists with a different sign-in method.',
    icon: Icons.account_circle,
    color: Colors.orange,
  );

  factory AuthError.firebaseError(String errorMessage) => AuthError._(
    type: AuthErrorType.firebaseError,
    message: 'Authentication error: $errorMessage',
    icon: Icons.error,
    color: Colors.red,
  );

  factory AuthError.platformError(String errorMessage) => AuthError._(
    type: AuthErrorType.platformError,
    message: 'Platform error: $errorMessage',
    icon: Icons.error,
    color: Colors.red,
  );

  const AuthError.unknownError(String errorMessage) : this._(
    type: AuthErrorType.unknownError,
    message: errorMessage,
    icon: Icons.error_outline,
    color: Colors.red,
  );
}

/// Authentication error types
enum AuthErrorType {
  noNetwork,
  userNotFound,
  invalidCredentials,
  invalidEmail,
  accountDisabled,
  emailAlreadyExists,
  weakPassword,
  serviceDisabled,
  tooManyRequests,
  userCancelled,
  googleSignInFailed,
  googleSignInRequired,
  networkError,
  maxRetriesExceeded,
  accountExistsWithDifferentCredential,
  firebaseError,
  platformError,
  unknownError,
}
