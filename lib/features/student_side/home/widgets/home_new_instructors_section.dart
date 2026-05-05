import 'package:flutter/material.dart';

import '../../../../data/services/firestore_service.dart';
import '../../../../domain/entities/app_user.dart';
import 'home_instructor_avatar_tile.dart';

class HomeNewInstructorsSection extends StatelessWidget {
  const HomeNewInstructorsSection({
    super.key,
    required this.secondaryTextColor,
    required this.onInstructorTap,
  });

  final Color secondaryTextColor;
  final void Function(AppUser appUser) onInstructorTap;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<AppUser>>(
      stream: FirestoreService.instance.streamInstructorsFromUsers(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SizedBox(
            height: 74,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: 4,
              separatorBuilder: (context, index) =>
                  const SizedBox(width: 10),
              itemBuilder: (context, index) {
                return SizedBox(
                  width: 52,
                  child: Column(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.grey[300],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        width: 40,
                        height: 8,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          color: Colors.grey[300],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        }

        if (snapshot.hasError) {
          return SizedBox(
            height: 74,
            child: Center(
              child: Text(
                'Unable to load instructors right now.',
                style: TextStyle(color: secondaryTextColor, fontSize: 12),
              ),
            ),
          );
        }

        final instructors = snapshot.data ?? const <AppUser>[];

        if (instructors.isEmpty) {
          return SizedBox(
            height: 74,
            child: Center(
              child: Text(
                'No instructors joined yet.',
                style: TextStyle(color: secondaryTextColor, fontSize: 12),
              ),
            ),
          );
        }

        return SizedBox(
          height: 74,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: instructors.length > 8 ? 8 : instructors.length,
            separatorBuilder: (context, index) =>
                const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final appUser = instructors[index];
              return HomeInstructorAvatarTile(
                name: appUser.name,
                imageUrl: appUser.photoUrl,
                onTap: () => onInstructorTap(appUser),
              );
            },
          ),
        );
      },
    );
  }
}
