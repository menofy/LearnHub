import 'dart:async' show unawaited;
import 'dart:developer' as developer;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../domain/entities/app_notification.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/entities/course.dart';
import '../../domain/entities/course_review.dart';
import '../../domain/entities/instructor.dart';
import '../../domain/entities/user_learning_state.dart';
import '../models/course_model.dart';
import '../models/user_model.dart';
import 'auth_exceptions.dart';
import 'email_service.dart';

class FirestoreService {
  FirestoreService._();

  static final FirestoreService instance = FirestoreService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const Duration _dbTimeout = Duration(seconds: 12);
  static const Duration _statsCacheDuration = Duration(minutes: 2);
  final Map<String, _IntCacheEntry> _followersCountCache =
      <String, _IntCacheEntry>{};
  final Map<String, Future<int>> _followersCountRequests =
      <String, Future<int>>{};
  final Map<String, _CountsCacheEntry> _enrollmentCountsCache =
      <String, _CountsCacheEntry>{};
  final Map<String, Future<Map<String, int>>> _enrollmentCountsRequests =
      <String, Future<Map<String, int>>>{};

  int get _nowMs => DateTime.now().millisecondsSinceEpoch;

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');
  CollectionReference<Map<String, dynamic>> get _instructors =>
      _firestore.collection('instructors');
  CollectionReference<Map<String, dynamic>> get _courses =>
      _firestore.collection('courses');
  CollectionReference<Map<String, dynamic>> get _enrollments =>
      _firestore.collection('enrollments');
  CollectionReference<Map<String, dynamic>> get _courseReviews =>
      _firestore.collection('course_reviews');
  CollectionReference<Map<String, dynamic>> get _followers =>
      _firestore.collection('followers');
  CollectionReference<Map<String, dynamic>> get _learningStates =>
      _firestore.collection('learning_states');
  CollectionReference<Map<String, dynamic>> get _notificationsCollection =>
      _firestore.collection('notifications');
  CollectionReference<Map<String, dynamic>> get _fcmTokens =>
      _firestore.collection('fcm_tokens');

  List<String> _sanitizeUploadedVideoUrls(Iterable<String> values) {
    final sanitized = <String>[];
    final seen = <String>{};
    for (final value in values) {
      final trimmed = value.trim();
      if (!Course.isSecureHostedVideoUrl(trimmed) || !seen.add(trimmed)) {
        continue;
      }
      sanitized.add(trimmed);
    }
    return sanitized;
  }

  Future<AppUser?> getUserProfile(String uid) async {
    final doc = await _users.doc(uid).get().timeout(_dbTimeout);
    if (!doc.exists) {
      return null;
    }
    final data = doc.data() ?? <String, dynamic>{};
    return UserModel.fromMap(data).toEntity();
  }

  Future<AppUser> ensureUserProfile({
    required User firebaseUser,
    AppUserRole? roleForNewUser,
  }) async {
    final existing = await getUserProfile(firebaseUser.uid);
    if (existing != null) {
      return existing;
    }

    final role = roleForNewUser;
    if (role == null) {
      throw const RoleSelectionRequiredException();
    }

    final name = (firebaseUser.displayName?.trim().isNotEmpty ?? false)
        ? firebaseUser.displayName!.trim()
        : (firebaseUser.email?.split('@').first ?? 'User');
    final email = firebaseUser.email?.trim() ?? '';

    final user = AppUser(
      id: firebaseUser.uid,
      name: name,
      email: email,
      role: role,
    );
    try {
      await _users
          .doc(firebaseUser.uid)
          .set({
            'uid': user.id,
            'name': user.name,
            'email': user.email,
            'role': user.role.value,
            'phone': '',
            'image': '',
            'createdAt': FieldValue.serverTimestamp(),
            'createdAtMs': _nowMs,
          }, SetOptions(merge: true))
          .timeout(_dbTimeout);
    } catch (e) {
      // If write fails, continue with fallback
    }

    if (role == AppUserRole.instructor) {
      unawaited(
        _createInstructorProfileIfMissing(
          userId: user.id,
          name: user.name,
          bio: 'Instructor at LearnHub',
        ).catchError((_) {}),
      );
    }

    return user;
  }

  Future<void> updateUserProfile({
    required String uid,
    required String name,
    required String email,
    required AppUserRole role,
    String? phone,
    String? image,
  }) async {
    final payload = <String, dynamic>{
      'uid': uid,
      'name': name,
      'email': email,
      'role': role.value,
      'createdAt': FieldValue.serverTimestamp(),
      'createdAtMs': _nowMs,
    };
    if (phone != null) {
      payload['phone'] = phone;
    }
    if (image != null) {
      payload['image'] = image;
    }

    try {
      await _users
          .doc(uid)
          .set(payload, SetOptions(merge: true))
          .timeout(_dbTimeout);

      if (role == AppUserRole.instructor) {
        await _createInstructorProfileIfMissing(
          userId: uid,
          name: name,
          bio: 'Instructor at LearnHub',
          image: image ?? '',
        );
      }
    } catch (e) {
      // If instructor profile creation fails, don't fail the entire registration
      if (role == AppUserRole.instructor) {
        unawaited(
          _createInstructorProfileIfMissing(
            userId: uid,
            name: name,
            bio: 'Instructor at LearnHub',
            image: image ?? '',
          ).catchError((_) {}),
        );
      }
    }
  }

  Future<void> _createInstructorProfileIfMissing({
    required String userId,
    required String name,
    required String bio,
    String image = '',
  }) async {
    await _instructors
        .doc(userId)
        .set({
          'userId': userId,
          'name': name,
          'bio': bio,
          'image': image,
          'createdAt': FieldValue.serverTimestamp(),
          'createdAtMs': _nowMs,
        }, SetOptions(merge: true))
        .timeout(_dbTimeout);
  }

