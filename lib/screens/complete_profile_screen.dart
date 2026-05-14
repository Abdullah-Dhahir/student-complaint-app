import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/helpers.dart';
import '../utils/app_theme.dart';
import '../models/user.dart' as app_models;
import '../services/firebase/firebase_auth_service.dart';
import '../services/firebase/messaging_service.dart';
import 'student_home_screen.dart';

class CompleteProfileScreen extends StatefulWidget {
  final String email;

  const CompleteProfileScreen({super.key, required this.email});

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLoading = false;

  final _authService = FirebaseAuthService();
  final _messagingService = MessagingService();

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _createProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;

      // Set a password so the user can log in with email+password next time
      await FirebaseAuth.instance.currentUser!.updatePassword(
        _passwordController.text,
      );

      // All self-registered users (both domains) get student role
      // Admin accounts are created manually
      await _authService.createUserProfile(
        uid: uid,
        email: widget.email,
        name: _nameController.text.trim(),
        username: _usernameController.text.trim(),
        role: 'student',
      );

      // Save FCM token for push notifications
      try {
        await _messagingService.saveTokenToDatabase(uid);
        await _messagingService.subscribeToTopic('student_notifications');
      } catch (_) {}

      setState(() => _isLoading = false);

      if (mounted) {
        final user = app_models.User(
          id: uid,
          username: _usernameController.text.trim(),
          name: _nameController.text.trim(),
          email: widget.email,
          role: app_models.UserRole.student,
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => StudentHomeScreen(user: user)),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) Helpers.showSnackBar(context, e.toString(), isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(40),
                child: Column(
                  children: [
                    Icon(Icons.person_add, size: 80, color: AppTheme.accentColor),
                    const SizedBox(height: 16),
                    const Text(
                      'Complete Your Profile',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.email,
                      style: const TextStyle(fontSize: 14, color: Colors.white70),
                    ),
                  ],
                ),
              ),

              // Form
              Container(
                decoration: const BoxDecoration(
                  color: AppTheme.backgroundColor,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 16),
                        const Text(
                          'Set up your account',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'This information will be used to identify you',
                          style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
                        ),
                        const SizedBox(height: 32),

                        // Full Name
                        TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'Full Name',
                            hintText: 'Enter your full name',
                            prefixIcon: Icon(Icons.person_outline),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter your full name';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Username
                        TextFormField(
                          controller: _usernameController,
                          decoration: const InputDecoration(
                            labelText: 'Username',
                            hintText: 'Choose a username',
                            prefixIcon: Icon(Icons.alternate_email),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter a username';
                            }
                            if (value.trim().length < 3) {
                              return 'Username must be at least 3 characters';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Password
                        TextFormField(
                          controller: _passwordController,
                          obscureText: !_isPasswordVisible,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            hintText: 'Create a password',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              icon: Icon(_isPasswordVisible
                                  ? Icons.visibility_off
                                  : Icons.visibility),
                              onPressed: () => setState(
                                  () => _isPasswordVisible = !_isPasswordVisible),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please create a password';
                            }
                            if (value.length < 6) {
                              return 'Password must be at least 6 characters';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 32),

                        // Submit button
                        ElevatedButton(
                          onPressed: _isLoading ? null : _createProfile,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : const Text(
                                  'Create Account',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
