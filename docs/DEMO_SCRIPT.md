# WashLens AI - Complete Demo Script

This document provides step-by-step instructions for demonstrating all features of the WashLens AI app.

## Prerequisites

- App installed on Android/iOS device
- Sample laundry photos ready
- Firebase project configured
- TFLite model loaded

---

## Demo Flow

### 1. First Launch (Onboarding)

**Steps:**
1. Open app
2. Watch animated splash screen (2.5s)
3. View onboarding screens (if first time):
   - Welcome screen
   - AI Detection feature explanation
   - Return matching feature
   - Permissions request (Camera, Notifications)

**Expected Result:**
- Smooth splash animation
- Clear feature explanation
- Permissions granted

---

### 2. Create New Wash Entry

**Scenario:** Student is sending 15 items to "Raju Dhobi"

**Steps:**
1. Tap floating action button "New Wash"
2. Enter dhobi name: "Raju Dhobi"
3. Tap camera icon to scan laundry
4. Take photo of laundry pile
5. Wait for AI detection (2-5 seconds)
6. Review detected items:
   - 6 Shirts
   - 3 T-shirts
   - 2 Pants
   - 2 Towels
   - 2 Socks (pairs)
7. Edit counts if needed (+ / - buttons)
8. Add notes (optional): "Please use gentle wash for blue shirt"
9. Tap "Save Entry"

**Expected Result:**
- AI accurately detects and counts items
- Category icons with counts displayed
- Photo saved securely
- Entry appears in "Recent Washes" with "Pending" status
- 3-day reminder scheduled automatically

**Demo Photos Location:** `samples/demo_wash_given.jpg`

---

### 3. View Wash Entry Details

**Steps:**
1. Tap on the "Raju Dhobi" entry from home screen
2. View details:
   - Given date/time
   - Photo proof
   - Item breakdown by category
   - Detected colors: Blue, White, Black
   - Status: Pending
   - Days pending: X days

**Expected Result:**
- All details displayed clearly
- Photo zoom-in available
- Color-coded status badge

---

### 4. Receive Reminder Notification

**Scenario:** 3 days have passed since wash was given

**Steps:**
1. Wait for 3 days OR manually trigger notification for demo
2. Notification appears: "⚠️ You gave 15 clothes on [Date]. Did you collect them?"
3. Tap notification
4. Opens app to specific wash entry

**Expected Result:**
- Notification delivered on time
- Deep link opens correct entry
- Clear call-to-action

---

### 5. Mark Items as Returned

**Scenario:** Dhobi returns clothes, but 1 t-shirt is missing

**Steps:**
1. Open wash entry for "Raju Dhobi"
2. Tap "Mark Returned" button
3. Take photo of returned laundry
4. AI re-detects and counts:
   - 6 Shirts ✓
   - 2 T-shirts ❌ (expected 3)
   - 2 Pants ✓
   - 2 Towels ✓
   - 2 Socks ✓
5. App shows comparison:
   - **Given:** 15 items
   - **Returned:** 14 items
   - **Missing:** 1 T-shirt
6. Review and confirm

**Expected Result:**
- Side-by-side comparison
- Missing items highlighted in red
- Matched items shown in green
- Missing item alert notification sent

**Demo Photos Location:** `samples/demo_wash_returned.jpg`

---

### 6. Export Proof (PDF + WhatsApp)

**Steps:**
1. Open wash entry details
2. Tap "Export Proof" button
3. PDF is generated with:
   - Dhobi name
   - Given vs Returned photos
   - Item counts breakdown
   - Missing items list
   - Date/time stamps
4. Tap "Share via WhatsApp"
5. Select "Raju Dhobi" contact
6. Message auto-populated: "Hi, 1 T-shirt is missing from my laundry (Order #WLN987654). Please see attached proof."

**Expected Result:**
- Professional PDF generated
- Share sheet opens
- WhatsApp message pre-filled
- PDF attached

---

### 7. View Analytics Dashboard

**Steps:**
1. Navigate to "Analytics" tab
2. View statistics:
   - **Total Items Given This Month:** 42
   - **Most Missing Category:** Socks (chart)
   - **Dhobi Risk Score:**
     - Raju Dhobi: **High Risk** (3 missing items in last month)
     - Anil Laundry: Low Risk
   - **Return Delay Pattern:** Bar chart by day of week
3. Tap on "Socks" category
4. View history of sock losses

**Expected Result:**
- Interactive charts (fl_chart)
- Color-coded risk levels
- Insights into patterns
- Actionable recommendations

---

### 8. Category Manager

**Steps:**
1. Go to Settings > Manage Categories
2. Add custom category: "Hoodie"
   - Choose icon
   - Choose color
   - Select group: Upper Wear
