import 'package:flutter/material.dart';
import '../data/simple_seed.dart';
import '../utils/app_theme.dart';

/// Screen to seed test data into Firebase
/// This is a developer tool and should be removed in production
class SeedDataScreen extends StatefulWidget {
  const SeedDataScreen({super.key});

  @override
  State<SeedDataScreen> createState() => _SeedDataScreenState();
}

class _SeedDataScreenState extends State<SeedDataScreen> {
  bool _isSeeding = false;
  bool _isClearing = false;
  bool _isCreatingAdmin = false;
  String _statusMessage = '';
  final SimpleSeed _simpleSeed = SimpleSeed();
  final TextEditingController _adminEmailController = TextEditingController();

  Future<void> _seedDatabase() async {
    setState(() {
      _isSeeding = true;
      _statusMessage = 'Seeding database...';
    });

    try {
      await _simpleSeed.seedFirestoreData();
      setState(() {
        _statusMessage = '✅ Firestore data seeded successfully!\n\n'
            'NOTE: Make sure you already created the user account:\n\n'
            'Student Account:\n'
            'Email: student@test.com\n'
            'Password: 123456\n\n'
            '5 sample complaints created for the student.\n\n'
            'You can now login!';
      });
    } catch (e) {
      setState(() {
        _statusMessage = '❌ Error: $e\n\n'
            'Make sure the user account exists first.\n'
            'Go back and register with:\n'
            'Email: student@test.com\n'
            'Password: 123456';
      });
    } finally {
      setState(() {
        _isSeeding = false;
      });
    }
  }

  Future<void> _clearTestData() async {
    setState(() {
      _isClearing = true;
      _statusMessage = 'Clearing test data...';
    });

    try {
      await _simpleSeed.clearTestData();
      setState(() {
        _statusMessage = '✅ Test data cleared successfully!';
      });
    } catch (e) {
      setState(() {
        _statusMessage = '❌ Error: $e';
      });
    } finally {
      setState(() {
        _isClearing = false;
      });
    }
  }

  Future<void> _createAdminUser() async {
    final email = _adminEmailController.text.trim();
    if (email.isEmpty) {
      setState(() {
        _statusMessage = '❌ Please enter an email address';
      });
      return;
    }

    setState(() {
      _isCreatingAdmin = true;
      _statusMessage = 'Creating admin user...';
    });

    try {
      await _simpleSeed.createAdminUser(email);
      setState(() {
        _statusMessage = '✅ Admin user created successfully!\\n\\n'
            'You can now login as admin with:\\n'
            'Email: $email\\n\\n'
            'The user role has been updated to admin.';
      });
      _adminEmailController.clear();
    } catch (e) {
      setState(() {
        _statusMessage = '❌ Error: $e';
      });
    } finally {
      setState(() {
        _isCreatingAdmin = false;
      });
    }
  }

  @override
  void dispose() {
    _adminEmailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Database Seeding Tool'),
        backgroundColor: AppTheme.primaryColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(
              Icons.science_outlined,
              size: 80,
              color: AppTheme.primaryColor,
            ),
            const SizedBox(height: 16),
            const Text(
              'Test Data Seeding',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Use this tool to populate your database with test data',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 32),

            // Seed Database Button
            ElevatedButton.icon(
              onPressed: _isSeeding || _isClearing ? null : _seedDatabase,
              icon: _isSeeding
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.add_circle_outline),
              label: Text(_isSeeding ? 'Seeding...' : 'Seed Test Data'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 16),

            // Clear Test Data Button
            OutlinedButton.icon(
              onPressed: _isSeeding || _isClearing ? null : _clearTestData,
              icon: _isClearing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                      ),
                    )
                  : const Icon(Icons.delete_outline),
              label: Text(_isClearing ? 'Clearing...' : 'Clear Test Data'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: const BorderSide(color: Colors.red),
                foregroundColor: Colors.red,
              ),
            ),
            const SizedBox(height: 32),

            // Admin User Creation Section
            const Divider(),
            const SizedBox(height: 16),
            const Text(
              'Create Admin User',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Register an account first, then enter the email below to make it an admin',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 16),

            // Email Input Field
            TextField(
              controller: _adminEmailController,
              decoration: InputDecoration(
                labelText: 'Admin Email',
                hintText: 'admin@test.com',
                prefixIcon: const Icon(Icons.email),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              keyboardType: TextInputType.emailAddress,
              enabled: !_isCreatingAdmin,
            ),
            const SizedBox(height: 16),

            // Create Admin Button
            ElevatedButton.icon(
              onPressed: _isSeeding || _isClearing || _isCreatingAdmin ? null : _createAdminUser,
              icon: _isCreatingAdmin
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.admin_panel_settings),
              label: Text(_isCreatingAdmin ? 'Creating Admin...' : 'Create Admin User'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: AppTheme.accentColor,
              ),
            ),
            const SizedBox(height: 32),

            // Status Message
            if (_statusMessage.isNotEmpty)
              Container(
                constraints: const BoxConstraints(minHeight: 100, maxHeight: 300),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.backgroundColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppTheme.textSecondary.withValues(alpha: 0.2),
                  ),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    _statusMessage,
                    style: const TextStyle(
                      fontSize: 14,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
