import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Handle background messages - must be top-level function
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('🔔 Background message: ${message.messageId}');
  print('📌 Title: ${message.notification?.title}');
  print('📝 Body: ${message.notification?.body}');
  print('📦 Data: ${message.data}');
}

class MessagingService {
  static final MessagingService _instance = MessagingService._internal();
  factory MessagingService() => _instance;
  MessagingService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  /// Initialize Firebase Cloud Messaging and Local Notifications
  Future<void> initialize() async {
    if (_initialized) {
      print('⚠️ MessagingService already initialized');
      return;
    }

    try {
      print('🚀 Initializing Firebase Messaging...');

      // Initialize local notifications for Android
      await _initializeLocalNotifications();

      // Request permission (especially important for iOS)
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
        announcement: false,
        carPlay: false,
        criticalAlert: false,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        print('✅ User granted notification permission');
      } else if (settings.authorizationStatus ==
          AuthorizationStatus.provisional) {
        print('⚠️ User granted provisional permission');
      } else {
        print('❌ User declined notification permission');
        return;
      }

      // Get FCM token
      final token = await _messaging.getToken();
      if (token != null) {
        print('🔑 FCM Token: $token');
      }

      // Listen for token refresh
      _messaging.onTokenRefresh.listen((newToken) {
        print('🔄 FCM Token refreshed: $newToken');
      });

      // Configure foreground notification presentation (iOS)
      await _messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Handle notification taps when app is in background
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

      // Handle notification tap when app was terminated
      final initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        print('📲 App opened from notification (terminated state)');
        _handleNotificationTap(initialMessage);
      }

      _initialized = true;
      print('✅ Firebase Messaging initialized successfully');
    } catch (e) {
      print('❌ Error initializing Firebase Messaging: $e');
      rethrow;
    }
  }

  /// Initialize local notifications for Android
  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create notification channel for Android
    const androidChannel = AndroidNotificationChannel(
      'complaint_updates', // id
      'Complaint Updates', // name
      description: 'Notifications for complaint status updates',
      importance: Importance.high,
      playSound: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);

    print('✅ Local notifications initialized');
  }

  /// Handle when local notification is tapped
  void _onNotificationTapped(NotificationResponse response) {
    print('📲 Local notification tapped: ${response.payload}');
    // TODO: Navigate to complaint detail screen
    // You can parse the payload to get complaint ID
  }

  /// Save FCM token to Firestore for the user
  Future<void> saveTokenToDatabase(String userId) async {
    try {
      final token = await _messaging.getToken();
      if (token != null) {
        await _firestore.collection('users').doc(userId).update({
          'fcmToken': token,
          'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
        });
        print('✅ FCM token saved to database for user: $userId');
      }
    } catch (e) {
      print('❌ Error saving FCM token: $e');
    }
  }

  /// Remove FCM token when user logs out
  Future<void> removeTokenFromDatabase(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'fcmToken': FieldValue.delete(),
        'fcmTokenUpdatedAt': FieldValue.delete(),
      });
      print('✅ FCM token removed from database');
    } catch (e) {
      print('❌ Error removing FCM token: $e');
    }
  }

  /// Handle foreground messages (when app is open)
  void _handleForegroundMessage(RemoteMessage message) {
    print('🔔 Foreground message received: ${message.messageId}');
    print('📌 Title: ${message.notification?.title}');
    print('📝 Body: ${message.notification?.body}');
    print('📦 Data: ${message.data}');

    // Show local notification when app is in foreground
    _showLocalNotification(message);
  }

  /// Show local notification
  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    const androidDetails = AndroidNotificationDetails(
      'complaint_updates',
      'Complaint Updates',
      channelDescription: 'Notifications for complaint status updates',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      details,
      payload: message.data['complaintId'], // Pass complaint ID as payload
    );
  }

  /// Handle notification tap (when app is in background/terminated)
  void _handleNotificationTap(RemoteMessage message) {
    print('📲 Notification tapped: ${message.messageId}');
    print('📦 Data: ${message.data}');

    final complaintId = message.data['complaintId'];
    if (complaintId != null) {
      print('📍 Navigate to complaint: $complaintId');
      // TODO: Implement navigation to complaint detail screen
      // You can use a navigation service or global key
    }
  }

  /// Subscribe to a topic (e.g., "admin_notifications")
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _messaging.subscribeToTopic(topic);
      print('✅ Subscribed to topic: $topic');
    } catch (e) {
      print('❌ Error subscribing to topic: $e');
    }
  }

  /// Unsubscribe from a topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _messaging.unsubscribeFromTopic(topic);
      print('✅ Unsubscribed from topic: $topic');
    } catch (e) {
      print('❌ Error unsubscribing from topic: $e');
    }
  }

  /// Get current FCM token
  Future<String?> getToken() async {
    try {
      return await _messaging.getToken();
    } catch (e) {
      print('❌ Error getting FCM token: $e');
      return null;
    }
  }

  /// Delete FCM token (for logout)
  Future<void> deleteToken() async {
    try {
      await _messaging.deleteToken();
      print('✅ FCM token deleted');
    } catch (e) {
      print('❌ Error deleting FCM token: $e');
    }
  }

  /// Check notification permissions
  Future<bool> hasPermission() async {
    try {
      final settings = await _messaging.getNotificationSettings();
      return settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;
    } catch (e) {
      print('❌ Error checking notification permission: $e');
      return false;
    }
  }

  /// Request notification permissions
  Future<bool> requestPermission() async {
    try {
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      return settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;
    } catch (e) {
      print('❌ Error requesting notification permission: $e');
      return false;
    }
  }

  /// Send notification when complaint status changes
  /// This would typically be done from backend/cloud function
  /// For demo purposes, we can trigger notifications via Firestore
  Future<void> sendComplaintUpdateNotification({
    required String studentId,
    required String complaintId,
    required String title,
    required String body,
  }) async {
    try {
      // Get student's FCM token from Firestore
      final userDoc = await _firestore.collection('users').doc(studentId).get();
      final fcmToken = userDoc.data()?['fcmToken'] as String?;

      if (fcmToken == null) {
        print('⚠️ No FCM token found for user: $studentId');
        return;
      }

      // Create notification document in Firestore
      // Cloud function or backend will read this and send via FCM Admin SDK
      await _firestore.collection('notifications').add({
        'token': fcmToken,
        'title': title,
        'body': body,
        'data': {
          'complaintId': complaintId,
          'type': 'complaint_update',
        },
        'createdAt': FieldValue.serverTimestamp(),
        'sent': false,
      });

      print('✅ Notification queued for sending');
    } catch (e) {
      print('❌ Error queuing notification: $e');
    }
  }
}
