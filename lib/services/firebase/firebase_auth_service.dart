import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/user.dart' as app_user;

class FirebaseAuthService {
  final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  firebase_auth.User? get currentUser => _auth.currentUser;

  // Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  // Auth state changes stream
  Stream<firebase_auth.User?> get authStateChanges => _auth.authStateChanges();

  // Register with email and password
  Future<app_user.User?> registerWithEmailAndPassword({
    required String email,
    required String password,
    required String name,
    required String username,
  }) async {
    try {
      // Create user in Firebase Auth
      final firebase_auth.UserCredential result =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final firebase_auth.User? firebaseUser = result.user;
      if (firebaseUser == null) return null;

      // Create user document in Firestore
      final appUser = app_user.User(
        id: firebaseUser.uid,
        username: username,
        name: name,
        email: email,
        role: app_user.UserRole.student, // Default role
      );

      await _firestore.collection('users').doc(firebaseUser.uid).set({
        'email': email,
        'name': name,
        'username': username,
        'role': 'student',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Send email verification
      await firebaseUser.sendEmailVerification();

      return appUser;
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'Registration failed: ${e.toString()}';
    }
  }

  // Sign in with email and password
  Future<app_user.User?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final firebase_auth.UserCredential result =
          await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final firebase_auth.User? firebaseUser = result.user;
      if (firebaseUser == null) return null;

      // Get user data from Firestore
      print('🔍 Fetching user data for UID: ${firebaseUser.uid}');
      final userDoc =
          await _firestore.collection('users').doc(firebaseUser.uid).get();

      print('📄 Document exists: ${userDoc.exists}');

      if (!userDoc.exists) {
        throw 'User data not found in database. Please contact administrator or try registering again.';
      }

      final data = userDoc.data();
      print('📊 User data: $data');

      if (data == null) {
        throw 'User data is empty. Please contact administrator.';
      }

      final userRole = data['role'] == 'admin'
          ? app_user.UserRole.admin
          : app_user.UserRole.student;

      print('👤 User role: ${data['role']} -> $userRole');

      return app_user.User(
        id: firebaseUser.uid,
        username: data['username'] ?? '',
        name: data['name'] ?? '',
        email: data['email'] ?? email,
        role: userRole,
      );
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'Login failed: ${e.toString()}';
    }
  }

  // Save a new user's profile to Firestore after first OTP login
  Future<void> createUserProfile({
    required String uid,
    required String email,
    required String name,
    required String username,
    String role = 'student',
  }) async {
    await _firestore.collection('users').doc(uid).set({
      'email': email,
      'name': name,
      'username': username,
      'role': role,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // Check if an email already has a profile in Firestore
  Future<bool> doesUserExistByEmail(String email) async {
    final snapshot = await _firestore
        .collection('users')
        .where('email', isEqualTo: email)
        .limit(1)
        .get();
    return snapshot.docs.isNotEmpty;
  }

  // Get user by ID, or create a basic student profile if it doesn't exist yet
  Future<app_user.User> getOrCreateUser(String uid, String email) async {
    final existing = await getUserById(uid);
    if (existing != null) return existing;

    // First OTP login — create a Firestore profile with the email prefix as name
    final username = email.split('@').first;
    await _firestore.collection('users').doc(uid).set({
      'email': email,
      'name': username,
      'username': username,
      'role': 'student',
      'createdAt': FieldValue.serverTimestamp(),
    });

    return app_user.User(
      id: uid,
      username: username,
      name: username,
      email: email,
      role: app_user.UserRole.student,
    );
  }

  // Get user by ID
  Future<app_user.User?> getUserById(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();

      if (!userDoc.exists) return null;

      final data = userDoc.data()!;

      return app_user.User(
        id: userId,
        username: data['username'] ?? '',
        name: data['name'] ?? '',
        email: data['email'] ?? '',
        role: data['role'] == 'admin'
            ? app_user.UserRole.admin
            : app_user.UserRole.student,
      );
    } catch (e) {
      return null;
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Change password
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw 'No user logged in';

      // Re-authenticate user
      final credential = firebase_auth.EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );

      await user.reauthenticateWithCredential(credential);

      // Update password
      await user.updatePassword(newPassword);
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Send email verification
  Future<void> sendEmailVerification() async {
    try {
      final user = _auth.currentUser;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
      }
    } catch (e) {
      throw 'Failed to send verification email: ${e.toString()}';
    }
  }

  // Check if email is verified
  bool get isEmailVerified => _auth.currentUser?.emailVerified ?? false;

  // Reload user to get updated verification status
  Future<void> reloadUser() async {
    await _auth.currentUser?.reload();
  }

  // Handle Firebase Auth exceptions
  String _handleAuthException(firebase_auth.FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'The password is too weak';
      case 'email-already-in-use':
        return 'An account already exists with this email';
      case 'user-not-found':
        return 'No user found with this email';
      case 'wrong-password':
        return 'Incorrect password';
      case 'invalid-email':
        return 'Invalid email address';
      case 'user-disabled':
        return 'This account has been disabled';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later';
      case 'operation-not-allowed':
        return 'Email/password sign-in is not enabled';
      default:
        return e.message ?? 'Authentication error occurred';
    }
  }
}
