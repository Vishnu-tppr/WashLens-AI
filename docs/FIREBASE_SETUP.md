# Firebase Setup Guide for WashLens AI

This guide will help you configure Firebase for Google Sign-In and other Firebase services in your WashLens AI app.

## Prerequisites

1. A Firebase project (create one at https://console.firebase.google.com/)
2. Android Studio and Java Development Kit (JDK) installed
3. Flutter project set up

## Steps to Configure Google Sign-In

### 1. Add Android App to Firebase

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project or create a new one named "washlens-ai"
3. Click "Add app" → Android icon
4. Enter your Android package name: `com.example.washlens_ai`
5. Enter a nickname for your app (e.g., "WashLens AI Android")
6. **Skip the google-services.json download for now** - we'll do this after adding SHA fingerprints

### 2. Generate SHA Certificate Fingerprints

You need to add SHA-1 and SHA-256 fingerprints from your Android keystore to Firebase.

#### For Debug Keystore (Development)

Run this command in your terminal:

```bash
# On Windows (adjust path if your Java is installed elsewhere)
keytool -list -v -keystore "%USERPROFILE%\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android

# On macOS/Linux
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
```

This will output something like:
```
Certificate fingerprints:
SHA1: AA:BB:CC:DD:EE:FF:...
SHA256: AA:BB:CC:DD:...
```

Copy the SHA-1 and SHA-256 values.

#### For Release Keystore (Production)

If you have a release keystore, run:
```bash
keytool -list -v -keystore /path/to/your/release/keystore.jks -alias your_alias
```

### 3. Add SHA Fingerprints to Firebase

1. In Firebase Console → Project Settings → General → Your Apps → Android app
2. Scroll to "SHA certificate fingerprints"
3. Click "Add fingerprint"
4. Paste your SHA-1 and SHA-256 values
5. Click "Save"

### 4. Download google-services.json

1. In Firebase Console → Project Settings → General → Your Apps → Android app
2. Click "Download google-services.json"
3. Place the downloaded file in `android/app/google-services.json`

### 5. Enable Authentication

1. In Firebase Console → Authentication → Get started
2. Go to "Sign-in method" tab
3. Enable "Google" as a sign-in provider
4. Add your project's public-facing name and support email
5. Click "Save"

### 6. Enable Storage (Optional)

If your app needs Firebase Storage:
1. In Firebase Console → Storage → Get started
2. Follow the setup wizard

### 7. Rebuild the App

After adding `google-services.json`, clean and rebuild your Flutter app:

```bash
flutter clean
flutter pub get
flutter run
```

## Configuration Files

### google-services.json template

Place this file in `android/app/google-services.json` (replace with your actual values):

```json
{
  "project_info": {
    "project_number": "YOUR_PROJECT_NUMBER",
    "project_id": "washlens-ai",
    "storage_bucket": "washlens-ai.appspot.com"
  },
  "client": [
    {
      "client_info": {
        "mobilesdk_app_id": "YOUR_MOBILE_SDK_APP_ID",
        "android_client_info": {
          "package_name": "com.example.washlens_ai"
        }
      },
      "oauth_client": [
        {
          "client_id": "YOUR_OAUTH_CLIENT_ID",
          "client_type": 3
        }
      ],
      "api_key": [
        {
          "current_key": "YOUR_API_KEY"
        }
      ],
      "services": {
        "appinvite_service": {
          "other_platform_oauth_client": [
            {
              "client_id": "YOUR_OAUTH_CLIENT_ID",
              "client_type": 3
            }
          ]
        }
      }
    }
  ],
  "configuration_version": "1"
}
```

## Troubleshooting

### "Google sign-in failed" error

This usually means:
- `google-services.json` is missing or incorrect
- SHA fingerprints don't match
- Package name doesn't match

Check the app logs for detailed error messages starting with "❌".

### Account picker shows but then fails

The account picker appearing means Firebase is partially configured, but the OAuth flow fails. This typically indicates:
- Missing or incorrect SHA fingerprints
- `google-services.json` not placed correctly
- Package name mismatch

### Build fails after adding google-services.json

Make sure:
- The JSON file is valid (no syntax errors)
- It's placed exactly at `android/app/google-services.json`
- You've run `flutter clean` after adding the file

## Environment Variables

Update your `.env` file with the correct Firebase values:

```env
# Firebase Configuration
FIREBASE_ANDROID_API_KEY=your_android_api_key_here
FIREBASE_ANDROID_APP_ID=your_android_app_id_here
FIREBASE_PROJECT_ID=washlens-ai
FIREBASE_MESSAGING_SENDER_ID=your_sender_id_here
FIREBASE_STORAGE_BUCKET=washlens-ai.appspot.com
```

## Testing

After setup, test the Google Sign-In flow:
1. Tap "Continue with Google" on the login screen
2. Select a Google account
3. The app should authenticate successfully and navigate to the home screen

