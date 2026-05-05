import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:learnhub/core/utils/app_error_mapper.dart';
import 'package:learnhub/domain/entities/course.dart';
import 'package:learnhub/domain/entities/course_review.dart';
import 'package:learnhub/domain/entities/instructor.dart';
import 'package:learnhub/domain/entities/lesson.dart';
import 'package:learnhub/domain/repositories/course_repository.dart';
import 'package:learnhub/features/course/providers/course_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late _FakeCourseRepository repository;
  late CourseProvider provider;

  const flutterCourse = Course(
    id: 'course-1',
    title: 'Flutter Offline Basics',
    category: 'Flutter',
    instructor: 'Teacher One',
  );

  const designCourse = Course(
    id: 'course-2',
    title: 'Design Essentials',
    category: 'Design',
    instructor: 'Teacher Two',
  );

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    repository = _FakeCourseRepository(
      courses: <Course>[flutterCourse, designCourse],
      instructors: const <Instructor>[
        Instructor(
          id: 'teacher-1',
          name: 'Teacher One',
          title: 'Flutter Instructor',
          bio: 'Builds Flutter lessons.',
          avatarUrl: '',
          rating: 4.8,
          studentCount: 120,
        ),
      ],
    );
    provider = CourseProvider(repository, bindRealtime: false);
  });

  tearDown(() {
    provider.dispose();
  });

  test(
    'loadCourses uses repository data without requiring realtime Firestore',
    () async {
      await provider.loadCourses();

      expect(provider.courses, <Course>[flutterCourse, designCourse]);
      expect(provider.searchResults, <Course>[flutterCourse, designCourse]);
      expect(provider.errorMessage, isNull);
      expect(provider.isLoading, isFalse);
    },
  );

  test('loadCoursesByCategory filters already loaded offline data', () async {
    await provider.loadCourses();

    await provider.loadCoursesByCategory('Flutter');

    expect(provider.searchResults, <Course>[flutterCourse]);
    expect(provider.errorMessage, isNull);
  });

  test('loadCourses maps slow network to timeout message', () async {
    repository.getCoursesError = TimeoutException('slow connection');

    await provider.loadCourses(force: true);

    expect(provider.courses, isEmpty);
    expect(provider.errorMessage, AppErrorMapper.timeout);
    expect(provider.isLoading, isFalse);
  });

  test('loadInstructors maps network errors clearly', () async {
    repository.getInstructorsError = FirebaseException(
      plugin: 'cloud_firestore',
      code: 'unavailable',
    );

    await provider.loadInstructors();

    expect(provider.instructors, isEmpty);
    expect(provider.errorMessage, AppErrorMapper.network);
    expect(provider.isLoading, isFalse);
  });

  test('enrollCourse keeps local enrollment when remote sync fails', () async {
    repository.enrollError = FirebaseException(
      plugin: 'cloud_firestore',
      code: 'unavailable',
    );

    await provider.enrollCourse(userId: 'user-1', courseId: 'course-1');

    expect(provider.isEnrolled('course-1'), isTrue);
    expect(provider.progressForCourse('course-1'), 0);
    expect(
      provider.errorMessage,
      'Enrollment saved locally. It will sync once the connection is stable.',
    );
  });

  test('concurrent course loads reuse the same in-flight request', () async {
    final completer = Completer<List<Course>>();
    repository.getCoursesHandler = () => completer.future;

    final firstLoad = provider.loadCourses();
    final secondLoad = provider.loadCourses(force: true);

    expect(repository.getCoursesCalls, 1);

    completer.complete(<Course>[flutterCourse, designCourse]);
    await Future.wait<void>(<Future<void>>[firstLoad, secondLoad]);

    expect(provider.courses, <Course>[flutterCourse, designCourse]);
  });

  test('concurrent lesson loads reuse the same in-flight request', () async {
    final lessonCompleter = Completer<List<Lesson>>();
    repository.getLessonsHandler = (_) => lessonCompleter.future;

    final firstLoad = provider.loadLessons('course-1');
    final secondLoad = provider.loadLessons('course-1', force: true);

    expect(repository.getLessonsCalls, 1);

    lessonCompleter.complete(const <Lesson>[
      Lesson(
        id: 'lesson-1',
        courseId: 'course-1',
        title: 'Intro',
        videoUrl: 'https://example.com/video.mp4',
        duration: '05:00',
        order: 1,
      ),
    ]);
    await Future.wait<void>(<Future<void>>[firstLoad, secondLoad]);

    expect(provider.lessonsByCourse('course-1'), hasLength(1));
  });
}

class _FakeCourseRepository implements CourseRepository {
  _FakeCourseRepository({
    this.courses = const <Course>[],
    this.instructors = const <Instructor>[],
  });

  final List<Course> courses;
  final List<Instructor> instructors;
  final List<Lesson> lessons = const <Lesson>[];
  final List<CourseReview> reviews = const <CourseReview>[];
  final List<Course> enrolledCourses = const <Course>[];

  Object? getCoursesError;
  Object? getInstructorsError;
  Object? getLessonsError;
  Object? getReviewsError;
  Object? enrollError;
  Object? getEnrolledError;
  int getCoursesCalls = 0;
  int getLessonsCalls = 0;
  Future<List<Course>> Function()? getCoursesHandler;
  Future<List<Lesson>> Function(String courseId)? getLessonsHandler;

  @override
  Future<List<Course>> getCourses() async {
    getCoursesCalls++;
    final error = getCoursesError;
    if (error != null) throw error;
    final handler = getCoursesHandler;
    if (handler != null) {
      return handler();
    }
    return courses;
  }

  @override
  Future<List<Course>> getCoursesByCategory(String category) async {
    final normalized = category.trim().toLowerCase();
    return courses
        .where((course) => course.category.trim().toLowerCase() == normalized)
        .toList(growable: false);
  }

  @override
  Future<List<Course>> searchCourses(String query) async {
    final value = query.trim().toLowerCase();
    if (value.isEmpty) return courses;
    return courses
        .where((course) => course.title.toLowerCase().contains(value))
        .toList(growable: false);
  }

  @override
  Future<List<Lesson>> getLessonsByCourse(String courseId) async {
    getLessonsCalls++;
    final error = getLessonsError;
    if (error != null) throw error;
    final handler = getLessonsHandler;
    if (handler != null) {
      return handler(courseId);
    }
    return lessons;
  }

  @override
  Future<List<Instructor>> getInstructors() async {
    final error = getInstructorsError;
    if (error != null) throw error;
    return instructors;
  }

  @override
  Future<List<CourseReview>> getCourseReviews(String courseId) async {
    final error = getReviewsError;
    if (error != null) throw error;
    return reviews;
  }

  @override
  Future<void> addCourseReview(CourseReview review) async {}

  @override
  Future<void> enrollCourse({
    required String userId,
    required String courseId,
  }) async {
    final error = enrollError;
    if (error != null) throw error;
  }

  @override
  Future<List<Course>> getEnrolledCourses(String userId) async {
    final error = getEnrolledError;
    if (error != null) throw error;
    return enrolledCourses;
  }
}
