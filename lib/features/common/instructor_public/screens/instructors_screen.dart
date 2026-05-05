import 'package:flutter/material.dart';
import 'package:learnhub/core/navigation/app_routes.dart';
import 'package:learnhub/core/navigation/route_args.dart';
import 'package:learnhub/core/shared_widgets/content_loading_skeleton.dart';
import 'package:learnhub/core/shared_widgets/edu_media.dart';
import 'package:learnhub/core/shared_widgets/empty_state.dart';
import 'package:learnhub/core/shared_widgets/error_retry_state.dart';
import 'package:learnhub/core/theme/app_colors.dart';
import 'package:learnhub/domain/entities/instructor.dart';
import 'package:learnhub/features/course/providers/course_provider.dart';
import 'package:provider/provider.dart';

class InstructorsScreen extends StatefulWidget {
  const InstructorsScreen({super.key, this.category});

  final String? category;

  @override
  State<InstructorsScreen> createState() => _InstructorsScreenState();
}

class _InstructorsScreenState extends State<InstructorsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<CourseProvider>();
      if (provider.courses.isEmpty) {
        provider.loadCourses(showLoading: false);
      }
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
    final dividerColor = isDark
        ? colorScheme.outline.withValues(alpha: 0.4)
        : const Color(AppColors.line);
    final normalizedCategory = widget.category?.trim() ?? '';
    final instructors = normalizedCategory.isEmpty
        ? provider.instructors
        : provider.instructorsForCategory(normalizedCategory);
    final sortedInstructors = List<Instructor>.from(instructors)
      ..sort((a, b) {
        final studentCmp = b.studentCount.compareTo(a.studentCount);
        if (studentCmp != 0) {
          return studentCmp;
        }
        return b.rating.compareTo(a.rating);
      });

    if (provider.isLoading && provider.instructors.isEmpty) {
      return const Scaffold(
        body: SafeArea(
          child: ContentLoadingSkeleton(
            showHeader: false,
            itemCount: 6,
            tileHeight: 72,
          ),
        ),
      );
    }

    if (provider.errorMessage != null && provider.instructors.isEmpty) {
      return Scaffold(
        body: SafeArea(
          child: ErrorRetryState(
            message: provider.errorMessage!,
            onRetry: () async {
              await context.read<CourseProvider>().loadCourses(
                force: true,
                showLoading: false,
              );
              if (!context.mounted) {
                return;
              }
              await context.read<CourseProvider>().loadInstructors(force: true);
            },
          ),
        ),
      );
    }

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
                    normalizedCategory.isEmpty
                        ? 'All Mentors'
                        : '$normalizedCategory Mentors',
                    style: TextStyle(
                      fontSize: 31,
                      fontWeight: FontWeight.w900,
                      color: titleColor,
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
              const SizedBox(height: 10),
              Expanded(
                child: sortedInstructors.isEmpty
                    ? EmptyState(
                        icon: Icons.person_search_rounded,
                        title: normalizedCategory.isEmpty
                            ? 'No instructors yet'
                            : 'No mentors found',
                        subtitle: normalizedCategory.isEmpty
                            ? 'New instructors will appear here as soon as they publish their profiles and courses.'
                            : 'Try another category or clear the current filter to explore more mentors.',
                      )
                    : ListView.separated(
                        itemCount: sortedInstructors.length,
                        separatorBuilder: (context, index) =>
                            Divider(height: 1, color: dividerColor),
                        itemBuilder: (context, index) {
                          final instructor = sortedInstructors[index];

                          return InkWell(
                            borderRadius: BorderRadius.circular(8),
                            onTap: () {
                              Navigator.of(context).pushNamed(
                                AppRoutes.instructorDetails,
                                arguments: InstructorDetailsArgs(
                                  instructor: instructor,
                                ),
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 12,
                                horizontal: 2,
                              ),
                              child: Row(
                                children: [
                                  InstructorAvatar(
                                    imageUrl: instructor.avatarUrl,
                                    instructorName: instructor.name,
                                    size: 44,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          instructor.name,
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w900,
                                            color: titleColor,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
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
                                  Text(
                                    instructor.rating.toStringAsFixed(1),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      color: Color(AppColors.primary),
                                    ),
                                  ),
                                ],
                              ),
                            ),
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
}
