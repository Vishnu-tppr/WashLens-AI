# 🧺 WashLens AI 📸🧠[<img align="center" alt="Chill gif" src="https://raw.githubusercontent.com/Vishnu-tppr/Vishnu-cse/main/Untitled%20gif%20-%20Made%20with%20Clipchamp.gif" width="100" height="100" />](https://github.com/Vishnu-tppr?tab=repositories)

> 🎯 A next‑gen AI-powered Flutter app that automatically detects, counts, and tracks your laundry.
>
> 📸 Snap a photo → 🧠 AI identifies items → 🔄 Track Given vs Returned → ⚠️ Get missing‑item alerts.

---

## 📌 Table of Contents

* [✨ Features](#-features)
* [📸 Demo Screenshots](#-demo-screenshots)
* [🧠 How It Works](#-how-it-works)
* [🏗️ Architecture](#️-architecture)
* [📁 Project Structure](#-project-structure)
* [⚙️ Requirements](#️-requirements)
* [🚀 Getting Started](#-getting-started)
* [🤖 TFLite Model Setup](#-tflite-model-setup)
* [▶️ Run the App](#️-run-the-app)
* [🧪 Testing](#-testing)
* [📱 Build for Production](#-build-for-production)
* [🧩 Technologies Used](#-technologies-used)
* [👨🏻‍💻 Author](#-author)
* [📜 License](#-license)

---

## ✨ Features

* 🤖 **AI Cloth Detection** – Shirts, t‑shirts, pants, shorts, towels, socks, bedsheets & more.
* 📸 **Camera Scanner** – On‑device TFLite model for fast offline detection.
* 🔄 **Return Verification** – Compare *Given vs Returned* instantly.
* ⚠️ **Missing Item Alerts** – Alerts for clothes not returned.
* 📊 **Analytics Dashboard** – Dhobi reliability, monthly stats, missing trends.
* 🕒 **Smart 3‑Day Reminders** – Auto reminders for unreturned laundry.
* 💾 **Offline‑First** – Works without internet.
* ☁️ **Cloud Backup** – Firebase Firestore + Storage sync.
* 🏷️ **Custom Categories** – Add/edit your own cloth types.
* 📤 **PDF / WhatsApp Export** – Proof with images & counts.
* 🎨 **Rive Animated Splash** – Clean motion intro.
* 🏠 **Home Widgets** – Android + iOS quick‑view widgets.

---

## 📸 Demo Screenshots

<p align="center">
  <img src="https://github.com/user-attachments/assets/92c44ef6-e2cd-4345-8015-a6a6d29c9353" width="300" />
  <img src="https://github.com/user-attachments/assets/0d4b5184-41b6-4dd1-879f-2cf704ee47df" width="300" />
  <img src="https://github.com/user-attachments/assets/95c01160-9070-4e1d-9d50-11e7471115cc" width="300" />
  <img src="https://github.com/user-attachments/assets/41e7348e-7b5b-419d-9fc9-567c125773b2" width="300" />
  <img src="https://github.com/user-attachments/assets/7653abb2-3bb6-4097-bffb-6bb378738f1c" width="300" />
  <img src="https://github.com/user-attachments/assets/3e09b5c5-ae4a-4278-bc71-8cfd5c21e4c3" width="300" />
  <img src="https://github.com/user-attachments/assets/4de19ff1-ad23-476d-a715-332152c40091" width="300" />
  <img src="https://github.com/user-attachments/assets/57291ce0-522f-4761-bb8e-9b84e04d0f43" width="300" />
  <img src="https://github.com/user-attachments/assets/7e041612-70a5-426f-9243-3ae914602ef5" width="300" />
  <img src="https://github.com/user-attachments/assets/01fc00cb-ce6b-411f-b1fa-ed896473361c" width="300" />
</p>

---

## 🧠 How It Works

### 1️⃣ Image → AI Detection

The app uses a quantized **YOLOv8 → TFLite** model to detect cloth items.

### 2️⃣ Count Extraction

Detections are grouped by class:

```
6 shirts
3 t‑shirts
1 towel
1 track pant
```

### 3️⃣ Save Wash Logs

Stored with:

* Date/time
* Dhobi name
* Detected counts
* Images
* Notes

### 4️⃣ Return Comparison

You capture the return photo → AI detects again → App compares both.

```
❌ Missing: 1 shirt, 1 towel
```

### 5️⃣ PDF/WhatsApp Export

Generates proof with before/after photos.

---

## 🏗️ Architecture

```
WashLens AI
 ├── Flutter Mobile UI
 ├── On‑Device ML (TFLite / YOLOv8)
 ├── Firebase Auth + Firestore + Storage
 ├── Offline SQLite Cache
 ├── Cloud Functions (Risk Analysis, Exports)
 └── Platform Integrations (Widgets, Notifications)
```

---

## 📁 Project Structure

```
lib/
├── main.dart
├── ui/
│   ├── splash/
│   ├── home/
│   ├── camera/
│   ├── wash_entry/
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
├── data/
│   ├── database.dart
│   ├── firestore_repo.dart
│   └── storage_repo.dart
└── native_integration/
    ├── widget_bridge.dart
    ├── notification_bridge.dart
    └── background_tasks.dart
```

---

## ⚙️ Requirements

* Flutter SDK ≥ 3.0.0
* Android Studio / Xcode
* Firebase account
* Python (for model training)
* Git

---

## 🚀 Getting Started

### 1️⃣ Clone Repo

```bash
git clone https://github.com/yourusername/washlens_ai.git
cd washlens_ai
```

### 2️⃣ Install Dependencies

```bash
flutter pub get
```

### 3️⃣ Add Firebase Files

```
android/app/google-services.json
ios/Runner/GoogleService-Info.plist
```

### 4️⃣ Deploy Rules

```bash
firebase deploy --only firestore:rules
firebase deploy --only storage
```

---

## 🤖 TFLite Model Setup

### Train YOLOv8 & Convert to TFLite

```bash
pip install ultralytics onnx tensorflow

yolo detect train data=laundry_dataset.yaml model=yolov8n.pt epochs=100
yolo export model=runs/detect/train/weights/best.pt format=tflite int8
```

Copy the file to:

```
assets/models/washlens_yolo.tflite
```

---

## ▶️ Run the App

### Android

```bash
flutter run
```

### iOS

```bash
cd ios && pod install && cd ..
flutter run
```

---

## 🧪 Testing

```bash
flutter test
```

### Coverage

```bash
flutter test --coverage
```

---

## 📱 Building for Production

### Android APK

```bash
flutter build apk --release
```

### Android App Bundle

```bash
flutter build appbundle --release
```

### iOS Release Build

```bash
flutter build ios --release
```

---

## 📤 Export & Sharing

PDF generation uses `pdf` & `printing` package.
Share via WhatsApp using system share sheet.

```dart
await Share.shareXFiles([pdfFile], text: 'Laundry Summary');
```

---

## 🧩 Technologies Used

* Flutter (Dart)
* Firebase
* TensorFlow Lite
* YOLOv8
* SQLite / Drift
* Rive
* Share Plus / PDF package

---

## 👨🏻‍💻 Author

Made with ❤️ by [**Vishnu**](https://www.linkedin.com/in/vishnu-v-31583b327/)

> "Solving my pain points" ⚡

---

## 📜 License

MIT License © 2025 WashLens AI

---

## ⭐ Support This Project

If you like this project, please **star ⭐ the repository** — it helps more people discover WashLens AI!
