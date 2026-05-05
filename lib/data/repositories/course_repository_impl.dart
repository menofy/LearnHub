import 'dart:async';

import '../../domain/entities/course.dart';
import '../../domain/entities/course_review.dart';
import '../../domain/entities/instructor.dart';
import '../../domain/entities/lesson.dart';
import '../../domain/repositories/course_repository.dart';
import '../services/firestore_service.dart';
import '../sources/mock_data_source.dart';
import '../sources/youtube_playlist_data_source.dart';

class CourseRepositoryImpl implements CourseRepository {
  CourseRepositoryImpl({
    MockDataSource? dataSource,
    FirestoreService? firestoreService,
    YoutubePlaylistDataSource? youtubePlaylistDataSource,
  }) : _dataSource = dataSource ?? MockDataSource.instance,
       _firestoreService = firestoreService ?? FirestoreService.instance,
       _youtubePlaylistDataSource =
           youtubePlaylistDataSource ?? YoutubePlaylistDataSource();

  final MockDataSource _dataSource;
  final FirestoreService _firestoreService;
  final YoutubePlaylistDataSource _youtubePlaylistDataSource;
  static const Duration _firstSnapshotTimeout = Duration(seconds: 8);

  @override
  Future<List<Course>> getCourses() async {
    try {
      final firestoreCourses = await _firestoreService
          .streamAllCourses()
          .first
          .timeout(_firstSnapshotTimeout);
      if (firestoreCourses.isNotEmpty) {
        return firestoreCourses;
      }
    } catch (_) {
      // Fall back to bundled demo content when Firestore is slow or offline.
    }
    final models = await _dataSource.getCourses();
    return models.map((model) => model.toEntity()).toList();
  }

  @override
  Future<List<Course>> getCoursesByCategory(String category) async {
    final courses = await getCourses();
    final normalized = category.trim().toLowerCase();
    return courses
        .where((course) => course.category.trim().toLowerCase() == normalized)
        .toList(growable: false);
  }

  @override
  Future<List<Lesson>> getLessonsByCourse(String courseId) async {
    try {
      final course = await _firestoreService.getCourseById(courseId);
      if (course != null) {
        final generated = await _buildLessonsFromCourse(course);
        if (generated.isNotEmpty) {
          return generated;
        }
      }
    } catch (_) {
      // Use local lesson data if the remote course cannot be reached.
    }

    final models = await _dataSource.getLessonsByCourse(courseId);
    return models.map((model) => model.toEntity()).toList();
  }

  @override
  Future<List<Course>> searchCourses(String query) async {
    final courses = await getCourses();
    final value = query.trim().toLowerCase();
    if (value.isEmpty) {
      return courses;
    }
    return courses
        .where((course) {
          return course.title.toLowerCase().contains(value) ||
              course.category.toLowerCase().contains(value) ||
              course.instructor.toLowerCase().contains(value) ||
              course.description.toLowerCase().contains(value);
        })
        .toList(growable: false);
  }

  @override
  Future<List<Instructor>> getInstructors() async {
    try {
      final instructors = await _firestoreService
          .streamInstructors()
          .first
          .timeout(_firstSnapshotTimeout);
      if (instructors.isNotEmpty) {
        return instructors;
      }
    } catch (_) {
      // Fall back to bundled instructors when Firestore is slow or offline.
    }
    final models = await _dataSource.getInstructors();
    return models.map((model) => model.toEntity()).toList();
  }

  @override
  Future<List<CourseReview>> getCourseReviews(String courseId) async {
    try {
      final firestoreReviews = await _firestoreService.getCourseReviews(
        courseId,
      );
      if (firestoreReviews.isNotEmpty) {
        return firestoreReviews;
      }
    } catch (_) {
      // Fall back to demo reviews when offline.
    }
    final models = await _dataSource.getCourseReviews(courseId);
    return models.map((model) => model.toEntity()).toList();
  }

  @override
  Future<void> addCourseReview(CourseReview review) {
    return _firestoreService.addCourseReview(review);
  }

  @override
  Future<void> enrollCourse({
    required String userId,
    required String courseId,
  }) {
    return _firestoreService.enrollCourse(userId: userId, courseId: courseId);
  }

  @override
  Future<List<Course>> getEnrolledCourses(String userId) {
    return _firestoreService.getEnrolledCourses(userId).catchError((_) {
      return const <Course>[];
    });
  }

