import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../domain/entities/app_user.dart';
import 'profile_avatar.dart';

class EditProfileAvatarPicker extends StatelessWidget {
  const EditProfileAvatarPicker({
    super.key,
    required this.user,
    required this.selectedImageBytes,
    required this.onTap,
  });

  final AppUser? user;
  final Uint8List? selectedImageBytes;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF1A8C7F), width: 2),
            ),
            clipBehavior: Clip.antiAlias,
            child: selectedImageBytes != null
                ? Image.memory(selectedImageBytes!, fit: BoxFit.cover)
                : _buildSavedAvatar(),
          ),
          Positioned(
            right: -2,
            bottom: 8,
            child: InkWell(
              onTap: onTap,
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: const Color(AppColors.bg),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF1A8C7F)),
                ),
                child: const Icon(
                  Icons.camera_alt_rounded,
                  size: 14,
                  color: Color(0xFF1A8C7F),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSavedAvatar() {
    if (user == null) {
      return const Icon(
        Icons.person_rounded,
        size: 40,
        color: Color(0xFF1A8C7F),
      );
    }

    return ProfileAvatar(
      user: user!,
      textColor: const Color(0xFF1A8C7F),
      iconColor: const Color(0xFF1A8C7F),
      fontSize: 32,
      iconSize: 40,
    );
  }
}