  Future<AppUserRole> inferRoleForExistingAuthUser(String uid) async {
    try {
      final userDoc = await _users.doc(uid).get().timeout(_dbTimeout);
      final data = userDoc.data();
      if (userDoc.exists) {
        return AppUserRoleX.fromValue(data?['role'] as String?);
      }
    } catch (_) {}

    try {
      final instructorDoc = await _instructors
          .doc(uid)
          .get()
          .timeout(_dbTimeout);
      if (instructorDoc.exists) {
        return AppUserRole.instructor;
      }
    } catch (_) {}

    return AppUserRole.student;
  }

  Stream<List<Course>> streamAllCourses() {
    return _courses.snapshots().map((snapshot) {
      final mapped = snapshot.docs
          .map(_courseFromDoc)
          .where((course) => course.isPublished)
          .toList();
      mapped.sort((a, b) {
        final aDate = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bDate = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bDate.compareTo(aDate);
      });
      return mapped;
    });
  }

  Stream<List<Course>> streamInstructorCourses(String instructorId) {
    return _courses
        .where('instructorId', isEqualTo: instructorId)
        .snapshots()
        .map((snapshot) {
          final mapped = snapshot.docs.map(_courseFromDoc).toList();
          mapped.sort((a, b) {
            final aDate = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            final bDate = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            return bDate.compareTo(aDate);
          });
          return mapped;
        });
  }

  Future<Course?> getCourseById(String courseId) async {
    final doc = await _courses.doc(courseId).get().timeout(_dbTimeout);
    if (!doc.exists) {
      return null;
    }
    return _courseFromDoc(doc);
  }

  Future<void> enrollCourse({
    required String userId,
    required String courseId,
  }) async {
    final docId = '${userId}_$courseId';
    await _enrollments
        .doc(docId)
        .set({
          'id': docId,
          'userId': userId,
          'courseId': courseId,
          'createdAt': FieldValue.serverTimestamp(),
          'createdAtMs': _nowMs,
        }, SetOptions(merge: true))
        .timeout(_dbTimeout);
    _enrollmentCountsCache.clear();
    _enrollmentCountsRequests.clear();
  }

  Future<List<Course>> getEnrolledCourses(String userId) async {
    final enrollmentDocs = await _enrollments
        .where('userId', isEqualTo: userId)
        .get()
        .timeout(_dbTimeout);
    if (enrollmentDocs.docs.isEmpty) {
      return const <Course>[];
    }

    final courseIds = enrollmentDocs.docs
        .map((doc) => _asString(doc.data()['courseId']))
        .where((id) => id.isNotEmpty)
        .toList(growable: false);
    if (courseIds.isEmpty) {
      return const <Course>[];
    }

    final List<Course> courses = <Course>[];
    for (final chunk in _chunk(courseIds, 10)) {
      final snapshot = await _courses
          .where(FieldPath.documentId, whereIn: chunk)
          .get()
          .timeout(_dbTimeout);
      courses.addAll(snapshot.docs.map(_courseFromDoc));
    }

    courses.sort((a, b) {
      final aDate = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bDate = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bDate.compareTo(aDate);
    });
    return courses;
  }

  Future<UserLearningState> getUserLearningState(String userId) async {
    final doc = await _learningStates.doc(userId).get().timeout(_dbTimeout);
    if (!doc.exists) {
      return const UserLearningState();
    }

    final data = doc.data() ?? const <String, dynamic>{};
    return UserLearningState(
      wishlistCourseIds: _stringSetFromValue(data['wishlistCourseIds']),
      downloadedLessonIds: _stringSetFromValue(data['downloadedLessonIds']),
      progressByCourse: _doubleMapFromValue(data['progressByCourse']),
      watchedPercentByCourse: _doubleMapFromValue(
        data['watchedPercentByCourse'],
      ),
      completedLessonsByCourse: _stringListMapFromValue(
        data['completedLessonsByCourse'],
      ),
      completedLessonIndexesByCourse: _intListMapFromValue(
        data['completedLessonIndexesByCourse'],
      ),
      lessonNotes: _stringMapFromValue(data['lessonNotes']),
      lastLessonByCourse: _stringMapFromValue(data['lastLessonByCourse']),
      lastWatchedLessonIndexByCourse: _intMapFromValue(
        data['lastWatchedLessonIndexByCourse'],
      ),
      lastOpenedAtByCourse: _intMapFromValue(data['lastOpenedAtByCourse']),
    );
  }

  Future<void> saveUserLearningState({
    required String userId,
    required UserLearningState state,
  }) async {
    await _learningStates
        .doc(userId)
        .set({
          'wishlistCourseIds': state.wishlistCourseIds.toList()..sort(),
          'downloadedLessonIds': state.downloadedLessonIds.toList()..sort(),
          'progressByCourse': state.progressByCourse.map(
            (key, value) => MapEntry(key, value.clamp(0, 1)),
          ),
          'watchedPercentByCourse': state.watchedPercentByCourse.map(
            (key, value) => MapEntry(key, value.clamp(0, 1)),
          ),
          'completedLessonsByCourse': state.completedLessonsByCourse.map(
            (key, value) => MapEntry(key, value.toList()..sort()),
          ),
          'completedLessonIndexesByCourse': state.completedLessonIndexesByCourse
              .map(
                (key, value) =>
                    MapEntry(key, value.toList(growable: false)..sort()),
              ),
          'lessonNotes': state.lessonNotes,
          'lastLessonByCourse': state.lastLessonByCourse,
          'lastWatchedLessonIndexByCourse':
              state.lastWatchedLessonIndexByCourse,
          'lastOpenedAtByCourse': state.lastOpenedAtByCourse,
          'updatedAt': FieldValue.serverTimestamp(),
          'updatedAtMs': _nowMs,
        }, SetOptions(merge: true))
        .timeout(_dbTimeout);
  }

  Future<List<CourseReview>> getCourseReviews(String courseId) async {
    final snapshot = await _courseReviews
        .where('courseId', isEqualTo: courseId)
        .get()
        .timeout(_dbTimeout);
    final reviews = snapshot.docs
        .map((doc) => _courseReviewFromDoc(doc))
        .toList(growable: false);
    reviews.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return reviews;
  }

