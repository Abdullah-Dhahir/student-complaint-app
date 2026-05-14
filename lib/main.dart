import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';
import 'utils/app_theme.dart';
import 'screens/login_screen.dart';
import 'services/firebase/messaging_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Initialize Firebase with platform-specific options
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('✅ Firebase initialized successfully');

    // Set up background message handler for FCM
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    print('✅ Background message handler registered');

    // Initialize messaging service
    try {
      await MessagingService().initialize();
      print('✅ Messaging service initialized');
    } catch (e) {
      print('⚠️ Warning: Messaging service failed to initialize: $e');
      // Continue anyway - app can work without notifications
    }

    runApp(const MyApp());
  } catch (e) {
    print('❌ Error initializing Firebase: $e');
    // Run app without Firebase if initialization fails
    runApp(const MyApp());
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TIU Complaint System',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const LoginScreen(),
    );
  }
}
