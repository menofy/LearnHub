import 'dart:async';
import 'dart:convert';
import 'dart:math' show max;

import 'package:flutter/foundation.dart';
import 'package:learnhub/core/utils/app_error_mapper.dart';
import 'package:learnhub/data/services/firestore_service.dart';
import 'package:learnhub/domain/entities/certificate.dart';
import 'package:learnhub/domain/entities/course.dart';
import 'package:learnhub/domain/entities/course_review.dart';
import 'package:learnhub/domain/entities/instructor.dart';
import 'package:learnhub/domain/entities/lesson.dart';
import 'package:learnhub/domain/entities/user_learning_state.dart';
import 'package:learnhub/domain/repositories/course_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum CourseSortOption { recommended, newest, rating, learners, priceLowToHigh }

class CourseProvider extends ChangeNotifier {
  CourseProvider(this._courseRepository, {bool bindRealtime = true})
    : _bindRealtime = bindRealtime {
    _restorePrefs();
  }

  final CourseRepository _courseRepository;
  final bool _bindRealtime;

  final Map<String, List<Lesson>> _lessonsByCourse = <String, List<Lesson>>{};
  final Map<String, List<CourseReview>> _reviewsByCourse =
      <String, List<CourseReview>>{};
  final Map<String, Set<String>> _completedLessonsByCourse =
      <String, Set<String>>{};
  final Map<String, Set<int>> _completedLessonIndexesByCourse =
      <String, Set<int>>{};
  final Map<String, String> _lessonNotes = <String, String>{};
  final Map<String, String> _lastLessonByCourse = <String, String>{};
  final Map<String, int> _lastWatchedLessonIndexByCourse = <String, int>{};
  final Map<String, int> _lastOpenedAtByCourse = <String, int>{};
  final Map<String, List<String>> _courseDiscussions = <String, List<String>>{};

  List<Course> _courses = <Course>[];
  List<Course> _searchResults = <Course>[];
  List<Instructor> _fallbackInstructors = <Instructor>[];
  List<Instructor> _platformInstructors = <Instructor>[];

  Set<String> _enrolledCourseIds = <String>{};
  Set<String> _wishlistCourseIds = <String>{};
  Set<String> _downloadedLessonIds = <String>{};
  final Map<String, double> _progressByCourse = <String, double>{};
  final Map<String, double> _watchedPercentByCourse = <String, double>{};

  bool _isLoading = false;
  String? _errorMessage;
  bool _hasBootstrapped = false;
  String? _lastLoadedUserId;
  String _localStateUserKey = 'guest';
  SharedPreferences? _prefs;
  StreamSubscription<List<Course>>? _coursesSubscription;
  StreamSubscription<List<Instructor>>? _instructorsSubscription;
  Future<void>? _loadCoursesFuture;
  Future<void>? _loadInstructorsFuture;
  final Map<String, Future<void>> _enrolledCoursesFutures =
      <String, Future<void>>{};
  final Map<String, Future<void>> _loadLessonsFutures =
      <String, Future<void>>{};
  final Map<String, Future<void>> _loadCourseReviewsFutures =
      <String, Future<void>>{};
  bool _realtimeBound = false;
  Timer? _pendingRemoteSyncTimer;

  static const _kEnrolled = 'course_enrolled_ids';
  static const _kWishlist = 'course_wishlist_ids';
  static const _kDownloaded = 'course_downloaded_lesson_ids';
  static const _kProgress = 'course_progress_map';
  static const _kWatchedPercent = 'course_watched_percent_map';
  static const _kCompleted = 'course_completed_lessons_map';
  static const _kCompletedIndexes = 'course_completed_lesson_indexes_map';
  static const _kNotes = 'course_lesson_notes_map';
  static const _kLastLesson = 'course_last_lesson_map';
  static const _kLastWatchedIndex = 'course_last_watched_lesson_index_map';
  static const _kLastOpenedAt = 'course_last_opened_at_map';