  Future<void> addCourseReview(CourseReview review) async {
    final doc = review.id.trim().isEmpty
        ? _courseReviews.doc()
        : _courseReviews.doc(review.id);
    await doc
        .set({
          'id': doc.id,
          'courseId': review.courseId,
          'userName': review.userName,
          'comment': review.comment,
          'rating': review.rating,
          'createdAt': FieldValue.serverTimestamp(),
          'createdAtMs': review.createdAt.millisecondsSinceEpoch,
        }, SetOptions(merge: true))
        .timeout(_dbTimeout);
  }

  Stream<List<Instructor>> streamInstructors() {
    return _instructors.snapshots().asyncMap((snapshot) async {
      final docs = snapshot.docs.toList()
        ..sort((a, b) {
          final aDate =
              _toDateTime(
                a.data()['createdAt'],
                fallbackRaw: a.data()['createdAtMs'],
              ) ??
              DateTime.fromMillisecondsSinceEpoch(0);
          final bDate =
              _toDateTime(
                b.data()['createdAt'],
                fallbackRaw: b.data()['createdAtMs'],
              ) ??
              DateTime.fromMillisecondsSinceEpoch(0);
          return bDate.compareTo(aDate);
        });

      return Future.wait<Instructor>(docs.map((doc) => _mapInstructorDoc(doc)));
    });
  }

  /// Stream instructors from users collection where role = 'instructor'
  Stream<List<AppUser>> streamInstructorsFromUsers() {
    return _users.where('role', isEqualTo: 'instructor').snapshots().map((
      snapshot,
    ) {
      final docs = snapshot.docs.toList();

      // Sort by creation date (newest first)
      docs.sort((a, b) {
        final aMs = (a.data()['createdAtMs'] ?? 0) as int;
        final bMs = (b.data()['createdAtMs'] ?? 0) as int;
        return bMs.compareTo(aMs);
      });

      return docs.map((doc) {
        final data = doc.data();
        return AppUser(
          id: _asString(data['uid'] ?? doc.id),
          name: _asString(data['name']).trim(),
          email: _asString(data['email']).trim(),
          role: AppUserRole.instructor,
          phone: _asString(data['phone']).trim(),
          photoUrl: _asString(data['image'] ?? data['photoUrl']).trim(),
        );
      }).toList();
    });
  }

  /// Stream unique instructors from courses collection
  /// Extracts instructors who have at least one course
  /// Returns list of {id, name} maps for instructors with actual courses
  Stream<List<Map<String, String>>> streamUniqueInstructorsFromCourses() {
    return streamAllCourses().map((courses) {
      final uniqueInstructors = <String, Map<String, String>>{};

      for (final course in courses) {
        final id = course.instructorId.trim();
        final name = course.instructorName.trim();

        // Only include non-admin, non-empty instructors
        if (id.isNotEmpty && name.isNotEmpty && id != 'admin') {
          uniqueInstructors[id] = {'id': id, 'name': name};
        }
      }

      return uniqueInstructors.values.toList();
    });
  }

