import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'ui/settings/settings_screen.dart';
import 'ui/settings/notification_settings_screen.dart';
import 'ui/splash/splash_screen.dart';
import 'ui/onboarding/welcome_screen.dart';
import 'ui/auth/login_screen.dart';
import 'ui/auth/signup_screen.dart';
import 'ui/home/home_screen.dart';
import 'ui/scan/scan_screen.dart';
import 'ui/scan/camera_scan_screen.dart';
import 'ui/wash/detection_summary_screen.dart';
import 'ui/history/history_screen.dart';
import 'ui/analytics/analytics_screen.dart';
import 'ui/settings/edit_profile_screen.dart';
import 'ui/categories/manage_categories_screen.dart';
import 'ui/laundry/mark_returned_screen.dart';
import 'ui/laundry/my_laundry_screen.dart';
import 'ui/laundry/new_laundry_entry_screen.dart';
import 'ui/laundry/quick_add_laundry_screen.dart';
import 'ui/laundry/wash_entry_summary_screen.dart';
import 'ui/laundry/laundry_return_summary_screen.dart';
import 'ui/laundry/confirm_manual_return_screen.dart';
import 'ui/notifications/notifications_screen.dart';
import 'services/notification_service_enhanced.dart';
import 'services/notification_timer_service.dart';
import 'services/supabase_service.dart';
import 'ml/detector.dart';
import 'providers/user_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: ".env");

  // Initialize Supabase (add your credentials in supabase_service.dart)
  await SupabaseService.initialize();

  // Initialize Firebase (for FCM notifications, Auth, and Storage only - NO Firestore)
  try {
    await Firebase.initializeApp();
    debugPrint(
        '✅ Firebase initialized (Auth + Storage + FCM only, NO Firestore)');
  } catch (e) {
    debugPrint('⚠️ Firebase initialization: $e');
  }

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialize services (no local database - using Supabase API)
  final detector = ClothDetector();
  final notificationService = NotificationServiceEnhanced();
  final timerService = NotificationTimerService();
  final userProvider = UserProvider();

  // Initialize notification service with error handling
  try {
    await notificationService.initialize();
    await timerService.initialize(notificationService);
    debugPrint(
        '✅ NotificationServiceEnhanced and TimerService initialized successfully');
  } catch (e) {
    debugPrint('❌ NotificationServiceEnhanced initialization failed: $e');
    // Continue anyway - app can work without notifications
  }

  // Initialize user provider
  await userProvider.initialize();
  userProvider.startAuthListeners();

  runApp(
    WashLensApp(
      detector: detector,
      notificationService: notificationService,
      userProvider: userProvider,
    ),
  );
}

// --- Tailwind Color Palette Translation ---
const Color kPrimary = Color(0xFF4A6FFF);
const Color kSecondary = Color(0xFFA3B4FF);
const Color kAccent = Color(0xFF6EE7B7);
const Color kBackgroundLight = Color(0xFFF8FAFC);
const Color kCardLight = Colors.white;
const Color kTextLightPrimary = Color(0xFF0F172A);
const Color kTextLightSecondary = Color(0xFF475569);

// Custom Border Radius (Based on 'rounded-2xl' and 'lg' in Tailwind config)
const BorderRadius kBorderRadiusLg = BorderRadius.all(Radius.circular(22.0));
const BorderRadius kBorderRadius2Xl = BorderRadius.all(Radius.circular(28.0));

class WashLensApp extends StatelessWidget {
  final ClothDetector detector;
  final NotificationServiceEnhanced notificationService;
  final UserProvider userProvider;

  const WashLensApp({
    super.key,
    required this.detector,
    required this.notificationService,
    required this.userProvider,
  });

  ThemeData _buildAppTheme() {
    return ThemeData(
      // Set 'Plus Jakarta Sans' as the default font
      textTheme: GoogleFonts.plusJakartaSansTextTheme(
        ThemeData.light().textTheme,
      ).copyWith(
        // Ensure proper contrast for readability
        bodyLarge: GoogleFonts.plusJakartaSans(
          color: kTextLightPrimary,
          fontSize: 16,
        ),
        bodyMedium: GoogleFonts.plusJakartaSans(
          color: kTextLightSecondary,
          fontSize: 14,
        ),
      ),
      scaffoldBackgroundColor: kBackgroundLight,
      primaryColor: kPrimary,
      colorScheme: const ColorScheme.light(
        primary: kPrimary,
        secondary: kSecondary,
        surface: kCardLight,
        onPrimary: Colors.white,
        onSurface: kTextLightPrimary,
      ),
      // Apply custom border radius to major interactive components
      cardTheme: const CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: kBorderRadiusLg),
      ),
      useMaterial3: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<ClothDetector>.value(value: detector),
        Provider<NotificationServiceEnhanced>.value(value: notificationService),
        // FirebaseService removed - we only use Firebase for Auth/Storage, not Firestore
        // Provider<FirebaseService>(create: (_) => FirebaseService()),
        ChangeNotifierProvider<UserProvider>.value(value: userProvider),
        // Supabase service is static - use SupabaseService.method() directly
      ],
      child: MaterialApp(
        title: 'WashLens AI',
        debugShowCheckedModeBanner: false,
        theme: _buildAppTheme(),
        initialRoute: '/',
        routes: {
          '/': (context) => const SplashScreen(),
          '/welcome': (context) => const WelcomeScreen(),
          '/login': (context) => const LoginScreen(),
          '/signup': (context) => const SignupScreen(),
          '/home': (context) => const HomeScreen(),
          '/scan': (context) => const ScanScreen(),
          '/camera-scan': (context) => const CameraScanScreen(),
          '/detection-summary': (context) => const DetectionSummaryScreen(),
          '/quick-add': (context) => const QuickAddLaundryScreen(),
          '/new-entry': (context) => const NewLaundryEntryScreen(),
          '/wash-summary': (context) => const WashEntrySummaryScreen(),
          '/return-summary': (context) => const LaundryReturnSummaryScreen(),
          '/my-laundry': (context) => const MyLaundryScreen(),
          '/history': (context) => const HistoryScreen(),
          '/analytics': (context) => const AnalyticsScreen(),
          '/settings': (context) => const SettingsScreen(),
          '/notifications': (context) => const NotificationsScreen(),
          '/edit-profile': (context) => const EditProfileScreen(),
          '/categories': (context) => const ManageCategoriesScreen(),
          '/mark_returned': (context) => const MarkReturnedScreen(),
          '/notification-settings': (context) =>
              const NotificationSettingsScreen(),
          '/confirm_manual_return': (context) =>
              const ConfirmManualReturnScreen(),
        },
        onUnknownRoute: (settings) {
          return MaterialPageRoute(
            builder: (context) => Scaffold(
              appBar: AppBar(title: const Text('Not Found')),
              body: const Center(child: Text('Screen not found')),
            ),
          );
        },
      ),
    );
  }
}
