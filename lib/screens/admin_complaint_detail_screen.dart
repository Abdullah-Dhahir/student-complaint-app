import 'package:flutter/material.dart';
import '../models/complaint.dart';
import '../utils/app_theme.dart';
import '../utils/helpers.dart';
import '../services/firebase/firestore_service.dart';
import '../services/firebase/messaging_service.dart';

class AdminComplaintDetailScreen extends StatefulWidget {
  final Complaint complaint;

  const AdminComplaintDetailScreen({
    super.key,
    required this.complaint,
  });

  @override
  State<AdminComplaintDetailScreen> createState() =>
      _AdminComplaintDetailScreenState();
}

class _AdminComplaintDetailScreenState
    extends State<AdminComplaintDetailScreen> {
  late ComplaintStatus _selectedStatus;
  final _responseController = TextEditingController();
  bool _isLoading = false;
  final _firestoreService = FirestoreService();
  final _messagingService = MessagingService();

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.complaint.status;
    _responseController.text = widget.complaint.adminResponse ?? '';
  }

  @override
  void dispose() {
    _responseController.dispose();
    super.dispose();
  }

  Color _getStatusColor(ComplaintStatus status) {
    switch (status) {
      case ComplaintStatus.received:
        return AppTheme.statusReceived;
      case ComplaintStatus.inProgress:
        return AppTheme.statusInProgress;
      case ComplaintStatus.resolved:
        return AppTheme.statusResolved;
    }
  }

  IconData _getStatusIcon(ComplaintStatus status) {
    switch (status) {
      case ComplaintStatus.received:
        return Icons.fiber_new;
      case ComplaintStatus.inProgress:
        return Icons.pending_actions;
      case ComplaintStatus.resolved:
        return Icons.check_circle;
    }
  }

  Future<void> _deleteComplaint() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Complaint'),
        content: const Text(
            'Are you sure you want to delete this resolved complaint? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);

    try {
      await _firestoreService.deleteComplaint(widget.complaint.id);
      if (mounted) {
        Helpers.showSnackBar(context, 'Complaint deleted successfully.');
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        Helpers.showSnackBar(context, 'Error deleting complaint: ${e.toString()}', isError: true);
      }
    }
  }

  Future<void> _updateComplaint() async {
    // Validate response if status is not received
    if (_selectedStatus != ComplaintStatus.received &&
        _responseController.text.trim().isEmpty) {
      Helpers.showSnackBar(
        context,
        'Please provide a response for the student',
        isError: true,
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Update complaint in Firestore
      await _firestoreService.updateComplaint(
        complaintId: widget.complaint.id,
        status: _selectedStatus,
        response: _responseController.text.trim(),
      );

      // Send notification to student
      try {
        final statusText = _selectedStatus == ComplaintStatus.received
            ? 'Received'
            : _selectedStatus == ComplaintStatus.inProgress
                ? 'In Progress'
                : 'Resolved';

        await _messagingService.sendComplaintUpdateNotification(
          studentId: widget.complaint.studentId,
          complaintId: widget.complaint.id,
          title: 'Complaint Update: ${widget.complaint.trackingNumber}',
          body: 'Status changed to $statusText',
        );
        print('✅ Notification sent to student');
      } catch (e) {
        print('⚠️ Warning: Failed to send notification: $e');
        // Continue even if notification fails
      }

      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        Helpers.showSnackBar(
          context,
          'Complaint updated successfully! Student will be notified.',
        );
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        Helpers.showSnackBar(
          context,
          'Error updating complaint: ${e.toString()}',
          isError: true,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Complaint'),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Complaint Info Section
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.05),
                border: Border(
                  bottom: BorderSide(
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  ),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.tag,
                        color: AppTheme.primaryColor,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        widget.complaint.trackingNumber,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(
                        Icons.person,
                        color: AppTheme.textSecondary,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        widget.complaint.studentName,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_today,
                        color: AppTheme.textSecondary,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        Helpers.formatDateTime(widget.complaint.submittedDate),
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
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
                  // Category
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Icon(
                            Icons.category,
                            size: 20,
                            color: AppTheme.primaryColor,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Category',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  widget.complaint.category,
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
                            widget.complaint.description,
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
                  if (widget.complaint.imageUrl != null) ...[
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
                                widget.complaint.imageUrl!,
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

                  const SizedBox(height: 24),

                  // Admin Actions Section
                  const Text(
                    'Update Complaint',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Status Selector
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Change Status',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            children: ComplaintStatus.values.map((status) {
                              final isSelected = _selectedStatus == status;
                              return ChoiceChip(
                                label: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      _getStatusIcon(status),
                                      size: 16,
                                      color: isSelected
                                          ? Colors.white
                                          : _getStatusColor(status),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(status.displayName),
                                  ],
                                ),
                                selected: isSelected,
                                onSelected: (selected) {
                                  setState(() {
                                    _selectedStatus = status;
                                  });
                                },
                                selectedColor: _getStatusColor(status),
                                backgroundColor: _getStatusColor(status)
                                    .withValues(alpha: 0.1),
                                labelStyle: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : _getStatusColor(status),
                                  fontWeight: FontWeight.w600,
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Response Field
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Add/Update Response',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _responseController,
                            maxLines: 5,
                            decoration: const InputDecoration(
                              hintText:
                                  'Write a response to the student...',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Update Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _updateComplaint,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Text(
                              'Update Complaint',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),

                  // Delete Button (only for resolved complaints)
                  if (widget.complaint.status == ComplaintStatus.resolved) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: _isLoading ? null : _deleteComplaint,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                        ),
                        child: const Text(
                          'Delete Complaint',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
