import 'dart:math' show max;

import 'package:learnhub/domain/entities/course.dart';
import 'package:learnhub/domain/entities/instructor.dart';

/// Handles instructor-related operations: hydration, filtering, and merging
class CourseInstructorHelper {
  CourseInstructorHelper({
    required List<Course> Function() courseGetter,
    required double Function(String, {double? explicitRating})
    ratingForInstructor,
  }) : _courseGetter = courseGetter,
       _ratingForInstructor = ratingForInstructor;

  final List<Course> Function() _courseGetter;
  final double Function(String, {double? explicitRating}) _ratingForInstructor;

  List<Course> get _courses => _courseGetter();

  List<Course> coursesForInstructor(String instructorName) {
    final name = instructorName.trim().toLowerCase();
    if (name.isEmpty) {
      return const <Course>[];
    }
    return _courses
        .where((course) => course.instructor.trim().toLowerCase() == name)
        .toList();
  }

  String primaryCategoryForInstructor(String instructorName) {
    final instructorCourses = coursesForInstructor(instructorName);
    if (instructorCourses.isEmpty) {
      return '';
    }

    final frequency = <String, int>{};
    for (final course in instructorCourses) {
      frequency.update(
        course.category,
        (count) => count + 1,
        ifAbsent: () => 1,
      );
    }

    final sorted = frequency.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.first.key;
  }

  List<Instructor> filterByCategory(List<Instructor> source, String category) {
    final normalized = category.trim().toLowerCase();
    if (normalized.isEmpty || normalized == 'all') {
      return List<Instructor>.from(source);
    }

    final instructorNames = _courses
        .where((course) => course.category.trim().toLowerCase() == normalized)
        .map((course) => course.instructor.trim().toLowerCase())
        .toSet();

    return source
        .where(
          (instructor) =>
              instructorNames.contains(instructor.name.trim().toLowerCase()),
        )
        .toList();
  }

  List<Instructor> hydrateInstructors(List<Instructor> source) {
    return source.map(_hydrateInstructor).toList(growable: false);
  }

  Instructor _hydrateInstructor(Instructor instructor) {
    final instructorCourses = coursesForInstructor(instructor.name);
    final primaryCategory = primaryCategoryForInstructor(instructor.name);
    final rawTitle = instructor.title.trim();
    final title =
        rawTitle.isEmpty ||
            rawTitle == 'Course Instructor' ||
            rawTitle == 'Instructor at LearnHub'
        ? (primaryCategory.isNotEmpty
              ? '$primaryCategory Instructor'
              : 'Course Instructor')
        : rawTitle;
    final rawBio = instructor.bio.trim();
    final bio = rawBio.isEmpty || rawBio == 'Instructor at LearnHub'
        ? (instructorCourses.isEmpty
              ? 'New instructor on LearnHub.'
              : 'Published ${instructorCourses.length} course${instructorCourses.length == 1 ? '' : 's'} on LearnHub.')
        : rawBio;

    return Instructor(
      id: instructor.id,
      name: instructor.name,
      title: title,
      bio: bio,
      avatarUrl: instructor.avatarUrl,
      rating: _ratingForInstructor(
        instructor.name,
        explicitRating: instructor.rating,
      ),
      studentCount: max(
        instructor.studentCount,
        instructorCourses.isEmpty ? 0 : instructorCourses.length * 124,
      ),
    );
  }

  String instructorKey(Instructor instructor) {
    final id = instructor.id.trim().toLowerCase();
    if (id.isNotEmpty) {
      return id;
    }
    return instructor.name.trim().toLowerCase();
  }

  List<Instructor> mergeInstructors(
    List<Instructor> platform,
    List<Instructor> fallback,
  ) {
    if (platform.isNotEmpty) {
      return platform;
    }

    final merged = <Instructor>[];
    final seen = <String>{};

    for (final instructor in platform) {
      final key = instructorKey(instructor);
      if (seen.add(key)) {
        merged.add(instructor);
      }
    }

    for (final instructor in hydrateInstructors(fallback)) {
      final key = instructorKey(instructor);
      if (seen.add(key)) {
        merged.add(instructor);
      }
    }

    return merged;
  }

  bool sameInstructorList(List<Instructor> a, List<Instructor> b) {
    if (identical(a, b)) {
      return true;
    }
    if (a.length != b.length) {
      return false;
    }

    for (var index = 0; index < a.length; index++) {
      final left = a[index];
      final right = b[index];
      if (left.id != right.id ||
          left.name != right.name ||
          left.title != right.title ||
          left.bio != right.bio ||
          left.avatarUrl != right.avatarUrl ||
          left.rating != right.rating ||
          left.studentCount != right.studentCount) {
        return false;
      }
    }

    return true;
  }
}
