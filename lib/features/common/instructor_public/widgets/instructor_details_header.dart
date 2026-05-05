import 'package:flutter/material.dart';

class InstructorDetailsHeader extends StatelessWidget {
  const InstructorDetailsHeader({
    super.key,
    required this.isOwnProfile,
    required this.onBack,
    required this.onSettingsTap,
  });

  final bool isOwnProfile;
  final VoidCallback onBack;
  final VoidCallback onSettingsTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 8),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          const Spacer(),
          if (isOwnProfile)
            IconButton(
              onPressed: onSettingsTap,
              icon: const Icon(Icons.settings_rounded),
            ),
        ],
      ),
    );
  }
}
