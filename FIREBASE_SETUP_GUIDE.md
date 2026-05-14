# Firebase Setup Guide for Student Complaint App

## ⚠️ IMPORTANT: You must complete this setup before the app will work with Firebase

---

## Step 1: Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Add project"
3. Enter project name: `student-complaint-app`
4. Disable Google Analytics (optional for this project)
5. Click "Create project"

---

## Step 2: Register Your Apps

### For iOS:

1. In Firebase Console, click the iOS icon
2. Enter iOS bundle ID: `com.example.studentComplaintApp`
3. Download `GoogleService-Info.plist`
4. **Place it here:** `/ios/Runner/GoogleService-Info.plist`
5. Skip all other steps (already configured)

### For Android:

1. In Firebase Console, click the Android icon
2. Enter Android package name: `com.example.student_complaint_app`
3. Download `google-services.json`
4. **Place it here:** `/android/app/google-services.json`
5. Skip all other steps (already configured)

### For macOS:

1. In Firebase Console, click the Apple icon (if you haven't added iOS yet)
2. Add macOS bundle ID: `com.example.studentComplaintApp`
3. Download `GoogleService-Info.plist` for macOS
4. **Place it here:** `/macos/Runner/GoogleService-Info.plist`

---

## Step 3: Enable Firebase Authentication

1. In Firebase Console, go to **Build → Authentication**
2. Click "Get started"
3. Click "Sign-in method" tab
4. Enable **Email/Password**
   - Toggle "Email/Password" to enabled
   - Do NOT enable "Email link (passwordless sign-in)" yet
   - Click "Save"

---

## Step 4: Create Firestore Database

1. In Firebase Console, go to **Build → Firestore Database**
2. Click "Create database"
3. Select **Start in test mode** (for development)
   ```
   rules_version = '2';
   service cloud.firestore {
     match /databases/{database}/documents {
       match /{document=**} {
         allow read, write: if request.time < timestamp.date(2025, 12, 31);
       }
     }
   }
   ```
4. Choose location: `us-central1` (or closest to you)
5. Click "Enable"

### Production-Ready Firestore Rules (Update later):

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users collection
    match /users/{userId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.uid == userId;
    }

    // Complaints collection
    match /complaints/{complaintId} {
      // Anyone authenticated can read
      allow read: if request.auth != null;

      // Students can create their own complaints
      allow create: if request.auth != null &&
                       request.resource.data.studentId == request.auth.uid;

      // Students can only update their own complaints (limited fields)
      allow update: if request.auth != null &&
                       resource.data.studentId == request.auth.uid &&
                       !request.resource.data.diff(resource.data).affectedKeys()
                         .hasAny(['status', 'adminResponse', 'responseDate']);

      // Admins can update any complaint
      allow update: if request.auth != null &&
                       get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';

      // Only admins can delete
      allow delete: if request.auth != null &&
                       get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
    }
  }
}
```

---

## Step 5: Set Up Firebase Storage

1. In Firebase Console, go to **Build → Storage**
2. Click "Get started"
3. Start in **test mode**:
   ```
   rules_version = '2';
   service firebase.storage {
     match /b/{bucket}/o {
       match /{allPaths=**} {
         allow read, write: if request.time < timestamp.date(2025, 12, 31);
       }
     }
   }
   ```
4. Choose same location as Firestore
5. Click "Done"

### Production-Ready Storage Rules (Update later):

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    // Complaint images
    match /complaints/{complaintId}/{fileName} {
      // Anyone authenticated can read
      allow read: if request.auth != null;

      // Only authenticated users can upload
      allow write: if request.auth != null &&
                      request.resource.size < 5 * 1024 * 1024 && // 5MB max
                      request.resource.contentType.matches('image/.*');
    }

    // Profile pictures
    match /profiles/{userId}/{fileName} {
      allow read: if request.auth != null;
      allow write: if request.auth != null &&
                      request.auth.uid == userId &&
                      request.resource.size < 2 * 1024 * 1024; // 2MB max
    }
  }
}
```

---

## Step 6: Enable Firebase Cloud Messaging (FCM)

### For Android:

