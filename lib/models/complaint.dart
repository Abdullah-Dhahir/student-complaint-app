class Complaint {
  final String id;
  final String trackingNumber;
  final String category;
  final String description;
  final String? imagePath;
  final String? imageUrl;
  final ComplaintStatus status;
  final String studentId;
  final String studentName;
  final DateTime submittedDate;
  final String? adminResponse;
  final DateTime? responseDate;

  Complaint({
    required this.id,
    required this.trackingNumber,
    required this.category,
    required this.description,
    this.imagePath,
    this.imageUrl,
    required this.status,
    required this.studentId,
    required this.studentName,
    required this.submittedDate,
    this.adminResponse,
    this.responseDate,
  });

  Complaint copyWith({
    String? id,
    String? trackingNumber,
    String? category,
    String? description,
    String? imagePath,
    String? imageUrl,
    ComplaintStatus? status,
    String? studentId,
    String? studentName,
    DateTime? submittedDate,
    String? adminResponse,
    DateTime? responseDate,
  }) {
    return Complaint(
      id: id ?? this.id,
      trackingNumber: trackingNumber ?? this.trackingNumber,
      category: category ?? this.category,
      description: description ?? this.description,
      imagePath: imagePath ?? this.imagePath,
      imageUrl: imageUrl ?? this.imageUrl,
      status: status ?? this.status,
      studentId: studentId ?? this.studentId,
      studentName: studentName ?? this.studentName,
      submittedDate: submittedDate ?? this.submittedDate,
      adminResponse: adminResponse ?? this.adminResponse,
      responseDate: responseDate ?? this.responseDate,
    );
  }
}

enum ComplaintStatus {
  received,
  inProgress,
  resolved,
}

extension ComplaintStatusExtension on ComplaintStatus {
  String get displayName {
    switch (this) {
      case ComplaintStatus.received:
        return 'Received';
      case ComplaintStatus.inProgress:
        return 'In Progress';
      case ComplaintStatus.resolved:
        return 'Resolved';
    }
  }
}
