import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:learnhub/core/shared_widgets/discard_changes_dialog.dart';
import 'package:learnhub/core/shared_widgets/edu_primary_button.dart';
import 'package:learnhub/core/theme/app_colors.dart';
import 'package:learnhub/core/utils/app_error_mapper.dart';
import 'package:learnhub/features/shared/auth/providers/auth_provider.dart';
import 'package:learnhub/features/student_side/profile/widgets/edit_profile_avatar_picker.dart';
import 'package:learnhub/features/student_side/profile/widgets/edit_profile_text_field.dart';
import 'package:provider/provider.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  Uint8List? _selectedImageBytes;
  String? _selectedImageDataUrl;
  String _initialName = '';
  String _initialPhone = '';
  String _initialPhotoUrl = '';
  AutovalidateMode _autovalidateMode = AutovalidateMode.disabled;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUserData();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _loadUserData() {
    final user = context.read<AuthProvider>().currentUser;
    if (user != null) {
      _nameController.text = user.name;
      _emailController.text = user.email;
      _phoneController.text = user.phone;
      _initialName = user.name.trim();
      _initialPhone = user.phone.trim();
      _initialPhotoUrl = user.photoUrl.trim();
    }
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        withData: true,
      );
      if (result == null || result.files.isEmpty) {
        return;
      }

      final picked = result.files.first;
      Uint8List? bytes = picked.bytes;
      if (bytes == null && picked.path != null) {
        bytes = await File(picked.path!).readAsBytes();
      }
      if (bytes == null || bytes.isEmpty) {
        return;
      }

      final ext = (picked.extension ?? '').toLowerCase();
      final mimeType = _mimeTypeFromExt(ext);
      final dataUrl = 'data:$mimeType;base64,${base64Encode(bytes)}';

      setState(() {
        _selectedImageBytes = bytes;
        _selectedImageDataUrl = dataUrl;
      });
      if (!mounted) {
        return;
      }

      final messenger = ScaffoldMessenger.of(context);
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Profile image selected successfully.'),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      final message = AppErrorMapper.external(
        error,
        fallback: 'Could not select this image. Please try another one.',
      );
      final messenger = ScaffoldMessenger.of(context);
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(SnackBar(content: Text(message)));
    }
  }

  void _showProfilePhotoOptions() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Profile Photo'),
        content: const Text('Choose image source'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _pickImageFromGallery();
            },
            child: const Text('Gallery'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveProfile() async {
    FocusScope.of(context).unfocus();
    final isValid = _formKey.currentState!.validate();
    if (!isValid) {
      setState(() {
        _autovalidateMode = AutovalidateMode.onUserInteraction;
      });
      return;
    }
    final name = _nameController.text.trim();

    final auth = context.read<AuthProvider>();
    final current = auth.currentUser;
    if (current == null) {
      return;
    }

    final ok = await auth.updateProfile(
      name: name,
      phone: _phoneController.text.trim(),
      photoUrl: _selectedImageDataUrl ?? current.photoUrl,
    );
    if (!mounted) {
      return;
    }

    if (ok) {
      _initialName = _nameController.text.trim();
      _initialPhone = _phoneController.text.trim();
      _initialPhotoUrl = _selectedImageDataUrl ?? current.photoUrl.trim();
      final messenger = ScaffoldMessenger.of(context);
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(const SnackBar(content: Text('Profile updated.')));
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(content: Text(auth.errorMessage ?? 'Could not update profile.')),
    );
  }

  bool get _hasUnsavedChanges {
    return _nameController.text.trim() != _initialName ||
        _phoneController.text.trim() != _initialPhone ||
        (_selectedImageDataUrl ?? _initialPhotoUrl) != _initialPhotoUrl;
  }

  Future<bool> _confirmExit() async {
    if (!_hasUnsavedChanges || context.read<AuthProvider>().isLoading) {
      return true;
    }
    return showDiscardChangesDialog(
      context,
      message:
          'Your profile edits are not saved yet. Leave this screen and lose those changes?',
    );
  }

  Future<void> _handleBack() async {
    final shouldLeave = await _confirmExit();
    if (!mounted || !shouldLeave) {
      return;
    }
    Navigator.of(context).pop();
  }

  String _mimeTypeFromExt(String ext) {
    switch (ext) {
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      default:
        return 'image/jpeg';
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;

    return PopScope<void>(
      canPop: !auth.isLoading && !_hasUnsavedChanges,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop || auth.isLoading) {
          return;
        }
        final shouldLeave = await _confirmExit();
        if (!mounted || !shouldLeave) {
          return;
        }
        Navigator.of(context).pop();
      },
      child: Scaffold(
        body: SafeArea(
          child: Form(
            key: _formKey,
            autovalidateMode: _autovalidateMode,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              children: [
                if (auth.isLoading) ...[
                  const LinearProgressIndicator(
                    minHeight: 3,
                    color: Color(AppColors.primary),
                  ),
                  const SizedBox(height: 10),
                ],
                Row(
                  children: [
                    IconButton(
                      onPressed: auth.isLoading ? null : _handleBack,
                      icon: const Icon(Icons.arrow_back_rounded),
                    ),
                    const Text(
                      'Edit Profile',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        color: Color(AppColors.primary),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                EditProfileAvatarPicker(
                  user: user,
                  selectedImageBytes: _selectedImageBytes,
                  onTap: auth.isLoading ? null : _showProfilePhotoOptions,
                ),
                const SizedBox(height: 12),
                EditProfileTextField(
                  controller: _nameController,
                  hint: 'Full Name',
                  enabled: !auth.isLoading,
                  textInputAction: TextInputAction.next,
                  onChanged: (_) => setState(() {}),
                  validator: (value) {
                    final text = (value ?? '').trim();
                    if (text.isEmpty) {
                      return 'Name is required.';
                    }
                    if (text.length < 2) {
                      return 'Name should be at least 2 characters.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 10),
                EditProfileTextField(
                  controller: _emailController,
                  hint: 'Email',
                  prefix: Icons.email_outlined,
                  readOnly: true,
                  enabled: !auth.isLoading,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 10),
                EditProfileTextField(
                  controller: _phoneController,
                  hint: 'Phone Number (Optional)',
                  prefix: Icons.phone_outlined,
                  enabled: !auth.isLoading,
                  textInputAction: TextInputAction.done,
                  keyboardType: TextInputType.phone,
                  onChanged: (_) => setState(() {}),
                  validator: (value) {
                    final text = (value ?? '').trim();
                    if (text.isEmpty) {
                      return null;
                    }
                    if (text.length < 7) {
                      return 'Phone number looks too short.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 18),
                EduPrimaryButton(
                  label: 'Update',
                  isLoading: auth.isLoading,
                  onPressed: auth.isLoading ? null : _saveProfile,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
