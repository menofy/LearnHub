import 'package:flutter/material.dart';
import 'package:learnhub/core/navigation/app_routes.dart';
import 'package:learnhub/core/navigation/route_args.dart';
import 'package:learnhub/core/shared_widgets/content_loading_skeleton.dart';
import 'package:learnhub/core/shared_widgets/edu_search_field.dart';
import 'package:learnhub/core/shared_widgets/error_retry_state.dart';
import 'package:learnhub/core/shared_widgets/section_header.dart';
import 'package:learnhub/domain/entities/app_user.dart';
import 'package:learnhub/domain/entities/course.dart';
import 'package:learnhub/domain/entities/instructor.dart';
import 'package:learnhub/features/home/widgets/home_course_strip_section.dart';
import 'package:learnhub/features/shared/auth/providers/auth_provider.dart';
import 'package:learnhub/features/student_side/home/widgets/home_category_selector.dart';
import 'package:learnhub/features/student_side/home/widgets/home_greeting_header.dart';
import 'package:learnhub/features/student_side/home/widgets/home_learning_focus_card.dart';
import 'package:learnhub/features/student_side/home/widgets/home_new_instructors_section.dart';
import 'package:learnhub/features/student_side/home/widgets/home_promo_carousel.dart';
import 'package:learnhub/features/student_side/home/widgets/home_top_mentors_strip.dart';
import 'package:learnhub/features/shared/providers/app_state_provider.dart';
import 'package:learnhub/features/course/providers/course_provider.dart';
import 'package:learnhub/features/course/widgets/course_card.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _selectedCategory = 'All';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<CourseProvider>();
      if (provider.courses.isEmpty) {
        provider.loadCourses();
      }
      if (provider.instructors.isEmpty) {
        provider.loadInstructors();
      }
    });
  }

  Future<void> _refreshContent() async {
    final provider = context.read<CourseProvider>();
    await provider.loadCourses(force: true);
    await provider.loadInstructors(force: true);
  }

  void _openPopularCourses() {
    Navigator.of(context).pushNamed(
      AppRoutes.popularCourses,
      arguments: CourseCollectionArgs(
        category: _selectedCategory == 'All' ? null : _selectedCategory,
        type: CourseCollectionType.popular,
      ),
    );
  }

  void _openInstructorCourses() {
    Navigator.of(context).pushNamed(
      AppRoutes.popularCourses,
      arguments: CourseCollectionArgs(
        category: _selectedCategory == 'All' ? null : _selectedCategory,
        type: CourseCollectionType.instructor,
      ),
    );
  }

  void _openInstructors() {
    Navigator.of(context).pushNamed(
      AppRoutes.instructors,
      arguments: InstructorsArgs(
        category: _selectedCategory == 'All' ? null : _selectedCategory,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final courseProvider = context.watch<CourseProvider>();
    final authProvider = context.watch<AuthProvider>();
    final unreadNotificationsCount = context.select<AppStateProvider, int>(
      (appState) => appState.unreadNotificationsCount,
    );
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final secondaryTextColor = onSurface.withValues(alpha: 0.7);
    final rawName = authProvider.currentUser?.name.trim() ?? '';
    final userName = rawName.isEmpty ? 'Student' : rawName;
    final hasNoCourses = courseProvider.courses.isEmpty;

    if (courseProvider.isLoading && hasNoCourses) {
      return const SafeArea(
        child: ContentLoadingSkeleton(itemCount: 4, tileHeight: 128),
      );
    }

    if (courseProvider.errorMessage != null && hasNoCourses) {
      return SafeArea(
        child: ErrorRetryState(
          message: courseProvider.errorMessage!,
          onRetry: () async {
            await context.read<CourseProvider>().loadCourses(force: true);
            if (!context.mounted) return;
            await context.read<CourseProvider>().loadInstructors(force: true);
          },
        ),
      );
    }

    final categories = <String>['All', ...courseProvider.categories.take(5)];

    final filteredCourses = _selectedCategory == 'All'
        ? courseProvider.courses
        : courseProvider.courses
              .where((course) => course.category == _selectedCategory)
              .toList();

    final featuredCourses =
        filteredCourses
            .where((course) => course.isAdminCourse)
            .toList(growable: false)
          ..sort((a, b) {
            final ratingCmp = b.rating.compareTo(a.rating);
            if (ratingCmp != 0) return ratingCmp;
            return b.studentCount.compareTo(a.studentCount);
          });

    final visibleFeaturedCourses = featuredCourses
        .take(5)
        .toList(growable: false);

    final instructorCourses =
        filteredCourses
            .where(
              (course) =>
                  !course.isAdminCourse && course.instructorId != 'admin',
            )
            .toList(growable: false)
          ..sort((a, b) {
            final aDate = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            final bDate = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            return bDate.compareTo(aDate);
          });

    final topMentors = courseProvider
        .platformInstructorsForCategory(_selectedCategory)
        .take(8)
        .toList(growable: false);
    final continueCourse = courseProvider.continueLearningCourses.isEmpty
        ? null
        : courseProvider.continueLearningCourses.first;
    final recommendedCourses = courseProvider.recommendedCourses
        .where(
          (course) => _selectedCategory == 'All'
              ? true
              : course.category == _selectedCategory,
        )
        .take(5)
        .toList(growable: false);

    return RefreshIndicator(
      onRefresh: _refreshContent,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        children: [
          const SizedBox(height: 16),
          HomeGreetingHeader(
            userName: userName,
            unreadCount: unreadNotificationsCount,
            onNotificationsTap: () =>
                Navigator.of(context).pushNamed(AppRoutes.notifications),
          ),
          const SizedBox(height: 16),
          EduSearchField(
            readOnly: true,
            onTap: () => Navigator.of(context).pushNamed(AppRoutes.search),
            onFilterTap: () =>
                Navigator.of(context).pushNamed(AppRoutes.search),
          ),
          const SizedBox(height: 15),
          const HomePromoCarousel(),
          if (continueCourse != null) ...[
            const SizedBox(height: 14),
            SectionHeader(
              title: 'Continue Learning',
              actionLabel: 'OPEN',
              onActionTap: () => _openCourseDetails(context, continueCourse),
            ),
            const SizedBox(height: 8),
            HomeLearningFocusCard(
              course: continueCourse,
              progress: courseProvider.progressForCourse(continueCourse.id),
              resumeLessonTitle: courseProvider
                  .resumeLessonForCourse(continueCourse.id)
                  ?.title,
              onTap: () => _openCourseDetails(context, continueCourse),
            ),
          ],
          if (recommendedCourses.isNotEmpty) ...[
            const SizedBox(height: 14),
            SectionHeader(
              title: 'Recommended For You',
              actionLabel: 'SEE ALL',
              onActionTap: () =>
                  Navigator.of(context).pushNamed(AppRoutes.search),
            ),
            const SizedBox(height: 8),
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
                    isBookmarked: courseProvider.isInWishlist(course.id),
                    onBookmarkTap: () => context
                        .read<CourseProvider>()
                        .toggleWishlist(course.id),
                    onTap: () => _openCourseDetails(context, course),
                  );
                },
              ),
            ),
          ],
          const SizedBox(height: 14),
          SectionHeader(
            title: 'Categories',
            actionLabel: 'SEE ALL',
            onActionTap: () =>
                Navigator.of(context).pushNamed(AppRoutes.categories),
          ),
          const SizedBox(height: 8),
          HomeCategorySelector(
            categories: categories,
            selectedCategory: _selectedCategory,
            onSelected: (category) {
              setState(() {
                _selectedCategory = category;
              });
            },
          ),
          const SizedBox(height: 16),
          HomeCourseStripSection(
            title: 'Popular Courses',
            actionLabel: 'SEE ALL',
            onActionTap: _openPopularCourses,
            courses: visibleFeaturedCourses,
            secondaryTextColor: secondaryTextColor,
            emptyMessage: 'No popular courses available in this category.',
            isBookmarked: courseProvider.isInWishlist,
            onBookmarkTap: context.read<CourseProvider>().toggleWishlist,
            onCourseTap: (course) => _openCourseDetails(context, course),
          ),
          const SizedBox(height: 14),
          if (instructorCourses.isNotEmpty) ...[
            HomeCourseStripSection(
              title: 'Instructor Courses',
              actionLabel: 'SEE ALL',
              onActionTap: _openInstructorCourses,
              courses: instructorCourses,
              secondaryTextColor: secondaryTextColor,
              emptyMessage: 'No instructor courses available right now.',
              isBookmarked: courseProvider.isInWishlist,
              onBookmarkTap: context.read<CourseProvider>().toggleWishlist,
              onCourseTap: (course) => _openCourseDetails(context, course),
            ),
            const SizedBox(height: 14),
          ],
          SectionHeader(
            title: 'New Instructors',
            actionLabel: 'SEE ALL',
            onActionTap: _openInstructors,
          ),
          const SizedBox(height: 8),
          HomeNewInstructorsSection(
            secondaryTextColor: secondaryTextColor,
            onInstructorTap: (appUser) {
              Navigator.of(context).pushNamed(
                AppRoutes.instructorDetails,
                arguments: InstructorDetailsArgs(
                  instructor: _resolveInstructorFromUser(
                    courseProvider,
                    appUser,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 14),
          SectionHeader(
            title: 'Top Mentors',
            actionLabel: 'SEE ALL',
            onActionTap: _openInstructors,
          ),
          const SizedBox(height: 8),
          HomeTopMentorsStrip(
            mentors: topMentors,
            secondaryTextColor: secondaryTextColor,
            onTap: (instructor) {
              Navigator.of(context).pushNamed(
                AppRoutes.instructorDetails,
                arguments: InstructorDetailsArgs(instructor: instructor),
              );
            },
          ),
        ],
      ),
    );
  }

  Instructor _resolveInstructorFromUser(
    CourseProvider courseProvider,
    AppUser appUser,
  ) {
    for (final instructor in courseProvider.platformInstructors) {
      if (instructor.id == appUser.id ||
          instructor.name.trim().toLowerCase() ==
              appUser.name.trim().toLowerCase()) {
        return instructor;
      }
    }

    return Instructor(
      id: appUser.id,
      name: appUser.name.isEmpty ? 'Instructor' : appUser.name,
      title: courseProvider.primaryCategoryForInstructor(appUser.name).isEmpty
          ? 'Course Instructor'
          : '${courseProvider.primaryCategoryForInstructor(appUser.name)} Instructor',
      bio: 'New instructor on LearnHub',
      avatarUrl: appUser.photoUrl,
      rating: courseProvider.ratingForInstructor(appUser.name),
      studentCount: 0,
    );
  }

  void _openCourseDetails(BuildContext context, Course course) {
    Navigator.of(context).pushNamed(
      AppRoutes.courseDetails,
      arguments: CourseDetailsArgs(course: course),
    );
  }
}
