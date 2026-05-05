import 'dart:async';

import '../models/course_model.dart';
import '../models/course_review_model.dart';
import '../models/instructor_model.dart';
import '../models/lesson_model.dart';

class MockDataSource {
  MockDataSource._();

  static final MockDataSource instance = MockDataSource._();

  final Map<String, Set<String>> _enrollments = <String, Set<String>>{};

  final List<CourseReviewModel> _reviews = <CourseReviewModel>[
    CourseReviewModel(
      id: 'review_1',
      courseId: 'course_1',
      userName: 'Ahmed Hassan',
      comment: 'Clear explanations and very practical lessons.',
      rating: 4.8,
      createdAt: DateTime(2026, 2, 3),
    ),
    CourseReviewModel(
      id: 'review_2',
      courseId: 'course_1',
      userName: 'Mariam Ali',
      comment: 'The project structure part was exactly what I needed.',
      rating: 4.6,
      createdAt: DateTime(2026, 2, 10),
    ),
    CourseReviewModel(
      id: 'review_3',
      courseId: 'course_2',
      userName: 'Nour Tarek',
      comment: 'Beautiful UI techniques and useful design systems intro.',
      rating: 4.7,
      createdAt: DateTime(2026, 1, 20),
    ),
    CourseReviewModel(
      id: 'review_4',
      courseId: 'course_3',
      userName: 'Karim Salah',
      comment: 'Good Firebase walkthrough, especially Firestore modeling.',
      rating: 4.5,
      createdAt: DateTime(2026, 3, 4),
    ),
  ];

  static const List<InstructorModel> _instructors = <InstructorModel>[
    InstructorModel(
      id: 'inst_1',
      name: 'Mohamed Adel',
      title: 'Senior Flutter Engineer',
      bio:
          'Builds scalable Flutter apps and mentors students in clean architecture.',
      avatarUrl:
          'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&w=600&q=80',
      rating: 4.9,
      studentCount: 14200,
    ),
    InstructorModel(
      id: 'inst_2',
      name: 'Sara Emad',
      title: 'Product Designer',
      bio:
          'Specialized in mobile UX and turning product ideas into intuitive journeys.',
      avatarUrl:
          'https://images.unsplash.com/photo-1494790108377-be9c29b29330?auto=format&fit=crop&w=600&q=80',
      rating: 4.8,
      studentCount: 9800,
    ),
    InstructorModel(
      id: 'inst_3',
      name: 'Khaled Magdy',
      title: 'Cloud Engineer',
      bio:
          'Teaches Firebase architecture, backend integrations, and app security basics.',
      avatarUrl:
          'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?auto=format&fit=crop&w=600&q=80',
      rating: 4.7,
      studentCount: 7600,
    ),
    InstructorModel(
      id: 'inst_4',
      name: 'Ayman Samir',
      title: 'CS Instructor',
      bio:
          'Focuses on algorithms and data structures for interviews and production thinking.',
      avatarUrl:
          'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?auto=format&fit=crop&w=600&q=80',
      rating: 4.6,
      studentCount: 11300,
    ),
    InstructorModel(
      id: 'inst_5',
      name: 'Laila Youssef',
      title: 'Mobile QA Lead',
      bio:
          'Covers testing strategy, release confidence, and quality-first mindset.',
      avatarUrl:
          'https://images.unsplash.com/photo-1544723795-3fb6469f5b39?auto=format&fit=crop&w=600&q=80',
      rating: 4.8,
      studentCount: 4300,
    ),
  ];

