# WashLens AI - FCM Test Backend

A simple Node.js server using Firebase Admin SDK to send test notifications to your WashLens AI app.

## Setup

1. **Firebase Admin Setup**
   ```bash
   npm install firebase-admin express cors
   ```

2. **Get Service Account Key**
   - Go to Firebase Console > Project Settings > Service Accounts
   - Generate new private key and save as `serviceAccountKey.json`
   - Place in the same directory as this script

3. **Environment Variables**
   Create a `.env` file:
   ```
   FIREBASE_PROJECT_ID=your-project-id
   FCM_SERVER_KEY=your-fcm-server-key
   ```

4. **Run the Server**
   ```bash
   node fcm-test-server.js
   ```

## Endpoints

### Send Test Notification
```
POST /send-test-notification
Content-Type: application/json

{
  "fcmToken": "user-fcm-token-here",
  "title": "Test Notification",
  "body": "This is a test notification from WashLens AI",
  "data": {
    "type": "test",
    "timestamp": "2024-01-01T00:00:00Z"
  }
}
```

### Send Wash Reminder
```
POST /send-wash-reminder
Content-Type: application/json

{
  "fcmToken": "user-fcm-token-here",
  "washId": "wash-123",
  "dhobiName": "Ramu Dhobi",
  "itemCount": 5,
  "reminderType": "pickup"
}
```

### Send Missing Item Alert
```
POST /send-missing-alert
Content-Type: application/json

{
  "fcmToken": "user-fcm-token-here",
  "washId": "wash-123",
  "dhobiName": "Ramu Dhobi",
  "missingItems": ["T-Shirt", "Jeans"],
  "severity": "high"
}
```

## Usage in Development

1. Start the server: `node fcm-test-server.js`
2. Open your WashLens AI app
3. Go to Notification Settings and tap the test button
4. The app will use this server to send test notifications
5. Check your device notifications

## Security Note

This is for development/testing only. In production:
- Use proper authentication
- Validate all input data
- Implement rate limiting
- Use HTTPS
- Store credentials securely