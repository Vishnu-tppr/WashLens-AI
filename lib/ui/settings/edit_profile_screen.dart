import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'custom_cropper_widget.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path_provider/path_provider.dart';
import '../theme/app_theme.dart';
import '../../providers/user_provider.dart';
import '../../services/supabase_service.dart';
import '../../models/app_user.dart' as models;

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

              // Profile Photo (tappable)
              GestureDetector(
                onTap: _isLoading ? null : _handleChangePhoto,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: screenWidth * 0.35,
                      height: screenWidth * 0.35,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        border: Border.all(
                          color: _selectedImage != null
                              ? AppTheme.primary
                              : Colors.transparent,
                          width: 3,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primary.withOpacity(0.2),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
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
                                // Check for existing profile photo (supports both Supabase and Firebase)
                                String? avatarUrl;
                                final currentAuthUser =
                                    userProvider.currentUser;

                                if (currentAuthUser != null) {
                                  if (currentAuthUser is models.SupabaseAuthUser) {
                                    final userMetadata = currentAuthUser.user.userMetadata;
                                    if (userMetadata != null &&
                                        userMetadata.containsKey('avatar_url')) {
                                      avatarUrl = userMetadata['avatar_url'] as String?;
                                    }
                                  } else if (currentAuthUser is models.FirebaseAuthUser) {
                                    // Firebase user - get photoURL from Google Sign-In
                                    avatarUrl = currentAuthUser.photoURL;
                                  }
                                }

                                // If we have an avatar URL, show the image
                                if (avatarUrl != null && avatarUrl.isNotEmpty) {
                                  return ClipOval(
                                    child: avatarUrl.startsWith('http')
                                        ? Image.network(
                                            avatarUrl,
                                            key: ValueKey(avatarUrl),
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (context, error, stackTrace) {
                                              return _buildInitialsAvatar(
                                                  userProvider.userName);
                                            },
                                            loadingBuilder: (context, child,
                                                loadingProgress) {
                                              if (loadingProgress == null) {
                                                return child;
                                              }
                                              return const Center(
                                                child:
                                                    CircularProgressIndicator(
                                                        strokeWidth: 2),
                                              );
                                            },
                                          )
                                        : Image.file(
                                            File(avatarUrl),
                                            key: ValueKey(avatarUrl),
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (context, error, stackTrace) {
                                              return _buildInitialsAvatar(
                                                  userProvider.userName);
                                            },
                                          ),
                                  );
                                }

                                // Otherwise show initials
                                return _buildInitialsAvatar(
                                    userProvider.userName);
                              },
                            ),
                    ),
                    if (_isImageLoading)
                      Container(
                        width: screenWidth * 0.35,
                        height: screenWidth * 0.35,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.black.withOpacity(0.5),
                        ),
                        child: const Center(
                          child: CircularProgressIndicator(
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                      ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.primary,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primary.withOpacity(0.4),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: screenHeight * 0.015),

              TextButton.icon(
                onPressed: _isLoading ? null : _handleChangePhoto,
                icon: const Icon(Icons.add_photo_alternate, size: 20),
                label: Text(
                  _selectedImage != null ? 'Change Photo' : 'Add Photo',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.primary,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
                    padding:
                        EdgeInsets.symmetric(vertical: screenHeight * 0.022),
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
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
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
    // Validate inputs first
    final newName = _nameController.text.trim();
    final newEmail = _emailController.text.trim();

    if (newName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.warning, color: Colors.white),
              SizedBox(width: 12),
              Text('Name cannot be empty'),
            ],
          ),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (newEmail.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.warning, color: Colors.white),
              SizedBox(width: 12),
              Text('Email cannot be empty'),
            ],
          ),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Email validation
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(newEmail)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.warning, color: Colors.white),
              SizedBox(width: 12),
              Expanded(child: Text('Please enter a valid email address')),
            ],
          ),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final user = userProvider.currentUser;

      if (user == null) {
        throw Exception('No user logged in');
      }

      String? photoUrl;

      // Save new photo locally if selected
      bool photoUploadFailed = false;
      String? photoErrorMessage;
      if (_selectedImage != null) {
        setState(() => _isImageLoading = true);
        try {
          debugPrint('Starting photo save to local storage...');

          // Get application documents directory
          final Directory appDir = await getApplicationDocumentsDirectory();
          final String profilePhotosDir = '${appDir.path}/profile_photos';

          // Create profile photos directory if it doesn't exist
          final Directory profileDir = Directory(profilePhotosDir);
          if (!await profileDir.exists()) {
            await profileDir.create(recursive: true);
            debugPrint('Created profile photos directory: $profilePhotosDir');
          }

          // Save with user ID in filename
          final String fileName = '${user.id}_profile.jpg';
          final String localPath = '$profilePhotosDir/$fileName';

          // Copy the selected image to local storage
          await File(_selectedImage!.path).copy(localPath);

          photoUrl = localPath;
          debugPrint('Photo saved locally: $photoUrl');
        } catch (photoError) {
          photoUploadFailed = true;
          photoErrorMessage = photoError.toString();
          debugPrint('Photo save error: $photoError');

          // Show immediate error feedback
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.white),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                          'Photo save failed: ${photoError.toString().split('\n').first}'),
                    ),
                  ],
                ),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 4),
              ),
            );
          }
        } finally {
          if (mounted) {
            setState(() => _isImageLoading = false);
          }
        }
      }

      // Update user metadata in Supabase
      bool emailChanged = false;
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
            emailChanged = true;
            debugPrint('Also updating email to: $newEmail');
          }

          await Supabase.instance.client.auth.updateUser(userAttributes);
          debugPrint('Profile updated successfully in Supabase');
        } catch (updateError) {
          debugPrint('Profile update error: $updateError');
          rethrow;
        }
      } else {
        debugPrint('Supabase service not available for profile update');
        throw Exception('Unable to connect to server');
      }

      // Refresh current user data to reflect changes
      debugPrint('Refreshing user data...');
      await userProvider.refreshCurrentUser();

      // Small delay to ensure UI updates
      await Future.delayed(const Duration(milliseconds: 500));

      if (mounted) {
        Navigator.pop(context);

        // Show appropriate success message
        String message = 'Profile updated successfully!';
        if (photoUploadFailed) {
          message =
              'Profile updated, but photo upload failed: ${photoErrorMessage ?? "Unknown error"}. Please try again.';
        } else if (emailChanged) {
          message =
              'Profile updated! Check your email to confirm the new address.';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  photoUploadFailed ? Icons.warning : Icons.check_circle,
                  color: Colors.white,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    message,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            backgroundColor:
                photoUploadFailed ? Colors.orange : AppTheme.accent,
            duration: Duration(seconds: emailChanged ? 5 : 3),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Failed to update profile: ${e.toString()}',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isImageLoading = false;
        });
      }
    }
  }

  Future<void> _handleChangePhoto() async {
    final result = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Choose Photo Source',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: _buildPhotoOption(
                      icon: Icons.camera_alt,
                      label: 'Camera',
                      onTap: () => Navigator.pop(context, ImageSource.camera),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildPhotoOption(
                      icon: Icons.photo_library,
                      label: 'Gallery',
                      onTap: () => Navigator.pop(context, ImageSource.gallery),
                    ),
                  ),
                ],
              ),
              if (_selectedImage != null) ...{
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      setState(() => _selectedImage = null);
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.close),
                    label: const Text('Remove Photo'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              },
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );

    if (result != null) {
      setState(() => _isImageLoading = true);

      try {
        final pickedFile = await _imagePicker.pickImage(
          source: result,
          maxWidth: 1024,
          maxHeight: 1024,
          imageQuality: 90,
        );

        if (pickedFile != null) {
          debugPrint('Image picked: ${pickedFile.path}');

          if (mounted) {
            setState(() => _isImageLoading = false);

            // Navigate to custom cropper
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CustomImageCropper(
                  imagePath: pickedFile.path,
                  onCropped: (Uint8List croppedImage) async {
                    try {
                      // Save cropped image temporarily
                      final tempDir = await getTemporaryDirectory();
                      final uniqueId = DateTime.now().millisecondsSinceEpoch;
                      final croppedPath = '${tempDir.path}/cropped_$uniqueId.jpg';

                      final file = await File(croppedPath).writeAsBytes(croppedImage);
                      setState(() {
                        _selectedImage = XFile(file.path);
                        _isImageLoading = false; // Reset loading state
                      });

                      if (context.mounted) {
                        Navigator.pop(context); // Close cropper
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Row(
                              children: [
                                Icon(Icons.check_circle, color: Colors.white),
                                SizedBox(width: 12),
                                Text('Photo cropped and ready! Don\'t forget to save.'),
                              ],
                            ),
                            backgroundColor: AppTheme.primary,
                            duration: Duration(seconds: 2),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    } catch (e) {
                      debugPrint('Error saving cropped image: $e');
                      setState(() => _isImageLoading = false); // Reset loading state
                      if (context.mounted) {
                        Navigator.pop(context); // Close cropper
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Failed to save cropped image: ${e.toString()}'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                  onCancel: () {
                    // User skipped cropping - use original image
                    setState(() {
                      _selectedImage = pickedFile;
                    });

                    Navigator.pop(context); // Close cropper

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.white),
                            SizedBox(width: 12),
                            Text('Using original photo. You can crop it later by selecting a new photo.'),
                          ],
                        ),
                        backgroundColor: Colors.blue,
                        duration: Duration(seconds: 3),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ),
              ),
            );
          }
        } else {
          setState(() => _isImageLoading = false);
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isImageLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(child: Text('Failed to pick image: $e')),
                ],
              ),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }



  Widget _buildInitialsAvatar(String userName) {
    final initials = userName.isNotEmpty
        ? userName.substring(0, userName.length > 1 ? 2 : 1).toUpperCase()
        : 'U';
    return Container(
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [AppTheme.primary, Color(0xFF6B8CFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Text(
          initials,
          style: const TextStyle(
            fontSize: 48,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: AppTheme.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 40, color: AppTheme.primary),
            const SizedBox(height: 12),
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