  Stream<List<AppNotification>> streamNotificationsForUser({
    required String userId,
    required AppUserRole role,
    int limit = 60,
  }) {
    final normalizedUserId = userId.trim();
    if (normalizedUserId.isEmpty) {
      return Stream<List<AppNotification>>.value(const <AppNotification>[]);
    }

    final normalizedRole = role.value;
    return _notificationsCollection
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
          final items = <AppNotification>[];
          for (final doc in snapshot.docs) {
            final data = doc.data();
            if (!_notificationMatchesAudience(
              data['audiences'],
              userId: normalizedUserId,
              roleValue: normalizedRole,
            )) {
              continue;
            }
            items.add(_notificationFromDoc(doc));
          }

          items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return items;
        });
  }

  Future<void> addCourse({
    required String title,
    required String description,
    required String videoUrl,
    required String category,
    required String instructorId,
    required String instructorName,
    String? playlistId,
    bool isAdminCourse = false,
    String imageUrl = '',
    String level = 'All Levels',
    List<String> tags = const <String>[],
    List<String> requirements = const <String>[],
    List<String> outcomes = const <String>[],
    String mediaSourceType = Course.linkMediaSource,
    List<String> uploadedVideoUrls = const <String>[],
    bool isPublished = true,
    bool isFree = true,
    double price = 0.0,
  }) async {
    final trimmedVideoUrl = videoUrl.trim();
    final sanitizedUploadedVideoUrls = _sanitizeUploadedVideoUrls(
      mediaSourceType == Course.uploadMediaSource
          ? <String>[trimmedVideoUrl, ...uploadedVideoUrls]
          : uploadedVideoUrls,
    );
    final resolvedPlaylistId = mediaSourceType == Course.uploadMediaSource
        ? ''
        : (playlistId == null || playlistId.trim().isEmpty)
        ? extractPlaylistId(trimmedVideoUrl)
        : playlistId.trim();
    final activeVideoUrl = mediaSourceType == Course.uploadMediaSource
        ? (sanitizedUploadedVideoUrls.isEmpty
              ? ''
              : sanitizedUploadedVideoUrls.first)
        : trimmedVideoUrl;

    final doc = _courses.doc();
    await doc.set({
      'id': doc.id,
      'title': title.trim(),
      'description': description.trim(),
      'image': imageUrl.trim(),
      'videoUrl': activeVideoUrl,
      'category': category.trim(),
      'playlistId': resolvedPlaylistId,
      'instructorId': instructorId,
      'instructorName': instructorName.trim(),
      'isAdminCourse': isAdminCourse,
      'level': level.trim().isEmpty ? 'All Levels' : level.trim(),
      'tags': tags
          .map((item) => item.trim())
          .where((item) => item.isNotEmpty)
          .toList(growable: false),
      'requirements': requirements
          .map((item) => item.trim())
          .where((item) => item.isNotEmpty)
          .toList(growable: false),
      'outcomes': outcomes
          .map((item) => item.trim())
          .where((item) => item.isNotEmpty)
          .toList(growable: false),
      'mediaSourceType': mediaSourceType,
      'uploadedVideoUrls': sanitizedUploadedVideoUrls,
      'isPublished': isPublished,
      'isFree': isFree,
      'price': price,
      'rating': 0.0,
      'studentCount': 0,
      'createdAt': FieldValue.serverTimestamp(),
      'createdAtMs': _nowMs,
      'lastUpdatedAt': FieldValue.serverTimestamp(),
      'lastUpdatedAtMs': _nowMs,
    });

    if (isPublished && !isAdminCourse) {
      try {
        await _createCoursePublishedNotification(
          courseId: doc.id,
          courseTitle: title.trim(),
          instructorId: instructorId,
          instructorName: instructorName.trim(),
        );
      } catch (e) {
        developer.log(
          'Failed to create publish notification for course ${doc.id}: $e',
          name: 'FirestoreService',
        );
      }
    }
  }

  Future<void> updateCourse({
    required String courseId,
    required String title,
    required String description,
    required String videoUrl,
    required String category,
    required String instructorName,
    String imageUrl = '',
    String? playlistId,
    String level = 'All Levels',
    List<String> tags = const <String>[],
    List<String> requirements = const <String>[],
    List<String> outcomes = const <String>[],
    String mediaSourceType = Course.linkMediaSource,
    List<String> uploadedVideoUrls = const <String>[],
    bool isPublished = true,
    bool isFree = true,
    double price = 0.0,
  }) async {
    final trimmedVideoUrl = videoUrl.trim();
    final sanitizedUploadedVideoUrls = _sanitizeUploadedVideoUrls(
      mediaSourceType == Course.uploadMediaSource
          ? <String>[trimmedVideoUrl, ...uploadedVideoUrls]
          : uploadedVideoUrls,
    );
    final resolvedPlaylistId = mediaSourceType == Course.uploadMediaSource
        ? ''
        : (playlistId == null || playlistId.trim().isEmpty)
        ? extractPlaylistId(trimmedVideoUrl)
        : playlistId.trim();
    final activeVideoUrl = mediaSourceType == Course.uploadMediaSource
        ? (sanitizedUploadedVideoUrls.isEmpty
              ? ''
              : sanitizedUploadedVideoUrls.first)
        : trimmedVideoUrl;
    final existingSnapshot = await _courses
        .doc(courseId)
        .get()
        .timeout(_dbTimeout);
    final existingData = existingSnapshot.data() ?? const <String, dynamic>{};
    final wasPublished = existingData['isPublished'] as bool? ?? false;

    await _courses
        .doc(courseId)
        .set({
          'title': title.trim(),
          'description': description.trim(),
          'image': imageUrl.trim(),
          'videoUrl': activeVideoUrl,
          'category': category.trim(),
          'playlistId': resolvedPlaylistId,
          'instructorName': instructorName.trim(),
          'level': level.trim().isEmpty ? 'All Levels' : level.trim(),
          'tags': tags
              .map((item) => item.trim())
              .where((item) => item.isNotEmpty)
              .toList(growable: false),
          'requirements': requirements
              .map((item) => item.trim())
              .where((item) => item.isNotEmpty)
              .toList(growable: false),
          'outcomes': outcomes
              .map((item) => item.trim())
              .where((item) => item.isNotEmpty)
              .toList(growable: false),
          'mediaSourceType': mediaSourceType,
          'uploadedVideoUrls': sanitizedUploadedVideoUrls,
          'isPublished': isPublished,
          'isFree': isFree,
          'price': price,
          'lastUpdatedAt': FieldValue.serverTimestamp(),
          'lastUpdatedAtMs': _nowMs,
        }, SetOptions(merge: true))
        .timeout(_dbTimeout);

    if (!wasPublished && isPublished) {
      try {
        await _createCoursePublishedNotification(
          courseId: courseId,
          courseTitle: title.trim(),
          instructorId: _asString(existingData['instructorId']),
          instructorName: instructorName.trim(),
        );
      } catch (e) {
        developer.log(
          'Failed to create publish notification for updated course $courseId: $e',
          name: 'FirestoreService',
        );
      }
    }
  }

  Future<void> deleteCourse(String courseId) async {
    await _courses.doc(courseId).delete();
    _enrollmentCountsCache.clear();
    _enrollmentCountsRequests.clear();
  }

  Future<Map<String, int>> getEnrollmentCountsForCourseIds(
    Iterable<String> courseIds,
  ) async {
    final normalizedIds = courseIds
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toSet()
        .toList(growable: false);
    if (normalizedIds.isEmpty) {
      return const <String, int>{};
    }

    normalizedIds.sort();
    final cacheKey = normalizedIds.join('|');
    final cached = _enrollmentCountsCache[cacheKey];
    if (cached != null && _isFresh(cached.cachedAt)) {
      return cached.values;
    }

    final pending = _enrollmentCountsRequests[cacheKey];
    if (pending != null) {
      return pending;
    }

    final future = _getEnrollmentCountsForCourseIdsInternal(
      normalizedIds,
      cacheKey,
    );
    _enrollmentCountsRequests[cacheKey] = future;
    return future.whenComplete(() {
      if (identical(_enrollmentCountsRequests[cacheKey], future)) {
        _enrollmentCountsRequests.remove(cacheKey);
      }
    });
  }

  Future<Map<String, int>> _getEnrollmentCountsForCourseIdsInternal(
    List<String> normalizedIds,
    String cacheKey,
  ) async {
    final counts = <String, int>{for (final id in normalizedIds) id: 0};
    for (final chunk in _chunk(normalizedIds, 10)) {
      final snapshot = await _enrollments
          .where('courseId', whereIn: chunk)
          .get()
          .timeout(_dbTimeout);
      for (final doc in snapshot.docs) {
        final courseId = _asString(doc.data()['courseId']);
        if (courseId.isEmpty) {
          continue;
        }
        counts.update(courseId, (value) => value + 1, ifAbsent: () => 1);
      }
    }

    final result = Map<String, int>.unmodifiable(counts);
    _enrollmentCountsCache[cacheKey] = _CountsCacheEntry(
      values: result,
      cachedAt: DateTime.now(),
    );
    return result;
  }

  String extractPlaylistId(String input) {
    final value = input.trim();
    if (value.isEmpty) {
      return '';
    }

    if (!value.contains('http')) {
      return value;
    }

    final uri = Uri.tryParse(value);
    if (uri == null) {
      return '';
    }

    final list = uri.queryParameters['list'];
    if (list != null && list.isNotEmpty) {
      return list;
    }
    return '';
  }

  String extractYoutubeVideoId(String input) {
    final value = input.trim();
    if (value.isEmpty) {
      return '';
    }
    final uri = Uri.tryParse(value);
    if (uri == null) {
      return '';
    }

    final host = uri.host.toLowerCase();
    if (host.contains('youtu.be')) {
      final path = uri.pathSegments.isNotEmpty ? uri.pathSegments.first : '';
      return path.trim();
    }

    if (host.contains('youtube.com')) {
      final v = uri.queryParameters['v'];
      if (v != null && v.isNotEmpty) {
        return v.trim();
      }
      final segments = uri.pathSegments;
      if (segments.length >= 2 && segments.first == 'embed') {
        return segments[1].trim();
      }
      if (segments.length >= 2 && segments.first == 'shorts') {
        return segments[1].trim();
      }
    }

    return '';
  }

  Future<void> ensureAdminCoursesSeeded() async {
    final existing = await _courses
        .where('isAdminCourse', isEqualTo: true)
        .limit(1)
        .get()
        .timeout(_dbTimeout);
    if (existing.docs.isNotEmpty) {
      return;
    }

    final now = FieldValue.serverTimestamp();
    final seeded = <Map<String, dynamic>>[
      {
        'title': 'Complete Flutter Bootcamp',
        'description':
            'Learn Flutter fundamentals and build practical mobile apps.',
        'category': 'Flutter',
        'videoUrl':
            'https://www.youtube.com/playlist?list=PLMDrOnfT8EAhsiJwkzspHp_Ob6oRCHxv0',
        'playlistId': 'PLMDrOnfT8EAhsiJwkzspHp_Ob6oRCHxv0',
        'level': 'Intermediate',
        'tags': <String>['Flutter', 'State Management', 'Architecture'],
        'requirements': <String>['Basic Dart syntax', 'Flutter SDK installed'],
        'outcomes': <String>[
          'Build structured Flutter apps',
          'Understand provider and clean architecture',
        ],
      },
      {
        'title': 'Dart & OOP Essentials',
        'description': 'Master Dart language essentials and OOP concepts.',
        'category': 'Programming',
        'videoUrl':
            'https://www.youtube.com/playlist?list=PL93xoMrxRJIutlMCImcV3CYMmjS0MmlWL',
        'playlistId': 'PL93xoMrxRJIutlMCImcV3CYMmjS0MmlWL',
        'level': 'Beginner',
        'tags': <String>['Dart', 'OOP', 'Programming Basics'],
        'requirements': <String>['No previous experience required'],
        'outcomes': <String>[
          'Write idiomatic Dart',
          'Use OOP concepts in real apps',
        ],
      },
      {
        'title': 'UI/UX Design Basics',
        'description':
            'Design cleaner interfaces with practical UX principles.',
        'category': 'Design',
        'videoUrl':
            'https://www.youtube.com/playlist?list=PLmQ0KfqeaHAuud_Aav-94nfToArf6Uh4K',
        'playlistId': 'PLmQ0KfqeaHAuud_Aav-94nfToArf6Uh4K',
        'level': 'Beginner',
        'tags': <String>['UX', 'UI', 'Design Systems'],
        'requirements': <String>['Interest in mobile design'],
        'outcomes': <String>[
          'Create cleaner interfaces',
          'Understand UX fundamentals',
        ],
      },
      {
        'title': 'Data Structures for Interviews',
        'description': 'Build strong problem-solving with data structures.',
        'category': 'Computer Science',
        'videoUrl':
            'https://www.youtube.com/playlist?list=PLCInYL3l2AajqOUW_2SwjWeMwf4vL4RSp',
        'playlistId': 'PLCInYL3l2AajqOUW_2SwjWeMwf4vL4RSp',
        'level': 'Advanced',
        'tags': <String>['Algorithms', 'Interviews', 'Problem Solving'],
        'requirements': <String>['Basic programming knowledge'],
        'outcomes': <String>[
          'Solve common interview patterns',
          'Choose the right data structure',
        ],
      },
    ];

    final batch = _firestore.batch();
    for (final item in seeded) {
      final doc = _courses.doc();
      batch.set(doc, {
        'id': doc.id,
        'title': item['title'],
        'description': item['description'],
        'videoUrl': item['videoUrl'],
        'category': item['category'],
        'playlistId': item['playlistId'],
        'instructorId': 'admin',
        'instructorName': 'Admin',
        'isAdminCourse': true,
        'level': item['level'],
        'tags': item['tags'],
        'requirements': item['requirements'],
        'outcomes': item['outcomes'],
        'isPublished': true,
        'createdAt': now,
        'createdAtMs': _nowMs,
        'lastUpdatedAt': now,
        'lastUpdatedAtMs': _nowMs,
      });
    }
    await batch.commit().timeout(_dbTimeout);
  }

  Course _courseFromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return CourseModel.fromMap({
      ...data,
      'id': doc.id,
      'createdAt': _toDateTime(
        data['createdAt'],
        fallbackRaw: data['createdAtMs'],
      ),
      'lastUpdatedAt': _toDateTime(
        data['lastUpdatedAt'],
        fallbackRaw: data['lastUpdatedAtMs'],
      ),
      'playlistId': _asString(data['playlistId']).isNotEmpty
          ? _asString(data['playlistId'])
          : extractPlaylistId(_asString(data['videoUrl'])),
      'is_popular': (data['isAdminCourse'] ?? false) as bool,
    }).toEntity();
  }

  CourseReview _courseReviewFromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? <String, dynamic>{};
    return CourseReview(
      id: _asString(data['id'], fallback: doc.id),
      courseId: _asString(data['courseId']),
      userName: _asString(data['userName']),
      comment: _asString(data['comment']),
      rating: (data['rating'] as num?)?.toDouble() ?? 0,
      createdAt:
          _toDateTime(data['createdAt'], fallbackRaw: data['createdAtMs']) ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  AppNotification _notificationFromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? const <String, dynamic>{};
    return AppNotification(
      id: _asString(data['id'], fallback: doc.id),
      title: _asString(data['title']),
      body: _asString(data['body']),
      createdAt:
          _toDateTime(data['createdAt'], fallbackRaw: data['createdAtMs']) ??
          DateTime.fromMillisecondsSinceEpoch(0),
      type: AppNotificationTypeX.fromValue(data['type']?.toString()),
      courseId: _asString(data['courseId']).trim().isEmpty
          ? null
          : _asString(data['courseId']).trim(),
    );
  }

  Iterable<List<String>> _chunk(List<String> values, int size) sync* {
    for (var index = 0; index < values.length; index += size) {
      final end = (index + size > values.length) ? values.length : index + size;
      yield values.sublist(index, end);
    }
  }

  Set<String> _stringSetFromValue(Object? raw) {
    if (raw is List) {
      return raw
          .map((item) => item.toString().trim())
          .where((item) => item.isNotEmpty)
          .toSet();
    }
    return <String>{};
  }

  Map<String, String> _stringMapFromValue(Object? raw) {
    if (raw is! Map) {
      return const <String, String>{};
    }
    return raw.map<String, String>((key, value) {
      return MapEntry(key.toString(), value?.toString() ?? '');
    });
  }

  Map<String, double> _doubleMapFromValue(Object? raw) {
    if (raw is! Map) {
      return const <String, double>{};
    }
    return raw.map<String, double>((key, value) {
      return MapEntry(key.toString(), (value as num?)?.toDouble() ?? 0);
    });
  }

  Map<String, List<String>> _stringListMapFromValue(Object? raw) {
    if (raw is! Map) {
      return const <String, List<String>>{};
    }
    return raw.map<String, List<String>>((key, value) {
      if (value is List) {
        return MapEntry(
          key.toString(),
          value
              .map((item) => item.toString().trim())
              .where((item) => item.isNotEmpty)
              .toList(growable: false),
        );
      }
      return MapEntry(key.toString(), const <String>[]);
    });
  }

  Map<String, int> _intMapFromValue(Object? raw) {
    if (raw is! Map) {
      return const <String, int>{};
    }
    return raw.map<String, int>((key, value) {
      return MapEntry(key.toString(), (value as num?)?.toInt() ?? 0);
    });
  }

  Map<String, List<int>> _intListMapFromValue(Object? raw) {
    if (raw is! Map) {
      return const <String, List<int>>{};
    }
    return raw.map<String, List<int>>((key, value) {
      if (value is! List) {
        return MapEntry(key.toString(), const <int>[]);
      }
      return MapEntry(
        key.toString(),
        value
            .map((item) => (item as num?)?.toInt())
            .whereType<int>()
            .where((item) => item >= 0)
            .toList(growable: false),
      );
    });
  }

  DateTime? _toDateTime(Object? raw, {Object? fallbackRaw}) {
    if (raw is Timestamp) {
      return raw.toDate();
    }
    if (fallbackRaw is int) {
      return DateTime.fromMillisecondsSinceEpoch(fallbackRaw);
    }
    if (fallbackRaw is num) {
      return DateTime.fromMillisecondsSinceEpoch(fallbackRaw.toInt());
    }
    return null;
  }

  bool _notificationMatchesAudience(
    Object? rawAudiences, {
    required String userId,
    required String roleValue,
  }) {
    final audiences = _stringSetFromValue(rawAudiences);
    if (audiences.isEmpty) {
      return false;
    }

    return audiences.contains('all') ||
        audiences.contains(roleValue) ||
        audiences.contains('user:$userId');
  }

  // ============ FOLLOW/UNFOLLOW METHODS ============

  /// Follow an instructor
  Future<void> followInstructor({
    required String currentUserId,
    required String instructorId,
    String? followerName,
  }) async {
    await _followers
        .add({
          'followerId': currentUserId,
          'followerName': followerName ?? currentUserId,
          'instructorId': instructorId,
          'followedAtMs': _nowMs,
        })
        .timeout(_dbTimeout);
    _followersCountCache.remove(instructorId);
    _followersCountRequests.remove(instructorId);
  }

  /// Unfollow an instructor
  Future<void> unfollowInstructor({
    required String currentUserId,
    required String instructorId,
  }) async {
    final query = await _followers
        .where('followerId', isEqualTo: currentUserId)
        .where('instructorId', isEqualTo: instructorId)
        .get()
        .timeout(_dbTimeout);

    for (final doc in query.docs) {
      await _followers.doc(doc.id).delete().timeout(_dbTimeout);
    }
    _followersCountCache.remove(instructorId);
    _followersCountRequests.remove(instructorId);
  }

  /// Check if user is following instructor
  Future<bool> isFollowingInstructor({
    required String currentUserId,
    required String instructorId,
  }) async {
    final query = await _followers
        .where('followerId', isEqualTo: currentUserId)
        .where('instructorId', isEqualTo: instructorId)
        .limit(1)
        .get()
        .timeout(_dbTimeout);

    return query.docs.isNotEmpty;
  }

  /// Get followers count for instructor
  Future<int> getFollowersCount(String instructorId) async {
    final normalizedInstructorId = instructorId.trim();
    if (normalizedInstructorId.isEmpty) {
      return 0;
    }

    final cached = _followersCountCache[normalizedInstructorId];
    if (cached != null && _isFresh(cached.cachedAt)) {
      return cached.value;
    }

    final pending = _followersCountRequests[normalizedInstructorId];
    if (pending != null) {
      return pending;
    }

    final future = _getFollowersCountInternal(normalizedInstructorId);
    _followersCountRequests[normalizedInstructorId] = future;
    return future.whenComplete(() {
      if (identical(_followersCountRequests[normalizedInstructorId], future)) {
        _followersCountRequests.remove(normalizedInstructorId);
      }
    });
  }

  // ==================== Password Reset OTP ====================

  /// Generate OTP code and send to email
  /// Generate OTP and send via email (using Firebase Email Extension)
  ///
  /// This generates a 6-digit OTP, saves it to Firestore with 10-minute expiry,
  /// and sends it to the user's email via Firebase Email Extension/Cloud Functions
  Future<String> generateAndSendPasswordResetOtp({
    required String email,
  }) async {
    final otp = _generateOtp();
    final timestamp = DateTime.now();
    final expiresAt = timestamp.add(const Duration(minutes: 10));
    final normalizedEmail = email.trim().toLowerCase();

    try {
      await _firestore
          .collection('password_reset_otps')
          .doc(normalizedEmail)
          .set({
            'email': normalizedEmail,
            'otp': otp,
            'createdAt': FieldValue.serverTimestamp(),
            'createdAtMs': timestamp.millisecondsSinceEpoch,
            'expiresAt': expiresAt.millisecondsSinceEpoch,
            'verified': false,
            'consumed': false,
          })
          .timeout(_dbTimeout);

      unawaited(
        EmailService.instance
            .sendPasswordResetOtpEmail(email: normalizedEmail, otp: otp)
            .catchError((_) {}),
      );

      return otp;
    } catch (e) {
      throw Exception('Failed to save OTP: $e');
    }
  }

  /// Verify OTP code
  Future<bool> verifyPasswordResetOtp({
    required String email,
    required String otp,
  }) async {
    try {
      final normalizedEmail = email.trim().toLowerCase();
      final doc = await _firestore
          .collection('password_reset_otps')
          .doc(normalizedEmail)
          .get()
          .timeout(_dbTimeout);

      if (!doc.exists) {
        throw Exception('OTP not found. Request a new one.');
      }

      final data = doc.data()!;
      final storedOtp = data['otp'] as String;
      final expiresAtMs = data['expiresAt'] as int;
      final verified = data['verified'] as bool? ?? false;
      final consumed = data['consumed'] as bool? ?? false;

      if (DateTime.now().millisecondsSinceEpoch > expiresAtMs) {
        throw Exception('OTP expired. Request a new one.');
      }

      if (consumed) {
        throw Exception('OTP already used. Request a new one.');
      }

      if (verified) {
        return true;
      }

      if (storedOtp != otp.trim()) {
        throw Exception('Invalid OTP code.');
      }

      await doc.reference
          .update({
            'verified': true,
            'verifiedAtMs': DateTime.now().millisecondsSinceEpoch,
          })
          .timeout(_dbTimeout);

      return true;
    } catch (e) {
      throw Exception('OTP verification failed: $e');
    }
  }

  Future<void> ensurePasswordResetOtpVerified(String email) async {
    final normalizedEmail = email.trim().toLowerCase();
    final doc = await _firestore
        .collection('password_reset_otps')
        .doc(normalizedEmail)
        .get()
        .timeout(_dbTimeout);

    if (!doc.exists) {
      throw Exception('OTP not found. Request a new code.');
    }

    final data = doc.data()!;
    final expiresAtMs = data['expiresAt'] as int? ?? 0;
    final verified = data['verified'] as bool? ?? false;
    final consumed = data['consumed'] as bool? ?? false;

    if (DateTime.now().millisecondsSinceEpoch > expiresAtMs) {
      throw Exception('OTP expired. Request a new code.');
    }

    if (!verified) {
      throw Exception('Verify the OTP code first.');
    }

    if (consumed) {
      throw Exception('OTP already used. Request a new code.');
    }
  }

  Future<void> consumePasswordResetOtp(String email) async {
    final normalizedEmail = email.trim().toLowerCase();
    await _firestore
        .collection('password_reset_otps')
        .doc(normalizedEmail)
        .update({
          'consumed': true,
          'consumedAtMs': DateTime.now().millisecondsSinceEpoch,
        })
        .timeout(_dbTimeout);
  }

  /// Clean up expired OTPs
  Future<void> cleanupExpiredOtps() async {
    try {
      final now = DateTime.now().millisecondsSinceEpoch;
      final snapshot = await _firestore
          .collection('password_reset_otps')
          .where('expiresAt', isLessThan: now)
          .get()
          .timeout(_dbTimeout);

      for (final doc in snapshot.docs) {
        await doc.reference.delete().timeout(_dbTimeout);
      }
    } catch (_) {
      // Ignore cleanup errors
    }
  }

  /// Generate random 6-digit OTP
  String _generateOtp() {
    final random = DateTime.now().millisecondsSinceEpoch % 1000000;
    return random.toString().padLeft(6, '0');
  }

  /// Get list of followers for instructor
  Future<List<Map<String, dynamic>>> getFollowersList(
    String instructorId,
  ) async {
    try {
      final query = await _followers
          .where('instructorId', isEqualTo: instructorId)
          .get()
          .timeout(_dbTimeout);
      return query.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      return [];
    }
  }

  /// Get list of followers with user details (name, email, etc.)
  Future<List<Map<String, dynamic>>> getFollowersListWithDetails(
    String instructorId,
  ) async {
    try {
      final query = await _followers
          .where('instructorId', isEqualTo: instructorId)
          .get()
          .timeout(_dbTimeout);

      final followers = query.docs.map((doc) => doc.data()).toList();

      // Fetch user details for each follower
      final followersWithDetails = <Map<String, dynamic>>[];
      for (final follower in followers) {
        final followerId = follower['followerId'] as String?;
        if (followerId != null) {
          final userDoc = await _users
              .doc(followerId)
              .get()
              .timeout(_dbTimeout);
          if (userDoc.exists) {
            final userData = userDoc.data() ?? <String, dynamic>{};
            followersWithDetails.add({
              ...follower,
              'followerName': userData['name'] ?? followerId,
              'followerEmail': userData['email'] ?? '',
            });
          } else {
            // If user not found, use the ID as fallback
            followersWithDetails.add({
              ...follower,
              'followerName': followerId,
              'followerEmail': '',
            });
          }
        }
      }

      return followersWithDetails;
    } catch (e) {
      return [];
    }
  }

  String _asString(Object? value, {String fallback = ''}) {
    if (value is String) {
      return value;
    }
    return fallback;
  }

  Future<Instructor> _mapInstructorDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) async {
    final data = doc.data() ?? const <String, dynamic>{};
    final userId = _asString(data['userId'], fallback: doc.id).trim();
    Map<String, dynamic> userData = const <String, dynamic>{};

    final needsUserFallback =
        _asString(data['image']).trim().isEmpty ||
        _asString(data['name']).trim().isEmpty;

    if (needsUserFallback && userId.isNotEmpty) {
      try {
        final userDoc = await _users.doc(userId).get().timeout(_dbTimeout);
        userData = userDoc.data() ?? const <String, dynamic>{};
      } catch (_) {
        userData = const <String, dynamic>{};
      }
    }

    final name = _firstNonEmpty(<String>[
      _asString(data['name']),
      _asString(userData['name']),
    ], fallback: 'Instructor');
    final bio = _firstNonEmpty(<String>[
      _asString(data['bio']),
    ], fallback: 'Instructor at LearnHub');
    final image = _firstNonEmpty(<String>[
      _asString(data['image']),
      _asString(userData['image']),
      _asString(userData['photoUrl']),
    ]);

    return Instructor(
      id: userId.isEmpty ? doc.id : userId,
      name: name,
      title: bio == 'Instructor at LearnHub' ? 'Course Instructor' : bio,
      bio: bio,
      avatarUrl: image,
      rating: (data['rating'] as num?)?.toDouble() ?? 0,
      studentCount: (data['studentCount'] as num?)?.toInt() ?? 0,
    );
  }

  String _firstNonEmpty(Iterable<String> values, {String fallback = ''}) {
    for (final value in values) {
      final trimmed = value.trim();
      if (trimmed.isNotEmpty) {
        return trimmed;
      }
    }
    return fallback;
  }

  Future<void> _createCoursePublishedNotification({
    required String courseId,
    required String courseTitle,
    required String instructorId,
    required String instructorName,
  }) async {
    final normalizedCourseId = courseId.trim();
    final normalizedInstructorId = instructorId.trim();
    final normalizedTitle = courseTitle.trim();
    final normalizedInstructorName = instructorName.trim();
    if (normalizedCourseId.isEmpty ||
        normalizedInstructorId.isEmpty ||
        normalizedTitle.isEmpty ||
        normalizedInstructorName.isEmpty) {
      return;
    }

    final docId = 'course_publish_$normalizedCourseId';
    await _notificationsCollection
        .doc(docId)
        .set({
          'id': docId,
          'title': 'New course available',
          'body':
              '$normalizedInstructorName published "$normalizedTitle". Start learning now.',
          'type': AppNotificationType.general.value,
          'courseId': normalizedCourseId,
          'instructorId': normalizedInstructorId,
          'instructorName': normalizedInstructorName,
          'audiences': const <String>['student'],
          'createdAt': FieldValue.serverTimestamp(),
          'createdAtMs': _nowMs,
        }, SetOptions(merge: true))
        .timeout(_dbTimeout);
  }

  Future<int> _getFollowersCountInternal(String instructorId) async {
    try {
      final query = await _followers
          .where('instructorId', isEqualTo: instructorId)
          .count()
          .get()
          .timeout(_dbTimeout);
      final value = query.count ?? 0;
      _followersCountCache[instructorId] = _IntCacheEntry(
        value: value,
        cachedAt: DateTime.now(),
      );
      return value;
    } catch (e) {
      return 0;
    }
  }

  bool _isFresh(DateTime cachedAt) {
    return DateTime.now().difference(cachedAt) < _statsCacheDuration;
  }

  /// Update FCM token in user document
  Future<void> updateUserFCMToken({
    required String userId,
    required String fcmToken,
  }) async {
    try {
      await _users
          .doc(userId)
          .update({
            'fcmToken': fcmToken,
            'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
          })
          .timeout(_dbTimeout);
    } catch (e) {
      developer.log(
        'Error updating user FCM token: $e',
        name: 'FirestoreService',
      );
      rethrow;
    }
  }

  /// Save FCM token record to fcm_tokens collection
  Future<void> saveFCMTokenRecord({
    required String userId,
    required String token,
  }) async {
    try {
      final platform = _getPlatform();

      await _fcmTokens
          .doc(token)
          .set({
            'uid': userId,
            'token': token,
            'platform': platform,
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true))
          .timeout(_dbTimeout);
    } catch (e) {
      developer.log(
        'Error saving FCM token record: $e',
        name: 'FirestoreService',
      );
      rethrow;
    }
  }

  /// Remove FCM token on logout
  Future<void> removeFCMToken({required String userId, String? token}) async {
    try {
      // Remove from fcm_tokens collection
      if (token != null && token.isNotEmpty) {
        await _fcmTokens.doc(token).delete().timeout(_dbTimeout);
      }

      // Remove from user document
      await _users
          .doc(userId)
          .update({'fcmToken': FieldValue.delete()})
          .timeout(_dbTimeout);
    } catch (e) {
      developer.log('Error removing FCM token: $e', name: 'FirestoreService');
      // Don't rethrow on removal failure to avoid logout issues
    }
  }

  /// Get platform identifier (ios/android/web)
  String _getPlatform() {
    // This will be used to identify which platform the token is from
    // Can be overridden by FCMService if needed
    return 'android'; // Default for now, will be determined by platform detection in real usage
  }
}

class _IntCacheEntry {
  const _IntCacheEntry({required this.value, required this.cachedAt});

  final int value;
  final DateTime cachedAt;
}

class _CountsCacheEntry {
  const _CountsCacheEntry({required this.values, required this.cachedAt});

  final Map<String, int> values;
  final DateTime cachedAt;
}
