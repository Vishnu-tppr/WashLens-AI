# Architecture Documentation

## System Overview

WashLens AI is a mobile-first application built with Flutter that uses on-device machine learning to automatically detect and count laundry items. The system follows an offline-first architecture with cloud synchronization.

## High-Level Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     Mobile Application                       │
│                       (Flutter)                              │
├─────────────────────────────────────────────────────────────┤
│  ┌─────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │  UI Layer   │  │ Service Layer │  │  Data Layer  │      │
│  │             │  │               │  │              │      │
│  │ • Screens   │──│ • Firebase    │──│ • Drift DB   │      │
│  │ • Widgets   │  │ • Notification│  │ • Repos      │      │
│  │ • State Mgmt│  │ • Sync        │  │ • Models     │      │
│  └─────────────┘  └──────────────┘  └──────────────┘      │
│                                                              │
│  ┌─────────────────────────────────────────────────┐       │
│  │           ML Inference Layer                     │       │
│  │  • TFLite Runtime                                │       │
│  │  • YOLOv8 Nano (INT8)                           │       │
│  │  • Image Preprocessing                           │       │
│  │  • Post-processing (NMS)                         │       │
│  └─────────────────────────────────────────────────┘       │
└─────────────────────────────────────────────────────────────┘
                           │
                           ├── REST API (Optional fallback)
                           │
┌─────────────────────────▼─────────────────────────────────┐
│                   Firebase Backend                         │
├─────────────────────────────────────────────────────────────┤
│  ┌──────────────┐  ┌──────────────┐  ┌─────────────┐     │
│  │  Firestore   │  │   Storage    │  │  Cloud      │     │
│  │  (Database)  │  │   (Images)   │  │  Messaging  │     │
│  │              │  │              │  │  (Push)     │     │
│  └──────────────┘  └──────────────┘  └─────────────┘     │
└─────────────────────────────────────────────────────────────┘
```

## Component Details

### 1. UI Layer

**Responsibilities:**
- Render screens and widgets
- Handle user interactions
- Manage local UI state

**Key Screens:**
- Splash Screen (Rive animation)
- Home Dashboard
- New Wash Entry
- Camera/Photo Picker
- Return Verification
- History List
- Analytics Dashboard
- Settings
- Category Manager

**State Management:**
- Provider for dependency injection
- StatefulWidget for local state
- Stream builders for reactive data

### 2. ML Inference Layer

**Architecture:**
```
Image Input → Preprocessing → TFLite Inference → Post-processing → Results
```

**Components:**
- `ClothDetector`: Main ML service
- `ColorClassifier`: Extract dominant colors
- `PatternClassifier`: Detect patterns (stripes, checks)

**Model Details:**
- **Model:** YOLOv8 Nano
- **Input:** 640x640x3 RGB
- **Output:** 8400 detections × 13 (x, y, w, h, conf, 8 classes)
- **Quantization:** INT8 for mobile efficiency
- **Size:** ~6MB
- **Latency:** 150-300ms on mid-range devices

**Classes:**
0. Shirt
1. T-shirt
2. Pants
3. Shorts
4. Track Pant
5. Towel
6. Socks
7. Bedsheet

### 3. Data Layer

**Local Database (Drift/SQLite):**

```sql
-- WashEntries Table
CREATE TABLE wash_entries (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL,
  dhobi_name TEXT NOT NULL,
  given_at DATETIME NOT NULL,
  returned_at DATETIME,
  status TEXT NOT NULL,
  given_photo_urls TEXT NOT NULL, -- JSON array
  returned_photo_urls TEXT,       -- JSON array
  given_counts TEXT NOT NULL,     -- JSON object
  returned_counts TEXT,            -- JSON object
  notes TEXT,
  created_at DATETIME NOT NULL,
  updated_at DATETIME NOT NULL,
  is_synced BOOLEAN DEFAULT 0
);

-- UserSettings Table
CREATE TABLE user_settings (
  user_id TEXT PRIMARY KEY,
  reminder_days INTEGER DEFAULT 3,
  enable_notifications BOOLEAN DEFAULT 1,
  enable_cloud_backup BOOLEAN DEFAULT 1,
  enable_offline_mode BOOLEAN DEFAULT 1,
  category_visibility TEXT,    -- JSON
  custom_categories TEXT,       -- JSON array
  preferred_dhobi TEXT,
  created_at DATETIME NOT NULL,
  updated_at DATETIME NOT NULL
);

-- SyncQueue Table
CREATE TABLE sync_queue (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  operation TEXT NOT NULL,  -- 'create', 'update', 'delete'
  entity_type TEXT NOT NULL,
  entity_id TEXT NOT NULL,
  payload TEXT NOT NULL,    -- JSON
  created_at DATETIME NOT NULL,
  is_pending BOOLEAN DEFAULT 1
);
```

**Cloud Database (Firestore):**

```
/users/{userId}
  /wash_entries/{entryId}
    - id
    - dhobiName
    - givenAt
    - returnedAt
    - status
    - givenPhotoUrls[]
    - returnedPhotoUrls[]
    - givenCounts{}
    - returnedCounts{}
    - notes
    - createdAt
    - updatedAt

/users/{userId}
  - settings{}
  - fcmToken
  - lastActive
