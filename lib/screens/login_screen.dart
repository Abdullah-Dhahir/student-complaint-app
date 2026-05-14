import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../utils/helpers.dart';
import '../utils/app_theme.dart';
import 'complete_profile_screen.dart';
import 'student_home_screen.dart';
import 'admin_home_screen.dart';
import '../models/user.dart';
import '../services/firebase/firebase_auth_service.dart';
import '../services/firebase/messaging_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _otpController = TextEditingController();

  // 'login' → email + password (returning users)
  // 'otp'   → OTP sent to email (first-time users)
  String _mode = 'login';

  bool _isLoading = false;
  bool _isPasswordVisible = false;

  // For Android emulator use 10.0.2.2 — for physical device use your computer's local IP
  static const String _backendUrl = 'http://10.0.2.2:3000';

  final _authService = FirebaseAuthService();
  final _messagingService = MessagingService();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  // ── Returning user: login with email + password ───────────────────────────
  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = await _authService.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (user == null) throw 'Login failed. Please try again.';

      try {
        await _messagingService.saveTokenToDatabase(user.id);
        await _messagingService.subscribeToTopic(
          user.role == UserRole.admin ? 'admin_notifications' : 'student_notifications',
        );
      } catch (_) {}

      setState(() => _isLoading = false);

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => user.role == UserRole.student
                ? StudentHomeScreen(user: user)
                : AdminHomeScreen(user: user),
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) Helpers.showSnackBar(context, e.toString(), isError: true);
    }
  }

  // ── New user step 1: send OTP to their uni email ──────────────────────────
  Future<void> _sendOtp() async {
    final email = _emailController.text.trim();

    final isValidDomain = email.endsWith('@std.tiu.edu.iq') || email.endsWith('@tiu.edu.iq');
    if (email.isEmpty || !isValidDomain) {
      Helpers.showSnackBar(
        context,
        'Please enter a university email (@std.tiu.edu.iq or @tiu.edu.iq)',
        isError: true,
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('$_backendUrl/send-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        setState(() { _mode = 'otp'; _isLoading = false; });
        if (mounted) Helpers.showSnackBar(context, 'Code sent to $email');
      } else {
        setState(() => _isLoading = false);
        if (mounted) {
          Helpers.showSnackBar(context, data['error'] ?? 'Failed to send code', isError: true);
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        Helpers.showSnackBar(
          context,
          'Cannot connect to server. Make sure the backend is running.',
          isError: true,
        );
      }
    }
  }

  // ── New user step 2: verify OTP → go to complete profile ─────────────────
  Future<void> _verifyOtp() async {
    final otp = _otpController.text.trim();

    if (otp.length != 6) {
      Helpers.showSnackBar(context, 'Please enter the 6-digit code', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('$_backendUrl/verify-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': _emailController.text.trim(),
          'otp': otp,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode != 200) {
        setState(() => _isLoading = false);
        if (mounted) {
          Helpers.showSnackBar(context, data['error'] ?? 'Invalid code', isError: true);
        }
        return;
      }

      // Sign in with the custom token from backend
      final customToken = data['token'] as String;
      await FirebaseAuth.instance.signInWithCustomToken(customToken);

      setState(() => _isLoading = false);

      // Email verified — go to complete profile (name + password setup)
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => CompleteProfileScreen(
              email: _emailController.text.trim(),
            ),
          ),
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
                    Icon(Icons.school, size: 80, color: AppTheme.accentColor),
                    const SizedBox(height: 16),
                    const Text(
                      'University Portal',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Student Complaint System',
                      style: TextStyle(fontSize: 16, color: Colors.white70),
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
                        Text(
                          _mode == 'otp' ? 'Verify Your Email' : 'Login',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _mode == 'otp'
                              ? 'Enter the 6-digit code sent to ${_emailController.text.trim()}'
                              : 'Sign in to your account',
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 32),

                        // ── Login mode (email + password) ──────────────────
                        if (_mode == 'login') ...[
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                              labelText: 'Email',
                              hintText: 'Enter your email',
                              prefixIcon: Icon(Icons.email_outlined),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter your email';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: !_isPasswordVisible,
                            decoration: InputDecoration(
                              labelText: 'Password',
                              hintText: 'Enter your password',
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
                                return 'Please enter your password';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: _isLoading ? null : _login,
                            child: _buildButtonChild('Login'),
                          ),
                          const SizedBox(height: 24),
                          const Divider(),
                          const SizedBox(height: 16),
                          // First-time users use OTP to register
                          Center(
                            child: Column(
                              children: [
                                const Text(
                                  'First time here?',
                                  style: TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                TextButton.icon(
                                  onPressed: () {
                                    setState(() {
                                      _mode = 'otp';
                                      _passwordController.clear();
                                    });
                                  },
                                  icon: const Icon(Icons.email_outlined, size: 16),
                                  label: const Text(
                                    'Verify your university email',
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        // ── OTP mode (new user email verification) ─────────
                        if (_mode == 'otp') ...[
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                              labelText: 'University Email',
                              hintText: '150722016@std.tiu.edu.iq',
                              prefixIcon: Icon(Icons.email_outlined),
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _isLoading ? null : _sendOtp,
                            child: _buildButtonChild('Send Verification Code'),
                          ),
                          const SizedBox(height: 24),
                          const Divider(),
                          const SizedBox(height: 8),
                          // OTP code field (shown after code is sent)
                          TextFormField(
                            controller: _otpController,
                            keyboardType: TextInputType.number,
                            maxLength: 6,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 28, letterSpacing: 10),
                            decoration: const InputDecoration(
                              labelText: 'Enter Code',
                              hintText: '000000',
                              counterText: '',
                              prefixIcon: Icon(Icons.lock_outline),
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _isLoading ? null : _verifyOtp,
                            child: _buildButtonChild('Verify & Continue'),
                          ),
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: _isLoading
                                ? null
                                : () => setState(() {
                                      _mode = 'login';
                                      _otpController.clear();
                                    }),
                            child: const Text('← Back to Login'),
                          ),
                        ],

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

  Widget _buildButtonChild(String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: _isLoading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : Text(
              label,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
    );
  }
}
