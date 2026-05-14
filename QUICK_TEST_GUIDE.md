# 🧪 Quick Testing Guide for Push Notifications

## 🚀 Quick Start (5 Minutes)

### **Step 1: Run the App**

```bash
cd "c:\Users\abdullah\Documents\GitHub\Newar-FE\Student_app\student_complaint_app2"
flutter run
```

**Expected Console Output:**
```
✅ Firebase initialized successfully
✅ Background message handler registered
🚀 Initializing Firebase Messaging...
✅ User granted notification permission
🔑 FCM Token: eXyz123abc... [COPY THIS TOKEN!]
✅ Local notifications initialized
✅ Messaging service initialized
```

### **Step 2: Login and Check Token**

1. Login as student: `student@test.com` / `123456`
2. Watch console for:
   ```
   ✅ FCM token saved and topic subscribed
   ```
3. **Copy the FCM token** from console (you'll need it for testing)

### **Step 3: Test Notification (Firebase Console)**

1. Go to: https://console.firebase.google.com/
2. Select project: `student-complaint-app-36d8e`
3. Click **Cloud Messaging** (left menu)
4. Click **Send your first message** (or **New campaign**)
5. Fill in:
   - **Notification title**: "Test Notification"
   - **Notification text**: "Your complaint has been updated"
6. Click **Next**
7. Choose **Select device**
8. Paste your FCM token from Step 2
9. Click **Next** → **Review** → **Publish**

**Result:** You should see a notification pop up! 🎉

---

## 🎯 Test Scenarios

### **Scenario 1: Foreground Notification**
**Test:** Send notification while app is open
**Expected:** Notification appears at the top of screen

### **Scenario 2: Background Notification**
**Test:** Send notification while app is in background (minimize app)
**Expected:** Notification appears in notification tray

### **Scenario 3: Terminated Notification**
**Test:** Force close app, then send notification
**Expected:** Notification appears, tapping it opens the app

### **Scenario 4: Admin Update Flow**
**Steps:**
1. Login as student, submit a complaint
2. Logout, login as admin
3. Update complaint status
4. Logout, login back as student
**Expected:** Notification was queued in Firestore

---

## 🐛 Common Issues & Fixes

### **Issue: No FCM token generated**

**Fix:**
```bash
flutter clean
flutter pub get
flutter run
```

### **Issue: "POST_NOTIFICATIONS permission denied"**

**Fix:**
1. Go to Android Settings → Apps → Student Complaint App
2. Enable Notifications permission
3. Restart app

### **Issue: Notification not appearing**

**Checklist:**
- [ ] Permission granted? Check app settings
- [ ] FCM token saved? Check Firestore users collection
- [ ] Using correct FCM token?
- [ ] App not force-stopped?
- [ ] Battery optimization disabled?

### **Issue: Build errors**

**Fix:**
```bash
cd android
./gradlew clean
cd ..
flutter clean
flutter pub get
flutter run
```

---

## 📊 Verify in Firestore

1. Go to Firebase Console → Firestore Database
2. Check `users` collection
3. Find your user document
4. Verify `fcmToken` field exists

```json
{
  "email": "student@test.com",
  "fcmToken": "eXyz123abc...",  ← Should be here!
  "fcmTokenUpdatedAt": Timestamp,
  "role": "student"
}
```

---

## 🎨 Test with cURL (Advanced)

Replace `YOUR_SERVER_KEY` and `FCM_TOKEN`:

```bash
curl -X POST https://fcm.googleapis.com/fcm/send \
  -H "Authorization: key=YOUR_SERVER_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "to": "FCM_TOKEN",
    "notification": {
      "title": "Complaint Update",
      "body": "Your complaint has been resolved!"
    },
    "data": {
      "complaintId": "test123",
      "type": "complaint_update"
    }
  }'
```

**Get Server Key:**
1. Firebase Console → Project Settings → Cloud Messaging
2. Copy "Server key"

---

## ✅ Success Checklist

After completing all tests:

- [ ] FCM token generated and saved
- [ ] Notification permissions granted
- [ ] Foreground notifications working
- [ ] Background notifications working
- [ ] Terminated state notifications working
- [ ] Admin updates trigger notifications
- [ ] Topics subscribed correctly (student/admin)

---

## 📞 Need Help?

Check the main setup guide: `PUSH_NOTIFICATIONS_SETUP.md`

**Common Questions:**

**Q: Do I need a backend for notifications to work?**
A: For production yes, but for testing you can use Firebase Console or cURL.

**Q: Why aren't notifications appearing immediately?**
A: Because the app queues them in Firestore. You need to set up Cloud Functions or a backend to actually send them.

**Q: Can I test without a real device?**
A: Emulators work, but physical devices are better for testing notifications.

---

## 🎉 Next Steps

1. ✅ Complete all test scenarios
2. 🔧 Set up Cloud Functions (see main guide)
3. 🚀 Deploy to production
4. 📱 Test on real devices

**Happy Testing!** 🎊