```

**Storage Structure:**
```
/users/{userId}/washes/{washId}/given/{imageId}.jpg
/users/{userId}/washes/{washId}/returned/{imageId}.jpg
```

### 4. Service Layer

**FirebaseService:**
- Authentication (Anonymous, Email/Password)
- Firestore CRUD operations
- Cloud Storage uploads
- Real-time data streams

**NotificationService:**
- Local notifications (flutter_local_notifications)
- Push notifications (FCM)
- Scheduled reminders
- Deep linking

**SyncService:**
- Offline queue management
- Conflict resolution
- Background sync
- Retry logic

**ExportService:**
- PDF generation
- WhatsApp share integration
- Image compression

### 5. Native Integration

**Android Widget (AppWidget):**
```kotlin
// android/app/src/main/kotlin/com/washlens/ai/WashLensWidget.kt
class WashLensWidget : AppWidgetProvider() {
    override fun onUpdate(...) {
        // Update widget UI from shared preferences
        // Set up deep links for buttons
    }
}
```

**iOS Widget (WidgetKit):**
```swift
// ios/WidgetExtension/WashLensWidget.swift
struct WashLensWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "WashLensWidget", provider: Provider()) { entry in
            WashLensWidgetView(entry: entry)
        }
    }
}
```

**Platform Channels:**
```dart
// lib/native_integration/widget_bridge.dart
class WidgetBridge {
  static const platform = MethodChannel('com.washlens.ai/widget');
  
  static Future<void> updateWidget(Map<String, dynamic> data) async {
    await platform.invokeMethod('updateWidget', data);
  }
}
```

## Data Flow

### Creating a New Wash Entry

```
1. User taps "New Wash" button
2. Camera screen opens
3. User captures photo
4. Image → ClothDetector.detectFromFile()
5. Preprocessing (resize, normalize)
6. TFLite inference
7. Post-processing (NMS, grouping)
8. UI displays detected items
9. User confirms/edits counts
10. WashEntry created
11. Saved to local SQLite
12. Added to sync queue
13. Background sync uploads to Firestore
14. Photos uploaded to Cloud Storage
15. Sync queue marked complete
16. 3-day reminder scheduled
17. Home widget updated
```

### Return Verification Flow

```
1. User opens pending wash entry
2. Taps "Mark Returned"
3. Camera opens
4. User captures returned items photo
5. ML detects returned items
6. Compare given vs returned counts
7. Calculate missing items
8. Display comparison UI
9. User confirms
10. Entry updated in SQLite
11. Sync to Firestore
12. If missing items:
    - Show alert notification
    - Update analytics
    - Risk score calculation
13. Cancel reminder notification
14. Update home widget
```

## Security & Privacy

### Data Encryption
- Firebase Storage: Server-side encryption at rest
- Local SQLite: Option for SQLCipher encryption
- Secure storage for sensitive keys

### Authentication
- Firebase Auth with email/password
- Anonymous auth for quick start
- Optional Google Sign-In

### Authorization Rules

**Firestore:**
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read, write: if request.auth.uid == userId;
      
      match /wash_entries/{entryId} {
        allow read, write: if request.auth.uid == userId;
      }
    }
  }
}
```

**Storage:**
```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /users/{userId}/{allPaths=**} {
      allow read, write: if request.auth.uid == userId;
    }
  }
}
```

## Performance Optimization

### Image Optimization
- Compress images before upload (70% quality, max 1920px)
- Use cached_network_image for display
- Progressive loading with placeholders

### ML Optimization
- INT8 quantization (6MB model)
- GPU acceleration via NNAPI (Android)
- Metal delegate (iOS)
- Batch processing for multiple images

### Database Optimization
- Indexed queries on userId, givenAt
- Pagination for large lists
- Lazy loading of photos

### Network Optimization
- Offline-first architecture
- Delta sync (only changed data)
- Image CDN caching
- Retry with exponential backoff

## Scalability Considerations

### Current Limits
- **Max images per entry:** 10
- **Max entries per user:** Unlimited
- **Max image size:** 10MB
- **Max users:** 100,000+ (Firestore Spark plan)

### Scaling Strategy
- **Database:** Firestore scales automatically
- **Storage:** Cloud Storage scales automatically
- **ML:** On-device = infinite scale
- **CDN:** Firebase CDN for global distribution

## Monitoring & Analytics

### Metrics Tracked
- ML inference latency
- Detection accuracy (manual feedback)
- Crash reports (Firebase Crashlytics)
- Usage analytics (Firebase Analytics)
- API error rates

### Logging
- Console logs (development)
- Firebase Crashlytics (production)
- Custom event tracking

## Deployment Architecture

```
Developer Machine
    │
    ├──> Git Push
    │
GitHub Actions (CI/CD)
    │
    ├──> Run Tests
    ├──> Build APK/AAB
    ├──> Build IPA
    │
Fastlane
    │
    ├──> Google Play Store (Beta track)
    ├──> Apple TestFlight
    │
End Users
```

## Technology Stack Summary

| Layer | Technology |
|-------|------------|
| Mobile Framework | Flutter 3.16+ |
| Language | Dart |
| State Management | Provider |
| Local Database | Drift (SQLite) |
| Cloud Backend | Firebase (Firestore, Storage, Auth, FCM) |
| ML Framework | TensorFlow Lite |
| ML Model | YOLOv8 Nano |
| Animations | Rive, Lottie |
| PDF Generation | pdf package |
| Charts | fl_chart |
| Notifications | flutter_local_notifications, FCM |
| Image Processing | image package |
| CI/CD | GitHub Actions, Fastlane |
| Monitoring | Firebase Crashlytics, Analytics |

---

**Last Updated:** November 15, 2025