  static const List<CourseModel> _courses = <CourseModel>[
    CourseModel(
      id: 'course_1',
      title: 'Complete Flutter Bootcamp',
      description:
          'Build modern cross-platform apps from scratch with architecture and state management.',
      instructor: 'Mohamed Adel',
      imageUrl:
          'https://images.unsplash.com/photo-1516116216624-53e697fedbea?auto=format&fit=crop&w=1200&q=80',
      category: 'Programming',
      isPopular: true,
      isAdminCourse: true,
      rating: 4.9,
      studentCount: 2850,
      totalHours: 42,
      lessonCount: 64,
      isFree: false,
      price: 99.99,
    ),
    CourseModel(
      id: 'course_2',
      title: 'UI/UX Design Basics',
      description:
          'Design clean, user-focused interfaces in Figma and design systems.',
      instructor: 'Sara Emad',
      imageUrl:
          'https://images.unsplash.com/photo-1586717791821-3f44a563fa4c?auto=format&fit=crop&w=1200&q=80',
      category: 'Design',
      isPopular: true,
      isAdminCourse: true,
      rating: 4.8,
      studentCount: 1920,
      totalHours: 32,
      lessonCount: 48,
      isFree: false,
      price: 79.99,
    ),
    CourseModel(
      id: 'course_3',
      title: 'Firebase for Mobile Apps',
      description:
          'Use Auth, Firestore, and Storage in real projects with best practices.',
      instructor: 'Khaled Magdy',
      imageUrl:
          'https://images.unsplash.com/photo-1555949963-aa79dcee981c?auto=format&fit=crop&w=1200&q=80',
      category: 'Backend',
      isPopular: false,
      isAdminCourse: true,
      rating: 4.7,
      studentCount: 1450,
      totalHours: 28,
      lessonCount: 42,
      isFree: false,
      price: 89.99,
    ),
    CourseModel(
      id: 'course_4',
      title: 'Intro to Data Structures',
      description:
          'Master the core data structures for interviews and app performance.',
      instructor: 'Ayman Samir',
      imageUrl:
          'https://images.unsplash.com/photo-1534751516642-a1af1ef26a56?auto=format&fit=crop&w=1200&q=80',
      category: 'Computer Science',
      isPopular: false,
      isAdminCourse: true,
      rating: 4.6,
      studentCount: 980,
      totalHours: 35,
      lessonCount: 52,
      isFree: false,
      price: 69.99,
    ),
    CourseModel(
      id: 'course_5',
      title: 'Flutter Animations Mastery',
      description:
          'Design delightful interactions, transitions, and advanced motion in Flutter.',
      instructor: 'Mohamed Adel',
      imageUrl:
          'https://images.unsplash.com/photo-1522542550221-31fd19575a2d?auto=format&fit=crop&w=1200&q=80',
      category: 'Programming',
      isPopular: true,
      isAdminCourse: true,
      rating: 4.85,
      studentCount: 1640,
      totalHours: 24,
      lessonCount: 36,
      isFree: false,
      price: 59.99,
    ),
    CourseModel(
      id: 'course_6',
      title: 'Product Thinking for Developers',
      description:
          'Learn user journeys, prioritization, and building features with impact.',
      instructor: 'Sara Emad',
      imageUrl:
          'https://images.unsplash.com/photo-1461749280684-dccba630e2f6?auto=format&fit=crop&w=1200&q=80',
      category: 'Product',
      isPopular: false,
      isAdminCourse: true,
      rating: 4.7,
      studentCount: 720,
      totalHours: 18,
      lessonCount: 27,
      isFree: false,
      price: 49.99,
    ),
    CourseModel(
      id: 'course_7',
      title: 'API Integration in Flutter',
      description:
          'Master REST APIs, error handling, pagination, and repository patterns.',
      instructor: 'Khaled Magdy',
      imageUrl:
          'https://images.unsplash.com/photo-1551288049-bebda4e38f71?auto=format&fit=crop&w=1200&q=80',
      category: 'Backend',
      isPopular: true,
      isAdminCourse: true,
      rating: 4.8,
      studentCount: 2100,
      totalHours: 26,
      lessonCount: 39,
      isFree: false,
      price: 74.99,
    ),
    CourseModel(
      id: 'course_8',
      title: 'Software Testing for Mobile',
      description:
          'Unit, widget, and integration tests for stable production releases.',
      instructor: 'Laila Youssef',
      imageUrl:
          'https://images.unsplash.com/photo-1516321318423-f06f85e504b3?auto=format&fit=crop&w=1200&q=80',
      category: 'Testing',
      isPopular: false,
      isAdminCourse: true,
      rating: 4.65,
      studentCount: 640,
      totalHours: 20,
      lessonCount: 30,
      isFree: false,
      price: 54.99,
    ),
  ];

