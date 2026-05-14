import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Upload complaint image to Firebase Storage
  /// Returns the download URL of the uploaded image
  Future<Map<String, String>> uploadComplaintImage({
    required String complaintId,
    required String filePath,
  }) async {
    try {
      final file = File(filePath);
      final fileName = 'image_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final storagePath = 'complaints/$complaintId/$fileName';

      // Create a reference to the file location
      final storageRef = _storage.ref().child(storagePath);

      // Upload the file
      final uploadTask = await storageRef.putFile(
        file,
        SettableMetadata(
          contentType: 'image/jpeg',
          customMetadata: {
            'uploadedAt': DateTime.now().toIso8601String(),
            'complaintId': complaintId,
          },
        ),
      );

      // Get the download URL
      final downloadUrl = await uploadTask.ref.getDownloadURL();

      return {
        'imagePath': storagePath,
        'imageUrl': downloadUrl,
      };
    } catch (e) {
      throw 'Failed to upload image: ${e.toString()}';
    }
  }

  /// Delete an image from Firebase Storage
  Future<void> deleteImage(String imagePath) async {
    try {
      final storageRef = _storage.ref().child(imagePath);
      await storageRef.delete();
    } catch (e) {
      // Silently fail if image doesn't exist
      // This prevents errors when deleting complaints that have no image
      if (e.toString().contains('object-not-found')) {
        return;
      }
      throw 'Failed to delete image: ${e.toString()}';
    }
  }

  /// Get download URL for an existing image
  Future<String?> getImageUrl(String imagePath) async {
    try {
      final storageRef = _storage.ref().child(imagePath);
      return await storageRef.getDownloadURL();
    } catch (e) {
      return null;
    }
  }

  /// Delete all images for a complaint
  Future<void> deleteComplaintImages(String complaintId) async {
    try {
      final storageRef = _storage.ref().child('complaints/$complaintId');
      final listResult = await storageRef.listAll();

      // Delete all files in the complaint folder
      for (var item in listResult.items) {
        await item.delete();
      }
    } catch (e) {
      // Silently fail if folder doesn't exist
      if (e.toString().contains('object-not-found')) {
        return;
      }
      throw 'Failed to delete complaint images: ${e.toString()}';
    }
  }

  /// Upload user profile image
  Future<String> uploadProfileImage({
    required String userId,
    required String filePath,
  }) async {
    try {
      final file = File(filePath);
      final fileName = 'profile_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final storagePath = 'profiles/$userId/$fileName';

      final storageRef = _storage.ref().child(storagePath);

      await storageRef.putFile(
        file,
        SettableMetadata(
          contentType: 'image/jpeg',
          customMetadata: {
            'uploadedAt': DateTime.now().toIso8601String(),
            'userId': userId,
          },
        ),
      );

      return await storageRef.getDownloadURL();
    } catch (e) {
      throw 'Failed to upload profile image: ${e.toString()}';
    }
  }

  /// Get storage usage statistics
  Future<Map<String, dynamic>> getStorageStats(String userId) async {
    try {
      final userRef = _storage.ref().child('profiles/$userId');
      final listResult = await userRef.listAll();

      int totalFiles = listResult.items.length;
      int totalSize = 0;

      for (var item in listResult.items) {
        final metadata = await item.getMetadata();
        totalSize += metadata.size ?? 0;
      }

      return {
        'totalFiles': totalFiles,
        'totalSize': totalSize,
        'totalSizeMB': (totalSize / (1024 * 1024)).toStringAsFixed(2),
      };
    } catch (e) {
      return {
        'totalFiles': 0,
        'totalSize': 0,
        'totalSizeMB': '0.00',
      };
    }
  }
}