  List<Course> get courses => _courses;
  List<Course> get searchResults => _searchResults;
  List<Instructor> get instructors => _mergedInstructors;
  List<Instructor> get platformInstructors =>
      _hydrateInstructors(_platformInstructors);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // ✅ NEW: Get admin/featured courses sorted by rating
  List<Course> get topAdminCourses {
    final adminCourses = _courses
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
      _courses.where((course) => course.isPopular).toList();

  List<Course> get recommendedCourses => queryCourses(
    query: '',
    sort: CourseSortOption.recommended,
    excludeEnrolled: true,
  ).take(6).toList(growable: false);

  List<Course> get wishlistCourses => _courses
      .where((course) => _wishlistCourseIds.contains(course.id))
      .toList();

  List<Course> get enrolledCourses {
    final result = _courses
        .where((course) => _enrolledCourseIds.contains(course.id))
        .toList();
    print('📚 enrolledCourses getter called: _courses=${_courses.length}, _enrolledCourseIds=${_enrolledCourseIds.length}, result=${result.length}');
    if (result.isEmpty && _enrolledCourseIds.isNotEmpty) {
      print('⚠️⚠️⚠️ PROBLEM: IDs registered but courses not in _courses! IDs: $_enrolledCourseIds');
      print('📊 Available course IDs: ${_courses.map((c) => c.id).toList()}');
    }
    return result;
  }

  List<Course> get continueLearningCourses =>
      enrolledCourses.where((course) {
        final progress = progressForCourse(course.id);
        return progress > 0 && _completionProgressForCourse(course.id) < 1;
      }).toList()..sort((a, b) {
        final aLastOpened = _lastOpenedAtByCourse[a.id] ?? 0;
        final bLastOpened = _lastOpenedAtByCourse[b.id] ?? 0;
        final lastOpenedCmp = bLastOpened.compareTo(aLastOpened);
        if (lastOpenedCmp != 0) {
          return lastOpenedCmp;
        }
        final aHasResume = _lastLessonByCourse.containsKey(a.id);
        final bHasResume = _lastLessonByCourse.containsKey(b.id);
        if (aHasResume != bHasResume) {
          return bHasResume ? 1 : -1;
        }
        final progressCmp = progressForCourse(
          b.id,
        ).compareTo(progressForCourse(a.id));
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

  List<Course> get completedCourses => enrolledCourses
      .where((course) => _completionProgressForCourse(course.id) >= 1)
      .toList();

  List<String> get categories {
    final values = _courses.map((course) => course.category).toSet().toList();
    values.sort();
    return values;
  }

  List<Course> coursesForInstructor(String instructorName) {
    final name = instructorName.trim().toLowerCase();
    if (name.isEmpty) {
      return const <Course>[];
    }
    return _courses
        .where((course) => course.instructor.trim().toLowerCase() == name)
        .toList();
  }

  List<Instructor> instructorsForCategory(String category) {
    return _filterInstructorsByCategory(instructors, category);
  }

  List<Instructor> platformInstructorsForCategory(String category) {
    return _filterInstructorsByCategory(platformInstructors, category);
  }

  double ratingForInstructor(String instructorName, {double? explicitRating}) {
    final normalizedExplicitRating = explicitRating ?? 0;
    if (normalizedExplicitRating > 0) {
      return normalizedExplicitRating;
    }

    final instructorCourses = coursesForInstructor(instructorName);
    if (instructorCourses.isEmpty) {
      return 0;
    }

    final totalRating = instructorCourses.fold<double>(
      0,
      (sum, course) => sum + course.rating,
    );
    final average = totalRating / instructorCourses.length;
    return double.parse(average.toStringAsFixed(1));
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

  bool isEnrolled(String courseId) => _enrolledCourseIds.contains(courseId);

  bool isInWishlist(String courseId) => _wishlistCourseIds.contains(courseId);

  bool isLessonDownloaded(String lessonId) =>
      _downloadedLessonIds.contains(lessonId);

  double progressForCourse(String courseId) {
    final completion = _completionProgressForCourse(courseId);
    final watched = _watchedPercentByCourse[courseId] ?? 0;
    return watched > completion ? watched : completion;
  }

  double watchedPercentForCourse(String courseId) =>
      _watchedPercentByCourse[courseId] ?? 0;

  List<Lesson> lessonsByCourse(String courseId) =>
      _lessonsByCourse[courseId] ?? <Lesson>[];

  List<CourseReview> reviewsByCourse(String courseId) =>
      _reviewsByCourse[courseId] ?? <CourseReview>[];

  List<String> discussionByCourse(String courseId) =>
      _courseDiscussions[courseId] ?? <String>[];

  String noteForLesson(String lessonId) => _lessonNotes[lessonId] ?? '';
  String? lastLessonIdForCourse(String courseId) =>
      _lastLessonByCourse[courseId];
  int? lastWatchedLessonIndexForCourse(String courseId) =>
      _lastWatchedLessonIndexByCourse[courseId];
  DateTime? lastOpenedAtForCourse(String courseId) {
    final value = _lastOpenedAtByCourse[courseId];
    if (value == null || value <= 0) {
      return null;
    }
    return DateTime.fromMillisecondsSinceEpoch(value);
  }

  bool isLessonCompleted(String courseId, String lessonId) {
    return _completedLessonsByCourse[courseId]?.contains(lessonId) ?? false;
  }

  int completedLessonsCountForCourse(String courseId) {
    final completedIdsCount = _completedLessonsByCourse[courseId]?.length ?? 0;
    final completedIndexesCount =
        _completedLessonIndexesByCourse[courseId]?.length ?? 0;
    return completedIdsCount > completedIndexesCount
        ? completedIdsCount
        : completedIndexesCount;
  }

  Set<int> completedLessonIndexesForCourse(String courseId) {
    return <int>{...?_completedLessonIndexesByCourse[courseId]};
  }

  Lesson? resumeLessonForCourse(String courseId) {
    final lessons = lessonsByCourse(courseId);
    if (lessons.isEmpty) {
      return null;
    }

    final lastLessonId = _lastLessonByCourse[courseId];
    if (lastLessonId != null) {
      for (final lesson in lessons) {
        if (lesson.id == lastLessonId) {
          return lesson;
        }
      }
    }

    final lastWatchedIndex = _lastWatchedLessonIndexByCourse[courseId];
    if (lastWatchedIndex != null &&
        lastWatchedIndex >= 0 &&
        lastWatchedIndex < lessons.length) {
      return lessons[lastWatchedIndex];
    }

    final completedIndexes = _completedLessonIndexesByCourse[courseId];
    for (var index = 0; index < lessons.length; index++) {
      final lesson = lessons[index];
      if (!isLessonCompleted(courseId, lesson.id) &&
          !(completedIndexes?.contains(index) ?? false)) {
        return lesson;
      }
    }

    return lessons.first;
  }

  Future<void> loadInitialData({String? userId}) async {
    _ensureRealtimeBindings();
    final normalizedUserId = userId?.trim();
    final userChanged = _lastLoadedUserId != normalizedUserId;

    if (userChanged) {
      await _restoreLocalStateForUser(normalizedUserId);
      if (normalizedUserId != null) {
        await _mergeRemoteStateForUser(normalizedUserId);
      }
      _hasBootstrapped = false;
    }

    if (_hasBootstrapped && _lastLoadedUserId == userId) {
      return;
    }

    final bootTasks = <Future<void>>[
      if (_courses.isEmpty) loadCourses(showLoading: false),
      if (_platformInstructors.isEmpty && _fallbackInstructors.isEmpty)
        loadInstructors(showLoading: false),
      if (normalizedUserId != null)
        loadEnrolledCourses(normalizedUserId, showLoading: false),
    ];

    if (bootTasks.isEmpty) {
      _hasBootstrapped = true;
      _lastLoadedUserId = normalizedUserId;
      return;
    }

    _setLoading(true);
    await Future.wait<void>(bootTasks);
    _hasBootstrapped = true;
    _lastLoadedUserId = normalizedUserId;
    _setLoading(false);
  }

  Future<void> _restorePrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _prefs = prefs;
    } catch (_) {
      _prefs = null;
    }
  }

  Future<void> _restoreLocalStateForUser(String? userId) async {
    _localStateUserKey = _normalizeUserStorageKey(userId);
    _clearInMemoryLocalState();
    final SharedPreferences prefs;
    try {
      prefs = _prefs ?? await SharedPreferences.getInstance();
      _prefs = prefs;
    } catch (_) {
      notifyListeners();
      return;
    }

    try {
      _enrolledCourseIds =
          (prefs.getStringList(_scopedKey(_kEnrolled)) ?? <String>[]).toSet();
      _wishlistCourseIds =
          (prefs.getStringList(_scopedKey(_kWishlist)) ?? <String>[]).toSet();
      _downloadedLessonIds =
          (prefs.getStringList(_scopedKey(_kDownloaded)) ?? <String>[]).toSet();

      final progressRaw = prefs.getString(_scopedKey(_kProgress));
      if (progressRaw != null && progressRaw.isNotEmpty) {
        final parsed = jsonDecode(progressRaw) as Map<String, dynamic>;
        _progressByCourse
          ..clear()
          ..addAll(
            parsed.map(
              (key, value) => MapEntry(key, (value as num).toDouble()),
            ),
          );
      }

      final watchedPercentRaw = prefs.getString(_scopedKey(_kWatchedPercent));
      if (watchedPercentRaw != null && watchedPercentRaw.isNotEmpty) {
        final parsed = jsonDecode(watchedPercentRaw) as Map<String, dynamic>;
        _watchedPercentByCourse
          ..clear()
          ..addAll(
            parsed.map(
              (key, value) => MapEntry(key, (value as num).toDouble()),
            ),
          );
      }

      final completedRaw = prefs.getString(_scopedKey(_kCompleted));
      if (completedRaw != null && completedRaw.isNotEmpty) {
        final parsed = jsonDecode(completedRaw) as Map<String, dynamic>;
        _completedLessonsByCourse
          ..clear()
          ..addAll(
            parsed.map(
              (key, value) => MapEntry(
                key,
                (value as List<dynamic>).map((item) => item.toString()).toSet(),
              ),
            ),
          );
      }

      final completedIndexesRaw = prefs.getString(
        _scopedKey(_kCompletedIndexes),
      );
      if (completedIndexesRaw != null && completedIndexesRaw.isNotEmpty) {
        final parsed = jsonDecode(completedIndexesRaw) as Map<String, dynamic>;
        _completedLessonIndexesByCourse
          ..clear()
          ..addAll(
            parsed.map(
              (key, value) => MapEntry(
                key,
                (value as List<dynamic>)
                    .map((item) => (item as num?)?.toInt())
                    .whereType<int>()
                    .where((item) => item >= 0)
                    .toSet(),
              ),
            ),
          );
      }

      final notesRaw = prefs.getString(_scopedKey(_kNotes));
      if (notesRaw != null && notesRaw.isNotEmpty) {
        final parsed = jsonDecode(notesRaw) as Map<String, dynamic>;
        _lessonNotes
          ..clear()
          ..addAll(parsed.map((key, value) => MapEntry(key, value.toString())));
      }

      final lastLessonRaw = prefs.getString(_scopedKey(_kLastLesson));
      if (lastLessonRaw != null && lastLessonRaw.isNotEmpty) {
        final parsed = jsonDecode(lastLessonRaw) as Map<String, dynamic>;
        _lastLessonByCourse
          ..clear()
          ..addAll(parsed.map((key, value) => MapEntry(key, value.toString())));
      }

      final lastWatchedIndexRaw = prefs.getString(
        _scopedKey(_kLastWatchedIndex),
      );
      if (lastWatchedIndexRaw != null && lastWatchedIndexRaw.isNotEmpty) {
        final parsed = jsonDecode(lastWatchedIndexRaw) as Map<String, dynamic>;
        _lastWatchedLessonIndexByCourse
          ..clear()
          ..addAll(
            parsed.map(
              (key, value) => MapEntry(key, (value as num?)?.toInt() ?? 0),
            ),
          );
      }

      final lastOpenedAtRaw = prefs.getString(_scopedKey(_kLastOpenedAt));
      if (lastOpenedAtRaw != null && lastOpenedAtRaw.isNotEmpty) {
        final parsed = jsonDecode(lastOpenedAtRaw) as Map<String, dynamic>;
        _lastOpenedAtByCourse
          ..clear()
          ..addAll(
            parsed.map(
              (key, value) => MapEntry(key, (value as num?)?.toInt() ?? 0),
            ),
          );
      }
    } catch (_) {
      _clearInMemoryLocalState();
    }
    notifyListeners();
  }

  void _clearInMemoryLocalState() {
    _enrolledCourseIds = <String>{};
    _wishlistCourseIds = <String>{};
    _downloadedLessonIds = <String>{};
    _progressByCourse.clear();
    _watchedPercentByCourse.clear();
    _completedLessonsByCourse.clear();
    _completedLessonIndexesByCourse.clear();
    _lessonNotes.clear();
    _lastLessonByCourse.clear();
    _lastWatchedLessonIndexByCourse.clear();
    _lastOpenedAtByCourse.clear();
  }

  String _normalizeUserStorageKey(String? userId) {
    final trimmed = userId?.trim() ?? '';
    return trimmed.isEmpty ? 'guest' : trimmed;
  }

  String _scopedKey(String baseKey) => '${baseKey}_$_localStateUserKey';

  void _persistLocalState() {
    final prefs = _prefs;
    if (prefs == null) {
      return;
    }
    prefs.setStringList(_scopedKey(_kEnrolled), _enrolledCourseIds.toList());
    prefs.setStringList(_scopedKey(_kWishlist), _wishlistCourseIds.toList());
    prefs.setStringList(
      _scopedKey(_kDownloaded),
      _downloadedLessonIds.toList(),
    );
    prefs.setString(_scopedKey(_kProgress), jsonEncode(_progressByCourse));
    prefs.setString(
      _scopedKey(_kWatchedPercent),
      jsonEncode(_watchedPercentByCourse),
    );
    prefs.setString(
      _scopedKey(_kCompleted),
      jsonEncode(
        _completedLessonsByCourse.map(
          (key, value) => MapEntry(key, value.toList()),
        ),
      ),
    );
    prefs.setString(
      _scopedKey(_kCompletedIndexes),
      jsonEncode(
        _completedLessonIndexesByCourse.map(
          (key, value) => MapEntry(key, value.toList(growable: false)..sort()),
        ),
      ),
    );
    prefs.setString(_scopedKey(_kNotes), jsonEncode(_lessonNotes));
    prefs.setString(_scopedKey(_kLastLesson), jsonEncode(_lastLessonByCourse));
    prefs.setString(
      _scopedKey(_kLastWatchedIndex),
      jsonEncode(_lastWatchedLessonIndexByCourse),
    );
    prefs.setString(
      _scopedKey(_kLastOpenedAt),
      jsonEncode(_lastOpenedAtByCourse),
    );
  }

  Future<void> loadCourses({
    bool force = false,
    bool showLoading = true,
  }) async {
    _ensureRealtimeBindings();
    if (!force && _courses.isNotEmpty) {
      return;
    }
    final inFlight = _loadCoursesFuture;
    if (inFlight != null) {
      return inFlight;
    }

    final future = _loadCoursesInternal(force: force, showLoading: showLoading);
    _loadCoursesFuture = future;
    return future.whenComplete(() {
      if (identical(_loadCoursesFuture, future)) {
        _loadCoursesFuture = null;
      }
    });
  }

  Future<void> _loadCoursesInternal({
    required bool force,
    required bool showLoading,
  }) async {
    if (!force && _courses.isNotEmpty) {
      return;
    }
    if (showLoading) {
      _setLoading(true);
    }
    _errorMessage = null;

    try {
      _courses = await _courseRepository.getCourses();
      _searchResults = List<Course>.from(_courses);
    } catch (error) {
      _errorMessage = AppErrorMapper.data(
        error,
        fallback: 'Unable to load courses.',
      );
    } finally {
      if (showLoading) {
        _setLoading(false);
      } else {
        notifyListeners();
      }
    }
  }

  Future<void> loadCoursesByCategory(
    String category, {
    bool showLoading = true,
  }) async {
    _ensureRealtimeBindings();
    if (showLoading) {
      _setLoading(true);
    }
    _errorMessage = null;

    try {
      if (_courses.isEmpty) {
        await loadCourses(showLoading: false);
      }
      final normalized = category.trim().toLowerCase();
      _searchResults = normalized.isEmpty || normalized == 'all'
          ? List<Course>.from(_courses)
          : _courses
                .where(
                  (course) =>
                      course.category.trim().toLowerCase() == normalized,
                )
                .toList();
    } catch (error) {
      _errorMessage = AppErrorMapper.data(
        error,
        fallback: 'Unable to load this category.',
      );
    } finally {
      if (showLoading) {
        _setLoading(false);
      } else {
        notifyListeners();
      }
    }
  }

  Future<void> searchCourses(String query) async {
    if (_courses.isEmpty) {
      await loadCourses(showLoading: false);
    }
    final next = queryCourses(query: query, sort: CourseSortOption.recommended);

    if (_sameCourseList(_searchResults, next)) {
      return;
    }

    _searchResults = next;
    notifyListeners();
  }

  Future<void> loadLessons(
    String courseId, {
    bool force = false,
    bool showLoading = true,
  }) async {
    if (!force && _lessonsByCourse.containsKey(courseId)) {
      return;
    }
    final normalizedCourseId = courseId.trim();
    if (normalizedCourseId.isEmpty) {
      return;
    }

    final inFlight = _loadLessonsFutures[normalizedCourseId];
    if (inFlight != null) {
      return inFlight;
    }

    final future = _loadLessonsInternal(
      normalizedCourseId,
      force: force,
      showLoading: showLoading,
    );
    _loadLessonsFutures[normalizedCourseId] = future;
    return future.whenComplete(() {
      if (identical(_loadLessonsFutures[normalizedCourseId], future)) {
        _loadLessonsFutures.remove(normalizedCourseId);
      }
    });
  }

  Future<void> _loadLessonsInternal(
    String courseId, {
    required bool force,
    required bool showLoading,
  }) async {
    if (!force && _lessonsByCourse.containsKey(courseId)) {
      return;
    }
    if (showLoading) {
      _setLoading(true);
    }
    _errorMessage = null;

    try {
      final lessons = await _courseRepository.getLessonsByCourse(courseId);
      final sorted = List<Lesson>.from(lessons)
        ..sort((a, b) => a.order.compareTo(b.order));
      _lessonsByCourse[courseId] = sorted;
      _reconcileCourseProgressWithLessons(courseId, sorted);
    } catch (error) {
      _errorMessage = AppErrorMapper.data(
        error,
        fallback: 'Could not load lessons.',
      );
    } finally {
      if (showLoading) {
        _setLoading(false);
      } else {
        notifyListeners();
      }
    }
  }

  Future<void> loadInstructors({
    bool force = false,
    bool showLoading = true,
  }) async {
    _ensureRealtimeBindings();
    if (!force &&
        (_platformInstructors.isNotEmpty || _fallbackInstructors.isNotEmpty)) {
      return;
    }
    final inFlight = _loadInstructorsFuture;
    if (inFlight != null) {
      return inFlight;
    }

    final future = _loadInstructorsInternal(
      force: force,
      showLoading: showLoading,
    );
    _loadInstructorsFuture = future;
    return future.whenComplete(() {
      if (identical(_loadInstructorsFuture, future)) {
        _loadInstructorsFuture = null;
      }
    });
  }

  Future<void> _loadInstructorsInternal({
    required bool force,
    required bool showLoading,
  }) async {
    if (!force &&
        (_platformInstructors.isNotEmpty || _fallbackInstructors.isNotEmpty)) {
      return;
    }
    if (showLoading) {
      _setLoading(true);
    }
    _errorMessage = null;

    try {
      _fallbackInstructors = await _courseRepository.getInstructors();
    } catch (error) {
      _errorMessage = AppErrorMapper.data(
        error,
        fallback: 'Unable to load instructors.',
      );
    } finally {
      if (showLoading) {
        _setLoading(false);
      } else {
        notifyListeners();
      }
    }
  }

  Future<void> loadCourseReviews(
    String courseId, {
    bool force = false,
    bool showLoading = true,
  }) async {
    if (!force && _reviewsByCourse.containsKey(courseId)) {
      return;
    }
    final normalizedCourseId = courseId.trim();
    if (normalizedCourseId.isEmpty) {
      return;
    }

    final inFlight = _loadCourseReviewsFutures[normalizedCourseId];
    if (inFlight != null) {
      return inFlight;
    }

    final future = _loadCourseReviewsInternal(
      normalizedCourseId,
      force: force,
      showLoading: showLoading,
    );
    _loadCourseReviewsFutures[normalizedCourseId] = future;
    return future.whenComplete(() {
      if (identical(_loadCourseReviewsFutures[normalizedCourseId], future)) {
        _loadCourseReviewsFutures.remove(normalizedCourseId);
      }
    });
  }

  Future<void> _loadCourseReviewsInternal(
    String courseId, {
    required bool force,
    required bool showLoading,
  }) async {
    if (!force && _reviewsByCourse.containsKey(courseId)) {
      return;
    }
    if (showLoading) {
      _setLoading(true);
    }
    _errorMessage = null;

    try {
      final reviews = await _courseRepository.getCourseReviews(courseId);
      _reviewsByCourse[courseId] = reviews;
    } catch (error) {
      _errorMessage = AppErrorMapper.data(
        error,
        fallback: 'Could not load reviews.',
      );
    } finally {
      if (showLoading) {
        _setLoading(false);
      } else {
        notifyListeners();
      }
    }
  }

  Future<void> addCourseReview({
    required String courseId,
    required String userName,
    required String comment,
    required double rating,
  }) async {
    final review = CourseReview(
      id: 'review_${DateTime.now().millisecondsSinceEpoch}',
      courseId: courseId,
      userName: userName,
      comment: comment,
      rating: rating,
      createdAt: DateTime.now(),
    );

    _setLoading(true);
    _errorMessage = null;

    try {
      await _courseRepository.addCourseReview(review);
      final current = List<CourseReview>.from(
        _reviewsByCourse[courseId] ?? <CourseReview>[],
      );
      _reviewsByCourse[courseId] = <CourseReview>[review, ...current];
    } catch (error) {
      _errorMessage = AppErrorMapper.data(
        error,
        fallback: 'Could not submit your review.',
      );
    } finally {
      _setLoading(false);
    }
  }

  Future<void> enrollCourse({
    required String userId,
    required String courseId,
  }) async {
    print('📌 enrollCourse called for user: $userId, course: $courseId');
    if (_enrolledCourseIds.contains(courseId)) {
      print('⚠️ Already enrolled in this course');
      return;
    }

    _setLoading(true);
    _errorMessage = null;

    // Apply enrollment locally first so the UI unlocks immediately.
    _enrolledCourseIds = <String>{..._enrolledCourseIds, courseId};
    _progressByCourse.putIfAbsent(courseId, () => 0.0);
    _watchedPercentByCourse.putIfAbsent(courseId, () => 0.0);
    _persistLocalState();
    notifyListeners();
    print('✅ Local enrollment applied, UI notified');

    try {
      print('🌐 Sending enrollment to backend...');
      await _courseRepository.enrollCourse(userId: userId, courseId: courseId);
      print('✅ Backend enrollment successful');
      
      // Create a certificate automatically when enrolled
      try {
        final course = _courses.firstWhere((c) => c.id == courseId);
        final certificate = Certificate(
          id: _generateCertificateId(),
          studentId: userId,
          studentName: 'Student', // Will be updated from user data
          courseId: courseId,
          courseName: course.title,
          instructorName: course.instructorName ?? 'Instructor',
          issuedDate: DateTime.now(),
          completionPercentage: 0.0,
          certificateUrl: '',
          certificateName: '${course.title} - In Progress',
        );
        
        print('📜 Saving certificate...');
        await FirestoreService.instance.saveCertificate(userId, certificate.toMap());
        print('✅ Certificate saved');
      } catch (certError) {
        print('⚠️ Error creating certificate: $certError');
        // Don't fail enrollment if certificate creation fails
      }
      
      // Reload enrolled courses to sync with Firestore (force refresh to bypass cache)
      print('🔄 Force-loading enrolled courses from Firestore...');
      await loadEnrolledCourses(userId, showLoading: false, force: true);
      print('✅ Enrolled courses reloaded');
      
      _scheduleRemoteSync();
    } catch (error) {
      print('❌ Enrollment error: $error');
      final syncMessage = AppErrorMapper.data(
        error,
        fallback:
            'Enrollment saved locally. It will sync once the connection is stable.',
      );
      _errorMessage = syncMessage == AppErrorMapper.permissionDenied
          ? syncMessage
          : 'Enrollment saved locally. It will sync once the connection is stable.';
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadEnrolledCourses(
    String userId, {
    bool showLoading = true,
    bool force = false,
  }) async {
    final normalizedUserId = userId.trim();
    if (normalizedUserId.isEmpty) {
      return;
    }

    final inFlight = _enrolledCoursesFutures[normalizedUserId];
    if (inFlight != null && !force) {
      return inFlight;
    }

    final future = _loadEnrolledCoursesInternal(
      normalizedUserId,
      showLoading: showLoading,
    );
    _enrolledCoursesFutures[normalizedUserId] = future;
    return future.whenComplete(() {
      if (identical(_enrolledCoursesFutures[normalizedUserId], future)) {
        _enrolledCoursesFutures.remove(normalizedUserId);
      }
    });
  }

  Future<void> _loadEnrolledCoursesInternal(
    String userId, {
    required bool showLoading,
  }) async {
    if (showLoading) {
      _setLoading(true);
    }
    _errorMessage = null;

    try {
      print('🔄 Loading enrolled courses for user: $userId');
      final enrolled = await _courseRepository.getEnrolledCourses(userId);
      print('✅ Got ${enrolled.length} enrolled courses from repository');
      final remoteEnrolled = enrolled.map((course) => course.id).toSet();
      print('📝 Remote enrolled IDs: $remoteEnrolled');
      print('📊 All courses in memory: ${_courses.length}');
      
      _enrolledCourseIds = <String>{..._enrolledCourseIds, ...remoteEnrolled};
      print('✨ Updated _enrolledCourseIds: $_enrolledCourseIds');
      
      _progressByCourse.removeWhere((courseId, _) {
        return !_enrolledCourseIds.contains(courseId);
      });
      _watchedPercentByCourse.removeWhere((courseId, _) {
        return !_enrolledCourseIds.contains(courseId);
      });
      for (final courseId in _enrolledCourseIds) {
        _progressByCourse.putIfAbsent(courseId, () => 0.0);
        _watchedPercentByCourse.putIfAbsent(courseId, () => 0.0);
        if ((_lastOpenedAtByCourse[courseId] ?? 0) > 0 &&
            !_lessonsByCourse.containsKey(courseId)) {
          unawaited(loadLessons(courseId, showLoading: false));
        }
      }
      _persistLocalState();
      print('🎯 Enrolled courses loaded successfully');
    } catch (error) {
      print('❌ Error loading enrolled courses: $error');
      _errorMessage = AppErrorMapper.data(
        error,
        fallback: 'Unable to load enrolled courses.',
      );
    } finally {
      if (showLoading) {
        _setLoading(false);
      } else {
        notifyListeners();
        print('🔔 notifyListeners() called');
      }
    }
  }

  Future<void> markLessonCompleted({
    required String courseId,
    required String lessonId,
  }) async {
    if (!_lessonsByCourse.containsKey(courseId)) {
      await loadLessons(courseId);
    }

    final completed = _completedLessonsByCourse.putIfAbsent(
      courseId,
      () => <String>{},
    );
    completed.add(lessonId);
    _lastLessonByCourse[courseId] = lessonId;
    _lastOpenedAtByCourse[courseId] = DateTime.now().millisecondsSinceEpoch;

    final lessons = _lessonsByCourse[courseId] ?? <Lesson>[];
    final lessonIndex = lessons.indexWhere((lesson) => lesson.id == lessonId);
    if (lessonIndex >= 0) {
      _lastWatchedLessonIndexByCourse[courseId] = lessonIndex;
      final completedIndexes = _completedLessonIndexesByCourse.putIfAbsent(
        courseId,
        () => <int>{},
      );
      completedIndexes.add(lessonIndex);
    }

    final total = lessons.length;
    if (total > 0) {
      final progress = (completed.length / total).clamp(0, 1).toDouble();
      _progressByCourse[courseId] = progress;
      final watchedPercent = _estimatedWatchedPercent(
        courseId,
        totalLessons: total,
      );
      _watchedPercentByCourse[courseId] = watchedPercent;

      // Check if course is 100% complete
      if (progress >= 1.0) {
        print('🎓 Course $courseId completed 100%! Updating certificate...');
        // Update certificate status
        try {
          // Get the course to find the title
          final course = _courses.firstWhere(
            (c) => c.id == courseId,
            orElse: () => Course(
              id: courseId,
              title: 'Course',
              category: '',
            ),
          );
          
          // Update all matching certificates for this course
          final userId = _lastLoadedUserId;
          if (userId != null) {
            await FirestoreService.instance.updateCertificateCompletion(
              userId: userId,
              courseId: courseId,
              courseName: course.title,
              completionPercentage: 100.0,
              certificateName: '${course.title} - Completed',
            );
            print('✅ Certificate updated to Completed for $courseId');
          }
        } catch (e) {
          print('⚠️ Error updating certificate: $e');
        }
      }
    }

    _persistLocalState();
    _scheduleRemoteSync();
    notifyListeners();
  }

  void updateCourseProgress({
    required String courseId,
    required double progress,
  }) {
    final clampedProgress = progress.clamp(0, 1).toDouble();
    _watchedPercentByCourse[courseId] = clampedProgress;
    if ((_progressByCourse[courseId] ?? 0) > clampedProgress) {
      _watchedPercentByCourse[courseId] = _progressByCourse[courseId] ?? 0;
    }
    _lastOpenedAtByCourse[courseId] = DateTime.now().millisecondsSinceEpoch;
    _persistLocalState();
    _scheduleRemoteSync();
    notifyListeners();
  }

  void toggleWishlist(String courseId) {
    if (_wishlistCourseIds.contains(courseId)) {
      _wishlistCourseIds.remove(courseId);
    } else {
      _wishlistCourseIds = <String>{..._wishlistCourseIds, courseId};
    }
    _persistLocalState();
    _scheduleRemoteSync();
    notifyListeners();
  }

  void toggleLessonDownload(String lessonId) {
    if (_downloadedLessonIds.contains(lessonId)) {
      _downloadedLessonIds.remove(lessonId);
    } else {
      _downloadedLessonIds = <String>{..._downloadedLessonIds, lessonId};
    }
    _persistLocalState();
    _scheduleRemoteSync();
    notifyListeners();
  }

  List<Lesson> get downloadedLessons {
    final allLessons = _lessonsByCourse.values
        .expand((lessons) => lessons)
        .toList();
    return allLessons
        .where((lesson) => _downloadedLessonIds.contains(lesson.id))
        .toList();
  }

  void saveLessonNote({required String lessonId, required String note}) {
    final trimmed = note.trimRight();
    if (trimmed.isEmpty) {
      _lessonNotes.remove(lessonId);
    } else {
      _lessonNotes[lessonId] = trimmed;
    }
    _persistLocalState();
    _scheduleRemoteSync();
    notifyListeners();
  }

  void saveCoursePlaybackState({
    required String courseId,
    required int currentLessonIndex,
    String? lessonId,
    Iterable<int>? completedLessonIndexes,
    double? watchedPercent,
  }) {
    final normalizedCourseId = courseId.trim();
    if (normalizedCourseId.isEmpty) {
      return;
    }

    final normalizedIndex = currentLessonIndex < 0 ? 0 : currentLessonIndex;

    if (_lastWatchedLessonIndexByCourse[normalizedCourseId] !=
        normalizedIndex) {
      _lastWatchedLessonIndexByCourse[normalizedCourseId] = normalizedIndex;
    }

    final trimmedLessonId = lessonId?.trim() ?? '';
    if (trimmedLessonId.isNotEmpty &&
        _lastLessonByCourse[normalizedCourseId] != trimmedLessonId) {
      _lastLessonByCourse[normalizedCourseId] = trimmedLessonId;
    }

    if (completedLessonIndexes != null) {
      final nextCompletedIndexes = completedLessonIndexes
          .where((index) => index >= 0)
          .toSet();
      final previousIndexes =
          _completedLessonIndexesByCourse[normalizedCourseId] ?? <int>{};
      if (!setEquals(previousIndexes, nextCompletedIndexes)) {
        _completedLessonIndexesByCourse[normalizedCourseId] =
            nextCompletedIndexes;
      }

      final lessons = _lessonsByCourse[normalizedCourseId] ?? <Lesson>[];
      if (lessons.isNotEmpty) {
        final completedLessonIds = <String>{};
        for (final index in nextCompletedIndexes) {
          if (index >= 0 && index < lessons.length) {
            completedLessonIds.add(lessons[index].id);
          }
        }
        final previousIds =
            _completedLessonsByCourse[normalizedCourseId] ?? <String>{};
        if (!setEquals(previousIds, completedLessonIds)) {
          _completedLessonsByCourse[normalizedCourseId] = completedLessonIds;
        }
        final completionProgress = _completionProgressForCourse(
          normalizedCourseId,
          totalLessons: lessons.length,
        );
        if ((_progressByCourse[normalizedCourseId] ?? 0) !=
            completionProgress) {
          _progressByCourse[normalizedCourseId] = completionProgress;
        }
      }
    }

    final incomingWatchedPercent =
        watchedPercent?.clamp(0, 1).toDouble() ??
        _estimatedWatchedPercent(
          normalizedCourseId,
          totalLessons:
              (_lessonsByCourse[normalizedCourseId] ?? <Lesson>[]).length,
        );
    final completionFloor = _progressByCourse[normalizedCourseId] ?? 0;
    final previousWatchedPercent =
        _watchedPercentByCourse[normalizedCourseId] ?? 0;
    final resolvedWatchedPercent = incomingWatchedPercent >
            previousWatchedPercent
        ? incomingWatchedPercent
        : previousWatchedPercent;
    final boundedWatchedPercent = resolvedWatchedPercent < completionFloor
        ? completionFloor
        : resolvedWatchedPercent;
    if ((_watchedPercentByCourse[normalizedCourseId] ?? 0) !=
        boundedWatchedPercent) {
      _watchedPercentByCourse[normalizedCourseId] = boundedWatchedPercent;
    }

    final nowMs = DateTime.now().millisecondsSinceEpoch;
    _lastOpenedAtByCourse[normalizedCourseId] = nowMs;

    _persistLocalState();
    _scheduleRemoteSync();
    notifyListeners();
  }

  void setLastOpenedLesson({
    required String courseId,
    required String lessonId,
  }) {
    if (courseId.trim().isEmpty || lessonId.trim().isEmpty) {
      return;
    }
    final lessonIndex = (_lessonsByCourse[courseId] ?? const <Lesson>[])
        .indexWhere((lesson) => lesson.id == lessonId);
    saveCoursePlaybackState(
      courseId: courseId,
      currentLessonIndex: lessonIndex < 0 ? 0 : lessonIndex,
      lessonId: lessonId,
    );
  }

  List<Course> queryCourses({
    required String query,
    String? category,
    String? level,
    CourseSortOption sort = CourseSortOption.recommended,
    bool excludeEnrolled = false,
  }) {
    final normalizedQuery = query.trim().toLowerCase();
    final normalizedCategory = (category ?? '').trim().toLowerCase();
    final normalizedLevel = (level ?? '').trim().toLowerCase();

    final results = _courses
        .where((course) {
          if (!course.isPublished) {
            return false;
          }
          if (excludeEnrolled && _enrolledCourseIds.contains(course.id)) {
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
    sorted.sort((a, b) => _compareCourses(a, b, sort, normalizedQuery));
    return sorted;
  }

  void addDiscussionMessage({
    required String courseId,
    required String message,
  }) {
    final current = List<String>.from(
      _courseDiscussions[courseId] ?? <String>[],
    );
    _courseDiscussions[courseId] = <String>[message, ...current];
    notifyListeners();
  }

  String? get _activeRemoteUserId =>
      _localStateUserKey == 'guest' ? null : _localStateUserKey;

  Future<void> _mergeRemoteStateForUser(String userId) async {
    try {
      final remote = await FirestoreService.instance.getUserLearningState(
        userId,
      );
      if (remote.isEmpty) {
        return;
      }

      _wishlistCourseIds = <String>{
        ..._wishlistCourseIds,
        ...remote.wishlistCourseIds,
      };
      _downloadedLessonIds = <String>{
        ..._downloadedLessonIds,
        ...remote.downloadedLessonIds,
      };

      for (final entry in remote.progressByCourse.entries) {
        final local = _progressByCourse[entry.key] ?? 0;
        _progressByCourse[entry.key] = entry.value > local
            ? entry.value
            : local;
      }

      for (final entry in remote.watchedPercentByCourse.entries) {
        final local = _watchedPercentByCourse[entry.key] ?? 0;
        _watchedPercentByCourse[entry.key] = entry.value > local
            ? entry.value
            : local;
      }

      for (final entry in remote.completedLessonsByCourse.entries) {
        final merged = _completedLessonsByCourse.putIfAbsent(
          entry.key,
          () => <String>{},
        );
        merged.addAll(entry.value);
      }

      for (final entry in remote.completedLessonIndexesByCourse.entries) {
        final merged = _completedLessonIndexesByCourse.putIfAbsent(
          entry.key,
          () => <int>{},
        );
        merged.addAll(entry.value.where((index) => index >= 0));
      }

      for (final entry in remote.lessonNotes.entries) {
        final local = _lessonNotes[entry.key]?.trim() ?? '';
        if (local.isEmpty) {
          _lessonNotes[entry.key] = entry.value;
        }
      }

      for (final entry in remote.lastOpenedAtByCourse.entries) {
        final courseId = entry.key;
        final remoteLastOpenedAt = entry.value;
        final localLastOpenedAt = _lastOpenedAtByCourse[courseId] ?? 0;
        if (remoteLastOpenedAt >= localLastOpenedAt) {
          _lastOpenedAtByCourse[courseId] = remoteLastOpenedAt;

          final remoteLessonId =
              remote.lastLessonByCourse[courseId]?.trim() ?? '';
          if (remoteLessonId.isNotEmpty) {
            _lastLessonByCourse[courseId] = remoteLessonId;
          }

          final remoteLessonIndex =
              remote.lastWatchedLessonIndexByCourse[courseId];
          if (remoteLessonIndex != null && remoteLessonIndex >= 0) {
            _lastWatchedLessonIndexByCourse[courseId] = remoteLessonIndex;
          }
        }
      }

      for (final entry in remote.lastLessonByCourse.entries) {
        _lastLessonByCourse.putIfAbsent(entry.key, () => entry.value);
      }

      for (final entry in remote.lastWatchedLessonIndexByCourse.entries) {
        _lastWatchedLessonIndexByCourse.putIfAbsent(
          entry.key,
          () => entry.value,
        );
      }

      _recomputeAllPersistedProgress();
      _persistLocalState();
      _scheduleRemoteSync();
      notifyListeners();
    } catch (_) {
      // Keep local state if cloud sync is temporarily unavailable.
    }
  }

  Future<void> _syncRemoteState(String? userId) async {
    final normalizedUserId = userId?.trim();
    if (normalizedUserId == null || normalizedUserId.isEmpty) {
      return;
    }

    final snapshot = UserLearningState(
      wishlistCourseIds: _wishlistCourseIds,
      downloadedLessonIds: _downloadedLessonIds,
      progressByCourse: _progressByCourse,
      watchedPercentByCourse: _watchedPercentByCourse,
      completedLessonsByCourse: _completedLessonsByCourse.map(
        (key, value) => MapEntry(key, value.toList(growable: false)),
      ),
      completedLessonIndexesByCourse: _completedLessonIndexesByCourse.map(
        (key, value) => MapEntry(key, value.toList(growable: false)..sort()),
      ),
      lessonNotes: _lessonNotes,
      lastLessonByCourse: _lastLessonByCourse,
      lastWatchedLessonIndexByCourse: _lastWatchedLessonIndexByCourse,
      lastOpenedAtByCourse: _lastOpenedAtByCourse,
    );

    try {
      await FirestoreService.instance.saveUserLearningState(
        userId: normalizedUserId,
        state: snapshot,
      );
    } catch (_) {
      // Local state remains the source of truth until the next successful sync.
    }
  }

  double _completionProgressForCourse(String courseId, {int? totalLessons}) {
    final sanitizedCourseId = courseId.trim();
    if (sanitizedCourseId.isEmpty) {
      return 0;
    }

    final storedProgress = (_progressByCourse[sanitizedCourseId] ?? 0).clamp(
      0,
      1,
    );
    final resolvedTotalLessons =
        totalLessons ??
        (_lessonsByCourse[sanitizedCourseId] ?? <Lesson>[]).length;
    if (resolvedTotalLessons <= 0) {
      return storedProgress.toDouble();
    }

    final completedIdsCount =
        _completedLessonsByCourse[sanitizedCourseId]?.length ?? 0;
    final completedIndexesCount =
        _completedLessonIndexesByCourse[sanitizedCourseId]?.length ?? 0;
    final completedCount = completedIdsCount > completedIndexesCount
        ? completedIdsCount
        : completedIndexesCount;
    final derivedProgress = (completedCount / resolvedTotalLessons).clamp(0, 1);
    return derivedProgress > storedProgress
        ? derivedProgress.toDouble()
        : storedProgress.toDouble();
  }

  double _estimatedWatchedPercent(String courseId, {int? totalLessons}) {
    final sanitizedCourseId = courseId.trim();
    if (sanitizedCourseId.isEmpty) {
      return 0;
    }

    final resolvedTotalLessons =
        totalLessons ??
        (_lessonsByCourse[sanitizedCourseId] ?? <Lesson>[]).length;
    final completionProgress = _completionProgressForCourse(
      sanitizedCourseId,
      totalLessons: resolvedTotalLessons,
    );
    if (resolvedTotalLessons <= 0) {
      return completionProgress;
    }

    final currentIndex = _lastWatchedLessonIndexByCourse[sanitizedCourseId];
    if (currentIndex == null || currentIndex < 0) {
      return completionProgress;
    }

    final clampedIndex = currentIndex >= resolvedTotalLessons
        ? resolvedTotalLessons - 1
        : currentIndex;
    final completedIndexes =
        _completedLessonIndexesByCourse[sanitizedCourseId] ?? <int>{};
    final currentLessonCompleted = completedIndexes.contains(clampedIndex);
    final positionUnits = clampedIndex + (currentLessonCompleted ? 1.0 : 0.35);
    final estimated = (positionUnits / resolvedTotalLessons).clamp(0, 1);
    final boundedEstimated = estimated >= 1 && completionProgress < 1
        ? 0.98
        : estimated.toDouble();
    return boundedEstimated > completionProgress
        ? boundedEstimated
        : completionProgress;
  }

  void _recomputeAllPersistedProgress() {
    final courseIds = <String>{
      ..._progressByCourse.keys,
      ..._watchedPercentByCourse.keys,
      ..._completedLessonsByCourse.keys,
      ..._completedLessonIndexesByCourse.keys,
      ..._lessonsByCourse.keys,
    };
    for (final courseId in courseIds) {
      final totalLessons = (_lessonsByCourse[courseId] ?? <Lesson>[]).length;
      final completionProgress = _completionProgressForCourse(
        courseId,
        totalLessons: totalLessons,
      );
      _progressByCourse[courseId] = completionProgress;
      final watchedPercent = _estimatedWatchedPercent(
        courseId,
        totalLessons: totalLessons,
      );
      if (watchedPercent > (_watchedPercentByCourse[courseId] ?? 0)) {
        _watchedPercentByCourse[courseId] = watchedPercent;
      }
    }
  }

  void _reconcileCourseProgressWithLessons(
    String courseId,
    List<Lesson> lessons,
  ) {
    if (courseId.trim().isEmpty) {
      return;
    }

    if (lessons.isEmpty) {
      _progressByCourse[courseId] = _completionProgressForCourse(courseId);
      return;
    }

    final completedIndexes =
        _completedLessonIndexesByCourse[courseId] ?? <int>{};
    final reconciledCompletedIndexes = <int>{...completedIndexes};
    final completedLessonIds = _completedLessonsByCourse.putIfAbsent(
      courseId,
      () => <String>{},
    );
    for (var index = 0; index < lessons.length; index++) {
      if (completedLessonIds.contains(lessons[index].id) ||
          completedIndexes.contains(index)) {
        reconciledCompletedIndexes.add(index);
        completedLessonIds.add(lessons[index].id);
      }
    }

    if (reconciledCompletedIndexes.isNotEmpty) {
      _completedLessonIndexesByCourse[courseId] = reconciledCompletedIndexes;
    }

    final savedIndex = _lastWatchedLessonIndexByCourse[courseId];
    if (savedIndex != null && savedIndex >= 0 && savedIndex < lessons.length) {
      final savedLessonId = lessons[savedIndex].id;
      final existingLastLessonId = _lastLessonByCourse[courseId]?.trim() ?? '';
      if (existingLastLessonId.isEmpty ||
          !lessons.any((lesson) => lesson.id == existingLastLessonId)) {
        _lastLessonByCourse[courseId] = savedLessonId;
      }
    }

    final completionProgress = _completionProgressForCourse(
      courseId,
      totalLessons: lessons.length,
    );
    _progressByCourse[courseId] = completionProgress;
    final watchedPercent = _estimatedWatchedPercent(
      courseId,
      totalLessons: lessons.length,
    );
    if (watchedPercent > (_watchedPercentByCourse[courseId] ?? 0)) {
      _watchedPercentByCourse[courseId] = watchedPercent;
    }
  }

  void _scheduleRemoteSync() {
    final activeUserId = _activeRemoteUserId;
    if (activeUserId == null || activeUserId.isEmpty) {
      return;
    }

    _pendingRemoteSyncTimer?.cancel();
    _pendingRemoteSyncTimer = Timer(const Duration(milliseconds: 650), () {
      unawaited(_syncRemoteState(activeUserId));
    });
  }

  bool _courseMatchesQuery(Course course, String query) {
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

  int _compareCourses(
    Course a,
    Course b,
    CourseSortOption sort,
    String normalizedQuery,
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
        final scoreA = _recommendationScore(a, normalizedQuery);
        final scoreB = _recommendationScore(b, normalizedQuery);
        final scoreCmp = scoreB.compareTo(scoreA);
        if (scoreCmp != 0) {
          return scoreCmp;
        }
        return _compareDateThenTitle(a, b);
    }
  }

  int _compareDateThenTitle(Course a, Course b) {
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

  double _recommendationScore(Course course, String normalizedQuery) {
    final preferredCategories = <String, int>{};
    final preferredTags = <String, int>{};

    for (final source in [...enrolledCourses, ...wishlistCourses]) {
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

    if (_wishlistCourseIds.contains(course.id)) {
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

  void _setLoading(bool value) {
    if (_isLoading == value) {
      return;
    }
    _isLoading = value;
    notifyListeners();
  }

  String _generateCertificateId() {
    return 'cert_${DateTime.now().millisecondsSinceEpoch}_${(DateTime.now().millisecond * 10).toStringAsFixed(0)}';
  }

  bool _sameCourseList(List<Course> a, List<Course> b) {
    if (identical(a, b)) {
      return true;
    }
    if (a.length != b.length) {
      return false;
    }
    for (var index = 0; index < a.length; index++) {
      if (a[index].id != b[index].id) {
        return false;
      }
    }
    return true;
  }

  void _bindRealtimeCourses() {
    _coursesSubscription?.cancel();
    _coursesSubscription = FirestoreService.instance.streamAllCourses().listen(
      (courses) {
        final oldIds = _courses.map((item) => item.id).toList(growable: false);
        final newIds = courses.map((item) => item.id).toList(growable: false);
        if (_sameStringList(oldIds, newIds)) {
          _courses = courses;
          return;
        }
        _courses = courses;
        _searchResults = List<Course>.from(courses);
        _errorMessage = null;
        notifyListeners();
      },
      onError: (error) {
        if (_courses.isEmpty) {
          _errorMessage = AppErrorMapper.data(
            error,
            fallback: 'Unable to load courses.',
          );
          notifyListeners();
        }
      },
    );
  }

  void _bindRealtimeInstructors() {
    _instructorsSubscription?.cancel();
    _instructorsSubscription = FirestoreService.instance
        .streamInstructors()
        .listen(
          (instructors) {
            if (_sameInstructorList(_platformInstructors, instructors)) {
              return;
            }
            _platformInstructors = instructors;
            _errorMessage = null;
            notifyListeners();
          },
          onError: (error) {
            if (_fallbackInstructors.isEmpty) {
              _errorMessage = AppErrorMapper.data(
                error,
                fallback: 'Unable to load instructors.',
              );
              notifyListeners();
            }
          },
        );
  }

  List<Instructor> get _mergedInstructors {
    if (platformInstructors.isNotEmpty) {
      return platformInstructors;
    }

    final merged = <Instructor>[];
    final seen = <String>{};

    for (final instructor in platformInstructors) {
      final key = _instructorKey(instructor);
      if (seen.add(key)) {
        merged.add(instructor);
      }
    }

    for (final instructor in _hydrateInstructors(_fallbackInstructors)) {
      final key = _instructorKey(instructor);
      if (seen.add(key)) {
        merged.add(instructor);
      }
    }

    return merged;
  }

  List<Instructor> _filterInstructorsByCategory(
    List<Instructor> source,
    String category,
  ) {
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

  List<Instructor> _hydrateInstructors(List<Instructor> source) {
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
      rating: ratingForInstructor(
        instructor.name,
        explicitRating: instructor.rating,
      ),
      studentCount: max(
        instructor.studentCount,
        instructorCourses.isEmpty ? 0 : instructorCourses.length * 124,
      ),
    );
  }

  String _instructorKey(Instructor instructor) {
    final id = instructor.id.trim().toLowerCase();
    if (id.isNotEmpty) {
      return id;
    }
    return instructor.name.trim().toLowerCase();
  }

  bool _sameStringList(List<String> a, List<String> b) {
    if (a.length != b.length) {
      return false;
    }
    for (var index = 0; index < a.length; index++) {
      if (a[index] != b[index]) {
        return false;
      }
    }
    return true;
  }

  bool _sameInstructorList(List<Instructor> a, List<Instructor> b) {
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

  @override
  void dispose() {
    final activeRemoteUserId = _activeRemoteUserId;
    final hadPendingRemoteSync = _pendingRemoteSyncTimer?.isActive ?? false;
    _pendingRemoteSyncTimer?.cancel();
    if (hadPendingRemoteSync && activeRemoteUserId != null) {
      unawaited(_syncRemoteState(activeRemoteUserId));
    }
    _coursesSubscription?.cancel();
    _instructorsSubscription?.cancel();
    super.dispose();
  }

  void _ensureRealtimeBindings() {
    if (!_bindRealtime || _realtimeBound) {
      return;
    }
    _realtimeBound = true;
    _bindRealtimeCourses();
    _bindRealtimeInstructors();
  }
}
