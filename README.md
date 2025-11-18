# 🧺 WashLens AI

**Smart Laundry Tracking with AI-Powered Cloth Detection**

WashLens AI is a Flutter mobile app designed for hostel students to automatically track laundry items using computer vision. Simply snap a photo of your laundry pile, and the app will detect and count every item. When clothes return from the dhobi, verify them instantly and get notified of any missing items.

---

## ✨ Features

- **🤖 AI Cloth Detection** – Single-photo auto-counting of shirts, t-shirts, pants, towels, socks, etc.
- **📸 Camera Scanning** – Integrated camera with on-device TFLite inference
- **🔄 Return Verification** – Automatic matching: Given vs Returned
- **⚠️ Missing Item Alerts** – Real-time notifications for missing clothes
- **📊 Analytics Dashboard** – Track laundry history, dhobi risk scores, most-missing items
- **💾 Offline-First** – Works without internet; syncs when online
- **☁️ Cloud Backup** – Firebase-powered secure backup
- **📤 PDF Export** – Generate proof with photos and share via WhatsApp
- **🏠 Home Widgets** – Quick stats on Android & iOS home screens
- **🔔 Smart Reminders** – 3-day alerts for pending returns
- **🎨 Animated Splash** – Beautiful Rive-powered intro animation

---

## 🏗️ Architecture

```
lib/
├── main.dart
├── ui/
│   ├── splash/
│   ├── home/
│   ├── wash_entry/
│   ├── camera/
│   ├── return_verification/
│   ├── history/
│   ├── analytics/
│   ├── settings/
│   └── category_manager/
├── services/
│   ├── firebase_service.dart
│   ├── storage_service.dart
│   ├── notification_service.dart
│   ├── sync_service.dart
│   └── export_service.dart
├── ml/
│   ├── detector.dart
│   ├── color_classifier.dart
│   └── pattern_classifier.dart
├── models/
│   ├── wash_entry.dart
│   ├── cloth_item.dart
│   ├── category.dart
│   └── user_settings.dart
├── data/
│   ├── database.dart (Drift)
│   ├── firestore_repo.dart
│   └── storage_repo.dart
└── native_integration/
    ├── widget_bridge.dart
    ├── notification_bridge.dart
    └── background_tasks.dart
```

---

## 🚀 Getting Started

### Prerequisites

- Flutter SDK (>=3.0.0)
- Android Studio / Xcode
- Firebase Account
- Git

### 1. Clone Repository

```bash
git clone https://github.com/yourusername/washlens_ai.git
cd washlens_ai
```

### 2. Install Dependencies

```bash
flutter pub get
```

### 3. Firebase Setup

#### Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Create a new project: `washlens-ai`
3. Enable:
   - Authentication (Email/Password + Google Sign-In)
   - Cloud Firestore
   - Firebase Storage
   - Firebase Cloud Messaging

#### Android Configuration

1. Register Android app in Firebase Console
   - Package name: `com.washlens.ai`
2. Download `google-services.json`
3. Place in: `android/app/google-services.json`

#### iOS Configuration

1. Register iOS app in Firebase Console
   - Bundle ID: `com.washlens.ai`
2. Download `GoogleService-Info.plist`
3. Place in: `ios/Runner/GoogleService-Info.plist`

#### Firestore Security Rules

Deploy rules from `firestore.rules`:

```bash
firebase deploy --only firestore:rules
```

#### Storage Security Rules

Deploy rules from `storage.rules`:

```bash
firebase deploy --only storage
```

### 4. Environment Variables

```bash
cp .env.example .env
# Edit .env with your Firebase config values
```

### 5. iOS App Group Setup (for Widget)

1. Open `ios/Runner.xcworkspace` in Xcode
2. Select Runner target → Signing & Capabilities
3. Add **App Groups** capability
4. Enable: `group.com.washlens.ai`
5. Repeat for **WidgetExtension** target

### 6. TFLite Model Setup

**Option A: Use Placeholder (for development)**

A dummy model is included at `assets/models/dummy_washlens.tflite`

**Option B: Train & Convert Real Model**

See [ML Model Training Guide](docs/ML_TRAINING.md)

Quick steps:

```bash
# Install dependencies
pip install ultralytics onnx tensorflow

# Train YOLOv8 Nano
yolo detect train data=laundry_dataset.yaml model=yolov8n.pt epochs=100

# Export to TFLite
yolo export model=runs/detect/train/weights/best.pt format=tflite int8

# Copy to assets
cp best_int8.tflite assets/models/washlens_yolo.tflite
```

### 7. Run the App

#### Android

```bash
flutter run
```

#### iOS

```bash
cd ios
pod install
cd ..
flutter run
```

#### Run with Hot Reload

```bash
flutter run --hot
```

---

## 🧪 Testing

