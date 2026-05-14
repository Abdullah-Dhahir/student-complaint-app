import 'package:cloud_firestore/cloud_firestore.dart';

/// Simple seeding script that only creates Firestore documents
/// Use this if the Firebase Auth users already exist
class SimpleSeed {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Seed user data and complaints
  Future<void> seedFirestoreData() async {
    try {
      print('🌱 Creating Firestore data...\n');

      // Create student user document
      const studentUid = 'nffVbyWWeZXIYNb1pnef6utF8SJ2'; // Your actual student UID from logs

      print('Creating Firestore document for user: $studentUid');

      await _firestore.collection('users').doc(studentUid).set({
        'email': 'student@test.com',
        'name': 'John Doe',
        'username': 'johndoe',
        'role': 'student',
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      print('✓ Student user document created');

      // Create sample complaints
      await createSampleComplaints(studentUid);

      print('\n✅ Firestore data seeded successfully!');
      print('\nLogin credentials:');
      print('Student - Email: student@test.com, Password: 123456');
      print('\nTo create admin account:');
      print('1. Register with admin@test.com / admin123');
      print('2. Then run "Create Admin User" from seed screen');
    } catch (e) {
      print('❌ Error seeding Firestore: $e');
      rethrow;
    }
  }

  /// Create admin user from existing auth account
  Future<void> createAdminUser(String adminEmail) async {
    try {
      print('🔧 Setting up admin user for: $adminEmail\n');

      // Find user by email in Firestore
      final usersSnapshot = await _firestore
          .collection('users')
          .where('email', isEqualTo: adminEmail)
          .limit(1)
          .get();

      if (usersSnapshot.docs.isEmpty) {
        throw 'User with email $adminEmail not found. Please register first.';
      }

      final userDoc = usersSnapshot.docs.first;

      // Update role to admin
      await _firestore.collection('users').doc(userDoc.id).update({
        'role': 'admin',
      });

      print('✅ User role updated to admin!');
      print('Admin ID: ${userDoc.id}');
      print('\nYou can now login as admin with:');
      print('Email: $adminEmail');
    } catch (e) {
      print('❌ Error creating admin: $e');
      rethrow;
    }
  }

  /// Create sample complaints
  Future<void> createSampleComplaints(String studentUserId) async {
    print('\nCreating sample complaints...');

    final complaints = [
      {
        'trackingNumber': 'CMP-2026-001',
        'category': 'Facilities',
        'description':
            'The AC in classroom 301 has not been working for the past week. It makes it very difficult to concentrate during lectures.',
        'status': 'received',
        'studentId': studentUserId,
        'studentName': 'John Doe',
        'submittedDate': Timestamp.fromDate(
            DateTime.now().subtract(const Duration(days: 5))),
        'adminResponse': null,
        'responseDate': null,
        'imagePath': null,
        'imageUrl': null,
      },
      {
        'trackingNumber': 'CMP-2026-002',
        'category': 'Library',
        'description':
            'There are not enough study spaces in the library during exam season. Students have to wait for hours to get a seat.',
        'status': 'inProgress',
        'studentId': studentUserId,
        'studentName': 'John Doe',
        'submittedDate': Timestamp.fromDate(
            DateTime.now().subtract(const Duration(days: 3))),
        'adminResponse':
            'We are looking into this issue. The library committee is considering extending library hours and adding more study spaces.',
        'responseDate': Timestamp.fromDate(
            DateTime.now().subtract(const Duration(days: 1))),
        'imagePath': null,
        'imageUrl': null,
      },
      {
        'trackingNumber': 'CMP-2026-003',
        'category': 'Cafeteria',
        'description':
            'The food quality in the cafeteria has decreased significantly. Also, prices have increased without notice.',
        'status': 'resolved',
        'studentId': studentUserId,
        'studentName': 'John Doe',
        'submittedDate': Timestamp.fromDate(
            DateTime.now().subtract(const Duration(days: 10))),
        'adminResponse':
            'Thank you for bringing this to our attention. We have met with the cafeteria management and they have agreed to improve food quality and freeze prices for this semester.',
        'responseDate': Timestamp.fromDate(
            DateTime.now().subtract(const Duration(days: 7))),
        'imagePath': null,
        'imageUrl': null,
      },
      {
        'trackingNumber': 'CMP-2026-004',
        'category': 'IT Services',
        'description':
            'The WiFi connection in the dormitory is very unstable. It disconnects frequently, especially during evening hours.',
        'status': 'received',
        'studentId': studentUserId,
        'studentName': 'John Doe',
        'submittedDate': Timestamp.fromDate(
            DateTime.now().subtract(const Duration(days: 2))),
        'adminResponse': null,
        'responseDate': null,
        'imagePath': null,
        'imageUrl': null,
      },
      {
        'trackingNumber': 'CMP-2026-005',
        'category': 'Transportation',
        'description':
            'The university shuttle bus is frequently late or overcrowded. Need more buses during peak hours.',
        'status': 'inProgress',
        'studentId': studentUserId,
        'studentName': 'John Doe',
        'submittedDate': Timestamp.fromDate(
            DateTime.now().subtract(const Duration(days: 6))),
        'adminResponse':
            'We are working on adding two more shuttle buses to the route. Expected to be operational next month.',
        'responseDate': Timestamp.fromDate(
            DateTime.now().subtract(const Duration(days: 4))),
        'imagePath': null,
        'imageUrl': null,
      },
    ];

    for (final complaint in complaints) {
      await _firestore.collection('complaints').add(complaint);
      print('✓ Created complaint: ${complaint['trackingNumber']}');
    }

    print('✓ All complaints created');
  }

  /// Clear all test data
  Future<void> clearTestData() async {
    try {
      print('🗑️  Clearing test data...');

      // Delete test complaints
      final complaintsSnapshot = await _firestore
          .collection('complaints')
          .where('studentName', isEqualTo: 'John Doe')
          .get();

      for (final doc in complaintsSnapshot.docs) {
        await doc.reference.delete();
        print('✓ Deleted complaint: ${doc.id}');
      }

      print('✅ Test data cleared successfully');
    } catch (e) {
      print('❌ Error clearing test data: $e');
      rethrow;
    }
  }
}
