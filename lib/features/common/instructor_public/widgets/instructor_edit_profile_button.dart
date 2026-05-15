import 'package:flutter/material.dart';
import 'package:learnhub/domain/entities/instructor.dart';

import '../../../../core/theme/app_colors.dart';
import '../screens/instructor_edit_profile_screen.dart';

/// Edit Profile Button
class InstructorEditProfileButton extends StatelessWidget {
  const InstructorEditProfileButton({super.key, required this.instructor});

  final Instructor instructor;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: const Color(AppColors.primary),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(AppColors.primary).withValues(alpha: 0.25),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) =>
                    InstructorEditProfileScreen(instructor: instructor),
              ),
            );
          },
          child: const Center(
            child: Text(
              'Edit Profile',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                color: Colors.white,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
