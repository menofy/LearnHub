import 'package:flutter/material.dart';
import 'package:learnhub/domain/entities/instructor.dart';
import 'package:learnhub/features/shared/auth/providers/auth_provider.dart';
import 'package:provider/provider.dart';
import 'package:learnhub/core/shared_widgets/edu_primary_button.dart';
import 'package:learnhub/core/theme/app_colors.dart';

class InstructorEditProfileScreen extends StatefulWidget {
  const InstructorEditProfileScreen({super.key, required this.instructor});

  final Instructor instructor;

  @override
  State<InstructorEditProfileScreen> createState() =>
      _InstructorEditProfileScreenState();
}

class _InstructorEditProfileScreenState
    extends State<InstructorEditProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _titleController;
  late TextEditingController _bioController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.instructor.name);
    _titleController = TextEditingController(text: widget.instructor.title);
    _bioController = TextEditingController(text: widget.instructor.bio);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _titleController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    final name = _nameController.text.trim();
    final title = _titleController.text.trim();

    if (name.isEmpty) {
      _showError('Name is required');
      return;
    }

    setState(() => _isSaving = true);

    try {
      final authProvider = context.read<AuthProvider>();

      // Update profile with name and phone (extended phone field for title)
      final success = await authProvider.updateProfile(
        name: name,
        phone: title, // Store title in phone field for now
        photoUrl: null,
      );

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );
        Navigator.of(context).pop();
      } else {
        _showError(authProvider.errorMessage ?? 'Failed to update profile');
      }
    } catch (e) {
      _showError('Error: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar Preview
            Center(
              child: CircleAvatar(
                radius: 60,
                backgroundImage: NetworkImage(widget.instructor.avatarUrl),
                onBackgroundImageError: (exception, stackTrace) {},
              ),
            ),
            const SizedBox(height: 24),

            // Name Field
            Text(
              'Name',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                hintText: 'Enter your name',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 18),

            // Title Field
            Text(
              'Professional Title',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                hintText: 'e.g., Senior Software Engineer',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 18),

            // Bio Field
            Text(
              'Bio',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _bioController,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: 'Write a brief bio about yourself',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Additional Info Cards
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? colorScheme.surface : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark
                      ? colorScheme.outline.withValues(alpha: 0.5)
                      : const Color(AppColors.line),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${widget.instructor.studentCount}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Students',
                            style: TextStyle(
                              fontSize: 12,
                              color: colorScheme.onSurface.withValues(alpha: 0.65),
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${widget.instructor.rating}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(
                                Icons.star_rounded,
                                size: 12,
                                color: Color(0xFFFFC83D),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Rating',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: colorScheme.onSurface.withValues(alpha: 0.65),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Save Button
            SizedBox(
              width: double.infinity,
              child: EduPrimaryButton(
                label: _isSaving ? 'Saving...' : 'Save Changes',
                onPressed: _isSaving ? null : _saveProfile,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
