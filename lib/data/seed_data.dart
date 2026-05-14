import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// This script seeds the Firebase database with test data
/// Run this once to populate your database with sample users and complaints
class SeedData {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Main function to seed all data
  Future<void> seedAll() async {
    try {
      print('🌱 Starting database seeding...\n');

      // Step 1: Create test users
      final studentUserId = await createStudentUser();
      final adminUserId = await createAdminUser();

      print('\n✅ Users created successfully!');
      print('Student Email: student@test.com');
      print('Student Password: 123456');
      print('Admin Email: admin@test.com');
      print('Admin Password: admin123\n');

      // Step 2: Create sample complaints
      if (studentUserId != null) {
        await createSampleComplaints(studentUserId);
      }

      print('\n🎉 Database seeding completed successfully!');
      print('You can now login with the test accounts.');
    } catch (e) {
      print('❌ Error seeding database: $e');
      rethrow;
    }
  }

  /// Create a student test user
  Future<UserCredential?> createStudentUser() async {
    try {
      print('Creating student user...');

      // Create auth user
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: 'student@test.com',
        password: '123456',
      );

      final user = userCredential.user;
      if (user == null) return null;

      // Create user document in Firestore
      await _firestore.collection('users').doc(user.uid).set({
        'email': 'student@test.com',
        'name': 'John Doe',
        'username': 'johndoe',
        'role': 'student',
        'createdAt': FieldValue.serverTimestamp(),
      });

      print('✓ Student user created: ${user.uid}');
      return userCredential;
    } catch (e) {
      if (e.toString().contains('email-already-in-use')) {
        print('⚠ Student user already exists in Auth, ensuring Firestore data...');
        // Sign in to get the user
        final userCredential = await _auth.signInWithEmailAndPassword(
          email: 'student@test.com',
          password: '123456',
        );

        final user = userCredential.user;
        if (user != null) {
          // Ensure Firestore document exists
          await _firestore.collection('users').doc(user.uid).set({
            'email': 'student@test.com',
            'name': 'John Doe',
            'username': 'johndoe',
            'role': 'student',
            'createdAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
          print('✓ Student Firestore data created/updated: ${user.uid}');
        }

        return userCredential;
      }
      print('❌ Error creating student: $e');
      return null;
    }
  }

  /// Create an admin test user
  Future<UserCredential?> createAdminUser() async {
    try {
      print('Creating admin user...');

      // Create auth user
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: 'admin@test.com',
        password: 'admin123',
      );

      final user = userCredential.user;
      if (user == null) return null;

      // Create user document in Firestore
      await _firestore.collection('users').doc(user.uid).set({
        'email': 'admin@test.com',
        'name': 'Admin User',
        'username': 'admin',
        'role': 'admin',  // Set as admin
        'createdAt': FieldValue.serverTimestamp(),
      });

      print('✓ Admin user created: ${user.uid}');
      return userCredential;
    } catch (e) {
      if (e.toString().contains('email-already-in-use')) {
        print('⚠ Admin user already exists in Auth, ensuring Firestore data...');
        // Sign in to get the user
        final userCredential = await _auth.signInWithEmailAndPassword(
          email: 'admin@test.com',
          password: 'admin123',
        );

        final user = userCredential.user;
        if (user != null) {
          // Ensure Firestore document exists
          await _firestore.collection('users').doc(user.uid).set({
            'email': 'admin@test.com',
            'name': 'Admin User',
            'username': 'admin',
            'role': 'admin',
            'createdAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
          print('✓ Admin Firestore data created/updated: ${user.uid}');
        }

        return userCredential;
      }
      print('❌ Error creating admin: $e');
      return null;
    }
  }

  /// Create sample complaints for testing
  Future<void> createSampleComplaints(UserCredential studentUser) async {
    try {
      print('\nCreating sample complaints...');
      final user = studentUser.user!;

      final complaints = [
        {
          'trackingNumber': 'CMP-2026-001',
          'category': 'Facilities',
          'description': 'The AC in classroom 301 has not been working for the past week. It makes it very difficult to concentrate during lectures.',
          'status': 'received',
          'studentId': user.uid,
          'studentName': 'John Doe',
          'submittedDate': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 5))),
          'adminResponse': null,
          'responseDate': null,
          'imagePath': null,
          'imageUrl': null,
        },
        {
          'trackingNumber': 'CMP-2026-002',
          'category': 'Library',
          'description': 'There are not enough study spaces in the library during exam season. Students have to wait for hours to get a seat.',
          'status': 'inProgress',
          'studentId': user.uid,
          'studentName': 'John Doe',
          'submittedDate': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 3))),
          'adminResponse': 'We are looking into this issue. The library committee is considering extending library hours and adding more study spaces.',
          'responseDate': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 1))),
          'imagePath': null,
          'imageUrl': null,
        },
        {
          'trackingNumber': 'CMP-2026-003',
          'category': 'Cafeteria',
          'description': 'The food quality in the cafeteria has decreased significantly. Also, prices have increased without notice.',
          'status': 'resolved',
          'studentId': user.uid,
          'studentName': 'John Doe',
          'submittedDate': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 10))),
          'adminResponse': 'Thank you for bringing this to our attention. We have met with the cafeteria management and they have agreed to improve food quality and freeze prices for this semester.',
          'responseDate': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 7))),
          'imagePath': null,
          'imageUrl': null,
        },
        {
          'trackingNumber': 'CMP-2026-004',
          'category': 'IT Services',
          'description': 'The WiFi connection in the dormitory is very unstable. It disconnects frequently, especially during evening hours.',
          'status': 'received',
          'studentId': user.uid,
          'studentName': 'John Doe',
          'submittedDate': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 2))),
          'adminResponse': null,
          'responseDate': null,
          'imagePath': null,
          'imageUrl': null,
        },
        {
          'trackingNumber': 'CMP-2026-005',
          'category': 'Transportation',
          'description': 'The university shuttle bus is frequently late or overcrowded. Need more buses during peak hours.',
          'status': 'inProgress',
          'studentId': user.uid,
          'studentName': 'John Doe',
          'submittedDate': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 6))),
          'adminResponse': 'We are working on adding two more shuttle buses to the route. Expected to be operational next month.',
          'responseDate': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 4))),
          'imagePath': null,
          'imageUrl': null,
        },
      ];

      for (final complaint in complaints) {
        await _firestore.collection('complaints').add(complaint);
        print('✓ Created complaint: ${complaint['trackingNumber']}');
      }

      print('✓ All complaints created successfully');
    } catch (e) {
      print('❌ Error creating complaints: $e');
    }
  }

  /// Clear all test data (use with caution!)
  Future<void> clearTestData() async {
    try {
      print('🗑️  Clearing test data...');

      // Delete test users from Firestore
      final usersSnapshot = await _firestore
          .collection('users')
          .where('email', whereIn: ['student@test.com', 'admin@test.com'])
          .get();

      for (final doc in usersSnapshot.docs) {
        await doc.reference.delete();
        print('✓ Deleted user document: ${doc.id}');
      }

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
    }
  }
}
