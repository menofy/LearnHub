import 'package:learnhub/domain/entities/course.dart';

enum CourseSortOption { recommended, newest, rating, learners, priceLowToHigh }

class CourseQuery {
  const CourseQuery._();

  static List<Course> filterAndSort({
    required List<Course> courses,
    required Set<String> enrolledCourseIds,
    required Iterable<Course> preferenceSources,
    required Set<String> wishlistCourseIds,
    required String query,
    String? category,
    String? level,
    CourseSortOption sort = CourseSortOption.recommended,
    bool excludeEnrolled = false,
  }) {
    final normalizedQuery = query.trim().toLowerCase();
    final normalizedCategory = (category ?? '').trim().toLowerCase();
    final normalizedLevel = (level ?? '').trim().toLowerCase();

    final results = courses
        .where((course) {
          if (!course.isPublished) {
            return false;
          }
          if (excludeEnrolled && enrolledCourseIds.contains(course.id)) {
            return false;
          }
          if (normalizedCategory.isNotEmpty &&
              normalizedCategory != 'all' &&
              course.category.trim().toLowerCase() != normalizedCategory) {
            return false;
          }
          if (normalizedLevel.isNotEmpty &&
              normalizedLevel != 'all levels' &&
              course.level.trim().toLowerCase() != normalizedLevel) {
            return false;
          }
          if (normalizedQuery.isEmpty) {
            return true;
          }
          return _courseMatchesQuery(course, normalizedQuery);
        })
        .toList(growable: false);

    final sorted = List<Course>.from(results);
    sorted.sort(
      (a, b) => _compareCourses(
        a,
        b,
        sort,
        normalizedQuery,
        preferenceSources,
        wishlistCourseIds,
      ),
    );
    return sorted;
  }

  static bool _courseMatchesQuery(Course course, String query) {
    final haystack = <String>[
      course.title,
      course.category,
      course.instructor,
      course.description,
      course.level,
      ...course.tags,
      ...course.outcomes,
    ].join(' ').toLowerCase();
    return haystack.contains(query);
  }

  static int _compareCourses(
    Course a,
    Course b,
    CourseSortOption sort,
    String normalizedQuery,
    Iterable<Course> preferenceSources,
    Set<String> wishlistCourseIds,
  ) {
    switch (sort) {
      case CourseSortOption.newest:
        return _compareDateThenTitle(a, b);
      case CourseSortOption.rating:
        return b.rating.compareTo(a.rating);
      case CourseSortOption.learners:
        return b.studentCount.compareTo(a.studentCount);
      case CourseSortOption.priceLowToHigh:
        return a.price.compareTo(b.price);
      case CourseSortOption.recommended:
        final scoreA = _recommendationScore(
          a,
          normalizedQuery,
          preferenceSources,
          wishlistCourseIds,
        );
        final scoreB = _recommendationScore(
          b,
          normalizedQuery,
          preferenceSources,
          wishlistCourseIds,
        );
        final scoreCmp = scoreB.compareTo(scoreA);
        if (scoreCmp != 0) {
          return scoreCmp;
        }
        return _compareDateThenTitle(a, b);
    }
  }

  static int _compareDateThenTitle(Course a, Course b) {
    final aDate =
        a.lastUpdatedAt ??
        a.createdAt ??
        DateTime.fromMillisecondsSinceEpoch(0);
    final bDate =
        b.lastUpdatedAt ??
        b.createdAt ??
        DateTime.fromMillisecondsSinceEpoch(0);
    final dateCmp = bDate.compareTo(aDate);
    if (dateCmp != 0) {
      return dateCmp;
    }
    return a.title.toLowerCase().compareTo(b.title.toLowerCase());
  }

  static double _recommendationScore(
    Course course,
    String normalizedQuery,
    Iterable<Course> preferenceSources,
    Set<String> wishlistCourseIds,
  ) {
    final preferredCategories = <String, int>{};
    final preferredTags = <String, int>{};

    for (final source in preferenceSources) {
      preferredCategories.update(
        source.category.trim().toLowerCase(),
        (value) => value + 1,
        ifAbsent: () => 1,
      );
      for (final tag in source.tags) {
        preferredTags.update(
          tag.trim().toLowerCase(),
          (value) => value + 1,
          ifAbsent: () => 1,
        );
      }
    }

    var score = 0.0;
    score += course.rating * 14;
    score += (course.studentCount / 75).clamp(0, 26);

    final categoryKey = course.category.trim().toLowerCase();
    score += (preferredCategories[categoryKey] ?? 0) * 18;

    for (final tag in course.tags) {
      score += (preferredTags[tag.trim().toLowerCase()] ?? 0) * 6;
    }

    if (course.isAdminCourse) {
      score += 4;
    }

    if (wishlistCourseIds.contains(course.id)) {
      score += 8;
    }

    if (normalizedQuery.isNotEmpty) {
      if (course.title.toLowerCase().contains(normalizedQuery)) {
        score += 32;
      }
      if (course.category.toLowerCase().contains(normalizedQuery)) {
        score += 14;
      }
      if (course.description.toLowerCase().contains(normalizedQuery)) {
        score += 10;
      }
      if (course.tags.any(
        (tag) => tag.toLowerCase().contains(normalizedQuery),
      )) {
        score += 10;
      }
    }

    return score;
  }
}
