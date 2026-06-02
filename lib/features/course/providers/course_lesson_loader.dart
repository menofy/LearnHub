import 'package:learnhub/core/utils/app_error_mapper.dart';
import 'package:learnhub/domain/entities/lesson.dart';
import 'package:learnhub/domain/repositories/course_repository.dart';

/// Handles loading and caching lessons for courses
class CourseLessonLoader {
  CourseLessonLoader({required CourseRepository courseRepository})
    : _courseRepository = courseRepository;

  final CourseRepository _courseRepository;

  final Map<String, List<Lesson>> _lessonsByCourse = <String, List<Lesson>>{};
  final Map<String, Future<void>> _loadingFutures = <String, Future<void>>{};

  List<Lesson> getLessonsByCourse(String courseId) =>
      _lessonsByCourse[courseId] ?? <Lesson>[];

  Iterable<String> getCourseIds() => _lessonsByCourse.keys;

  Future<void> loadLessons({
    required String courseId,
    required bool force,
    required void Function(bool) onLoadingChange,
    required void Function(String?) onErrorChange,
  }) async {
    if (!force && _lessonsByCourse.containsKey(courseId)) {
      return;
    }

    final inFlight = _loadingFutures[courseId];
    if (inFlight != null && !force) {
      return inFlight;
    }

    final future = _loadLessonsInternal(
      courseId: courseId,
      onLoadingChange: onLoadingChange,
      onErrorChange: onErrorChange,
    );
    _loadingFutures[courseId] = future;
    return future.whenComplete(() {
      if (identical(_loadingFutures[courseId], future)) {
        _loadingFutures.remove(courseId);
      }
    });
  }

  Future<void> _loadLessonsInternal({
    required String courseId,
    required void Function(bool) onLoadingChange,
    required void Function(String?) onErrorChange,
  }) async {
    onLoadingChange(true);
    onErrorChange(null);

    try {
      final lessons = await _courseRepository.getLessonsByCourse(courseId);
      final sorted = List<Lesson>.from(lessons)
        ..sort((a, b) => a.order.compareTo(b.order));
      _lessonsByCourse[courseId] = sorted;
    } catch (error) {
      onErrorChange(
        AppErrorMapper.data(error, fallback: 'Could not load lessons.'),
      );
    } finally {
      onLoadingChange(false);
    }
  }

  void clearCache() {
    _lessonsByCourse.clear();
    _loadingFutures.clear();
  }

  void clearCourseCache(String courseId) {
    _lessonsByCourse.remove(courseId);
    _loadingFutures.remove(courseId);
  }
}
