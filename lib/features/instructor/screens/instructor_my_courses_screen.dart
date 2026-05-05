import 'package:flutter/material.dart';
import 'package:learnhub/core/shared_widgets/content_loading_skeleton.dart';
import 'package:learnhub/core/shared_widgets/edu_primary_button.dart';
import 'package:learnhub/features/instructor/widgets/my_courses_management_card.dart';
import 'package:learnhub/features/instructor/widgets/my_courses_summary_tile.dart';
import 'package:learnhub/features/shared/auth/providers/auth_provider.dart';
import 'package:provider/provider.dart';

import 'package:learnhub/core/navigation/app_routes.dart';
import '../../../core/navigation/route_args.dart';
import 'package:learnhub/core/theme/app_colors.dart';
import '../../../data/services/firestore_service.dart';
import '../../../domain/entities/app_user.dart';
import '../../../domain/entities/course.dart';
import 'instructor_shared.dart';

class InstructorMyCoursesScreen extends StatefulWidget {
  const InstructorMyCoursesScreen({
    super.key,
    this.embedded = false,
    this.onCreateCourse,
  });

  final bool embedded;
  final VoidCallback? onCreateCourse;

  @override
  State<InstructorMyCoursesScreen> createState() =>
      _InstructorMyCoursesScreenState();
}

