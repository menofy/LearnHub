import 'package:flutter/material.dart';
import 'package:learnhub/core/shared_widgets/edu_media.dart';

class HomeInstructorAvatarTile extends StatelessWidget {
  const HomeInstructorAvatarTile({
    super.key,
    required this.name,
    this.imageUrl = '',
    required this.onTap,
  });

  final String name;
  final String imageUrl;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final safeName = name.trim().isEmpty ? 'Instructor' : name.trim();

    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Column(
        children: [
          InstructorAvatar(
            imageUrl: imageUrl,
            instructorName: safeName,
            size: 44,
          ),
          const SizedBox(height: 4),
          SizedBox(
            width: 52,
            child: Text(
              safeName.split(' ').first,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700)
                  .copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
