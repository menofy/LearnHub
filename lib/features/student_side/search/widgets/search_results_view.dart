import 'package:flutter/material.dart';
import 'package:learnhub/core/shared_widgets/empty_state.dart';
import 'package:learnhub/features/course/widgets/course_card.dart';

import '../../../../domain/entities/course.dart';
import '../../../../core/navigation/app_routes.dart';
import '../../../../core/navigation/route_args.dart';

class SearchResultsView extends StatelessWidget {
  const SearchResultsView({
    super.key,
    required this.results,
    required this.isBookmarked,
    required this.onBookmarkTap,
  });

  final List<Course> results;
  final bool Function(String courseId) isBookmarked;
  final ValueChanged<String> onBookmarkTap;

  @override
  Widget build(BuildContext context) {
    if (results.isEmpty) {
      return const EmptyState(
        icon: Icons.search_off_rounded,
        title: 'No results found',
        subtitle: 'Try a different keyword or category.',
      );
    }

    return ListView.separated(
      itemCount: results.length,
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final course = results[index];
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
          isHorizontal: false,
        );
      },
    );
  }
}
