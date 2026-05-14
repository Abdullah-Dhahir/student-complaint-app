import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/user.dart';
import '../utils/app_theme.dart';
import '../utils/helpers.dart';
import '../services/firebase/firestore_service.dart';
import '../services/firebase/storage_service.dart';

class SubmitComplaintScreen extends StatefulWidget {
  final User user;

  const SubmitComplaintScreen({super.key, required this.user});

  @override
  State<SubmitComplaintScreen> createState() => _SubmitComplaintScreenState();
}

class _SubmitComplaintScreenState extends State<SubmitComplaintScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  String? _selectedCategory;
  bool _isLoading = false;
  XFile? _selectedImage;

  final _firestoreService = FirestoreService();
  final _storageService = StorageService();

  final List<String> _categories = [
    'Classroom Facilities',
    'Cafeteria',
    'Library',
    'IT Infrastructure',
    'Hostel',
    'Transportation',
    'Administration',
    'Academic',
    'Sports Facilities',
    'Other',
  ];

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImageFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImage = image;
        });
        if (mounted) {
          Helpers.showSnackBar(
            context,
            'Photo captured successfully!',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Helpers.showSnackBar(
          context,
          'Error capturing photo: ${e.toString()}',
          isError: true,
        );
      }
    }
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImage = image;
        });
        if (mounted) {
          Helpers.showSnackBar(
            context,
            'Photo selected successfully!',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Helpers.showSnackBar(
          context,
          'Error selecting photo: ${e.toString()}',
          isError: true,
        );
      }
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Add Photo',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(
                    Icons.camera_alt,
                    color: AppTheme.primaryColor,
                  ),
                  title: const Text('Take Photo'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImageFromCamera();
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.photo_library,
                    color: AppTheme.primaryColor,
                  ),
                  title: const Text('Choose from Gallery'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImageFromGallery();
                  },
                ),
                if (_selectedImage != null)
                  ListTile(
                    leading: const Icon(
                      Icons.delete,
                      color: Colors.red,
                    ),
                    title: const Text('Remove Photo'),
                    onTap: () {
                      Navigator.pop(context);
                      setState(() {
                        _selectedImage = null;
                      });
                      Helpers.showSnackBar(
                        context,
                        'Photo removed',
                      );
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _submitComplaint() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      String? imagePath;
      String? imageUrl;

      // Upload image if selected
      if (_selectedImage != null) {
        final imageFile = File(_selectedImage!.path);
        final fileSizeInBytes = await imageFile.length();
        const maxSizeInBytes = 5 * 1024 * 1024; // 5MB
        if (fileSizeInBytes > maxSizeInBytes) {
          setState(() => _isLoading = false);
          if (mounted) {
            Helpers.showSnackBar(
              context,
              'Image is too large. Maximum allowed size is 5MB.',
              isError: true,
            );
          }
          return;
        }

        // Create a temporary complaint ID for the image upload
        final tempComplaintId = DateTime.now().millisecondsSinceEpoch.toString();

        final uploadResult = await _storageService.uploadComplaintImage(
          complaintId: tempComplaintId,
          filePath: _selectedImage!.path,
        );

        imagePath = uploadResult['imagePath'];
        imageUrl = uploadResult['imageUrl'];
      }

      // Create complaint in Firestore
      final complaintId = await _firestoreService.createComplaint(
        category: _selectedCategory!,
        description: _descriptionController.text.trim(),
        imagePath: imagePath,
        imageUrl: imageUrl,
        studentId: widget.user.id,
        studentName: widget.user.name,
      );

      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        Helpers.showSnackBar(
          context,
          'Complaint submitted successfully! Your tracking number has been generated.',
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        Helpers.showSnackBar(
          context,
          'Error submitting complaint: ${e.toString()}',
          isError: true,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Submit Complaint'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Describe Your Issue',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Please provide details about your complaint or suggestion',
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 24),

              // Category Dropdown
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  hintText: 'Select a category',
                  prefixIcon: Icon(Icons.category_outlined),
                ),
                items: _categories.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select a category';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Description Field
              TextFormField(
                controller: _descriptionController,
                maxLines: 6,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'Describe the issue in detail...',
                  alignLabelWithHint: true,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please describe your complaint';
                  }
                  if (value.trim().length < 20) {
                    return 'Please provide more details (minimum 20 characters)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Photo Upload Section
              if (_selectedImage != null) ...[
                Card(
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          File(_selectedImage!.path),
                          height: 200,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: CircleAvatar(
                          backgroundColor: Colors.black.withValues(alpha: 0.6),
                          child: IconButton(
                            icon: const Icon(Icons.close, color: Colors.white),
                            onPressed: () {
                              setState(() {
                                _selectedImage = null;
                              });
                              Helpers.showSnackBar(
                                context,
                                'Photo removed',
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Photo Upload Button
              OutlinedButton.icon(
                onPressed: _showImageSourceDialog,
                icon: Icon(
                  _selectedImage != null ? Icons.edit : Icons.camera_alt,
                ),
                label: Text(
                  _selectedImage != null ? 'Change Photo' : 'Add Photo (Optional)',
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
              const SizedBox(height: 32),

              // Submit Button
              ElevatedButton(
                onPressed: _isLoading ? null : _submitComplaint,
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
                        'Submit Complaint',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
