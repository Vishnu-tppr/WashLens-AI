import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import 'login_screen.dart';
import '../home/home_screen.dart';
import '../../services/supabase_service.dart';
import '../../services/firebase_service.dart';
import '../../providers/user_provider.dart';

/// Signup Screen
class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _emailController = TextEditingController();
  final _roomController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _roomController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // Helper function for navigating with replacement
  void _navigateToHome() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  // Function to handle Email/Password Sign Up
  Future<void> _handleSignUp() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final email = _emailController.text.trim();
    final roomNumber = _roomController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    // --- Validation ---
    if (email.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      setState(() {
        _errorMessage = 'Please fill in all required fields';
        _isLoading = false;
      });
      return;
    }

    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      setState(() {
        _errorMessage = 'Please enter a valid email address';
        _isLoading = false;
      });
      return;
    }

    if (password.length < 6) {
      setState(() {
        _errorMessage = 'Password must be at least 6 characters';
        _isLoading = false;
      });
      return;
    }

    if (password != confirmPassword) {
      setState(() {
        _errorMessage = 'Passwords do not match';
        _isLoading = false;
      });
      return;
    }

    // --- Authentication ---
    try {
      // 1. Try Supabase first
      if (!SupabaseService.isAvailable) {
        setState(() {
          _errorMessage = 'Backend service is not available. Please check your configuration.';
          _isLoading = false;
        });
        return;
      }

      final user = await SupabaseService.signUpWithPassword(
        email,
        password,
        roomNumber: roomNumber.isNotEmpty ? roomNumber : null,
      );

        if (user != null && mounted) {
          final userProvider = Provider.of<UserProvider>(context, listen: false);
          userProvider.setCurrentSupabaseUser(user);

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Account created successfully! Please verify your email.'),
              backgroundColor: AppTheme.accent,
            ),
          );

          // Wait for user settings to load before navigation
          await Future.delayed(const Duration(milliseconds: 200));

          if (userProvider.isLoggedIn) {
            _navigateToHome();
          } else {
            setState(() {
              _errorMessage = 'Account created but failed to load user data. Please try logging in.';
            });
          }
          return;
        }

      setState(() {
        _errorMessage = 'Sign up failed. Please check your details and try again.';
      });
    } catch (e) {
      debugPrint('Sign-up error: $e');
      debugPrint('Error type: ${e.runtimeType}');
      setState(() {
        _errorMessage = _parseError(e.toString());
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Function to handle Google Sign-In via Firebase
  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final firebaseService = FirebaseService();
      if (!firebaseService.isAvailable) {
        setState(() {
          _errorMessage = 'Authentication service is not available.';
          _isLoading = false;
        });
        return;
      }

      // Sign in with Google through Firebase
      final user = await firebaseService.signInWithGoogle();
      if (user != null && mounted) {
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        userProvider.setCurrentFirebaseUser(user);
        _navigateToHome();
        return;
      } else {
        setState(() {
          _errorMessage = 'Google Sign-In failed. Please try again.';
          _isLoading = false;
        });
      }

    } catch (e) {
      debugPrint('Google Sign-In error: $e');
      setState(() {
        if (e.toString().contains('CANCELLED') || e.toString().contains('cancelled') || e.toString().contains('user-cancelled')) {
          _errorMessage = 'Sign-in was cancelled';
        } else if (e.toString().contains('network') || e.toString().contains('NETWORK')) {
          _errorMessage = 'Network error. Please check your internet connection.';
        } else if (e.toString().contains('google-sign-in-failed') || e.toString().contains('PlatformException')) {
          _errorMessage = 'Google Sign-In is not properly configured. Please contact support or use email/password login.';
        } else {
          _errorMessage = 'Google Sign-In failed: ${_parseError(e.toString())}';
        }
        _isLoading = false;
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _parseError(String error) {
    if (error.contains('email-already-in-use') || error.contains('User already registered')) {
      return 'An account with this email already exists. Try logging in.';
    } else if (error.contains('invalid-email')) {
      return 'Invalid email address format.';
    } else if (error.contains('weak-password')) {
      return 'Password is too weak. Use at least 6 characters.';
    } else if (error.contains('network') || error.contains('Network error')) {
      return 'Network error. Please check your connection.';
    } else if (error.contains('PlatformException') && error.contains('sign_in_failed')) {
      return 'Google Sign-In failed due to configuration error.';
    }
    return 'Sign up failed. Please try again later.';
  }

  // --- UI Components remain the same ---

  Widget _buildLabel(String text, double screenWidth) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: TextStyle(
          fontSize: screenWidth * 0.035,
          fontWeight: FontWeight.w600,
          color: AppTheme.textPrimary,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required double screenWidth,
    required double screenHeight,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FB),
        borderRadius: BorderRadius.circular(screenWidth * 0.08),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        style: TextStyle(fontSize: screenWidth * 0.037),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(
            color: AppTheme.textTertiary,
            fontSize: screenWidth * 0.037,
          ),
          suffixIcon: suffixIcon,
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            horizontal: screenWidth * 0.05,
            vertical: screenHeight * 0.014,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: screenWidth * 0.06,
            vertical: screenHeight * 0.012,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: screenHeight * 0.008),

              // Logo and Title
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/images/WashLens AI Animated Logo 1 transparent.png',
                    width: screenWidth * 0.11,
                    height: screenWidth * 0.11,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: screenWidth * 0.12,
                        height: screenWidth * 0.12,
                        decoration: const BoxDecoration(
                          color: AppTheme.primary,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.local_laundry_service,
                          size: screenWidth * 0.065,
                          color: Colors.white,
                        ),
                      );
                    },
                  ),
                  SizedBox(width: screenWidth * 0.02),
                  Text(
                    'WashLens AI',
                    style: TextStyle(
                      fontSize: screenWidth * 0.065,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),

              SizedBox(height: screenHeight * 0.015),

              Text(
                'Create Your Account',
                style: TextStyle(
                  fontSize: screenWidth * 0.055,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),

              SizedBox(height: screenHeight * 0.004),

              Text(
                'Join the smart laundry revolution today.',
                style: TextStyle(
                  fontSize: screenWidth * 0.033,
                  color: AppTheme.textSecondary,
                ),
              ),

              SizedBox(height: screenHeight * 0.02),

              // Email Field
              _buildLabel('Email', screenWidth),
              SizedBox(height: screenHeight * 0.005),
              _buildTextField(
                controller: _emailController,
                hintText: 'Enter your email',
                keyboardType: TextInputType.emailAddress,
                screenWidth: screenWidth,
                screenHeight: screenHeight,
              ),

              SizedBox(height: screenHeight * 0.012),

              // Hostel Room Number Field
              _buildLabel('Hostel Room Number', screenWidth),
              SizedBox(height: screenHeight * 0.005),
              _buildTextField(
                controller: _roomController,
                hintText: 'e.g. A-101 (Optional)',
                screenWidth: screenWidth,
                screenHeight: screenHeight,
              ),

              SizedBox(height: screenHeight * 0.012),

              // Password Field
              _buildLabel('Password', screenWidth),
              SizedBox(height: screenHeight * 0.005),
              _buildTextField(
                controller: _passwordController,
                hintText: 'Enter your password (min 6 characters)',
                obscureText: _obscurePassword,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    color: AppTheme.textSecondary,
                    size: screenWidth * 0.05,
                  ),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
                screenWidth: screenWidth,
                screenHeight: screenHeight,
              ),

              SizedBox(height: screenHeight * 0.012),

              // Confirm Password Field
              _buildLabel('Confirm Password', screenWidth),
              SizedBox(height: screenHeight * 0.005),
              _buildTextField(
                controller: _confirmPasswordController,
                hintText: 'Confirm your password',
                obscureText: _obscureConfirmPassword,
                suffixIcon: IconButton(
                  // FIX: Consistent visibility icon toggle logic
                  icon: Icon(
                    _obscureConfirmPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    color: AppTheme.textSecondary,
                    size: screenWidth * 0.055,
                  ),
                  onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                ),
                screenWidth: screenWidth,
                screenHeight: screenHeight,
              ),

              SizedBox(height: screenHeight * 0.018),

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

              // Sign Up Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleSignUp,
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
                          'Sign Up',
                          style: TextStyle(
                            fontSize: screenWidth * 0.04,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),

              SizedBox(height: screenHeight * 0.012),

              // Divider with "or"
              Row(
                children: [
                  const Expanded(child: Divider(color: Color(0xFFE2E8F0), thickness: 1)),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.03),
                    child: Text(
                      'or',
                      style: TextStyle(
                        fontSize: screenWidth * 0.035,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ),
                  const Expanded(child: Divider(color: Color(0xFFE2E8F0), thickness: 1)),
                ],
              ),

              SizedBox(height: screenHeight * 0.012),

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
                      fontSize: screenWidth * 0.037,
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

              SizedBox(height: screenHeight * 0.015),

              // Login Link
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Already have an account? ',
                    style: TextStyle(
                      fontSize: screenWidth * 0.038,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                      );
                    },
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      'Log In',
                      style: TextStyle(
                        fontSize: screenWidth * 0.038,
                        color: AppTheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: screenHeight * 0.05), // Add extra space at the bottom for larger screens
            ],
          ),
        ),
      ),
    );
  }
}
