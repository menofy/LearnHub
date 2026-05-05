import 'package:flutter/material.dart';

import '../../../../domain/entities/app_user.dart';
import '../../../../domain/entities/instructor.dart';
import 'instructor_edit_profile_button.dart';
import 'instructor_follow_button.dart';
import 'instructor_primary_button.dart';

class InstructorDetailsActionRow extends StatelessWidget {
  const InstructorDetailsActionRow({
    super.key,
    required this.instructor,
    required this.currentUser,
    required this.isOwnProfile,
    required this.isFollowing,
    required this.isLoadingFollowStatus,
    required this.onFollowStateChanged,
    required this.onMessageTap,
  });

  final Instructor instructor;
  final AppUser? currentUser;
  final bool isOwnProfile;
  final bool isFollowing;
  final bool isLoadingFollowStatus;
  final ValueChanged<bool> onFollowStateChanged;
  final VoidCallback onMessageTap;

  @override
  Widget build(BuildContext context) {
    if (isOwnProfile) {
      return const InstructorEditProfileButton();
    }

    return Row(
      children: [
        Expanded(
          child: InstructorFollowButton(
            isFollowing: isFollowing,
            isLoading: isLoadingFollowStatus,
            instructorName: instructor.name,
            instructorId: instructor.id,
            currentUserId: currentUser?.id ?? '',
            currentUserName: currentUser?.name ?? 'User',
            onFollowStateChanged: onFollowStateChanged,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: InstructorPrimaryButton(
            label: 'Message',
            onTap: onMessageTap,
          ),
        ),
      ],
    );
  }
}
