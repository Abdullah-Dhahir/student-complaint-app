import 'package:flutter/material.dart';
import '../models/user.dart';
import '../models/complaint.dart';
import '../utils/app_theme.dart';
import '../widgets/complaint_card.dart';
import 'submit_complaint_screen.dart';
import 'complaint_detail_screen.dart';
import 'login_screen.dart';
import '../services/firebase/firestore_service.dart';
import '../services/firebase/firebase_auth_service.dart';
import '../services/firebase/messaging_service.dart';

class StudentHomeScreen extends StatefulWidget {
  final User user;

  const StudentHomeScreen({super.key, required this.user});

  @override
  State<StudentHomeScreen> createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends State<StudentHomeScreen> {
  String _selectedFilter = 'All';
  final _firestoreService = FirestoreService();
  final _authService = FirebaseAuthService();
  final _messagingService = MessagingService();

  List<Complaint> _getFilteredComplaints(List<Complaint> complaints) {
    if (_selectedFilter == 'All') {
      return complaints;
    } else if (_selectedFilter == 'Received') {
      return complaints
          .where((c) => c.status == ComplaintStatus.received)
          .toList();
    } else if (_selectedFilter == 'In Progress') {
      return complaints
          .where((c) => c.status == ComplaintStatus.inProgress)
          .toList();
    } else if (_selectedFilter == 'Resolved') {
      return complaints
          .where((c) => c.status == ComplaintStatus.resolved)
          .toList();
    }
    return complaints;
  }

  int _getCountByStatus(List<Complaint> complaints, ComplaintStatus status) {
    return complaints.where((c) => c.status == status).length;
  }

  Future<void> _handleLogout() async {
    // Remove FCM token and unsubscribe from topics
    await _messagingService.removeTokenFromDatabase(widget.user.id);
    await _messagingService.unsubscribeFromTopic('student_notifications');
    await _messagingService.deleteToken();

    // Sign out
    await _authService.signOut();

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const LoginScreen(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Complaints'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _handleLogout,
          ),
        ],
      ),
      body: StreamBuilder<List<Complaint>>(
        stream: _firestoreService.getStudentComplaints(widget.user.id),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 60,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 16),
                  Text('Error: ${snapshot.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {});
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final allComplaints = snapshot.data ?? [];
          final filteredComplaints = _getFilteredComplaints(allComplaints);

          return Column(
        children: [
          // User Info Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: AppTheme.accentColor,
                      child: Text(
                        widget.user.name[0].toUpperCase(),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.user.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.user.email,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withValues(alpha: 0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Stats Row
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        'Received',
                        _getCountByStatus(allComplaints, ComplaintStatus.received),
                        AppTheme.statusReceived,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        'In Progress',
                        _getCountByStatus(allComplaints, ComplaintStatus.inProgress),
                        AppTheme.statusInProgress,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        'Resolved',
                        _getCountByStatus(allComplaints, ComplaintStatus.resolved),
                        AppTheme.statusResolved,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Filter Chips
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('All'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Received'),
                  const SizedBox(width: 8),
                  _buildFilterChip('In Progress'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Resolved'),
                ],
              ),
            ),
          ),

          // Complaints List
          Expanded(
            child: filteredComplaints.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.only(bottom: 80),
                    itemCount: filteredComplaints.length,
                    itemBuilder: (context, index) {
                      final complaint = filteredComplaints[index];
                      return ComplaintCard(
                        complaint: complaint,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ComplaintDetailScreen(
                                complaint: complaint,
                                isStudent: true,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SubmitComplaintScreen(user: widget.user),
            ),
          );
          // No need to reload - StreamBuilder handles real-time updates
        },
        icon: const Icon(Icons.add),
        label: const Text('New Complaint'),
        backgroundColor: AppTheme.accentColor,
      ),
    );
  }

  Widget _buildStatCard(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            count.toString(),
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.white.withValues(alpha: 0.9),
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _selectedFilter == label;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedFilter = label;
        });
      },
      backgroundColor: Colors.white,
      selectedColor: AppTheme.primaryColor,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : AppTheme.textPrimary,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
      checkmarkColor: Colors.white,
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 80,
            color: AppTheme.textSecondary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            _selectedFilter == 'All'
                ? 'No complaints submitted yet'
                : 'No $_selectedFilter complaints',
            style: TextStyle(
              fontSize: 18,
              color: AppTheme.textSecondary.withValues(alpha: 0.7),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _selectedFilter == 'All'
                ? 'Tap the button below to submit your first complaint'
                : 'Try selecting a different filter',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}
