// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:washlens_ai/main.dart';
import 'package:washlens_ai/services/notification_service_enhanced.dart';
import 'package:washlens_ai/ml/detector.dart';
import 'package:washlens_ai/providers/user_provider.dart';

void main() {
  testWidgets('WashLensApp should build without errors',
      (WidgetTester tester) async {
    // Create mock instances for testing
    final detector = ClothDetector(); // Initialize detector
    final notificationService = NotificationServiceEnhanced();
    final userProvider = UserProvider();

    // Build our app and trigger a frame.
    final app = WashLensApp(
      detector: detector,
      notificationService: notificationService,
      userProvider: userProvider,
    );
    await tester.pumpWidget(app);

    // Verify that the app builds successfully
    expect(find.byType(WashLensApp), findsOneWidget);
  });
}