class _InstructorMyCoursesScreenState extends State<InstructorMyCoursesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  String _statusFilter = 'All';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _confirmDelete(Course course) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete course?'),
          content: Text(
            '“${course.title}” will be removed from the instructor library and student view.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(AppColors.danger),
              ),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) {
      return;
    }

    try {
      await FirestoreService.instance.deleteCourse(course.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('“${course.title}” deleted successfully.')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not delete this course right now.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    final theme = Theme.of(context);
    final titleColor = instructorTitleColor(context);
    final secondaryText = instructorMutedColor(context);
    if (user == null) {
      // ✅ Use unified skeleton loading
      return const Scaffold(
        body: SafeArea(
          child: ContentLoadingSkeleton(itemCount: 4, tileHeight: 128),
        ),
      );
    }
    if (user.role != AppUserRole.instructor) {
      return Scaffold(
        appBar: AppBar(title: const Text('My Courses')),
        body: Center(
          child: Text(
            'This section is available for instructors only.',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: secondaryText,
            ),
          ),
        ),
      );
    }

    final page = SafeArea(
      bottom: false,
      child: StreamBuilder<List<Course>>(
        stream: FirestoreService.instance.streamInstructorCourses(user.id),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return ListView(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 110),
              children: [
                InstructorEmptyState(
                  title: 'Unable to load courses',
                  message:
                      'Your instructor library could not be loaded right now. Try again in a moment.',
                  icon: Icons.cloud_off_rounded,
                  action: EduPrimaryButton(
                    label: 'Create Course',
                    expanded: false,
                    onPressed: _handleCreateCourse,
                  ),
                ),
              ],
            );
          }

          final courses = snapshot.data ?? const <Course>[];
          final filteredCourses = courses.where((course) {
            if (_statusFilter == 'Published' && !course.isPublished) {
              return false;
            }
            if (_statusFilter == 'Drafts' && course.isPublished) {
              return false;
            }
            if (_query.isEmpty) {
              return true;
            }
            final q = _query.toLowerCase();
            return course.title.toLowerCase().contains(q) ||
                course.category.toLowerCase().contains(q) ||
                course.description.toLowerCase().contains(q);
          }).toList();

          final publishedCount = courses
              .where((course) => course.isPublished)
              .length;
          final draftCount = courses.length - publishedCount;

          return FutureBuilder<Map<String, int>>(
            future: FirestoreService.instance.getEnrollmentCountsForCourseIds(
              filteredCourses.map((course) => course.id),
            ),
            builder: (context, countsSnapshot) {
              final enrollmentCounts =
                  countsSnapshot.data ?? const <String, int>{};
              final totalEnrollments = enrollmentCounts.values.fold<int>(
                0,
                (sum, value) => sum + value,
              );

              return ListView(
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 110),
                children: [
                  Text(
                    'My Courses',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: titleColor,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Review, edit, and organize every course with visibility and enrollment context.',
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.55,
                      fontWeight: FontWeight.w700,
                      color: secondaryText,
                    ),
                  ),
                  const SizedBox(height: 18),
                  InstructorSurfaceCard(
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: MyCourseSummaryTile(
                                label: 'All Courses',
                                value: '${courses.length}',
                                icon: Icons.auto_stories_rounded,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: MyCourseSummaryTile(
                                label: 'Published',
                                value: '$publishedCount',
                                icon: Icons.public_rounded,
                                accentColor: const Color(0xFF17A36B),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: MyCourseSummaryTile(
                                label: 'Drafts',
                                value: '$draftCount',
                                icon: Icons.edit_note_rounded,
                                accentColor: const Color(0xFF4153F4),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: MyCourseSummaryTile(
                                label: 'Students',
                                value: '$totalEnrollments',
                                icon: Icons.groups_2_outlined,
                                accentColor: const Color(0xFF7A4BFF),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: MyCourseSummaryTile(
                                label: 'Filtered',
                                value: '${filteredCourses.length}',
                                icon: Icons.filter_alt_outlined,
                                accentColor: const Color(0xFFEF8F00),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _searchController,
                          onChanged: (value) =>
                              setState(() => _query = value.trim()),
                          decoration: instructorInputDecoration(
                            context: context,
                            label: 'Search library',
                            hint: 'Search by title, category, or description',
                            icon: Icons.search_rounded,
                            suffixIcon: _query.isEmpty
                                ? const Icon(Icons.tune_rounded)
                                : IconButton(
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() => _query = '');
                                    },
                                    icon: const Icon(Icons.close_rounded),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: ['All', 'Published', 'Drafts']
                              .map(
                                (status) => ChoiceChip(
                                  label: Text(status),
                                  selected: _statusFilter == status,
                                  onSelected: (_) =>
                                      setState(() => _statusFilter = status),
                                  backgroundColor: instructorInsetColor(
                                    context,
                                  ),
                                  selectedColor: const Color(
                                    AppColors.primary,
                                  ).withValues(alpha: 0.18),
                                  side: BorderSide(
                                    color: _statusFilter == status
                                        ? const Color(AppColors.primary)
                                        : instructorBorderColor(context),
                                  ),
                                  labelStyle: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    color: _statusFilter == status
                                        ? const Color(AppColors.primary)
                                        : titleColor,
                                  ),
                                ),
                              )
                              .toList(growable: false),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  InstructorSectionHeader(
                    title: 'Course Library',
                    subtitle: filteredCourses.isEmpty
                        ? 'Nothing matched your current search.'
                        : 'Showing ${filteredCourses.length} item${filteredCourses.length == 1 ? '' : 's'}.',
                    actionLabel: 'Create',
                    onAction: _handleCreateCourse,
                  ),
                  const SizedBox(height: 12),
                  if (courses.isEmpty)
                    InstructorEmptyState(
                      title: 'Your library is still empty',
                      message:
                          'As soon as you publish your first course, it will appear here and in the student app automatically.',
                      icon: Icons.library_add_check_rounded,
                      action: EduPrimaryButton(
                        label: 'Create Course',
                        expanded: false,
                        onPressed: _handleCreateCourse,
                      ),
                    )
                  else if (filteredCourses.isEmpty)
                    const InstructorEmptyState(
                      title: 'No results found',
                      message:
                          'Try another keyword or clear the current search to see all of your courses again.',
                      icon: Icons.manage_search_rounded,
                    )
                  else
                    ...filteredCourses.map(
                      (course) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: MyCourseManagementCard(
                          course: course,
                          enrollmentCount: enrollmentCounts[course.id] ?? 0,
                          onEdit: () {
                            Navigator.of(context).pushNamed(
                              AppRoutes.instructorEditCourse,
                              arguments: InstructorCourseEditorArgs(
                                course: course,
                              ),
                            );
                          },
                          onDelete: () => _confirmDelete(course),
                        ),
                      ),
                    ),
                ],
              );
            },
          );
        },
      ),
    );

    if (widget.embedded) {
      return page;
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(title: const Text('My Courses')),
      body: page,
    );
  }

  void _handleCreateCourse() {
    if (widget.onCreateCourse != null) {
      widget.onCreateCourse!();
      return;
    }
    Navigator.of(context).pushNamed(AppRoutes.instructorAddCourse);
  }
}
