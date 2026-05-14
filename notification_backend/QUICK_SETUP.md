# ⚡ Quick Setup Guide (5 Minutes)

Get push notifications working in 5 simple steps!

## Step 1: Get Firebase Service Account Key (2 minutes)

1. Open [Firebase Console](https://console.firebase.google.com/)
2. Select project: **student-complaint-app-36d8e**
3. Click **⚙️** (Settings) → **Project Settings**
4. Click **Service Accounts** tab
5. Click **Generate New Private Key** button
6. Click **Generate Key** in the popup
7. Save the downloaded JSON file as `serviceAccountKey.json` in this folder

**Your folder should now have:**
```
notification_backend/
├── serviceAccountKey.json  ← Just downloaded!
├── index.js
├── package.json
└── ...
```

## Step 2: Install Dependencies (1 minute)

Open terminal in this directory and run:

```bash
npm install
```

Wait for packages to install...

## Step 3: Start the Service (30 seconds)

```bash
npm start
```

**Expected output:**
```
═══════════════════════════════════════════════════════
🚀 Push Notification Sender Service
═══════════════════════════════════════════════════════

✅ Firebase Admin SDK initialized
🔍 Checking for pending notifications...
   No pending notifications found.
👂 Starting real-time listener for new notifications...

✅ Service is running. Press Ctrl+C to stop.
```

## Step 4: Test with Flutter App (1 minute)

Keep the service running, then:

1. Open your Flutter app
2. Login as admin
3. Go to any complaint
4. Update its status (e.g., from "Pending" to "In Progress")

**Watch the service console** - you should see:

```
🔔 New notification(s) detected! Processing...
📤 Sending notification abc123...
   Title: Complaint Update: CMP-2026-001
   Body: Status changed to In Progress
✅ Notification sent successfully!
```

## Step 5: Check Student's Device (30 seconds)

On the student's device, you should see a notification appear! 🎉

---

## 🎯 That's It!

Your push notifications are now working!

### What Happens Behind the Scenes:

```
Admin updates complaint
    ↓
Firestore creates notification document
    ↓
This service detects it (real-time)
    ↓
Sends notification via FCM
    ↓
Student receives notification 🔔
```

---

## 🐛 Troubleshooting

### "Cannot find module './serviceAccountKey.json'"

**Fix**: Make sure you downloaded the key and saved it as `serviceAccountKey.json` in this folder.

### No notification received on student device

**Checklist**:
- [ ] Is the service running? (Check terminal)
- [ ] Did admin actually update the complaint?
- [ ] Is student logged in to the app?
- [ ] Does student have notification permissions enabled?
- [ ] Is student's FCM token saved in Firestore? (Check Firebase Console → Firestore → users collection)

### "Permission denied" errors

**Fix**: Make sure you used the correct service account key for your Firebase project.

---

## 🚀 Next Steps

For production deployment, see [README.md](./README.md) for hosting options:
- Heroku (free tier available)
- DigitalOcean
- Google Cloud Run
- Your own server

---

**Need more help?** See the detailed [README.md](./README.md)
