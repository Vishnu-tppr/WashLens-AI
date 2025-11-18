import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../theme/app_assets.dart';
import 'package:permission_handler/permission_handler.dart';

/// Welcome/Onboarding screen with permissions and feature showcase
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  bool _cameraPermissionGranted = false;
  bool _notificationPermissionGranted = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacing24),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: AppTheme.spacing32),

                      // App Icon/Logo
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.0, end: 1.0),
                        duration: const Duration(milliseconds: 800),
                        curve: Curves.elasticOut,
                        builder: (context, value, child) {
                          return Transform.scale(
                            scale: value,
                            child: Container(
                              width: 150,
                              height: 150,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(
                                  AppTheme.radius24,
                                ),
                                boxShadow: AppTheme.shadowPrimary,
                              ),
                              child: Image.asset(
                                AppAssets.animatedLogo,
                                fit: BoxFit.contain,
                              ),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: AppTheme.spacing24),

                      // Title
                      Text(
                        'Welcome to WashLens AI',
                        style: Theme.of(context).textTheme.displayMedium,
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: AppTheme.spacing12),

                      // Subtitle
                      Text(
                        'Your smart laundry assistant.',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: AppTheme.spacing48),

                      // Feature Cards
                      _buildFeatureCard(
                        icon: Icons.auto_awesome,
                        iconColor: AppTheme.primary,
                        title: 'AI Cloth Detection',
                        description:
                            'Instantly recognize clothes with a single photo.',
                      ),

                      const SizedBox(height: AppTheme.spacing16),

                      _buildFeatureCard(
                        icon: Icons.calculate_outlined,
                        iconColor: AppTheme.accent,
                        title: 'Auto Counting',
                        description: 'Never lose a sock again.',
                      ),

                      const SizedBox(height: AppTheme.spacing16),

                      _buildFeatureCard(
                        icon: Icons.compare_arrows_rounded,
                        iconColor: AppTheme.accentGreen,
                        title: 'Return Matching',
                        description: 'Verify you got all your clothes back.',
                      ),

                      const SizedBox(height: AppTheme.spacing48),

                      // Permissions Section
                      Container(
                        padding: const EdgeInsets.all(AppTheme.spacing20),
                        decoration: BoxDecoration(
                          color: AppTheme.surface,
                          borderRadius: BorderRadius.circular(
                            AppTheme.radius16,
                          ),
                          boxShadow: AppTheme.shadow1,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Permissions We Need',
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),

                            const SizedBox(height: AppTheme.spacing20),

                            // Camera Permission
                            _buildPermissionItem(
                              icon: Icons.camera_alt_outlined,
                              iconColor: AppTheme.primary,
                              title: 'Camera Access',
                              description:
                                  'We need access to scan your laundry pile.',
                              isGranted: _cameraPermissionGranted,
                            ),

                            const SizedBox(height: AppTheme.spacing16),

                            // Notification Permission
                            _buildPermissionItem(
                              icon: Icons.notifications_outlined,
                              iconColor: AppTheme.accent,
                              title: 'Notifications',
                              description:
                                  'Get reminders when your laundry is done.',
                              isGranted: _notificationPermissionGranted,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Get Started Button
              const SizedBox(height: AppTheme.spacing24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _handleGetStarted,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                  ),
                  child: const Text('Let\'s Get Started'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing20),
      decoration: BoxDecoration(
        color: iconColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(AppTheme.radius16),
        border: Border.all(color: iconColor.withOpacity(0.2), width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(AppTheme.radius12),
            ),
            child: Icon(icon, color: iconColor, size: 28),
          ),
          const SizedBox(width: AppTheme.spacing16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: AppTheme.spacing4),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String description,
    required bool isGranted,
  }) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppTheme.radius12),
          ),
          child: Icon(icon, color: iconColor, size: 24),
        ),
        const SizedBox(width: AppTheme.spacing16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: AppTheme.spacing4),
              Text(
                description,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppTheme.textTertiary),
              ),
            ],
          ),
        ),
        if (isGranted)
          const Icon(Icons.check_circle, color: AppTheme.success, size: 24),
      ],
    );
  }

  Future<void> _handleGetStarted() async {
    // Request camera permission
    final cameraStatus = await Permission.camera.request();
    setState(() {
      _cameraPermissionGranted = cameraStatus.isGranted;
    });

    // Request notification permission
    final notificationStatus = await Permission.notification.request();
    setState(() {
      _notificationPermissionGranted = notificationStatus.isGranted;
    });

    // Navigate to home screen (will be implemented when wiring navigation)
    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/home');
    }
  }
}
