import '../models/complaint.dart';
import '../models/user.dart';

class DummyData {
  // Dummy users
  static final List<User> users = [
    User(
      id: '1',
      username: 'student1',
      name: 'Ahmed Ali',
      email: 'ahmed.ali@university.edu',
      role: UserRole.student,
    ),
    User(
      id: '2',
      username: 'student2',
      name: 'Fatima Hassan',
      email: 'fatima.hassan@university.edu',
      role: UserRole.student,
    ),
    User(
      id: '3',
      username: 'admin',
      name: 'Admin User',
      email: 'admin@university.edu',
      role: UserRole.admin,
    ),
  ];

  // Complaint categories
  static final List<String> categories = [
    'Classroom Facilities',
    'Cafeteria',
    'Library',
    'IT Services',
    'Hostel',
    'Transportation',
    'Administration',
    'Academic',
    'Sports Facilities',
    'Other',
  ];

  // Dummy complaints
  static final List<Complaint> complaints = [
    Complaint(
      id: '1',
      trackingNumber: 'CMP-2024-001',
      category: 'Classroom Facilities',
      description: 'The air conditioning in Room 301 is not working. It has been very hot during lectures.',
      status: ComplaintStatus.resolved,
      studentId: '1',
      studentName: 'Ahmed Ali',
      submittedDate: DateTime.now().subtract(const Duration(days: 5)),
      adminResponse: 'The AC has been repaired. Thank you for reporting this issue.',
      responseDate: DateTime.now().subtract(const Duration(days: 2)),
    ),
    Complaint(
      id: '2',
      trackingNumber: 'CMP-2024-002',
      category: 'Cafeteria',
      description: 'The food quality in the cafeteria has decreased recently. Many students are complaining about the taste and hygiene.',
      status: ComplaintStatus.inProgress,
      studentId: '1',
      studentName: 'Ahmed Ali',
      submittedDate: DateTime.now().subtract(const Duration(days: 3)),
      adminResponse: 'We are working with the cafeteria management to improve the quality. An inspection has been scheduled.',
      responseDate: DateTime.now().subtract(const Duration(days: 1)),
    ),
    Complaint(
      id: '3',
      trackingNumber: 'CMP-2024-003',
      category: 'Library',
      description: 'The library closes too early at 6 PM. Many students need to study until late evening, especially during exam season.',
      status: ComplaintStatus.received,
      studentId: '1',
      studentName: 'Ahmed Ali',
      submittedDate: DateTime.now().subtract(const Duration(hours: 12)),
    ),
    Complaint(
      id: '4',
      trackingNumber: 'CMP-2024-004',
      category: 'IT Services',
      description: 'WiFi connection in the computer lab is very slow. Students cannot access online resources properly.',
      status: ComplaintStatus.inProgress,
      studentId: '2',
      studentName: 'Fatima Hassan',
      submittedDate: DateTime.now().subtract(const Duration(days: 4)),
      adminResponse: 'IT team is upgrading the network infrastructure. Expected completion in 2 days.',
      responseDate: DateTime.now().subtract(const Duration(days: 1)),
    ),
    Complaint(
      id: '5',
      trackingNumber: 'CMP-2024-005',
      category: 'Hostel',
      description: 'Water supply in Block A hostel is irregular. Sometimes there is no water in the morning.',
      status: ComplaintStatus.received,
      studentId: '2',
      studentName: 'Fatima Hassan',
      submittedDate: DateTime.now().subtract(const Duration(hours: 6)),
    ),
    Complaint(
      id: '6',
      trackingNumber: 'CMP-2024-006',
      category: 'Transportation',
      description: 'University bus is frequently late. Students are missing their classes because of this.',
      status: ComplaintStatus.resolved,
      studentId: '2',
      studentName: 'Fatima Hassan',
      submittedDate: DateTime.now().subtract(const Duration(days: 7)),
      adminResponse: 'Additional buses have been added and a new schedule has been implemented. Thank you for your feedback.',
      responseDate: DateTime.now().subtract(const Duration(days: 3)),
    ),
    Complaint(
      id: '7',
      trackingNumber: 'CMP-2024-007',
      category: 'Academic',
      description: 'The course material for CS301 is not uploaded on the portal. Students are facing difficulties in preparing for exams.',
      status: ComplaintStatus.inProgress,
      studentId: '1',
      studentName: 'Ahmed Ali',
      submittedDate: DateTime.now().subtract(const Duration(days: 2)),
      adminResponse: 'We have contacted the professor. Materials will be uploaded within 24 hours.',
      responseDate: DateTime.now().subtract(const Duration(hours: 8)),
    ),
    Complaint(
      id: '8',
      trackingNumber: 'CMP-2024-008',
      category: 'Sports Facilities',
      description: 'The basketball court needs maintenance. The surface is cracked and dangerous for players.',
      status: ComplaintStatus.received,
      studentId: '2',
      studentName: 'Fatima Hassan',
      submittedDate: DateTime.now().subtract(const Duration(hours: 3)),
    ),
  ];

  // Get complaints for a specific student
  static List<Complaint> getComplaintsForStudent(String studentId) {
    return complaints.where((c) => c.studentId == studentId).toList();
  }

  // Get all complaints (for admin)
  static List<Complaint> getAllComplaints() {
    return complaints;
  }

  // Find user by username
  static User? findUserByUsername(String username) {
    try {
      return users.firstWhere((user) => user.username == username);
    } catch (e) {
      return null;
    }
  }
}
