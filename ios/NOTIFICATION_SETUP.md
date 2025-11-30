# iOS Configuration for WashLens AI Notifications

## Add to ios/Runner/Info.plist

Add these entries to your `ios/Runner/Info.plist` file within the `<dict>` section:

```xml
<!-- Firebase Cloud Messaging -->
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLName</key>
        <string>REVERSED_CLIENT_ID</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>YOUR_REVERSED_CLIENT_ID</string>
        </array>
    </dict>
</array>

<!-- Push Notifications Capability -->
<key>UIBackgroundModes</key>
<array>
    <string>remote-notification</string>
    <string>background-processing</string>
</array>

<!-- Notification Categories -->
<key>UNUserNotificationCenter</key>
<dict>
    <key>UNNotificationCategories</key>
    <array>
        <dict>
            <key>UNNotificationCategoryIdentifier</key>
            <string>WASH_REMINDER</string>
            <key>UNNotificationCategoryActions</key>
            <array>
                <dict>
                    <key>UNNotificationActionIdentifier</key>
                    <string>VIEW_WASH</string>
                    <key>UNNotificationActionTitle</key>
                    <string>View Details</string>
                    <key>UNNotificationActionOptions</key>
                    <integer>1</integer>
                </dict>
            </array>
        </dict>
        <dict>
            <key>UNNotificationCategoryIdentifier</key>
            <string>MISSING_ITEMS</string>
            <key>UNNotificationCategoryActions</key>
            <array>
                <dict>
                    <key>UNNotificationActionIdentifier</key>
                    <string>MARK_FOUND</string>
                    <key>UNNotificationActionTitle</key>
                    <string>Mark Found</string>
                    <key>UNNotificationActionOptions</key>
                    <integer>1</integer>
                </dict>
            </array>
        </dict>
    </array>
</dict>

<!-- App Transport Security -->
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <true/>
</dict>
```

## Xcode Project Settings

### 1. Enable Push Notifications Capability
1. Open `ios/Runner.xcworkspace` in Xcode
2. Select the `Runner` target
3. Go to "Signing & Capabilities" tab
4. Click "+ Capability" and add "Push Notifications"

### 2. Enable Background Modes
1. Click "+ Capability" and add "Background Modes"
2. Check "Remote notifications"
3. Check "Background processing"

### 3. Configure Firebase
1. Ensure `GoogleService-Info.plist` is in `ios/Runner/`
2. In Xcode, right-click Runner folder and "Add Files to Runner"
3. Select `GoogleService-Info.plist`
4. Make sure "Add to target: Runner" is checked

### 4. Update Deployment Target
Set iOS Deployment Target to iOS 12.0 or higher for full notification support.

## APNs Certificate Setup

### Development Environment
1. Go to Apple Developer Console
2. Certificates, Identifiers & Profiles
3. Create APNs Development SSL Certificate
4. Upload to Firebase Project Settings > Cloud Messaging

### Production Environment
1. Create APNs Production SSL Certificate
2. Upload to Firebase Project Settings > Cloud Messaging

## Testing on Device
- Notifications only work on physical devices, not in simulator
- Ensure proper provisioning profile is selected
- Test both foreground and background notification delivery