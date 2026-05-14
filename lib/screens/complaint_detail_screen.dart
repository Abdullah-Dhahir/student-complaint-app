import 'package:flutter/material.dart';
import '../models/complaint.dart';
import '../utils/app_theme.dart';
import '../utils/helpers.dart';

class ComplaintDetailScreen extends StatelessWidget {
  final Complaint complaint;
  final bool isStudent;

  const ComplaintDetailScreen({
    super.key,
    required this.complaint,
    this.isStudent = true,
  });

  Color _getStatusColor() {
    switch (complaint.status) {
      case ComplaintStatus.received:
        return AppTheme.statusReceived;
      case ComplaintStatus.inProgress:
        return AppTheme.statusInProgress;
      case ComplaintStatus.resolved:
        return AppTheme.statusResolved;
    }
  }

  IconData _getStatusIcon() {
    switch (complaint.status) {
      case ComplaintStatus.received:
        return Icons.fiber_new;
      case ComplaintStatus.inProgress:
        return Icons.pending_actions;
      case ComplaintStatus.resolved:
        return Icons.check_circle;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Complaint Details'),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status Banner
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _getStatusColor(),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Icon(
                    _getStatusIcon(),
                    size: 48,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    complaint.status.displayName,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),

            // Details Section
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tracking Number
                  _buildDetailCard(
                    icon: Icons.tag,
                    title: 'Tracking Number',
                    content: complaint.trackingNumber,
                  ),
                  const SizedBox(height: 16),

                  // Category
                  _buildDetailCard(
                    icon: Icons.category,
                    title: 'Category',
                    content: complaint.category,
                  ),
                  const SizedBox(height: 16),

                  // Submitted By (only show for admin)
                  if (!isStudent) ...[
                    _buildDetailCard(
                      icon: Icons.person,
                      title: 'Submitted By',
                      content: complaint.studentName,
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Submitted Date
                  _buildDetailCard(
                    icon: Icons.calendar_today,
                    title: 'Submitted Date',
                    content: Helpers.formatDateTime(complaint.submittedDate),
                  ),
                  const SizedBox(height: 16),

                  // Description
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.description,
                                size: 20,
                                color: AppTheme.primaryColor,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Description',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            complaint.description,
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppTheme.textSecondary,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Attached Image (if available)
                  if (complaint.imageUrl != null) ...[
                    const SizedBox(height: 16),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.image,
                                  size: 20,
                                  color: AppTheme.primaryColor,
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'Attached Image',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                complaint.imageUrl!,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                loadingBuilder: (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return Container(
                                    height: 200,
                                    alignment: Alignment.center,
                                    child: CircularProgressIndicator(
                                      value: loadingProgress.expectedTotalBytes != null
                                          ? loadingProgress.cumulativeBytesLoaded /
                                              loadingProgress.expectedTotalBytes!
                                          : null,
                                    ),
                                  );
                                },
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    height: 200,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: Colors.grey[200],
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.broken_image,
                                          size: 48,
                                          color: Colors.grey[400],
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Failed to load image',
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],

                  // Admin Response (if available)
                  if (complaint.adminResponse != null) ...[
                    const SizedBox(height: 16),
                    Card(
                      color: AppTheme.accentColor.withValues(alpha: 0.05),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.admin_panel_settings,
                                  size: 20,
                                  color: AppTheme.accentColor,
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'Admin Response',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                            if (complaint.responseDate != null) ...[
                              const SizedBox(height: 8),
                              Text(
                                'Responded on ${Helpers.formatDateTime(complaint.responseDate!)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color:
                                      AppTheme.textSecondary.withValues(alpha: 0.7),
                                ),
                              ),
                            ],
                            const SizedBox(height: 12),
                            Text(
                              complaint.adminResponse!,
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppTheme.textPrimary,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailCard({
    required IconData icon,
    required String title,
    required String content,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: AppTheme.primaryColor,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    content,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
