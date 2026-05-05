import 'package:flutter/material.dart';
import 'package:learnhub/core/shared_widgets/content_loading_skeleton.dart';
import 'package:learnhub/core/shared_widgets/edu_media.dart';
import 'package:learnhub/core/shared_widgets/empty_state.dart';
import 'package:learnhub/core/shared_widgets/error_retry_state.dart';
import 'package:learnhub/features/course/providers/course_provider.dart';
import 'package:learnhub/features/course/widgets/course_card.dart';
import 'package:provider/provider.dart';

import 'package:learnhub/core/navigation/app_routes.dart';
import '../../../core/navigation/route_args.dart';
import 'package:learnhub/core/theme/app_colors.dart';
import '../../../domain/entities/course.dart';
import '../../../domain/entities/instructor.dart';
import 'widgets/category_filter_bottom_sheet.dart';
import 'widgets/category_tab_switcher.dart';

class CategoryCoursesScreen extends StatefulWidget {
  const CategoryCoursesScreen({super.key, required this.category});

  final String category;

  @override
  State<CategoryCoursesScreen> createState() => _CategoryCoursesScreenState();
}

class _CategoryCoursesScreenState extends State<CategoryCoursesScreen> {
  bool _showCourses = true;
  String _sortBy = 'relevance';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<CourseProvider>();
      provider.loadCoursesByCategory(widget.category);
      if (provider.instructors.isEmpty) {
        provider.loadInstructors();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CourseProvider>();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final titleColor = colorScheme.onSurface;
    final subtitleColor = colorScheme.onSurface.withValues(alpha: 0.64);
    final sortedCourses = _sortedCourses(provider.searchResults);
    final categoryInstructors = provider.instructorsForCategory(
      widget.category,
    );
    final activeResultsCount = _showCourses
        ? sortedCourses.length
        : categoryInstructors.length;
    final shouldShowLoading =
        provider.isLoading &&
        ((_showCourses && sortedCourses.isEmpty) ||
            (!_showCourses && categoryInstructors.isEmpty));

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
                    'Online Courses',
                    style: TextStyle(
                      fontSize: 31,
                      fontWeight: FontWeight.w900,
                      color: titleColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                height: 50,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: isDark ? colorScheme.surface : Colors.white,
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(
                    color: isDark
                        ? colorScheme.outline.withValues(alpha: 0.55)
                        : Colors.transparent,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: isDark ? 0.16 : 0.03,
                      ),
                      blurRadius: isDark ? 18 : 8,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(Icons.search_rounded, size: 21, color: subtitleColor),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.category,
                        style: TextStyle(
                          color: subtitleColor,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: _openFilterSheet,
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: const Color(AppColors.primary),
                        ),
                        child: const Icon(
                          Icons.tune_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isDark
                      ? colorScheme.surface
                      : const Color(AppColors.chip),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isDark
                        ? colorScheme.outline.withValues(alpha: 0.42)
                        : Colors.transparent,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: CategoryTabSwitcher(
                        label: 'Courses',
                        active: _showCourses,
                        onTap: () => setState(() => _showCourses = true),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: CategoryTabSwitcher(
                        label: 'Mentors',
                        active: !_showCourses,
                        onTap: () => setState(() => _showCourses = false),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Text(
                    'Result for "${widget.category}"',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: titleColor,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '$activeResultsCount RESULTS',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: Color(AppColors.primary),
                    ),
                  ),
                  const SizedBox(width: 2),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: Color(AppColors.primary),
                    size: 16,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Expanded(
                child: shouldShowLoading
                    ? const ContentLoadingSkeleton(
                        itemCount: 5,
                        showHeader: false,
                        tileHeight: 100,
                      )
                    : _buildResults(
                        provider,
                        sortedCourses,
                        categoryInstructors,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResults(
    CourseProvider provider,
    List<Course> sortedCourses,
    List<Instructor> categoryInstructors,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final titleColor = colorScheme.onSurface;
    final subtitleColor = colorScheme.onSurface.withValues(alpha: 0.64);
    final hasNoResults = _showCourses
        ? sortedCourses.isEmpty
        : categoryInstructors.isEmpty;

    if (hasNoResults && provider.errorMessage != null) {
      return ErrorRetryState(
        message: provider.errorMessage!,
        onRetry: () {
          provider.loadCoursesByCategory(widget.category);
          if (provider.instructors.isEmpty) {
            provider.loadInstructors();
          }
        },
      );
    }

    if (hasNoResults) {
      return EmptyState(
        icon: _showCourses
            ? Icons.play_lesson_outlined
            : Icons.person_search_rounded,
        title: _showCourses ? 'No courses found' : 'No mentors found',
        subtitle: _showCourses
            ? 'Try another category or adjust filters.'
            : 'Try another category.',
      );
    }

    if (_showCourses) {
      return ListView.separated(
        itemCount: sortedCourses.length,
        separatorBuilder: (context, index) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final course = sortedCourses[index];
          return CourseCard(
            course: course,
            isBookmarked: provider.isInWishlist(course.id),
            onBookmarkTap: () => provider.toggleWishlist(course.id),
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

    return ListView.separated(
      itemCount: categoryInstructors.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final instructor = categoryInstructors[index];
        return InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            Navigator.of(context).pushNamed(
              AppRoutes.instructorDetails,
              arguments: InstructorDetailsArgs(instructor: instructor),
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            decoration: BoxDecoration(
              color: isDark ? colorScheme.surface : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark
                    ? colorScheme.outline.withValues(alpha: 0.55)
                    : Colors.transparent,
              ),
            ),
            child: Row(
              children: [
                InstructorAvatar(
                  imageUrl: instructor.avatarUrl,
                  instructorName: instructor.name,
                  size: 34,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        instructor.name,
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          color: titleColor,
                        ),
                      ),
                      Text(
                        instructor.title,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: subtitleColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _openFilterSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return CategoryFilterBottomSheet(
          currentSortBy: _sortBy,
          onSortChanged: (value) => setState(() => _sortBy = value),
          onClear: () => setState(() => _sortBy = 'relevance'),
          onApply: () {},
        );
      },
    );
  }

  List<Course> _sortedCourses(List<Course> courses) {
    final data = List<Course>.from(courses);
    if (_sortBy == 'title') {
      data.sort((a, b) => a.title.compareTo(b.title));
    } else if (_sortBy == 'popular') {
      data.sort((a, b) => (b.isPopular ? 1 : 0).compareTo(a.isPopular ? 1 : 0));
    }
    return data;
  }
}