1. In Firebase Console, go to **Project Settings** (gear icon)
2. Go to **Cloud Messaging** tab
3. Make sure **Cloud Messaging API (Legacy)** is enabled
4. Copy the **Server Key** (you'll need this for sending notifications)

### For iOS:

1. You need an Apple Developer account (paid)
2. Create APNs authentication key in Apple Developer Console
3. Upload the key to Firebase Console → Project Settings → Cloud Messaging
4. Enter Key ID and Team ID

### For macOS:

Similar to iOS setup

---

## Step 7: Create Initial Admin User

After deploying your app, you'll need to manually create an admin user in Firestore:

1. Register a user through the app
2. Go to Firebase Console → Firestore Database
3. Find the user document in the `users` collection
4. Edit the document and add/change:
   ```json
   {
     "role": "admin"
   }
   ```

---

## Step 8: Android Configuration (Already Done)

The following has been configured in `/android/app/build.gradle`:

```gradle
apply plugin: 'com.google.gms.google-services'

dependencies {
    implementation platform('com.google.firebase:firebase-bom:32.7.0')
}
```

And in `/android/build.gradle`:

```gradle
dependencies {
    classpath 'com.google.gms:google-services:4.4.0'
}
```

**Just make sure you placed `google-services.json` in the correct location!**

---

## Step 9: iOS Configuration (Already Done)

Firebase is configured in the iOS project. Just make sure:
- `GoogleService-Info.plist` is in `/ios/Runner/`
- The bundle ID matches what you entered in Firebase Console

---

## Step 10: Test Your Setup

After placing the configuration files, run:

```bash
cd student_complaint_app
flutter clean
flutter pub get
flutter run
```

---

## Firestore Data Structure

### Collections:

#### 1. `users` Collection:
```json
{
  "userId": {
    "email": "student@university.edu",
    "name": "Ahmed Ali",
    "role": "student",  // or "admin"
    "createdAt": "2024-11-22T10:00:00Z",
    "username": "ahmed123"
  }
}
```

#### 2. `complaints` Collection:
```json
{
  "complaintId": {
    "trackingNumber": "CMP-2024-001",
    "category": "Classroom Facilities",
    "description": "AC not working...",
    "imagePath": "complaints/abc123/image.jpg", // Firebase Storage path
    "imageUrl": "https://firebase.../image.jpg", // Download URL
    "status": "received", // or "inProgress" or "resolved"
    "studentId": "userId123",
    "studentName": "Ahmed Ali",
    "submittedDate": "2024-11-22T10:00:00Z",
    "adminResponse": "We're working on it...",
    "responseDate": "2024-11-22T15:00:00Z"
  }
}
```

---

## Testing Checklist

- [ ] Firebase project created
- [ ] iOS `GoogleService-Info.plist` added
- [ ] Android `google-services.json` added
- [ ] macOS `GoogleService-Info.plist` added
- [ ] Authentication enabled (Email/Password)
- [ ] Firestore database created (test mode)
- [ ] Firebase Storage created (test mode)
- [ ] Cloud Messaging enabled
- [ ] App builds without errors
- [ ] Can register new user
- [ ] Can login
- [ ] Can submit complaint
- [ ] Can upload image
- [ ] Admin can update complaint status
- [ ] Notifications work (after testing)

---

## Troubleshooting

### "No Firebase App has been created"
- Make sure configuration files are in the correct locations
- Run `flutter clean && flutter pub get`
- Rebuild the app completely

### "Firebase initialization failed"
- Check that bundle IDs match in Firebase Console
- Verify configuration files are not corrupted
- Check console for specific error messages

### "Permission denied" on Firestore
- Make sure you're in test mode OR
- Update security rules as shown above
- Verify user is authenticated

### Images not uploading
- Check Storage rules are in test mode
- Verify internet connection
- Check file size (< 5MB)
- Check file type (must be image)

---

## Security Note

**IMPORTANT:** The test mode rules expire after the date specified. Before going to production:

1. Update Firestore rules (see production rules above)
2. Update Storage rules (see production rules above)
3. Set up proper authentication checks
4. Add email verification requirement
5. Implement rate limiting

---

## Need Help?

If you encounter issues:
1. Check Firebase Console for error messages
2. Check Flutter console for detailed errors
3. Verify all configuration files are in place
4. Make sure bundle IDs match exactly
5. Try `flutter clean` and rebuild

---

**Once you complete these steps, the app will be fully functional with Firebase!** 🔥
