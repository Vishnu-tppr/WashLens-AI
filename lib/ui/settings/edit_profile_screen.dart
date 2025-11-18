import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/app_theme.dart';
import '../../providers/user_provider.dart';
import '../../services/supabase_service.dart';
import 'dart:io';

/// Edit Profile Screen - User profile management
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();
  XFile? _selectedImage;
  bool _isLoading = false;
  bool _isImageLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    _nameController.text = userProvider.userName;
    _emailController.text = userProvider.userEmail;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Edit Profile',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(screenWidth * 0.04),
          child: Column(
            children: [
              SizedBox(height: screenHeight * 0.02),

              // Profile Photo
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: screenWidth * 0.3,
                    height: screenWidth * 0.3,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: _selectedImage != null
                        ? ClipOval(
                            child: Image.file(
                              File(_selectedImage!.path),
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return const Icon(
                                  Icons.person,
                                  size: 80,
                                  color: AppTheme.textTertiary,
                                );
                              },
                            ),
                          )
                        : Consumer<UserProvider>(
                            builder: (context, userProvider, _) {
                              return ClipOval(
                                child: Image.network(
                                  'https://ui-avatars.com/api/?name=${Uri.encodeComponent(userProvider.userName)}&background=4A6FFF&color=fff&size=256',
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return const Icon(
                                      Icons.person,
                                      size: 80,
                                      color: AppTheme.textTertiary,
                                    );
                                  },
                                ),
                              );
                            },
                          ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: screenWidth * 0.28,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: AppTheme.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.edit,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: screenHeight * 0.02),

              _isImageLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
                      ),
                    )
                  : TextButton(
                      onPressed: _handleChangePhoto,
                      child: const Text(
                        'Change Photo',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primary,
                        ),
                      ),
                    ),

              SizedBox(height: screenHeight * 0.04),

              // Full Name
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Full Name',
                  style: TextStyle(
                    fontSize: screenWidth * 0.04,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
              SizedBox(height: screenHeight * 0.012),
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: screenWidth * 0.04,
                    vertical: screenHeight * 0.02,
                  ),
                ),
                style: TextStyle(fontSize: screenWidth * 0.04),
              ),

              SizedBox(height: screenHeight * 0.025),

              // Email Address
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Email Address',
                  style: TextStyle(
                    fontSize: screenWidth * 0.04,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
              SizedBox(height: screenHeight * 0.012),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: screenWidth * 0.04,
                    vertical: screenHeight * 0.02,
                  ),
                ),
                style: TextStyle(fontSize: screenWidth * 0.04),
              ),

              SizedBox(height: screenHeight * 0.06),

              // Save Changes Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleSaveChanges,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: screenHeight * 0.022),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
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
                          'Save Changes',
                          style: TextStyle(
                            fontSize: screenWidth * 0.042,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleSaveChanges() async {
    setState(() => _isLoading = true);

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final user = userProvider.currentUser;

      if (user == null) {
        throw Exception('No user logged in');
      }

      // Validate inputs
      final newName = _nameController.text.trim();
      final newEmail = _emailController.text.trim();

      if (newName.isEmpty) {
        throw Exception('Name cannot be empty');
      }

      if (newEmail.isEmpty) {
        throw Exception('Email cannot be empty');
      }

      // Basic email validation
      final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
      if (!emailRegex.hasMatch(newEmail)) {
        throw Exception('Please enter a valid email address');
      }

      String? photoUrl;

      // Upload new photo if selected
      if (_selectedImage != null) {
        try {
          final fileName = '${user.id}_${DateTime.now().millisecondsSinceEpoch}.jpg';
          final bytes = await _selectedImage!.readAsBytes();

          photoUrl = await SupabaseService.uploadImage(
            'profile-photos',
            fileName,
            bytes,
          );

          if (photoUrl == null) {
            // Photo upload failed, but continue with other updates
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Profile updated but photo upload failed'),
                  backgroundColor: Colors.orange,
                ),
              );
            }
          }
        } catch (photoError) {
          debugPrint('Photo upload error: $photoError');
          // Continue with profile update even if photo fails
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Profile updated but photo upload failed'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        }
      }

      // Update user metadata in Supabase
      if (SupabaseService.isAvailable) {
        try {
          final updateData = <String, dynamic>{
            'full_name': newName,
          };

          // Add photo URL if uploaded successfully
          if (photoUrl != null) {
            updateData['avatar_url'] = photoUrl;
            debugPrint('Including avatar_url in update: $photoUrl');
          }

          debugPrint('Updating user with data: $updateData');

          // Prepare user attributes
          final userAttributes = UserAttributes(data: updateData);

          // Only include email if it changed
          if (newEmail != userProvider.userEmail) {
            userAttributes.email = newEmail;
            debugPrint('Also updating email to: $newEmail');
          }

          final response = await Supabase.instance.client.auth.updateUser(userAttributes);
          debugPrint('Update response: $response');
          debugPrint('Updated user metadata: ${response.user?.userMetadata}');

          // Note: Email changes may require confirmation via email
          // The user will receive a confirmation email if email was changed
        } catch (updateError) {
          debugPrint('Profile update error: $updateError');

          // Check if it's an email confirmation issue
          if (updateError.toString().contains('confirmation') ||
              updateError.toString().contains('email')) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Profile updated! Check your email for confirmation if you changed it.'),
                  backgroundColor: Colors.blue,
                ),
              );
            }
          } else {
            rethrow; // Re-throw for general error handling
          }
        }
      } else {
        debugPrint('Supabase service not available for profile update');
      }

      // Refresh current user data to reflect changes
      await userProvider.refreshCurrentUser();

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully'),
            backgroundColor: AppTheme.accent,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update profile: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleChangePhoto() async {
    final result = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Choose Photo Source',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (result != null) {
      setState(() => _isImageLoading = true);

      try {
        final pickedFile = await _imagePicker.pickImage(
          source: result,
          maxWidth: 800,
          maxHeight: 800,
          imageQuality: 85,
        );

        if (pickedFile != null) {
          setState(() => _selectedImage = pickedFile);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to pick image: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isImageLoading = false);
        }
      }
    }
  }
}
