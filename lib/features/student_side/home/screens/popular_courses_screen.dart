import 'package:flutter/material.dart';
import 'package:learnhub/core/navigation/app_routes.dart';
import 'package:learnhub/core/navigation/route_args.dart';
import 'package:learnhub/core/shared_widgets/category_chip.dart';
import 'package:learnhub/core/shared_widgets/content_loading_skeleton.dart';
import 'package:learnhub/core/shared_widgets/error_retry_state.dart';
import 'package:learnhub/domain/entities/course.dart';
import 'package:learnhub/features/course/providers/course_provider.dart';
import 'package:learnhub/features/course/widgets/course_card.dart';
import 'package:provider/provider.dart';

class PopularCoursesScreen extends StatefulWidget {
  const PopularCoursesScreen({
    super.key,
    this.initialCategory,
    this.collectionType = CourseCollectionType.popular,
  });

  final String? initialCategory;
  final CourseCollectionType collectionType;

  @override
  State<PopularCoursesScreen> createState() => _PopularCoursesScreenState();
}

class _PopularCoursesScreenState extends State<PopularCoursesScreen> {
  String _selected = 'All';

  @override
  void initState() {
    super.initState();
    final initialCategory = widget.initialCategory?.trim() ?? '';
    if (initialCategory.isNotEmpty) {
      _selected = initialCategory;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<CourseProvider>();
      if (provider.courses.isEmpty) {
        provider.loadCourses();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CourseProvider>();
    final colorScheme = Theme.of(context).colorScheme;
    if (provider.isLoading && provider.courses.isEmpty) {
      return const Scaffold(
        body: SafeArea(
          child: ContentLoadingSkeleton(itemCount: 6, tileHeight: 100),
        ),
      );
    }

    if (provider.errorMessage != null && provider.courses.isEmpty) {
      return Scaffold(
        body: SafeArea(
          child: ErrorRetryState(
            message: provider.errorMessage!,
            onRetry: () =>
                context.read<CourseProvider>().loadCourses(force: true),
          ),
        ),
      );
    }

    final allCourses = _allCoursesForType(provider);
    final categories = <String>{
      'All',
      if (widget.initialCategory != null &&
          widget.initialCategory!.trim().isNotEmpty)
        widget.initialCategory!.trim(),
      ...allCourses.map((course) => course.category),
    }.toList();

    final visible = _selected == 'All'
        ? allCourses
        : allCourses.where((course) => course.category == _selected).toList();

    final title = widget.collectionType == CourseCollectionType.instructor
        ? 'Instructor Courses'
        : 'Popular Courses';
    final emptyMessage =
        widget.collectionType == CourseCollectionType.instructor
        ? 'No instructor courses available in this category.'
        : 'No popular courses available in this category.';

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Column(
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 31,
                      fontWeight: FontWeight.w900,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () =>
                        Navigator.of(context).pushNamed(AppRoutes.search),
                    icon: const Icon(Icons.search_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              SizedBox(
                height: 34,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: categories.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final category = categories[index];
                    return CategoryChip(
                      label: category,
                      isSelected: _selected == category,
                      onTap: () => setState(() => _selected = category),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: visible.isEmpty
                    ? Center(
                        child: Text(
                          emptyMessage,
                          style: TextStyle(
                            color: colorScheme.onSurface.withValues(
                              alpha: 0.72,
                            ),
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      )
                    : ListView.separated(
                        itemCount: visible.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final course = visible[index];
                          return CourseCard(
                            course: course,
                            isBookmarked: provider.isInWishlist(course.id),
                            onBookmarkTap: () => context
                                .read<CourseProvider>()
                                .toggleWishlist(course.id),
                            onTap: () {
                              Navigator.of(context).pushNamed(
                                AppRoutes.courseDetails,
                                arguments: CourseDetailsArgs(course: course),
                              );
                            },
                            isHorizontal: false,
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Course> _allCoursesForType(CourseProvider provider) {
    final courses = widget.collectionType == CourseCollectionType.instructor
        ? provider.courses
              .where(
                (course) =>
                    !course.isAdminCourse && course.instructorId != 'admin',
              )
              .toList(growable: false)
        : provider.courses
              .where((course) => course.isAdminCourse)
              .toList(growable: false);

    courses.sort((a, b) {
      if (widget.collectionType == CourseCollectionType.instructor) {
        final aDate = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bDate = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bDate.compareTo(aDate);
      }

      final ratingCmp = b.rating.compareTo(a.rating);
      if (ratingCmp != 0) {
        return ratingCmp;
      }
      return b.studentCount.compareTo(a.studentCount);
    });

    return courses;
  }
}
