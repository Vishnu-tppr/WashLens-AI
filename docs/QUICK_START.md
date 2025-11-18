# 🚀 Quick Start Guide - WashLens AI

Get the app running in 15 minutes!

## Prerequisites

- Windows 10/11, macOS, or Linux
- 8GB+ RAM
- 10GB free disk space
- Internet connection

---

## Step 1: Install Flutter (5 minutes)

### Windows
```cmd
# Download Flutter SDK
# Visit: https://docs.flutter.dev/get-started/install/windows

# Extract to C:\src\flutter
# Add to PATH: C:\src\flutter\bin

# Verify installation
flutter doctor
```

### macOS
```bash
# Install via Homebrew
brew install --cask flutter

# Verify installation
flutter doctor
```

### Linux
```bash
# Download Flutter
cd ~
wget https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.16.0-stable.tar.xz
tar xf flutter_linux_3.16.0-stable.tar.xz

# Add to PATH
echo 'export PATH="$PATH:`pwd`/flutter/bin"' >> ~/.bashrc
source ~/.bashrc

# Verify
flutter doctor
```

---

## Step 2: Install Dependencies (3 minutes)

### Android Studio (for Android development)
```
1. Download from https://developer.android.com/studio
2. Install Android SDK (API 33+)
3. Install Flutter & Dart plugins
4. Accept Android licenses: flutter doctor --android-licenses
```

### Xcode (for iOS development - macOS only)
```bash
# Install Xcode from App Store
xcode-select --install

# Accept licenses
sudo xcodebuild -license accept

# Install CocoaPods
sudo gem install cocoapods
```

---

## Step 3: Clone & Setup Project (2 minutes)

```bash
# Clone repository
git clone https://github.com/yourusername/washlens_ai.git
cd washlens_ai

# Install dependencies
flutter pub get

# Generate database files (if needed)
flutter pub run build_runner build --delete-conflicting-outputs
```

---

## Step 4: Firebase Setup (3 minutes)

### Create Firebase Project
1. Go to https://console.firebase.google.com
2. Click "Add project"
3. Name: "washlens-ai"
4. Enable Google Analytics (optional)
5. Create project

### Enable Services
1. **Authentication**: Email/Password + Anonymous
2. **Firestore**: Start in production mode
3. **Storage**: Start in production mode
4. **Cloud Messaging**: Enable

### Add Android App
```
1. Click "Add app" → Android icon
2. Package name: com.washlens.ai
3. Download google-services.json
4. Place in: android/app/google-services.json
```

### Add iOS App (macOS only)
```
1. Click "Add app" → iOS icon
2. Bundle ID: com.washlens.ai
3. Download GoogleService-Info.plist
4. Place in: ios/Runner/GoogleService-Info.plist
```

---

## Step 5: Run the App (2 minutes)

### Android Emulator
```bash
# List available devices
flutter emulators

# Launch emulator
flutter emulators --launch Pixel_5_API_33

# Run app
flutter run
```

### iOS Simulator (macOS only)
```bash
# Open simulator
open -a Simulator

# Run app
flutter run
```

### Physical Device
```bash
# Android: Enable USB debugging
# iOS: Trust developer certificate

# Connect device via USB
flutter devices

# Run on device
flutter run -d <device-id>
```

---

## Step 6: Verify Installation

You should see:
✅ Animated splash screen (2.5s)
✅ Home dashboard
✅ Bottom navigation (Home, New, Analytics, Profile)
✅ Sample wash entries

---

## Troubleshooting

### "Google Services file is missing"
**Solution:**
```bash
# Android
cp google-services.json.example android/app/google-services.json
# Edit with your Firebase config

# iOS
cp GoogleService-Info.plist.example ios/Runner/GoogleService-Info.plist
# Edit with your Firebase config
```

### "TFLite model not found"
**Solution:**
```
Model is placeholder - app will show warning
To add real model:
1. Follow docs/ML_TRAINING.md
2. Place washlens_yolo.tflite in assets/models/
3. Run: flutter clean && flutter pub get
```

### "Build failed" on Android
**Solution:**
```bash
# Clean build
cd android
./gradlew clean
cd ..
flutter clean
flutter pub get
flutter run
```

### "Pod install failed" on iOS
**Solution:**
```bash
cd ios
pod deintegrate
pod install
cd ..
flutter run
```

### "Firebase not initialized"
**Solution:**
Check google-services.json / GoogleService-Info.plist are in correct locations

---

## Development Tips

### Hot Reload
```bash
# While app is running, press:
r  # Hot reload
R  # Hot restart
p  # Show performance overlay
q  # Quit
```

### Debug Mode
```bash
# Run in debug mode (default)
flutter run

# Run in profile mode (performance testing)
flutter run --profile

# Run in release mode
flutter run --release
```

### View Logs
```bash
# Android
adb logcat | grep flutter

# iOS
idevicesyslog | grep flutter
```

### Clear Cache
```bash
flutter clean
flutter pub get
```

---

## Next Steps

1. ✅ App is running!
2. 📸 Implement camera screen (see `lib/ui/camera/`)
3. 🧠 Train ML model (see `docs/ML_TRAINING.md`)
4. 🎨 Customize theme (see `lib/main.dart`)
5. 🚀 Build for production (see README.md)

---

## Common Commands

```bash
# Install packages
flutter pub get

# Update packages
flutter pub upgrade

# Run tests
flutter test

# Build APK
flutter build apk --release

# Build iOS
flutter build ios --release

# Check for issues
flutter doctor -v

# Format code
flutter format .

# Analyze code
flutter analyze
```

---

## Performance Tips

### First Run is Slow
- Gradle build takes 5-10 minutes first time
- Subsequent builds are much faster (30s - 2min)

### Speed Up Development
```bash
# Enable hot reload
flutter run --hot

# Use debug build (faster)
flutter run --debug

# Skip pub get if no changes
flutter run --no-pub
```

---

## Need Help?

- 📖 Read `README.md` for detailed setup
- 🏗️ Check `docs/ARCHITECTURE.md` for system design
- 🎬 Follow `docs/DEMO_SCRIPT.md` for features
- 🐛 Create GitHub issue for bugs
- 💬 Email support@washlens.ai

---

## Success Checklist

- [ ] Flutter installed (`flutter doctor` shows no errors)
- [ ] Project dependencies installed (`flutter pub get` successful)
- [ ] Firebase project created
- [ ] google-services.json / GoogleService-Info.plist added
- [ ] App runs on emulator/device
- [ ] Splash screen animation plays
- [ ] Home screen loads
- [ ] No crashes or errors

---

**You're all set! Happy coding! 🎉**

---

*Estimated total setup time: 15 minutes*
*If you encounter issues, check the troubleshooting section above*