  Future<List<Lesson>> _buildLessonsFromCourse(Course course) async {
    if (course.usesUploadedVideos) {
      final uploadedLessons = _buildLessonsFromUploadedVideos(course);
      if (uploadedLessons.isNotEmpty) {
        return uploadedLessons;
      }
      if (course.primaryPlayableVideoUrl.trim().isEmpty) {
        return const <Lesson>[];
      }
      return <Lesson>[
        Lesson(
          id: '${course.id}_upload_intro',
          courseId: course.id,
          title: course.title,
          videoUrl: course.primaryPlayableVideoUrl.trim(),
          duration: 'On-demand',
          order: 1,
          sectionTitle: 'Getting Started',
          isPreview: true,
        ),
      ];
    }

    final playlistId = course.playlistId.trim();
    if (playlistId.isNotEmpty) {
      try {
        final items = await _youtubePlaylistDataSource.fetchAllPlaylistItems(
          playlistId: playlistId,
        );
        final lessons = items
            .asMap()
            .entries
            .map(
              (entry) => Lesson(
                id: '${course.id}_${entry.value.videoId}',
                courseId: course.id,
                title: entry.value.title,
                videoUrl:
                    'https://www.youtube.com/watch?v=${entry.value.videoId}',
                duration: entry.value.duration.isNotEmpty
                    ? entry.value.duration
                    : 'YouTube lesson',
                order: entry.key + 1,
                sectionTitle: _sectionTitleForIndex(entry.key),
                isPreview: entry.key < 2,
              ),
            )
            .toList(growable: false);
        if (lessons.isNotEmpty) {
          return lessons;
        }
      } catch (_) {
        // Fall through to direct link fallback.
      }

      return <Lesson>[
        Lesson(
          id: '${course.id}_playlist',
          courseId: course.id,
          title: course.title,
          videoUrl: course.videoUrl.trim(),
          duration: 'Playlist',
          order: 1,
          sectionTitle: 'Getting Started',
          isPreview: true,
        ),
      ];
    }

    final directVideoUrl = course.videoUrl.trim();
    if (!Course.isNetworkVideoUrl(directVideoUrl)) {
      return const <Lesson>[];
    }

    return <Lesson>[
      Lesson(
        id: '${course.id}_intro',
        courseId: course.id,
        title: course.title,
        videoUrl: directVideoUrl,
        duration: 'On-demand',
        order: 1,
        sectionTitle: 'Getting Started',
        isPreview: true,
      ),
    ];
  }

  List<Lesson> _buildLessonsFromUploadedVideos(Course course) {
    final urls = course.playableUploadedVideoUrls;
    if (urls.isEmpty) {
      return const <Lesson>[];
    }

    return urls
        .asMap()
        .entries
        .map(
          (entry) => Lesson(
            id: '${course.id}_upload_${entry.key}',
            courseId: course.id,
            title: _uploadedLessonTitle(entry.value, entry.key),
            videoUrl: entry.value,
            duration: 'On-demand',
            order: entry.key + 1,
            sectionTitle: _sectionTitleForIndex(entry.key),
            isPreview: entry.key < 2,
          ),
        )
        .toList(growable: false);
  }

  String _uploadedLessonTitle(String source, int index) {
    final uri = Uri.tryParse(source);
    final lastSegment = uri != null && uri.pathSegments.isNotEmpty
        ? Uri.decodeComponent(uri.pathSegments.last)
        : '';
    final rawName = lastSegment.trim().isEmpty
        ? 'Lesson ${index + 1}'
        : lastSegment.trim();
    final dotIndex = rawName.lastIndexOf('.');
    final withoutExtension = dotIndex <= 0
        ? rawName
        : rawName.substring(0, dotIndex);
    final normalized = withoutExtension
        .replaceAll(RegExp(r'[_\-]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (normalized.isEmpty) {
      return 'Lesson ${index + 1}';
    }
    return _titleCaseLessonName(normalized);
  }

  String _titleCaseLessonName(String value) {
    final words = value
        .split(' ')
        .map((word) => word.trim())
        .where((word) => word.isNotEmpty)
        .toList(growable: false);
    if (words.isEmpty) {
      return value;
    }

    return words
        .map((word) {
          final lower = word.toLowerCase();
          final firstLetterIndex = lower.indexOf(RegExp(r'[a-z0-9]'));
          if (firstLetterIndex < 0) {
            return word;
          }
          final prefix = word.substring(0, firstLetterIndex);
          final first = lower[firstLetterIndex].toUpperCase();
          final suffix = lower.substring(firstLetterIndex + 1);
          return '$prefix$first$suffix';
        })
        .join(' ');
  }

  String _sectionTitleForIndex(int index) {
    final module = (index ~/ 4) + 1;
    if (module == 1) {
      return 'Getting Started';
    }
    return 'Module $module';
  }
}
