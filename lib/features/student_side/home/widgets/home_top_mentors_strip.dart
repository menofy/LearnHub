import 'package:flutter/material.dart';

import '../../../../domain/entities/instructor.dart';
import 'home_instructor_avatar_tile.dart';

class HomeTopMentorsStrip extends StatelessWidget {
  const HomeTopMentorsStrip({
    super.key,
    required this.mentors,
    required this.secondaryTextColor,
    required this.onTap,
  });

  final List<Instructor> mentors;
  final Color secondaryTextColor;
  final ValueChanged<Instructor> onTap;

  @override
  Widget build(BuildContext context) {
    if (mentors.isEmpty) {
      return SizedBox(
        height: 74,
        child: Center(
          child: Text(
            'No mentor profiles ready yet.',
            style: TextStyle(color: secondaryTextColor, fontSize: 12),
          ),
        ),
      );
    }

    return SizedBox(
      height: 74,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: mentors.length,
        separatorBuilder: (context, index) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final instructor = mentors[index];
          return HomeInstructorAvatarTile(
            name: instructor.name,
            imageUrl: instructor.avatarUrl,
            onTap: () => onTap(instructor),
          );
        },
      ),
    );
  }
}