  static const List<LessonModel> _lessons = <LessonModel>[
    LessonModel(
      id: 'lesson_1',
      courseId: 'course_1',
      title: 'Welcome to Flutter',
      videoUrl: 'https://test-streams.mux.dev/x36xhzz/x36xhzz.m3u8',
      duration: '08:20',
    ),
    LessonModel(
      id: 'lesson_2',
      courseId: 'course_1',
      title: 'Dart Fundamentals',
      videoUrl: 'https://test-streams.mux.dev/test_001/stream.m3u8',
      duration: '12:11',
    ),
    LessonModel(
      id: 'lesson_3',
      courseId: 'course_1',
      title: 'State Management with Provider',
      videoUrl: 'https://test-streams.mux.dev/x36xhzz/x36xhzz.m3u8',
      duration: '14:05',
    ),
    LessonModel(
      id: 'lesson_4',
      courseId: 'course_2',
      title: 'Design Principles',
      videoUrl:
          'https://demo.unified-streaming.com/k8s/features/stable/video/tears-of-steel/tears-of-steel.ism/.m3u8',
      duration: '09:45',
    ),
    LessonModel(
      id: 'lesson_5',
      courseId: 'course_2',
      title: 'Figma Auto Layout',
      videoUrl: 'https://test-streams.mux.dev/x36xhzz/x36xhzz.m3u8',
      duration: '15:10',
    ),
    LessonModel(
      id: 'lesson_6',
      courseId: 'course_3',
      title: 'Firebase Auth Setup',
      videoUrl: 'https://test-streams.mux.dev/test_001/stream.m3u8',
      duration: '11:38',
    ),
    LessonModel(
      id: 'lesson_7',
      courseId: 'course_3',
      title: 'Firestore Data Modeling',
      videoUrl: 'https://test-streams.mux.dev/x36xhzz/x36xhzz.m3u8',
      duration: '13:20',
    ),
    LessonModel(
      id: 'lesson_8',
      courseId: 'course_4',
      title: 'Arrays and Linked Lists',
      videoUrl:
          'https://demo.unified-streaming.com/k8s/features/stable/video/tears-of-steel/tears-of-steel.ism/.m3u8',
      duration: '13:04',
    ),
    LessonModel(
      id: 'lesson_9',
      courseId: 'course_5',
      title: 'Implicit vs Explicit Animations',
      videoUrl: 'https://test-streams.mux.dev/test_001/stream.m3u8',
      duration: '10:42',
    ),
    LessonModel(
      id: 'lesson_10',
      courseId: 'course_6',
      title: 'Problem Framing',
      videoUrl: 'https://test-streams.mux.dev/x36xhzz/x36xhzz.m3u8',
      duration: '07:55',
    ),
    LessonModel(
      id: 'lesson_11',
      courseId: 'course_7',
      title: 'REST API Basics',
      videoUrl: 'https://test-streams.mux.dev/test_001/stream.m3u8',
      duration: '12:15',
    ),
    LessonModel(
      id: 'lesson_12',
      courseId: 'course_8',
      title: 'Unit Testing Fundamentals',
      videoUrl:
          'https://demo.unified-streaming.com/k8s/features/stable/video/tears-of-steel/tears-of-steel.ism/.m3u8',
      duration: '16:33',
    ),
  ];

  Future<List<CourseModel>> getCourses() async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return List<CourseModel>.from(_courses);
  }

  Future<List<CourseModel>> getCoursesByCategory(String category) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    return _courses
        .where(
          (course) =>
              course.category.toLowerCase() == category.trim().toLowerCase(),
        )
        .toList();
  }

  Future<List<CourseModel>> searchCourses(String query) async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    if (query.trim().isEmpty) {
      return List<CourseModel>.from(_courses);
    }
    final lower = query.trim().toLowerCase();
    return _courses
        .where(
          (course) =>
              course.title.toLowerCase().contains(lower) ||
              course.category.toLowerCase().contains(lower) ||
              course.instructor.toLowerCase().contains(lower),
        )
        .toList();
  }

  Future<List<LessonModel>> getLessonsByCourse(String courseId) async {
    await Future<void>.delayed(const Duration(milliseconds: 220));
    return _lessons.where((lesson) => lesson.courseId == courseId).toList();
  }

  Future<List<InstructorModel>> getInstructors() async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    return List<InstructorModel>.from(_instructors);
  }

  Future<List<CourseReviewModel>> getCourseReviews(String courseId) async {
    await Future<void>.delayed(const Duration(milliseconds: 160));
    return _reviews.where((review) => review.courseId == courseId).toList();
  }

  Future<void> addCourseReview(CourseReviewModel review) async {
    await Future<void>.delayed(const Duration(milliseconds: 110));
    _reviews.insert(0, review);
  }

  Future<void> enrollCourse({
    required String userId,
    required String courseId,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 120));
    final enrolledSet = _enrollments.putIfAbsent(userId, () => <String>{});
    enrolledSet.add(courseId);
  }

  Future<List<CourseModel>> getEnrolledCourses(String userId) async {
    await Future<void>.delayed(const Duration(milliseconds: 180));
    final enrolledIds = _enrollments[userId] ?? <String>{};
    return _courses.where((course) => enrolledIds.contains(course.id)).toList();
  }
}
