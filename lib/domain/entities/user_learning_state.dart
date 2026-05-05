class UserLearningState {
  const UserLearningState({
    this.wishlistCourseIds = const <String>{},
    this.downloadedLessonIds = const <String>{},
    this.progressByCourse = const <String, double>{},
    this.watchedPercentByCourse = const <String, double>{},
    this.completedLessonsByCourse = const <String, List<String>>{},
    this.completedLessonIndexesByCourse = const <String, List<int>>{},
    this.lessonNotes = const <String, String>{},
    this.lastLessonByCourse = const <String, String>{},
    this.lastWatchedLessonIndexByCourse = const <String, int>{},
    this.lastOpenedAtByCourse = const <String, int>{},
  });

  final Set<String> wishlistCourseIds;
  final Set<String> downloadedLessonIds;
  final Map<String, double> progressByCourse;
  final Map<String, double> watchedPercentByCourse;
  final Map<String, List<String>> completedLessonsByCourse;
  final Map<String, List<int>> completedLessonIndexesByCourse;
  final Map<String, String> lessonNotes;
  final Map<String, String> lastLessonByCourse;
  final Map<String, int> lastWatchedLessonIndexByCourse;
  final Map<String, int> lastOpenedAtByCourse;

  bool get isEmpty =>
      wishlistCourseIds.isEmpty &&
      downloadedLessonIds.isEmpty &&
      progressByCourse.isEmpty &&
      watchedPercentByCourse.isEmpty &&
      completedLessonsByCourse.isEmpty &&
      completedLessonIndexesByCourse.isEmpty &&
      lessonNotes.isEmpty &&
      lastLessonByCourse.isEmpty &&
      lastWatchedLessonIndexByCourse.isEmpty &&
      lastOpenedAtByCourse.isEmpty;

  UserLearningState copyWith({
    Set<String>? wishlistCourseIds,
    Set<String>? downloadedLessonIds,
    Map<String, double>? progressByCourse,
    Map<String, double>? watchedPercentByCourse,
    Map<String, List<String>>? completedLessonsByCourse,
    Map<String, List<int>>? completedLessonIndexesByCourse,
    Map<String, String>? lessonNotes,
    Map<String, String>? lastLessonByCourse,
    Map<String, int>? lastWatchedLessonIndexByCourse,
    Map<String, int>? lastOpenedAtByCourse,
  }) {
    return UserLearningState(
      wishlistCourseIds: wishlistCourseIds ?? this.wishlistCourseIds,
      downloadedLessonIds: downloadedLessonIds ?? this.downloadedLessonIds,
      progressByCourse: progressByCourse ?? this.progressByCourse,
      watchedPercentByCourse:
          watchedPercentByCourse ?? this.watchedPercentByCourse,
      completedLessonsByCourse:
          completedLessonsByCourse ?? this.completedLessonsByCourse,
      completedLessonIndexesByCourse:
          completedLessonIndexesByCourse ?? this.completedLessonIndexesByCourse,
      lessonNotes: lessonNotes ?? this.lessonNotes,
      lastLessonByCourse: lastLessonByCourse ?? this.lastLessonByCourse,
      lastWatchedLessonIndexByCourse:
          lastWatchedLessonIndexByCourse ??
          this.lastWatchedLessonIndexByCourse,
      lastOpenedAtByCourse: lastOpenedAtByCourse ?? this.lastOpenedAtByCourse,
    );
  }
}
