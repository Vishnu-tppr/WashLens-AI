const admin = require('firebase-admin');
const express = require('express');
const cors = require('cors');

// Initialize Express app
const app = express();
app.use(cors());
app.use(express.json());

// Initialize Firebase Admin SDK
try {
  const serviceAccount = require('./serviceAccountKey.json');
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
    projectId: process.env.FIREBASE_PROJECT_ID || serviceAccount.project_id,
  });
  console.log('✅ Firebase Admin SDK initialized');
} catch (error) {
  console.error('❌ Failed to initialize Firebase Admin SDK:', error.message);
  console.log('Please ensure serviceAccountKey.json is in the same directory');
  process.exit(1);
}

// Helper function to send FCM message
async function sendFCMMessage(fcmToken, title, body, data = {}) {
  try {
    const message = {
      token: fcmToken,
      notification: {
        title: title,
        body: body,
      },
      data: {
        ...data,
        // Convert all data values to strings (FCM requirement)
        timestamp: new Date().toISOString(),
      },
      android: {
        notification: {
          channelId: 'washlens_channel',
          priority: 'high',
          sound: 'default',
          icon: 'ic_notification',
          color: '#4A6FFF',
        },
        priority: 'high',
      },
      apns: {
        payload: {
          aps: {
            alert: {
              title: title,
              body: body,
            },
            badge: 1,
            sound: 'default',
          },
        },
      },
    };

    const response = await admin.messaging().send(message);
    console.log('✅ FCM message sent successfully:', response);
    return { success: true, messageId: response };
  } catch (error) {
    console.error('❌ Error sending FCM message:', error);
    throw error;
  }
}

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({ 
    status: 'OK', 
    service: 'WashLens AI FCM Test Server',
    timestamp: new Date().toISOString() 
  });
});

// Send test notification
app.post('/send-test-notification', async (req, res) => {
  try {
    const { fcmToken, title, body, data } = req.body;

    if (!fcmToken) {
      return res.status(400).json({ error: 'FCM token is required' });
    }

    const messageTitle = title || '🧪 Test Notification';
    const messageBody = body || 'This is a test notification from WashLens AI. If you see this, FCM is working!';
    const messageData = data || { type: 'test' };

    await sendFCMMessage(fcmToken, messageTitle, messageBody, messageData);

    res.json({ 
      success: true, 
      message: 'Test notification sent successfully' 
    });
  } catch (error) {
    res.status(500).json({ 
      error: 'Failed to send test notification', 
      details: error.message 
    });
  }
});

// Send wash reminder notification
app.post('/send-wash-reminder', async (req, res) => {
  try {
    const { fcmToken, washId, dhobiName, itemCount, reminderType } = req.body;

    if (!fcmToken || !washId || !dhobiName) {
      return res.status(400).json({ error: 'Missing required fields' });
    }

    let title, body;
    if (reminderType === 'pickup') {
      title = '⏰ Pickup Reminder';
      body = `Time to collect your ${itemCount} items from ${dhobiName}!`;
    } else {
      title = '⏰ Laundry Reminder';
      body = `You have ${itemCount} items with ${dhobiName}. Don't forget to check!`;
    }

    const data = {
      type: 'wash_reminder',
      id: washId,
      dhobi: dhobiName,
      reminderType: reminderType || 'general',
    };

    await sendFCMMessage(fcmToken, title, body, data);

    res.json({ 
      success: true, 
      message: 'Wash reminder sent successfully' 
    });
  } catch (error) {
    res.status(500).json({ 
      error: 'Failed to send wash reminder', 
      details: error.message 
    });
  }
});

// Send missing item alert
app.post('/send-missing-alert', async (req, res) => {
  try {
    const { fcmToken, washId, dhobiName, missingItems, severity } = req.body;

    if (!fcmToken || !washId || !dhobiName || !missingItems) {
      return res.status(400).json({ error: 'Missing required fields' });
    }

    const itemCount = missingItems.length;
    const itemList = missingItems.slice(0, 2).join(', ');
    const moreItems = itemCount > 2 ? ` and ${itemCount - 2} more` : '';

    const title = '❌ Missing Items Alert';
    const body = `${itemCount} items missing from ${dhobiName}: ${itemList}${moreItems}`;

    const data = {
      type: 'missing_items',
      id: washId,
      dhobi: dhobiName,
      severity: severity || 'medium',
      missingCount: itemCount.toString(),
    };

    await sendFCMMessage(fcmToken, title, body, data);

    res.json({ 
      success: true, 
      message: 'Missing item alert sent successfully' 
    });
  } catch (error) {
    res.status(500).json({ 
      error: 'Failed to send missing item alert', 
      details: error.message 
    });
  }
});

// Send pickup timer notification
app.post('/send-pickup-timer', async (req, res) => {
  try {
    const { fcmToken, washId, dhobiName, hoursRemaining } = req.body;

    if (!fcmToken || !washId || !dhobiName) {
      return res.status(400).json({ error: 'Missing required fields' });
    }

    const hours = hoursRemaining || 0;
    let title, body;

    if (hours <= 0) {
      title = '✅ Ready for Pickup';
      body = `Your laundry at ${dhobiName} is ready for collection!`;
    } else if (hours <= 2) {
      title = '⏱️ Almost Ready';
      body = `Your laundry at ${dhobiName} will be ready in ${hours} ${hours === 1 ? 'hour' : 'hours'}`;
    } else {
      title = '⏱️ Pickup Timer';
      body = `Your laundry at ${dhobiName} will be ready in ${hours} hours`;
    }

    const data = {
      type: 'pickup_timer',
      id: washId,
      dhobi: dhobiName,
      hoursRemaining: hours.toString(),
    };

    await sendFCMMessage(fcmToken, title, body, data);

    res.json({ 
      success: true, 
      message: 'Pickup timer notification sent successfully' 
    });
  } catch (error) {
    res.status(500).json({ 
      error: 'Failed to send pickup timer', 
      details: error.message 
    });
  }
});

// Send return confirmation
app.post('/send-return-confirmation', async (req, res) => {
  try {
    const { fcmToken, dhobiName, returnedCount } = req.body;

    if (!fcmToken || !dhobiName) {
      return res.status(400).json({ error: 'Missing required fields' });
    }

    const title = '✅ Laundry Returned';
    const body = `Successfully returned ${returnedCount || 'all'} items from ${dhobiName}!`;

    const data = {
      type: 'return_confirmation',
      dhobi: dhobiName,
      returnedCount: (returnedCount || 0).toString(),
    };

    await sendFCMMessage(fcmToken, title, body, data);

    res.json({ 
      success: true, 
      message: 'Return confirmation sent successfully' 
    });
  } catch (error) {
    res.status(500).json({ 
      error: 'Failed to send return confirmation', 
      details: error.message 
    });
  }
});

// Error handling middleware
app.use((error, req, res, next) => {
  console.error('Unhandled error:', error);
  res.status(500).json({ 
    error: 'Internal server error', 
    details: error.message 
  });
});

// Start server
const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`🚀 WashLens AI FCM Test Server running on port ${PORT}`);
  console.log(`📡 Health check: http://localhost:${PORT}/health`);
  console.log(`🔔 Send test notification: POST http://localhost:${PORT}/send-test-notification`);
});

module.exports = app;