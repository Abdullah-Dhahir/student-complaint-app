import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/complaint.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Generate tracking number
  Future<String> _generateTrackingNumber() async {
    final year = DateTime.now().year;
    final querySnapshot = await _firestore
        .collection('complaints')
        .where('trackingNumber', isGreaterThanOrEqualTo: 'CMP-$year-')
        .orderBy('trackingNumber', descending: true)
        .limit(1)
        .get();

    if (querySnapshot.docs.isEmpty) {
      return 'CMP-$year-001';
    }

    final lastTracking = querySnapshot.docs.first.data()['trackingNumber'] as String;
    final lastNumber = int.parse(lastTracking.split('-').last);
    final newNumber = (lastNumber + 1).toString().padLeft(3, '0');
    return 'CMP-$year-$newNumber';
  }

  // Create a new complaint
  Future<String> createComplaint({
    required String category,
    required String description,
    String? imagePath,
    String? imageUrl,
    required String studentId,
    required String studentName,
  }) async {
    try {
      final trackingNumber = await _generateTrackingNumber();
      final complaintRef = _firestore.collection('complaints').doc();

      await complaintRef.set({
        'trackingNumber': trackingNumber,
        'category': category,
        'description': description,
        'imagePath': imagePath,
        'imageUrl': imageUrl,
        'status': 'received',
        'studentId': studentId,
        'studentName': studentName,
        'submittedDate': FieldValue.serverTimestamp(),
        'adminResponse': null,
        'responseDate': null,
      });

      return complaintRef.id;
    } catch (e) {
      throw 'Failed to create complaint: ${e.toString()}';
    }
  }

  // Get all complaints (for admin)
  Stream<List<Complaint>> getAllComplaints() {
    return _firestore
        .collection('complaints')
        .orderBy('submittedDate', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => _complaintFromFirestore(doc)).toList();
    });
  }

  // Get complaints for a specific student
  Stream<List<Complaint>> getStudentComplaints(String studentId) {
    return _firestore
        .collection('complaints')
        .where('studentId', isEqualTo: studentId)
        // Removed orderBy to avoid composite index requirement
        // Sorting will be done in memory
        .snapshots()
        .map((snapshot) {
      final complaints = snapshot.docs.map((doc) => _complaintFromFirestore(doc)).toList();
      // Sort in memory by submittedDate descending
      complaints.sort((a, b) => b.submittedDate.compareTo(a.submittedDate));
      return complaints;
    });
  }

  // Get complaints by status
  Stream<List<Complaint>> getComplaintsByStatus(ComplaintStatus status) {
    return _firestore
        .collection('complaints')
        .where('status', isEqualTo: _statusToString(status))
        .orderBy('submittedDate', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => _complaintFromFirestore(doc)).toList();
    });
  }

  // Get student complaints by status
  Stream<List<Complaint>> getStudentComplaintsByStatus(
    String studentId,
    ComplaintStatus status,
  ) {
    return _firestore
        .collection('complaints')
        .where('studentId', isEqualTo: studentId)
        .where('status', isEqualTo: _statusToString(status))
        .orderBy('submittedDate', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => _complaintFromFirestore(doc)).toList();
    });
  }

  // Get a single complaint by ID
  Future<Complaint?> getComplaintById(String complaintId) async {
    try {
      final doc = await _firestore.collection('complaints').doc(complaintId).get();
      if (!doc.exists) return null;
      return _complaintFromFirestore(doc);
    } catch (e) {
      return null;
    }
  }

  // Update complaint status
  Future<void> updateComplaintStatus({
    required String complaintId,
    required ComplaintStatus status,
  }) async {
    try {
      await _firestore.collection('complaints').doc(complaintId).update({
        'status': _statusToString(status),
      });
    } catch (e) {
      throw 'Failed to update status: ${e.toString()}';
    }
  }

  // Add admin response
  Future<void> addAdminResponse({
    required String complaintId,
    required String response,
  }) async {
    try {
      await _firestore.collection('complaints').doc(complaintId).update({
        'adminResponse': response,
        'responseDate': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw 'Failed to add response: ${e.toString()}';
    }
  }

  // Update complaint status and response together
  Future<void> updateComplaint({
    required String complaintId,
    required ComplaintStatus status,
    required String response,
  }) async {
    try {
      await _firestore.collection('complaints').doc(complaintId).update({
        'status': _statusToString(status),
        'adminResponse': response,
        'responseDate': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw 'Failed to update complaint: ${e.toString()}';
    }
  }

  // Delete a complaint
  Future<void> deleteComplaint(String complaintId) async {
    try {
      await _firestore.collection('complaints').doc(complaintId).delete();
    } catch (e) {
      throw 'Failed to delete complaint: ${e.toString()}';
    }
  }

  // Get complaint statistics for a student
  Future<Map<String, int>> getStudentStatistics(String studentId) async {
    try {
      final snapshot = await _firestore
          .collection('complaints')
          .where('studentId', isEqualTo: studentId)
          .get();

      int total = snapshot.docs.length;
      int received = 0;
      int inProgress = 0;
      int resolved = 0;

      for (var doc in snapshot.docs) {
        final status = doc.data()['status'] as String;
        switch (status) {
          case 'received':
            received++;
            break;
          case 'inProgress':
            inProgress++;
            break;
          case 'resolved':
            resolved++;
            break;
        }
      }

      return {
        'total': total,
        'received': received,
        'inProgress': inProgress,
        'resolved': resolved,
      };
    } catch (e) {
      return {
        'total': 0,
        'received': 0,
        'inProgress': 0,
        'resolved': 0,
      };
    }
  }

  // Get overall statistics (for admin)
  Future<Map<String, int>> getAllStatistics() async {
    try {
      final snapshot = await _firestore.collection('complaints').get();

      int total = snapshot.docs.length;
      int received = 0;
      int inProgress = 0;
      int resolved = 0;

      for (var doc in snapshot.docs) {
        final status = doc.data()['status'] as String;
        switch (status) {
          case 'received':
            received++;
            break;
          case 'inProgress':
            inProgress++;
            break;
          case 'resolved':
            resolved++;
            break;
        }
      }

      return {
        'total': total,
        'received': received,
        'inProgress': inProgress,
        'resolved': resolved,
      };
    } catch (e) {
      return {
        'total': 0,
        'received': 0,
        'inProgress': 0,
        'resolved': 0,
      };
    }
  }

  // Helper: Convert Firestore document to Complaint model
  Complaint _complaintFromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return Complaint(
      id: doc.id,
      trackingNumber: data['trackingNumber'] ?? '',
      category: data['category'] ?? '',
      description: data['description'] ?? '',
      imagePath: data['imagePath'],
      imageUrl: data['imageUrl'],
      status: _stringToStatus(data['status'] ?? 'received'),
      studentId: data['studentId'] ?? '',
      studentName: data['studentName'] ?? '',
      submittedDate: (data['submittedDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      adminResponse: data['adminResponse'],
      responseDate: (data['responseDate'] as Timestamp?)?.toDate(),
    );
  }

  // Helper: Convert status enum to string
  String _statusToString(ComplaintStatus status) {
    switch (status) {
      case ComplaintStatus.received:
        return 'received';
      case ComplaintStatus.inProgress:
        return 'inProgress';
      case ComplaintStatus.resolved:
        return 'resolved';
    }
  }

  // Helper: Convert string to status enum
  ComplaintStatus _stringToStatus(String status) {
    switch (status) {
      case 'inProgress':
        return ComplaintStatus.inProgress;
      case 'resolved':
        return ComplaintStatus.resolved;
      case 'received':
      default:
        return ComplaintStatus.received;
    }
  }
}