3. Reorder categories (drag & drop)
4. Hide "Bedsheet" category
5. Save changes

**Expected Result:**
- New category appears in detection
- Hidden categories don't show in UI
- Changes persist after app restart

---

### 9. Home Screen Widget (Android)

**Steps:**
1. Long-press home screen
2. Add "WashLens Summary" widget
3. Widget shows:
   - "Raju Dhobi - 15 items"
   - "Missing: 1"
   - Quick action buttons
4. Tap widget to open app

**Expected Result:**
- Widget updates automatically
- Deep links work
- Compact and readable

---

### 10. Offline Mode

**Scenario:** No internet connection

**Steps:**
1. Turn off WiFi and mobile data
2. Create new wash entry
3. Take photo and detect items
4. Save entry
5. App shows "Queued for sync" badge
6. Turn on internet
7. Entry automatically syncs to Firebase

**Expected Result:**
- Full functionality offline
- Local SQLite storage
- Auto-sync when online
- No data loss

---

### 11. Color & Pattern Detection

**Steps:**
1. Create wash entry with colorful clothes
2. After detection, view "Detected Colors & Patterns":
   - Colors: Blue, Red, White, Black
   - Patterns: Striped, Checked, Plain
3. Use this info to identify specific items when missing

**Expected Result:**
- Accurate color detection
- Pattern recognition (basic)
- Helps differentiate similar items

---

### 12. Partial Return

**Scenario:** Dhobi returns clothes in 2 batches

**Steps:**
1. Mark items as "Partially Returned"
2. Check off:
   - 3 Shirts (out of 6)
   - 1 Pant (out of 2)
3. Status changes to "Partially Returned"
4. Later, mark remaining items
5. Status changes to "Returned"

**Expected Result:**
- Flexible partial marking
- Status updates correctly
- History maintained

---

### 13. Multi-Image Support

**Scenario:** Laundry pile too big for one photo

**Steps:**
1. Start new wash entry
2. Take first photo (6 items)
3. Tap "Add More Photos"
4. Take second photo (9 items)
5. AI merges counts:
   - Total: 15 items across both photos

**Expected Result:**
- Multiple photos supported
- Counts aggregated correctly
- All photos stored

---

### 14. Quick Add (Manual Mode)

**Scenario:** User prefers manual entry

**Steps:**
1. Tap "Quick Add" button
2. Manually increment counts:
   - Shirts +5
   - Pants +2
3. Save without photo

**Expected Result:**
- Manual entry works
- No AI inference needed
- Faster for experienced users

---

### 15. Settings & Preferences

**Steps:**
1. Go to Settings
2. Configure:
   - Reminder days: 3 → 5
   - Enable/disable cloud backup
   - Offline mode preferences
   - PDF export quality: High
3. View account info
4. Test "Clear Cache" and "Export Data"

**Expected Result:**
- All settings functional
- Changes applied immediately
- Data export as JSON

---

## Performance Benchmarks

Expected performance on mid-range device:

| Operation | Target Time |
|-----------|-------------|
| Splash screen | 2.5s |
| ML inference (single photo) | 150-300ms |
| Photo upload to Firebase | 2-5s |
| Offline save | <100ms |
| PDF generation | 1-2s |
| Widget update | <500ms |

---

## Edge Cases to Test

1. **Very low light photos** - Should show confidence warning
2. **Empty laundry pile** - Should detect 0 items
3. **Non-clothing objects** - Should ignore or mark as unknown
4. **100+ items** - Should handle large counts
5. **Rapid entry creation** - No crashes or duplicates
6. **Kill app during sync** - Resume sync on restart
7. **Change Firebase credentials** - Handle auth errors gracefully

---

## Demo Tips

- **Have good lighting** for accurate detection
- **Use real laundry photos** for authenticity
- **Pre-load sample data** for analytics demo
- **Enable developer mode** to show inference times
- **Keep backup samples** in case of network issues

---

## Troubleshooting Demo Issues

### AI Detection Not Working
- Check if `washlens_yolo.tflite` exists in `assets/models/`
- Verify model is not corrupted
- Check device has sufficient RAM

### Firebase Not Syncing
- Verify `google-services.json` is present
- Check internet connection
- Verify Firebase project is active

### Widget Not Updating
- Check background task permissions
- Verify App Group configured (iOS)
- Manually trigger update for demo

### Notifications Not Showing
- Grant notification permissions
- Check notification settings in device
- Verify FCM token is valid

---

## Post-Demo Survey Questions

1. Was the AI detection accurate?
2. Is the UI intuitive?
3. Would you use this app?
4. What features would you add?
5. Any bugs encountered?

---

**End of Demo Script**
