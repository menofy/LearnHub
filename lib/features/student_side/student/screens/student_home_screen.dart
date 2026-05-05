import 'package:flutter/material.dart';
import 'package:learnhub/core/shared_widgets/category_chip.dart';
import 'package:learnhub/core/shared_widgets/content_loading_skeleton.dart';
import 'package:learnhub/core/shared_widgets/edu_search_field.dart';
import 'package:learnhub/core/theme/app_colors.dart';
import 'package:learnhub/data/services/firestore_service.dart';
import 'package:learnhub/domain/entities/course.dart';
import 'package:learnhub/features/shared/auth/providers/auth_provider.dart';
import 'package:learnhub/features/student_side/student/widgets/student_course_tile.dart';
import 'package:learnhub/features/student_side/student/widgets/student_empty_section.dart';
import 'package:learnhub/features/student_side/student/widgets/student_error_state.dart';
import 'package:learnhub/features/student_side/student/widgets/student_section_count_header.dart';
import 'package:provider/provider.dart';

class StudentHomeScreen extends StatefulWidget {
  const StudentHomeScreen({super.key});

  @override
  State<StudentHomeScreen> createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends State<StudentHomeScreen> {
  String _selectedCategory = 'All';

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    final colorScheme = Theme.of(context).colorScheme;
    final secondaryText = colorScheme.onSurface.withValues(alpha: 0.7);

    return SafeArea(
      child: StreamBuilder<List<Course>>(
        stream: FirestoreService.instance.streamAllCourses(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            // ✅ Use unified skeleton loading
            return const ContentLoadingSkeleton(itemCount: 4, tileHeight: 128);
          }
          if (snapshot.hasError) {
            return StudentErrorState(
              message: 'Could not load courses. Pull to retry.',
              onRetry: () => setState(() {}),
            );
          }

          final allCourses = snapshot.data ?? const <Course>[];
          final categories = <String>{
            'All',
            ...allCourses
                .map((course) => course.category)
                .where((item) => item.isNotEmpty),
          }.toList();
          final categoryFiltered = _selectedCategory == 'All'
              ? allCourses
              : allCourses
                    .where((course) => course.category == _selectedCategory)
                    .toList();
          final topCourses = categoryFiltered
              .where((course) => course.isAdminCourse)
              .toList(growable: false);
          final newCourses = categoryFiltered
              .where((course) => !course.isAdminCourse)
              .toList(growable: false);

          return RefreshIndicator(
            onRefresh: () async => setState(() {}),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              children: [
                // Header with gradient background
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color(AppColors.primary).withValues(alpha: 0.1),
                        const Color(AppColors.primary).withValues(alpha: 0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hi, ${user?.name ?? 'Student'}',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Explore the latest playlists from admin and instructors.',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: secondaryText,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const SizedBox(height: 14),
                EduSearchField(
                  readOnly: true,
                  onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Search is available in full module.'),
                    ),
                  ),
                  onFilterTap: () {},
                ),
                const SizedBox(height: 14),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: categories
                        .map(
                          (category) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: CategoryChip(
                              label: category,
                              isSelected: _selectedCategory == category,
                              onTap: () =>
                                  setState(() => _selectedCategory = category),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
                const SizedBox(height: 16),
                StudentSectionCountHeader(
                  title: 'Top Courses',
                  count: topCourses.length,
                ),
                const SizedBox(height: 8),
                if (topCourses.isEmpty)
                  const StudentEmptySection(
                    text: 'No admin courses in this category yet.',
                  )
                else
                  ...topCourses.map(
                    (course) => StudentCourseTile(course: course),
                  ),
                const SizedBox(height: 12),
                StudentSectionCountHeader(
                  title: 'New Courses',
                  count: newCourses.length,
                ),
                const SizedBox(height: 8),
                if (newCourses.isEmpty)
                  const StudentEmptySection(text: 'No instructor courses yet.')
                else
                  ...newCourses.map(
                    (course) => StudentCourseTile(course: course),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
