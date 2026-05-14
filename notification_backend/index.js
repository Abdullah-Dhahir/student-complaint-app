const admin = require('firebase-admin');
const express = require('express');
const nodemailer = require('nodemailer');
const path = require('path');
require('dotenv').config();

// ─── Firebase Setup ───────────────────────────────────────────────────────────
const serviceAccount = require(path.resolve('./serviceAccountKey.json'));

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();
const messaging = admin.messaging();
console.log('✅ Firebase initialized');

// ─── Email Setup ──────────────────────────────────────────────────────────────
// Uses Gmail to send OTP codes to users
const emailTransporter = nodemailer.createTransport({
  service: 'gmail',
  auth: {
    user: process.env.EMAIL_USER,
    pass: process.env.EMAIL_PASS,
  },
});

// ─── Express HTTP Server ──────────────────────────────────────────────────────
const app = express();
app.use(express.json());

// ─── POST /send-otp ───────────────────────────────────────────────────────────
// Flutter calls this when user enters their email on the login screen.
// It generates a 6-digit code, saves it to Firestore, and emails it to the user.
app.post('/send-otp', async (req, res) => {
  try {
    const { email } = req.body;
    if (!email) return res.status(400).json({ error: 'Email is required' });

    // Only allow university email addresses
    if (!email.endsWith('@std.tiu.edu.iq') && !email.endsWith('@tiu.edu.iq')) {
      return res.status(400).json({ error: 'Only university emails (@std.tiu.edu.iq or @tiu.edu.iq) are allowed' });
    }

    // Generate a random 6-digit code
    const otp = Math.floor(100000 + Math.random() * 900000).toString();
    const expiresAt = Date.now() + 10 * 60 * 1000; // expires in 10 minutes

    // Save OTP to Firestore (overwrites any previous code for this email)
    await db.collection('otps').doc(email).set({
      otp: otp,
      expiresAt: expiresAt,
      used: false,
    });

    // Send the code to the user's email
    await emailTransporter.sendMail({
      from: process.env.EMAIL_USER,
      to: email,
      subject: 'Your Login Verification Code',
      text: `Your verification code is: ${otp}\n\nThis code expires in 10 minutes.`,
    });

    console.log(`✅ OTP sent to ${email}`);
    res.json({ message: 'Verification code sent to your email' });

  } catch (error) {
    console.error('❌ Error in /send-otp:', error.message);
    res.status(500).json({ error: 'Failed to send code. Please try again.' });
  }
});

// ─── POST /verify-otp ────────────────────────────────────────────────────────
// Flutter calls this when user submits the 6-digit code.
// If correct, it returns a Firebase custom token so the app can log the user in.
app.post('/verify-otp', async (req, res) => {
  try {
    const { email, otp } = req.body;
    if (!email || !otp) return res.status(400).json({ error: 'Email and code are required' });

    // Get the saved OTP from Firestore
    const otpDoc = await db.collection('otps').doc(email).get();
    if (!otpDoc.exists) {
      return res.status(400).json({ error: 'No code found. Please request a new one.' });
    }

    const otpData = otpDoc.data();

    // Validate the code
    if (otpData.used) {
      return res.status(400).json({ error: 'Code already used. Please request a new one.' });
    }
    if (Date.now() > otpData.expiresAt) {
      return res.status(400).json({ error: 'Code expired. Please request a new one.' });
    }
    if (otpData.otp !== otp) {
      return res.status(400).json({ error: 'Incorrect code. Please try again.' });
    }

    // Mark code as used so it cannot be used again
    await db.collection('otps').doc(email).update({ used: true });

    // Get the user's Firebase UID — create them if they don't exist yet
    let userRecord;
    try {
      userRecord = await admin.auth().getUserByEmail(email);
    } catch (e) {
      // First time logging in — create a Firebase Auth account for them
      userRecord = await admin.auth().createUser({ email: email });
    }

    // Create a custom token — Flutter will use this to sign in via Firebase Auth
    const customToken = await admin.auth().createCustomToken(userRecord.uid);

    console.log(`✅ OTP verified for ${email}`);
    res.json({ token: customToken });

  } catch (error) {
    console.error('❌ Error in /verify-otp:', error.message);
    res.status(500).json({ error: 'Verification failed. Please try again.' });
  }
});

// ─── Push Notification Listener ───────────────────────────────────────────────
// Watches Firestore 'notifications' collection and sends FCM push notifications.
// This runs alongside the HTTP server.
db.collection('notifications')
  .where('sent', '==', false)
  .onSnapshot(async (snapshot) => {
    for (const doc of snapshot.docs) {
      const n = doc.data();
      if (!n.token) continue;

      try {
        const response = await messaging.send({
          notification: { title: n.title || 'Notification', body: n.body || '' },
          data: n.data || {},
          token: n.token,
          android: {
            notification: { channelId: 'complaint_updates', priority: 'high' },
          },
        });

        await doc.ref.update({
          sent: true,
          sentAt: admin.firestore.FieldValue.serverTimestamp(),
          messageId: response,
        });

        console.log('✅ Push notification sent');
      } catch (error) {
        await doc.ref.update({ error: error.message });
        console.error('❌ Failed to send notification:', error.message);
      }
    }
  });

// ─── Start Server ─────────────────────────────────────────────────────────────
app.listen(3000, () => {
  console.log('🚀 Server running on http://localhost:3000');
  console.log('📧 OTP endpoints: POST /send-otp  |  POST /verify-otp');
});
