import 'package:flutter/material.dart';
import 'package:learnhub/core/shared_widgets/content_loading_skeleton.dart';
import 'package:learnhub/core/shared_widgets/edu_primary_button.dart';
import 'package:learnhub/features/instructor/widgets/dashboard_action_card.dart';
import 'package:learnhub/features/instructor/widgets/dashboard_course_card.dart';
import 'package:learnhub/features/instructor/widgets/dashboard_hero_banner.dart';
import 'package:learnhub/features/shared/auth/providers/auth_provider.dart';
import 'package:provider/provider.dart';

import 'package:learnhub/core/navigation/app_routes.dart';
import 'package:learnhub/core/theme/app_colors.dart';
import '../../../data/services/firestore_service.dart';
import '../../../domain/entities/app_user.dart';
import '../../../domain/entities/course.dart';
import 'instructor_shared.dart';

class InstructorDashboardScreen extends StatelessWidget {
  const InstructorDashboardScreen({
    super.key,
    this.embedded = false,
    this.onOpenCreate,
    this.onOpenCourses,
    this.onOpenProfile,
  });

  final bool embedded;
  final VoidCallback? onOpenCreate;
  final VoidCallback? onOpenCourses;
  final VoidCallback? onOpenProfile;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;
    final theme = Theme.of(context);
    final titleColor = instructorTitleColor(context);
    final secondaryText = instructorMutedColor(context);
    if (user == null) {
      // ✅ Use unified skeleton loading
      return const Scaffold(
        body: SafeArea(
          child: ContentLoadingSkeleton(itemCount: 4, tileHeight: 120),
        ),
      );
    }
    if (user.role != AppUserRole.instructor) {
      return Scaffold(
        appBar: AppBar(title: const Text('Instructor Dashboard')),
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

    final handleCreateCourse =
        onOpenCreate ??
        () => Navigator.of(context).pushNamed(AppRoutes.instructorAddCourse);
    final handleOpenCourses =
        onOpenCourses ??
        () => Navigator.of(context).pushNamed(AppRoutes.instructorMyCourses);
    final handleOpenProfile =
        onOpenProfile ?? () => Navigator.of(context).maybePop();

    final page = SafeArea(
      bottom: false,
      child: StreamBuilder<List<Course>>(
        stream: FirestoreService.instance.streamInstructorCourses(user.id),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return ListView(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 110),
              children: const [
                InstructorEmptyState(
                  title: 'Dashboard unavailable',
                  message:
                      'We could not load your instructor workspace right now. Please try again in a moment.',
                  icon: Icons.wifi_off_rounded,
                ),
              ],
            );
          }

          final courses = snapshot.data ?? const <Course>[];
          final isLoading =
              snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData;
          final categoryCount = courses
              .map((course) => course.category.trim())
              .where((category) => category.isNotEmpty)
              .toSet()
              .length;
          final newestCourse = courses.isEmpty ? null : courses.first;
          final publishedCount = courses
              .where((course) => course.isPublished)
              .length;
          final draftCount = courses.length - publishedCount;

          return FutureBuilder<Map<String, int>>(
            future: FirestoreService.instance.getEnrollmentCountsForCourseIds(
              courses.map((course) => course.id),
            ),
            builder: (context, countsSnapshot) {
              final enrollmentCounts =
                  countsSnapshot.data ?? const <String, int>{};
              final totalStudents = enrollmentCounts.values.fold<int>(
                0,
                (sum, value) => sum + value,
              );

              return ListView(
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 110),
                children: [
                  if (isLoading) ...[
                    const LinearProgressIndicator(
                      minHeight: 3,
                      color: Color(AppColors.primary),
                    ),
                    const SizedBox(height: 12),
                  ],
                  Text(
                    'Instructor Workspace',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: titleColor,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Everything you need to create, organize, and publish courses with stronger teaching signals.',
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.55,
                      fontWeight: FontWeight.w700,
                      color: secondaryText,
                    ),
                  ),
                  const SizedBox(height: 18),
                  DashboardHeroBanner(
                    userName: user.name,
                    courseCount: courses.length,
                    latestPublishedLabel: newestCourse == null
                        ? 'Ready for your first launch'
                        : 'Latest: ${instructorFormatDate(newestCourse.createdAt)}',
                    onCreateCourse: handleCreateCourse,
                    onOpenCourses: handleOpenCourses,
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: InstructorMetricCard(
                          label: 'Live Courses',
                          value: '$publishedCount',
                          icon: Icons.play_lesson_rounded,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: InstructorMetricCard(
                          label: 'Learners',
                          value: '$totalStudents',
                          icon: Icons.groups_2_outlined,
                          accentColor: const Color(0xFF7A4BFF),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: InstructorMetricCard(
                          label: 'Categories',
                          value: '$categoryCount',
                          icon: Icons.grid_view_rounded,
                          accentColor: const Color(0xFF4153F4),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: InstructorMetricCard(
                          label: 'Drafts',
                          value: '$draftCount',
                          icon: Icons.edit_note_rounded,
                          accentColor: const Color(0xFFEF8F00),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  const InstructorSectionHeader(
                    title: 'Quick Actions',
                    subtitle:
                        'Move fast between course creation, editing, and your profile setup.',
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: DashboardActionCard(
                          icon: Icons.add_circle_outline_rounded,
                          title: 'Create Course',
                          subtitle: 'Start a new learning product',
                          accent: const Color(AppColors.primary),
                          onTap: handleCreateCourse,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DashboardActionCard(
                          icon: Icons.view_list_rounded,
                          title: 'Manage Library',
                          subtitle: 'Review, edit, and publish content',
                          accent: const Color(0xFF4153F4),
                          onTap: handleOpenCourses,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  DashboardActionCard(
                    icon: Icons.person_outline_rounded,
                    title: 'Profile & Settings',
                    subtitle: 'Polish your instructor identity and workspace.',
                    accent: const Color(0xFF1F3458),
                    onTap: handleOpenProfile,
                  ),
                  const SizedBox(height: 18),
                  InstructorSectionHeader(
                    title: 'Recent Courses',
                    subtitle: courses.isEmpty
                        ? 'Your published work will appear here.'
                        : 'Your latest uploads are ready to review.',
                    actionLabel: courses.isNotEmpty ? 'See All' : null,
                    onAction: courses.isNotEmpty ? handleOpenCourses : null,
                  ),
                  const SizedBox(height: 12),
                  if (courses.isEmpty)
                    InstructorEmptyState(
                      title: 'No courses published yet',
                      message:
                          'Create your first course and it will appear automatically in the student experience under instructor content.',
                      icon: Icons.auto_stories_rounded,
                      action: EduPrimaryButton(
                        label: 'Create First Course',
                        expanded: false,
                        onPressed: handleCreateCourse,
                      ),
                    )
                  else
                    ...courses
                        .take(4)
                        .map(
                          (course) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: DashboardCourseCard(
                              course: course,
                              enrollmentCount: enrollmentCounts[course.id] ?? 0,
                              onManage: handleOpenCourses,
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

    if (embedded) {
      return page;
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Instructor Dashboard'),
        actions: [
          IconButton(
            onPressed: () => context.read<AuthProvider>().logout(),
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      body: page,
    );
  }
}
