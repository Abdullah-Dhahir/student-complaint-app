# 🔔 Push Notification Backend Service

This service listens to the Firestore `notifications` collection and automatically sends push notifications via Firebase Cloud Messaging (FCM).

## 🚀 Features

- Real-time listening for new notification requests
- Automatic retry for failed notifications
- Error logging to Firestore
- Graceful shutdown handling
- Batch processing of pending notifications
- Rate limiting protection

## 📋 Prerequisites

- Node.js 14 or higher
- Firebase Admin SDK service account key
- Firebase project with Cloud Messaging enabled

## 🛠️ Setup

### Step 1: Get Firebase Service Account Key

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project: `student-complaint-app-36d8e`
3. Click **⚙️ Settings** (gear icon) → **Project Settings**
4. Go to **Service Accounts** tab
5. Click **Generate New Private Key**
6. Save the downloaded JSON file as `serviceAccountKey.json` in this directory

**⚠️ IMPORTANT**: Never commit `serviceAccountKey.json` to version control!

### Step 2: Install Dependencies

```bash
cd notification_backend
npm install
```

### Step 3: Configure Environment (Optional)

Create a `.env` file if you want to customize settings:

```bash
cp .env.example .env
```

Edit `.env`:
```
SERVICE_ACCOUNT_PATH=./serviceAccountKey.json
```

### Step 4: Run the Service

**Development mode** (auto-restart on file changes):
```bash
npm run dev
```

**Production mode**:
```bash
npm start
```

## 📊 How It Works

### Flow Diagram

```
┌─────────────────────────────────────────────────────────────┐
│  1. Admin updates complaint in Flutter app                  │
└─────────────────────┬───────────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────────┐
│  2. Firestore notification document created                 │
│     Collection: notifications                                │
│     {                                                        │
│       token: "user-fcm-token",                              │
│       title: "Complaint Update",                            │
│       body: "Status changed to In Progress",                │
│       sent: false                                            │
│     }                                                        │
└─────────────────────┬───────────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────────┐
│  3. This service detects new document                       │
│     (Real-time listener triggers)                           │
└─────────────────────┬───────────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────────┐
│  4. Service sends notification via FCM Admin SDK            │
│     admin.messaging().send(message)                         │
└─────────────────────┬───────────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────────┐
│  5. Update Firestore document                               │
│     {                                                        │
│       sent: true,                                            │
│       sentAt: timestamp,                                     │
│       messageId: "fcm-message-id"                           │
│     }                                                        │
└─────────────────────────────────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────────┐
│  6. Student receives notification on device                 │
└─────────────────────────────────────────────────────────────┘
```

### Key Features

1. **Real-time Processing**: Uses Firestore snapshots to instantly detect new notifications
2. **Pending Queue Processing**: On startup, processes any notifications that failed previously
3. **Error Handling**: Logs errors to Firestore for debugging
4. **Rate Limiting**: Adds 100ms delay between notifications to avoid FCM rate limits
5. **Graceful Shutdown**: Handles Ctrl+C properly, closing listeners before exit

## 🧪 Testing

### Test 1: Manual Test via Flutter App

1. Start this service:
   ```bash
   npm start
   ```

2. In your Flutter app:
   - Login as admin
   - Update a complaint status
   - Watch this service console for logs

**Expected output:**
```
🔔 New notification(s) detected! Processing...
📤 Sending notification abc123...
   Title: Complaint Update: CMP-2026-001
   Body: Status changed to In Progress
✅ Notification sent successfully: projects/.../messages/xyz
```

### Test 2: Manual Firestore Document

Create a test notification directly in Firestore:

```javascript
{
  "token": "your-fcm-token-here",
  "title": "Test Notification",
  "body": "This is a test message",
  "data": {
    "complaintId": "test123",
    "type": "complaint_update"
  },
  "createdAt": Firebase.firestore.Timestamp.now(),
  "sent": false
}
```

The service should automatically detect and send it.

## 📁 Project Structure

```
notification_backend/
├── index.js              # Main notification sender service
├── package.json          # Node.js dependencies
├── .env.example          # Environment variables template
├── .env                  # Your environment config (gitignored)
├── serviceAccountKey.json # Firebase Admin SDK key (gitignored)
└── README.md             # This file
```

## 🐛 Troubleshooting

