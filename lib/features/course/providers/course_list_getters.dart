import 'package:learnhub/domain/entities/course.dart';

/// Provides computed course lists based on various criteria
class CourseListProvider {
  CourseListProvider({
    required List<Course> Function() allCourses,
    required Set<String> Function() enrolledIds,
    required Set<String> Function() wishlistIds,
    required List<Course> Function({
      required String query,
      required String? category,
      required String? level,
      required bool excludeEnrolled,
    })
    queryCourses,
    required double Function(String courseId) progressGetter,
    required double Function(String courseId) completionGetter,
    required Map<String, int> Function() lastOpenedAtGetter,
    required Map<String, String> Function() lastLessonGetter,
  }) : _allCourses = allCourses,
       _enrolledIds = enrolledIds,
       _wishlistIds = wishlistIds,
       _queryCourses = queryCourses,
       _progressGetter = progressGetter,
       _completionGetter = completionGetter,
       _lastOpenedAtGetter = lastOpenedAtGetter,
       _lastLessonGetter = lastLessonGetter;

  final List<Course> Function() _allCourses;
  final Set<String> Function() _enrolledIds;
  final Set<String> Function() _wishlistIds;
  final List<Course> Function({
    required String query,
    required String? category,
    required String? level,
    required bool excludeEnrolled,
  })
  _queryCourses;
  final double Function(String courseId) _progressGetter;
  final double Function(String courseId) _completionGetter;
  final Map<String, int> Function() _lastOpenedAtGetter;
  final Map<String, String> Function() _lastLessonGetter;

  List<Course> get topAdminCourses {
    final adminCourses = _allCourses()
        .where((course) => course.isAdminCourse)
        .toList(growable: false);
    adminCourses.sort((a, b) {
      final ratingCmp = b.rating.compareTo(a.rating);
      if (ratingCmp != 0) return ratingCmp;
      return b.studentCount.compareTo(a.studentCount);
    });
    return adminCourses;
  }

  List<Course> get popularCourses =>
      _allCourses().where((course) => course.isPopular).toList();

  List<Course> get recommendedCourses {
    final results = _queryCourses(
      query: '',
      category: null,
      level: null,
      excludeEnrolled: true,
    );
    return results.take(6).toList(growable: false);
  }

  List<Course> get wishlistCourses => _allCourses()
      .where((course) => _wishlistIds().contains(course.id))
      .toList();

  List<Course> get enrolledCourses {
    final enrolled = _enrolledIds();
    final result = _allCourses()
        .where((course) => enrolled.contains(course.id))
        .toList();
    return result;
  }

  List<Course> get continueLearningCourses {
    final learning = enrolledCourses.where((course) {
      final progress = _progressGetter(course.id);
      return progress > 0 && _completionGetter(course.id) < 1;
    }).toList();

    learning.sort((a, b) {
      final lastOpenedMap = _lastOpenedAtGetter();
      final aLastOpened = lastOpenedMap[a.id] ?? 0;
      final bLastOpened = lastOpenedMap[b.id] ?? 0;
      final lastOpenedCmp = bLastOpened.compareTo(aLastOpened);
      if (lastOpenedCmp != 0) {
        return lastOpenedCmp;
      }

      final lastLessonMap = _lastLessonGetter();
      final aHasResume = lastLessonMap.containsKey(a.id);
      final bHasResume = lastLessonMap.containsKey(b.id);
      if (aHasResume != bHasResume) {
        return bHasResume ? 1 : -1;
      }

      final progressCmp = _progressGetter(
        b.id,
      ).compareTo(_progressGetter(a.id));
      if (progressCmp != 0) {
        return progressCmp;
      }

      final aDate =
          a.lastUpdatedAt ??
          a.createdAt ??
          DateTime.fromMillisecondsSinceEpoch(0);
      final bDate =
          b.lastUpdatedAt ??
          b.createdAt ??
          DateTime.fromMillisecondsSinceEpoch(0);
      return bDate.compareTo(aDate);
    });

    return learning;
  }

  List<Course> get completedCourses => enrolledCourses
      .where((course) => _completionGetter(course.id) >= 1)
      .toList();

  List<String> get categories {
    final values = _allCourses()
        .map((course) => course.category)
        .toSet()
        .toList();
    values.sort();
    return values;
  }
}
