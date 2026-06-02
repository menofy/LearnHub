import 'package:learnhub/core/utils/app_error_mapper.dart';
import 'package:learnhub/domain/entities/course_review.dart';
import 'package:learnhub/domain/repositories/course_repository.dart';

/// Handles loading and managing course reviews
class CourseReviewHandler {
  CourseReviewHandler({required CourseRepository courseRepository})
    : _courseRepository = courseRepository;

  final CourseRepository _courseRepository;

  final Map<String, List<CourseReview>> _reviewsByCourse =
      <String, List<CourseReview>>{};
  final Map<String, Future<void>> _loadingFutures = <String, Future<void>>{};

  List<CourseReview> getReviewsByCourse(String courseId) =>
      _reviewsByCourse[courseId] ?? <CourseReview>[];

  Future<void> loadReviews({
    required String courseId,
    required bool force,
    required void Function(bool) onLoadingChange,
    required void Function(String?) onErrorChange,
  }) async {
    if (!force && _reviewsByCourse.containsKey(courseId)) {
      return;
    }

    final inFlight = _loadingFutures[courseId];
    if (inFlight != null && !force) {
      return inFlight;
    }

    final future = _loadReviewsInternal(
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

  Future<void> _loadReviewsInternal({
    required String courseId,
    required void Function(bool) onLoadingChange,
    required void Function(String?) onErrorChange,
  }) async {
    onLoadingChange(true);
    onErrorChange(null);

    try {
      final reviews = await _courseRepository.getCourseReviews(courseId);
      _reviewsByCourse[courseId] = reviews;
    } catch (error) {
      onErrorChange(
        AppErrorMapper.data(error, fallback: 'Could not load reviews.'),
      );
    } finally {
      onLoadingChange(false);
    }
  }

  Future<void> addReview({
    required String courseId,
    required String userName,
    required String comment,
    required double rating,
    required void Function(bool) onLoadingChange,
    required void Function(String?) onErrorChange,
  }) async {
    final review = CourseReview(
      id: 'review_${DateTime.now().millisecondsSinceEpoch}',
      courseId: courseId,
      userName: userName,
      comment: comment,
      rating: rating,
      createdAt: DateTime.now(),
    );

    onLoadingChange(true);
    onErrorChange(null);

    try {
      await _courseRepository.addCourseReview(review);
      final current = List<CourseReview>.from(
        _reviewsByCourse[courseId] ?? <CourseReview>[],
      );
      _reviewsByCourse[courseId] = <CourseReview>[review, ...current];
    } catch (error) {
      onErrorChange(
        AppErrorMapper.data(error, fallback: 'Could not submit your review.'),
      );
    } finally {
      onLoadingChange(false);
    }
  }

  void clearCache() {
    _reviewsByCourse.clear();
    _loadingFutures.clear();
  }

  void clearCourseCache(String courseId) {
    _reviewsByCourse.remove(courseId);
    _loadingFutures.remove(courseId);
  }
}