### Unit Tests

```bash
flutter test
```

### Widget Tests

```bash
flutter test test/ui/
```

### Integration Tests

```bash
flutter drive \
  --driver=test_driver/integration_test.dart \
  --target=integration_test/app_test.dart
```

### Test Coverage

```bash
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

---

## 📱 Building for Production

### Android APK

```bash
flutter build apk --release
```

Output: `build/app/outputs/flutter-apk/app-release.apk`

### Android App Bundle (for Play Store)

```bash
flutter build appbundle --release
```

Output: `build/app/outputs/bundle/release/app-release.aab`

### iOS IPA

```bash
flutter build ios --release
cd ios
fastlane beta  # Upload to TestFlight
```

---

## 🤖 ML Model Details

### Model Architecture

- **Base**: YOLOv8 Nano
- **Input**: 640x640 RGB
- **Output**: Bounding boxes + class predictions
- **Classes**: 8 categories (shirt, t-shirt, pants, shorts, track_pant, towel, socks, bedsheet)
- **Quantization**: INT8 for mobile efficiency

### Inference Pipeline

1. Image preprocessing (resize, normalize)
2. TFLite inference
3. Non-Maximum Suppression (NMS)
4. Category grouping
5. Color/pattern detection (secondary classifier)

### Performance

- **Latency**: ~150-300ms on mid-range Android devices
- **Accuracy**: 92% mAP@0.5
- **Model Size**: ~6MB (quantized)

---

## 🏠 Home Widget Setup

### Android

Uses `home_widget` Flutter plugin + native AppWidget.

**Update Widget from Flutter:**

```dart
HomeWidget.saveWidgetData<String>('summary', 'Dhobi - 15 items');
HomeWidget.updateWidget(
  name: 'WashLensWidgetProvider',
  androidName: 'WashLensWidgetProvider',
);
```

**Widget Layout:** `android/app/src/main/res/layout/widget_layout.xml`

### iOS

Uses WidgetKit extension with App Group data sharing.

**Update Widget from Flutter:**

```dart
await WidgetBridge.updateWidget({
  'summary': 'Raju Dhobi - 15 items',
  'missing': 1,
  'lastUpdate': DateTime.now().toIso8601String(),
});
```

**Widget Extension:** `ios/WidgetExtension/`

---

## 🔔 Notifications

### Local Notifications

- Reminder after 3 days (configurable)
- Missing item alerts
- Return confirmation

### Push Notifications (FCM)

- Server-triggered reminders
- Risk score alerts
- Promotional messages

**Handle Notification Tap:**

```dart
FirebaseMessaging.onMessageOpenedApp.listen((message) {
  Navigator.pushNamed(context, '/wash-entry/${message.data['washId']}');
});
```

---

## 🔧 Configuration

Edit `.env` or app settings:

| Setting | Default | Description |
|---------|---------|-------------|
| `DEFAULT_REMINDER_DAYS` | 3 | Days before reminder |
| `ENABLE_CLOUD_BACKUP` | true | Auto Firebase sync |
| `ENABLE_OFFLINE_MODE` | true | Work without internet |
| `TFLITE_MODEL_PATH` | `assets/models/washlens_yolo.tflite` | Path to model |

---

## 📂 Project Structure

```
washlens_ai/
├── android/              # Android-specific code
├── ios/                  # iOS-specific code
│   └── WidgetExtension/  # iOS Widget
├── lib/                  # Dart application code
├── assets/               # Images, models, animations
├── test/                 # Unit & widget tests
├── integration_test/     # E2E tests
├── docs/                 # Documentation
├── design/               # Design files (Figma, Rive)
├── samples/              # Sample images for demo
├── tools/                # Scripts (model conversion, etc.)
├── .github/workflows/    # CI/CD pipelines
└── fastlane/             # iOS/Android deployment automation
```

---

## 🚢 CI/CD

### GitHub Actions

Workflows in `.github/workflows/`:

- **ci.yml**: Lint, test, build on every PR
- **release.yml**: Build & deploy on tag push

### Fastlane

#### Android

```bash
cd android
fastlane beta  # Upload to Play Store Beta track
```

#### iOS

```bash
cd ios
fastlane beta  # Upload to TestFlight
```

---

## 🤝 Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md)

---

## 📄 License

MIT License - see [LICENSE](LICENSE)

---

## 🙋 Support

- **Issues**: [GitHub Issues](https://github.com/yourusername/washlens_ai/issues)
- **Discussions**: [GitHub Discussions](https://github.com/yourusername/washlens_ai/discussions)
- **Email**: support@washlens.ai

---

## 🎉 Acknowledgments

- Flutter Team
- TensorFlow Lite Team
- Ultralytics (YOLOv8)
- Firebase Team
- Rive Animations

---

Built with ❤️ by students, for students