### Issue: "Cannot find module './serviceAccountKey.json'"

**Solution**:
1. Make sure you downloaded the service account key from Firebase Console
2. Rename it to `serviceAccountKey.json`
3. Place it in the `notification_backend` directory

### Issue: "FCM send error: Requested entity was not found"

**Solution**: The FCM token is invalid or expired. This happens when:
- User uninstalled the app
- User cleared app data
- Token expired (tokens can expire after ~2 months)

The service will log this error to Firestore. The app should refresh tokens periodically.

### Issue: No notifications being sent

**Checklist**:
- [ ] Service is running (`npm start`)
- [ ] Service account key is valid
- [ ] Firestore has documents in `notifications` collection with `sent: false`
- [ ] User has valid FCM token in Firestore `users` collection
- [ ] FCM is enabled in Firebase Console
- [ ] No errors in console logs

## 🔐 Security Best Practices

1. **Never commit service account key** to Git
   - Already added to `.gitignore`
   - Use environment variables in production

2. **Restrict service account permissions**
   - Only grant necessary permissions (Firestore read/write, FCM send)

3. **Validate notification data**
   - Service validates required fields before sending

4. **Rate limiting**
   - Service adds delays between notifications
   - FCM has a limit of ~500,000 messages per project per day

5. **Monitor for abuse**
   - Check Firestore for excessive notification creation
   - Implement rate limits in Flutter app

## 🚀 Deployment Options

### Option 1: Run Locally (Development)

```bash
npm start
# Keep terminal open
```

**Pros**: Simple, free
**Cons**: Must keep computer running

### Option 2: Deploy to Cloud Server (Production)

#### Heroku:

```bash
# Install Heroku CLI
heroku login
heroku create student-complaint-notifier

# Set config vars
heroku config:set SERVICE_ACCOUNT_PATH=./serviceAccountKey.json

# Deploy
git add notification_backend
git commit -m "Add notification backend"
git push heroku main
```

#### DigitalOcean App Platform:

1. Create new app
2. Connect GitHub repo
3. Select `notification_backend` directory
4. Upload service account key as secret
5. Deploy

#### Google Cloud Run:

```bash
# Create Dockerfile
# Build and deploy
gcloud run deploy notification-service \
  --source . \
  --region us-central1 \
  --allow-unauthenticated
```

### Option 3: Firebase Cloud Functions (Recommended for Firebase projects)

If you can upgrade Node.js to 20+:

```bash
firebase init functions
firebase deploy --only functions
```

See [CLOUD_FUNCTIONS_ALTERNATIVE.md](./CLOUD_FUNCTIONS_ALTERNATIVE.md) for details.

## 📊 Monitoring

### Console Logs

The service outputs detailed logs:

```
✅ Service is running. Press Ctrl+C to stop.

🔔 New notification(s) detected! Processing...
📤 Sending notification abc123...
   Title: Complaint Update: CMP-2026-001
   Body: Status changed to In Progress
✅ Notification sent successfully: projects/.../messages/xyz
```

### Firestore Monitoring

Check the `notifications` collection for:
- `sent: true` = Successfully sent
- `error` field = Failed notifications
- `sentAt` timestamp = When notification was sent

### Firebase Console

Go to **Cloud Messaging** → **Reports** to see delivery statistics.

## 🎯 Production Checklist

- [ ] Service account key secured (not in Git)
- [ ] Service running 24/7 (use PM2 or cloud hosting)
- [ ] Error alerting set up (email/Slack on failures)
- [ ] Monitoring dashboard (Firebase Console + custom logs)
- [ ] Backup strategy (multiple service instances)
- [ ] Rate limiting implemented
- [ ] Notification retry logic (already included)
- [ ] Graceful shutdown handling (already included)

## 📚 Additional Resources

- [Firebase Admin SDK Documentation](https://firebase.google.com/docs/admin/setup)
- [FCM Architecture Best Practices](https://firebase.google.com/docs/cloud-messaging/concept-options)
- [Node.js Production Best Practices](https://github.com/goldbergyoni/nodebestpractices)

## 🆘 Support

For issues specific to this service, check:

1. Console logs for error messages
2. Firestore `notifications` collection for failed notifications
3. Firebase Console → Cloud Messaging for FCM errors
4. [Firebase Support](https://firebase.google.com/support)

---

**Happy Notifying!** 🎉
