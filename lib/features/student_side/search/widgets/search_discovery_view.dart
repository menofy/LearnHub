import 'package:flutter/material.dart';
import 'package:learnhub/features/course/widgets/course_card.dart';

import '../../../../domain/entities/course.dart';
import '../../../../core/navigation/app_routes.dart';
import '../../../../core/navigation/route_args.dart';
import '../../../../core/theme/app_colors.dart';

class SearchDiscoveryView extends StatelessWidget {
  const SearchDiscoveryView({
    super.key,
    required this.recommendedCourses,
    required this.recentSearches,
    required this.isDark,
    required this.secondaryText,
    required this.isBookmarked,
    required this.onBookmarkTap,
    required this.onRecentTap,
    required this.onRemoveRecent,
    required this.onClearRecents,
  });

  final List<Course> recommendedCourses;
  final List<String> recentSearches;
  final bool isDark;
  final Color secondaryText;
  final bool Function(String courseId) isBookmarked;
  final ValueChanged<String> onBookmarkTap;
  final ValueChanged<String> onRecentTap;
  final ValueChanged<String> onRemoveRecent;
  final VoidCallback onClearRecents;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ListView(
      children: [
        if (recommendedCourses.isNotEmpty) ...[
          Row(
            children: [
              Text(
                'Recommended For You',
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Spacer(),
              Text(
                '${recommendedCourses.length} courses',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: secondaryText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 240,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: recommendedCourses.length,
              separatorBuilder: (context, index) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final course = recommendedCourses[index];
                return CourseCard(
                  course: course,
                  isBookmarked: isBookmarked(course.id),
                  onBookmarkTap: () => onBookmarkTap(course.id),
                  onTap: () {
                    Navigator.of(context).pushNamed(
                      AppRoutes.courseDetails,
                      arguments: CourseDetailsArgs(course: course),
                    );
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 18),
        ],
        Row(
          children: [
            Text(
              'Recents Search',
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w900,
              ),
            ),
            const Spacer(),
            TextButton(
              onPressed: onClearRecents,
              child: const Text(
                'CLEAR ALL',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  color: Color(AppColors.primary),
                ),
              ),
            ),
          ],
        ),
        ...recentSearches.map((item) {
          return InkWell(
            onTap: () => onRecentTap(item),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 9),
              child: Row(
                children: [
                  Text(
                    item,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? colorScheme.onSurface.withValues(alpha: 0.88)
                          : Colors.black.withValues(alpha: 0.35),
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => onRemoveRecent(item),
                    child: Icon(
                      Icons.close_rounded,
                      size: 16,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}
