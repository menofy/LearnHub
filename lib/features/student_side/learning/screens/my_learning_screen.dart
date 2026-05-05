import 'package:flutter/material.dart';
import 'package:learnhub/core/navigation/app_routes.dart';
import 'package:learnhub/core/navigation/route_args.dart';
import 'package:learnhub/core/shared_widgets/content_loading_skeleton.dart';
import 'package:learnhub/core/shared_widgets/edu_primary_button.dart';
import 'package:learnhub/core/shared_widgets/empty_state.dart';
import 'package:learnhub/core/shared_widgets/error_retry_state.dart';
import 'package:learnhub/domain/entities/certificate.dart';
import 'package:learnhub/domain/entities/course.dart';
import 'package:learnhub/features/shared/auth/providers/auth_provider.dart';
import 'package:learnhub/features/student_side/learning/widgets/learning_course_tile.dart';
import 'package:learnhub/features/student_side/learning/widgets/learning_screen_header.dart';
import 'package:learnhub/presentation/providers/app_state_provider.dart';
import 'package:learnhub/features/course/providers/course_provider.dart';
import 'package:provider/provider.dart';

class MyLearningScreen extends StatefulWidget {
  const MyLearningScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<MyLearningScreen> createState() => _MyLearningScreenState();
}

class _MyLearningScreenState extends State<MyLearningScreen> {
  bool _completedTab = true;
  String _lastSyncedCompletedSignature = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final courseProvider = context.read<CourseProvider>();
      final userId = context.read<AuthProvider>().currentUser?.id;

      if (courseProvider.courses.isEmpty) {
        courseProvider.loadCourses();
      }
      if (userId != null) {
        courseProvider.loadEnrolledCourses(userId, showLoading: false);
      }
    });
  }

  void _syncCertificatesIfNeeded(List<Course> completedCourses) {
    final signature = completedCourses.map((course) => course.id).join('|');
    if (_lastSyncedCompletedSignature == signature) {
      return;
    }

    _lastSyncedCompletedSignature = signature;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      context.read<AppStateProvider>().syncCertificatesFromCompletedCourses(
        completedCourses,
      );
    });
  }

  void _openCourseDetails(Course course) {
    Navigator.of(context).pushNamed(
      AppRoutes.courseDetails,
      arguments: CourseDetailsArgs(course: course),
    );
  }

  void _openCertificate(Course course, AppStateProvider appState) {
    final certificate =
        appState.certificateForCourseId(course.id) ??
        Certificate(
          id: 'cert_${course.id}',
          courseTitle: course.title,
          issueDate: DateTime.now(),
          grade: 'Completed',
        );

    Navigator.of(context).pushNamed(
      AppRoutes.certificateDetails,
      arguments: CertificateDetailsArgs(certificate: certificate),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CourseProvider>();
    final appState = context.watch<AppStateProvider>();

    if (provider.isLoading && provider.courses.isEmpty) {
      const loading = SafeArea(
        bottom: false,
        child: ContentLoadingSkeleton(itemCount: 5, tileHeight: 100),
      );
      if (widget.embedded) {
        return loading;
      }
      return const Scaffold(body: loading);
    }

    if (provider.errorMessage != null && provider.courses.isEmpty) {
      final error = SafeArea(
        bottom: false,
        child: ErrorRetryState(
          message: provider.errorMessage!,
          onRetry: () =>
              context.read<CourseProvider>().loadCourses(force: true),
        ),
      );
      if (widget.embedded) {
        return error;
      }
      return Scaffold(body: error);
    }

    final completed = provider.completedCourses;
    final ongoing = provider.continueLearningCourses;
    _syncCertificatesIfNeeded(completed);

    final visible = _completedTab
        ? completed
        : (ongoing.isEmpty ? provider.enrolledCourses : ongoing);
    final primaryContinueCourse = ongoing.isEmpty ? null : ongoing.first;

    final content = SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: Column(
          children: [
            LearningScreenHeader(
              showCompleted: _completedTab,
              onSearchTap: () =>
                  Navigator.of(context).pushNamed(AppRoutes.search),
              onCompletedTap: () => setState(() => _completedTab = true),
              onOngoingTap: () => setState(() => _completedTab = false),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: visible.isEmpty
                  ? const EmptyState(
                      icon: Icons.school_outlined,
                      title: 'No enrolled courses yet',
                      subtitle:
                          'Start any course from Home and it will appear here.',
                    )
                  : ListView.separated(
                      itemCount: visible.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final course = visible[index];
                        final progress = provider.progressForCourse(course.id);
                        return LearningCourseTile(
                          course: course,
                          isCompleted: _completedTab,
                          progress: progress,
                          resumeLessonTitle: provider
                              .resumeLessonForCourse(course.id)
                              ?.title,
                          onTap: () => _completedTab
                              ? _openCertificate(course, appState)
                              : _openCourseDetails(course),
                        );
                      },
                    ),
            ),
            if (!_completedTab) ...[
              const SizedBox(height: 8),
              EduPrimaryButton(
                label: 'Continue Courses',
                onPressed: primaryContinueCourse == null
                    ? null
                    : () {
                        Navigator.of(context).pushNamed(
                          AppRoutes.courseDetails,
                          arguments: CourseDetailsArgs(
                            course: primaryContinueCourse,
                          ),
                        );
                      },
              ),
            ],
          ],
        ),
      ),
    );

    if (widget.embedded) {
      return content;
    }

    return Scaffold(body: content);
  }
}
