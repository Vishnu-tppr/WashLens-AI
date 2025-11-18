import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import 'signup_screen.dart';
import '../../services/firebase_service.dart';
import '../../services/supabase_service.dart';
import '../../providers/user_provider.dart';

/// Login Screen
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: screenWidth * 0.06,
            vertical: screenHeight * 0.012,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: screenHeight * 0.015),

              // Logo and Title
              Image.asset(
                'assets/images/WashLens AI Animated Logo 1 transparent.png',
                width: screenWidth * 0.28,
                height: screenWidth * 0.28,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: screenWidth * 0.28,
                    height: screenWidth * 0.28,
                    decoration: const BoxDecoration(
                      color: Color(0xFFE8EDFF),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.local_laundry_service,
                      size: screenWidth * 0.14,
                      color: AppTheme.primary,
                    ),
                  );
                },
              ),

              SizedBox(height: screenHeight * 0.012),

              Text(
                'WashLens AI',
                style: TextStyle(
                  fontSize: screenWidth * 0.065,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),

              SizedBox(height: screenHeight * 0.003),

              Text(
                'Smart Laundry, Simplified',
                style: TextStyle(
                  fontSize: screenWidth * 0.035,
                  color: AppTheme.textSecondary,
                ),
              ),

              SizedBox(height: screenHeight * 0.025),

              // Email Field
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Email',
                  style: TextStyle(
                    fontSize: screenWidth * 0.037,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),

              SizedBox(height: screenHeight * 0.008),

              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F9FB),
                  borderRadius: BorderRadius.circular(screenWidth * 0.08),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: TextStyle(fontSize: screenWidth * 0.04),
                  decoration: InputDecoration(
                    hintText: 'Enter your email',
                    hintStyle: TextStyle(
                      color: AppTheme.textTertiary,
                      fontSize: screenWidth * 0.04,
                    ),
                    prefixIcon: Padding(
                      padding: EdgeInsets.all(screenWidth * 0.035),
                      child: Icon(
                        Icons.email_outlined,
                        color: AppTheme.textSecondary,
                        size: screenWidth * 0.055,
                      ),
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: screenWidth * 0.04,
                      vertical: screenHeight * 0.018,
                    ),
                  ),
                ),
              ),

              SizedBox(height: screenHeight * 0.018),

              // Password Field
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Password',
                  style: TextStyle(
                    fontSize: screenWidth * 0.037,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),

              SizedBox(height: screenHeight * 0.008),

              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F9FB),
                  borderRadius: BorderRadius.circular(screenWidth * 0.08),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: TextField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  style: TextStyle(fontSize: screenWidth * 0.04),
                  decoration: InputDecoration(
                    hintText: 'Enter your password',
                    hintStyle: TextStyle(
                      color: AppTheme.textTertiary,
                      fontSize: screenWidth * 0.04,
                    ),
                    prefixIcon: Padding(
                      padding: EdgeInsets.all(screenWidth * 0.035),
                      child: Icon(
                        Icons.lock_outline,
                        color: AppTheme.textSecondary,
                        size: screenWidth * 0.055,
                      ),
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: screenWidth * 0.04,
                      vertical: screenHeight * 0.018,
                    ),
                  ),
                ),
              ),

              SizedBox(height: screenHeight * 0.01),

              // Forgot Password
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _showForgotPasswordDialog,
                  child: Text(
                    'Forgot Password?',
                    style: TextStyle(
                      color: AppTheme.primary,
                      fontSize: screenWidth * 0.035,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),

              SizedBox(height: screenHeight * 0.015),

              // Error Message
              if (_errorMessage != null)
                Container(
                  padding: EdgeInsets.all(screenWidth * 0.03),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 20),
                      SizedBox(width: screenWidth * 0.02),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(
                            fontSize: screenWidth * 0.032,
                            color: Colors.red.shade900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              if (_errorMessage != null) SizedBox(height: screenHeight * 0.015),

              // Login Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleEmailLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    padding: EdgeInsets.symmetric(vertical: screenHeight * 0.016),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(screenWidth * 0.08),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          'Login',
                          style: TextStyle(
                            fontSize: screenWidth * 0.045,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),

              SizedBox(height: screenHeight * 0.018),

              // Continue with Google
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _isLoading ? null : _handleGoogleSignIn,
                  icon: Container(
                    width: screenWidth * 0.05,
                    height: screenWidth * 0.05,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(2),
                      image: const DecorationImage(
                        image: NetworkImage(
                          'https://www.google.com/images/branding/googleg/1x/googleg_standard_color_128dp.png',
                        ),
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  label: Text(
                    'Continue with Google',
                    style: TextStyle(
                      fontSize: screenWidth * 0.04,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: screenHeight * 0.014),
                    side: const BorderSide(color: Color(0xFFE2E8F0), width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(screenWidth * 0.08),
                    ),
                  ),
                ),
              ),

              SizedBox(height: screenHeight * 0.018),

              // Sign Up Link
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Don't have an account? ",
                    style: TextStyle(
                      fontSize: screenWidth * 0.038,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SignupScreen()),
                      );
                    },
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      'Sign Up',
                      style: TextStyle(
                        fontSize: screenWidth * 0.038,
                        color: AppTheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleEmailLogin() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter both email and password';
        _isLoading = false;
      });
      return;
    }

    try {
      // Try Supabase first
      if (SupabaseService.isAvailable) {
        final user = await SupabaseService.signInWithPassword(email, password);
        if (user != null && mounted) {
          final userProvider = Provider.of<UserProvider>(context, listen: false);
          userProvider.setCurrentSupabaseUser(user);
          Navigator.pushReplacementNamed(context, '/home');
          return;
        }
      }

      // Fallback to Firebase
      final firebaseService = FirebaseService();
      if (firebaseService.isAvailable) {
        final credential = await firebaseService.signInWithEmailPassword(email, password);
        if (credential != null && mounted) {
          Navigator.pushReplacementNamed(context, '/home');
          return;
        }
      }

      setState(() {
        _errorMessage = 'Login failed. Please check your credentials.';
      });
    } catch (e) {
      setState(() {
        _errorMessage = _parseError(e.toString());
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final firebaseService = FirebaseService();
      
      if (!firebaseService.isAvailable) {
        setState(() {
          _errorMessage = 'Firebase is not configured. Please use email/password login.';
          _isLoading = false;
        });
        return;
      }

      // FirebaseService.signInWithGoogle() returns User? directly
      final firebaseUser = await firebaseService.signInWithGoogle();

      if (firebaseUser == null) {
        setState(() {
          _errorMessage = 'Google Sign-In was cancelled';
          _isLoading = false;
        });
        return;
      }

      if (mounted) {
        debugPrint('Google sign-in successful: ${firebaseUser.displayName} (${firebaseUser.email})');

        // Set Firebase user in provider
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        userProvider.setCurrentFirebaseUser(firebaseUser);

        // Try to sync with Supabase (optional - create or link account)
        if (SupabaseService.isAvailable && firebaseUser.email != null) {
          try {
            // This is a temporary solution - in production you'd want a better OAuth flow
            // For now, just continue with Firebase-only authentication
            debugPrint('Firebase user authenticated, using Firebase auth storage');
          } catch (e) {
            debugPrint('Supabase sync skipped: $e');
          }
        }

        if (mounted) {
          Navigator.pushReplacementNamed(context, '/home');
        }
        return;
      }

      setState(() {
        _errorMessage = 'Google Sign-In failed. Please try again.';
      });
    } catch (e) {
      debugPrint('Google Sign-In error: $e');
      setState(() {
        if (e.toString().contains('CANCELLED') || e.toString().contains('cancelled')) {
          _errorMessage = 'Sign-in was cancelled';
        } else if (e.toString().contains('network') || e.toString().contains('NETWORK')) {
          _errorMessage = 'Network error. Please check your internet connection.';
        } else if (e.toString().contains('PlatformException')) {
          _errorMessage = 'Google Sign-In is not properly configured. Please contact support or use email/password login.';
        } else {
          _errorMessage = 'Google Sign-In failed: ${_parseError(e.toString())}';
        }
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _showForgotPasswordDialog() async {
    final controller = TextEditingController();

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Reset Password'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: 'Enter your email address',
              labelText: 'Email',
            ),
            keyboardType: TextInputType.emailAddress,
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Send Reset Link'),
              onPressed: () async {
                final email = controller.text.trim();
                if (email.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter an email address')),
                  );
                  return;
                }

                try {
                  await SupabaseService.resetPassword(email);
                  Navigator.of(context).pop();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Password reset link sent! Check your email.'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: ${e.toString()}')),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  String _parseError(String error) {
    if (error.contains('invalid-email')) {
      return 'Invalid email address';
    } else if (error.contains('user-not-found')) {
      return 'No account found with this email';
    } else if (error.contains('wrong-password')) {
      return 'Incorrect password';
    } else if (error.contains('network')) {
      return 'Network error. Please check your connection.';
    } else if (error.contains('too-many-requests')) {
      return 'Too many attempts. Please try again later.';
    } else if (error.contains('Invalid login credentials')) {
      return 'Invalid email or password';
    }
    return 'Login failed. Please try again.';
  }
}
