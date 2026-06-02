import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Handles local state persistence for user-specific course data
class CourseLocalState {
  CourseLocalState(String? userId) : _userKey = _normalizeUserKey(userId);

  final String _userKey;

  // State maps
  Set<String> enrolledCourseIds = <String>{};
  Set<String> wishlistCourseIds = <String>{};
  Set<String> downloadedLessonIds = <String>{};
  Map<String, double> progressByCourse = <String, double>{};
  Map<String, double> watchedPercentByCourse = <String, double>{};
  Map<String, Set<String>> completedLessonsByCourse = <String, Set<String>>{};
  Map<String, Set<int>> completedLessonIndexesByCourse = <String, Set<int>>{};
  Map<String, String> lessonNotes = <String, String>{};
  Map<String, String> lastLessonByCourse = <String, String>{};
  Map<String, int> lastWatchedLessonIndexByCourse = <String, int>{};
  Map<String, int> lastOpenedAtByCourse = <String, int>{};

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

  Future<void> restore(SharedPreferences prefs) async {
    try {
      final enrolledRaw = prefs.getStringList(_scopedKey(_kEnrolled));
      enrolledCourseIds = enrolledRaw?.toSet() ?? <String>{};

      final wishlistRaw = prefs.getStringList(_scopedKey(_kWishlist));
      wishlistCourseIds = wishlistRaw?.toSet() ?? <String>{};

      final downloadedRaw = prefs.getStringList(_scopedKey(_kDownloaded));
      downloadedLessonIds = downloadedRaw?.toSet() ?? <String>{};

      final progressRaw = prefs.getString(_scopedKey(_kProgress));
      if (progressRaw != null && progressRaw.isNotEmpty) {
        final parsed = jsonDecode(progressRaw) as Map<String, dynamic>;
        progressByCourse = parsed.map(
          (key, value) => MapEntry(key, (value as num).toDouble()),
        );
      }

      final watchedPercentRaw = prefs.getString(_scopedKey(_kWatchedPercent));
      if (watchedPercentRaw != null && watchedPercentRaw.isNotEmpty) {
        final parsed = jsonDecode(watchedPercentRaw) as Map<String, dynamic>;
        watchedPercentByCourse = parsed.map(
          (key, value) => MapEntry(key, (value as num).toDouble()),
        );
      }

      final completedRaw = prefs.getString(_scopedKey(_kCompleted));
      if (completedRaw != null && completedRaw.isNotEmpty) {
        final parsed = jsonDecode(completedRaw) as Map<String, dynamic>;
        completedLessonsByCourse = parsed.map(
          (key, value) => MapEntry(
            key,
            (value as List<dynamic>).map((item) => item.toString()).toSet(),
          ),
        );
      }

      final completedIndexesRaw = prefs.getString(
        _scopedKey(_kCompletedIndexes),
      );
      if (completedIndexesRaw != null && completedIndexesRaw.isNotEmpty) {
        final parsed = jsonDecode(completedIndexesRaw) as Map<String, dynamic>;
        completedLessonIndexesByCourse = parsed.map(
          (key, value) => MapEntry(
            key,
            (value as List<dynamic>)
                .map((item) => (item as num?)?.toInt())
                .whereType<int>()
                .where((item) => item >= 0)
                .toSet(),
          ),
        );
      }

      final notesRaw = prefs.getString(_scopedKey(_kNotes));
      if (notesRaw != null && notesRaw.isNotEmpty) {
        final parsed = jsonDecode(notesRaw) as Map<String, dynamic>;
        lessonNotes = parsed.map(
          (key, value) => MapEntry(key, value.toString()),
        );
      }

      final lastLessonRaw = prefs.getString(_scopedKey(_kLastLesson));
      if (lastLessonRaw != null && lastLessonRaw.isNotEmpty) {
        final parsed = jsonDecode(lastLessonRaw) as Map<String, dynamic>;
        lastLessonByCourse = parsed.map(
          (key, value) => MapEntry(key, value.toString()),
        );
      }

      final lastWatchedIndexRaw = prefs.getString(
        _scopedKey(_kLastWatchedIndex),
      );
      if (lastWatchedIndexRaw != null && lastWatchedIndexRaw.isNotEmpty) {
        final parsed = jsonDecode(lastWatchedIndexRaw) as Map<String, dynamic>;
        lastWatchedLessonIndexByCourse = parsed.map(
          (key, value) => MapEntry(key, (value as num?)?.toInt() ?? 0),
        );
      }

      final lastOpenedAtRaw = prefs.getString(_scopedKey(_kLastOpenedAt));
      if (lastOpenedAtRaw != null && lastOpenedAtRaw.isNotEmpty) {
        final parsed = jsonDecode(lastOpenedAtRaw) as Map<String, dynamic>;
        lastOpenedAtByCourse = parsed.map(
          (key, value) => MapEntry(key, (value as num?)?.toInt() ?? 0),
        );
      }
    } catch (_) {
      clear();
    }
  }

  void persist(SharedPreferences prefs) {
    prefs.setStringList(_scopedKey(_kEnrolled), enrolledCourseIds.toList());
    prefs.setStringList(_scopedKey(_kWishlist), wishlistCourseIds.toList());
    prefs.setStringList(_scopedKey(_kDownloaded), downloadedLessonIds.toList());
    prefs.setString(_scopedKey(_kProgress), jsonEncode(progressByCourse));
    prefs.setString(
      _scopedKey(_kWatchedPercent),
      jsonEncode(watchedPercentByCourse),
    );
    prefs.setString(
      _scopedKey(_kCompleted),
      jsonEncode(
        completedLessonsByCourse.map(
          (key, value) => MapEntry(key, value.toList()),
        ),
      ),
    );
    prefs.setString(
      _scopedKey(_kCompletedIndexes),
      jsonEncode(
        completedLessonIndexesByCourse.map(
          (key, value) => MapEntry(key, value.toList(growable: false)..sort()),
        ),
      ),
    );
    prefs.setString(_scopedKey(_kNotes), jsonEncode(lessonNotes));
    prefs.setString(_scopedKey(_kLastLesson), jsonEncode(lastLessonByCourse));
    prefs.setString(
      _scopedKey(_kLastWatchedIndex),
      jsonEncode(lastWatchedLessonIndexByCourse),
    );
    prefs.setString(
      _scopedKey(_kLastOpenedAt),
      jsonEncode(lastOpenedAtByCourse),
    );
  }

  void clear() {
    enrolledCourseIds = <String>{};
    wishlistCourseIds = <String>{};
    downloadedLessonIds = <String>{};
    progressByCourse.clear();
    watchedPercentByCourse.clear();
    completedLessonsByCourse.clear();
    completedLessonIndexesByCourse.clear();
    lessonNotes.clear();
    lastLessonByCourse.clear();
    lastWatchedLessonIndexByCourse.clear();
    lastOpenedAtByCourse.clear();
  }

  String _scopedKey(String baseKey) => '${baseKey}_$_userKey';

  static String _normalizeUserKey(String? userId) {
    final trimmed = userId?.trim() ?? '';
    return trimmed.isEmpty ? 'guest' : trimmed;
  }
}
