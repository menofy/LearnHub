import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/navigation/app_navigator.dart';
import '../../data/services/fcm_service.dart';
import '../../data/services/firestore_service.dart';
import '../../domain/entities/app_notification.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/entities/certificate.dart';
import '../../domain/entities/course.dart';
import '../../domain/entities/notification_preferences.dart';

class AppStateProvider extends ChangeNotifier {
  AppStateProvider() {
    FCMService.instance.setForegroundNotificationCallback(
      _handleForegroundNotification,
    );
    FCMService.instance.setNotificationOpenedCallback(
      _handleOpenedNotification,
    );
    _restoreLocalState();
  }

  static const String _guestUserKey = 'guest';
  static const String _kSeenOnboarding = 'app_seen_onboarding';
  static const String _kThemeMode = 'app_theme_mode';
  static const String _kLanguage = 'app_language';
  static const String _kRecentSearches = 'app_recent_searches';
  static const String _kNotifications = 'app_notifications';
  static const String _kNotificationPreferences = 'app_notification_preferences';
  static const String _kCertificates = 'app_certificates';
  static const int _maxRecentSearches = 8;

  SharedPreferences? _prefs;
  bool _isInitialized = false;
  bool _hasSeenOnboarding = false;
  ThemeMode _themeMode = ThemeMode.system;
  String _language = 'English';
  String _localStateUserKey = '';
  AppUserRole? _localStateUserRole;
  bool _isDisposed = false;

  List<String> _recentSearches = <String>[];
  List<AppNotification> _notifications = <AppNotification>[];
  NotificationPreferences _notificationPreferences =
      const NotificationPreferences();
  List<Certificate> _certificates = <Certificate>[];

  StreamSubscription<List<AppNotification>>? _notificationsSubscription;
  StreamSubscription<String>? _fcmTokenRefreshSubscription;
  bool _hasHydratedNotificationStream = false;

  bool get hasSeenOnboarding => _hasSeenOnboarding;
  bool get isInitialized => _isInitialized;
  ThemeMode get themeMode => _themeMode;
  String get language => _language;
  bool get isArabic => _language == 'Arabic';
  Locale get locale => isArabic ? const Locale('ar') : const Locale('en');

  List<String> get recentSearches => List<String>.unmodifiable(_recentSearches);
  List<AppNotification> get notifications =>
      List<AppNotification>.unmodifiable(_filteredNotifications(_notifications));
  List<Certificate> get certificates =>
      List<Certificate>.unmodifiable(_certificates);
  NotificationPreferences get notificationPreferences =>
      _notificationPreferences;

  int get unreadNotificationsCount =>
      notifications.where((notification) => !notification.isRead).length;

  Future<void> _restoreLocalState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_isDisposed) {
        return;
      }

      _prefs = prefs;
      _hasSeenOnboarding = prefs.getBool(_kSeenOnboarding) ?? false;
      _language = prefs.getString(_kLanguage) ?? 'English';

      final savedThemeIndex = prefs.getInt(_kThemeMode);
      if (savedThemeIndex != null &&
          savedThemeIndex >= 0 &&
          savedThemeIndex < ThemeMode.values.length) {
        _themeMode = ThemeMode.values[savedThemeIndex];
      }

      await loadForUser(null, notify: false);
    } catch (_) {
      _recentSearches = <String>[];
      _notifications = _defaultNotificationsForScope(_guestUserKey);
      _notificationPreferences = const NotificationPreferences();
      _certificates = <Certificate>[];
      _localStateUserKey = _guestUserKey;
      _localStateUserRole = null;
    } finally {
      _isInitialized = true;
      _notifyIfActive();
    }
  }

  Future<void> loadForUser(
    String? userId, {
    AppUserRole? role,
    bool notify = true,
  }) async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    if (_isDisposed) {
      return;
    }

    _prefs = prefs;

    final nextUserKey = _normalizeUserStorageKey(userId);
    final nextRole = role;
    final normalizedUserId = userId?.trim() ?? '';
    final isSameScope =
        nextUserKey == _localStateUserKey && nextRole == _localStateUserRole;
    final needsRemoteRebind =
        normalizedUserId.isNotEmpty &&
        role != null &&
        (_notificationsSubscription == null ||
            _fcmTokenRefreshSubscription == null);

    if (isSameScope && !needsRemoteRebind) {
      if (notify) {
        _notifyIfActive();
      }
      return;
    }

    await _notificationsSubscription?.cancel();
    _notificationsSubscription = null;
    await _fcmTokenRefreshSubscription?.cancel();
    _fcmTokenRefreshSubscription = null;
    _hasHydratedNotificationStream = false;

    _localStateUserKey = nextUserKey;
    _localStateUserRole = nextRole;
    _recentSearches =
        prefs.getStringList(_scopedKey(_kRecentSearches)) ?? <String>[];
    _notifications =
        _decodeNotifications(prefs.getString(_scopedKey(_kNotifications))) ??
        _defaultNotificationsForScope(nextUserKey);
    _notificationPreferences =
        _decodeNotificationPreferences(
          prefs.getString(_scopedKey(_kNotificationPreferences)),
        ) ??
        const NotificationPreferences();
    _certificates =
        _decodeCertificates(prefs.getString(_scopedKey(_kCertificates))) ??
        <Certificate>[];

    if (normalizedUserId.isNotEmpty && role != null) {
      await _startNotificationSync(normalizedUserId, role);
    }

    if (notify) {
      _notifyIfActive();
    }
  }

  void completeOnboarding() {
    if (_hasSeenOnboarding) {
      return;
    }

    _hasSeenOnboarding = true;
    _prefs?.setBool(_kSeenOnboarding, true);
    _notifyIfActive();
  }

  void setThemeMode(ThemeMode mode) {
    if (_themeMode == mode) {
      return;
    }

    _themeMode = mode;
    _prefs?.setInt(_kThemeMode, mode.index);
    _notifyIfActive();
  }

  void setLanguage(String value) {
    final normalized = value == 'Arabic' ? 'Arabic' : 'English';
    if (_language == normalized) {
      return;
    }

    _language = normalized;
    _prefs?.setString(_kLanguage, normalized);
    _notifyIfActive();
  }

  void addRecentSearch(String query) {
    final value = query.trim();
    if (value.isEmpty) {
      return;
    }

    _recentSearches.remove(value);
    _recentSearches.insert(0, value);

    if (_recentSearches.length > _maxRecentSearches) {
      _recentSearches = _recentSearches.take(_maxRecentSearches).toList();
    }

    _persistRecentSearches();
    _notifyIfActive();
  }

  void removeRecentSearch(String query) {
    final value = query.trim();
    if (value.isEmpty) {
      return;
    }

    final changed = _recentSearches.remove(value);
    if (!changed) {
      return;
    }

    _persistRecentSearches();
    _notifyIfActive();
  }

  void clearRecentSearches() {
    if (_recentSearches.isEmpty) {
      return;
    }

    _recentSearches = <String>[];
    _persistRecentSearches();
    _notifyIfActive();
  }

  void markNotificationRead(String notificationId) {
    var didChange = false;
    _notifications = _notifications.map((notification) {
      if (notification.id != notificationId || notification.isRead) {
        return notification;
      }
      didChange = true;
      return notification.copyWith(isRead: true);
    }).toList(growable: false);

    if (!didChange) {
      return;
    }

    _persistNotifications();
    _notifyIfActive();
  }

  void markAllNotificationsAsRead() {
    final hasUnread = _notifications.any((notification) => !notification.isRead);
    if (!hasUnread) {
      return;
    }

    _notifications = _notifications
        .map((notification) => notification.copyWith(isRead: true))
        .toList(growable: false);
    _persistNotifications();
    _notifyIfActive();
  }

  void deleteNotification(String notificationId) {
    final initialLength = _notifications.length;
    _notifications = _notifications
        .where((notification) => notification.id != notificationId)
        .toList(growable: false);

    if (_notifications.length == initialLength) {
      return;
    }

    _persistNotifications();
    _notifyIfActive();
  }

  void deleteAllReadNotifications() {
    final initialLength = _notifications.length;
    _notifications = _notifications
        .where((notification) => !notification.isRead)
        .toList(growable: false);

    if (_notifications.length == initialLength) {
      return;
    }

    _persistNotifications();
    _notifyIfActive();
  }

  void clearNotifications() {
    if (_notifications.isEmpty) {
      return;
    }

    _notifications = <AppNotification>[];
    _persistNotifications();
    _notifyIfActive();
  }

  void updateNotificationPreferences(NotificationPreferences preferences) {
    if (_sameNotificationPreferences(_notificationPreferences, preferences)) {
      return;
    }

    _notificationPreferences = preferences;
    _persistNotificationPreferences();
    _notifyIfActive();
  }

  Certificate? certificateForCourseId(String courseId) {
    final expectedId = 'cert_$courseId';
    for (final certificate in _certificates) {
      if (certificate.id == expectedId) {
        return certificate;
      }
    }
    return null;
  }

  void syncCertificatesFromCompletedCourses(Iterable<Course> completedCourses) {
    final previousById = <String, Certificate>{
      for (final certificate in _certificates) certificate.id: certificate,
    };

    final nextCertificates =
        completedCourses
            .map((course) {
              final certificateId = 'cert_${course.id}';
              final existing = previousById[certificateId];
              return Certificate(
                id: certificateId,
                courseTitle: course.title,
                issueDate: existing?.issueDate ?? DateTime.now(),
                grade: existing?.grade ?? 'Completed',
              );
            })
            .toList(growable: false)
          ..sort((a, b) => b.issueDate.compareTo(a.issueDate));

    if (_sameCertificates(nextCertificates, _certificates)) {
      return;
    }

    _certificates = nextCertificates;
    _persistCertificates();
    _notifyIfActive();
  }

  Future<void> clearUserData({String? userId}) async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    if (_isDisposed) {
      return;
    }

    _prefs = prefs;
    final scopedUserKey = _normalizeUserStorageKey(userId);

    await prefs.remove(_scopedKeyFor(_kRecentSearches, scopedUserKey));
    await prefs.remove(_scopedKeyFor(_kNotifications, scopedUserKey));
    await prefs.remove(_scopedKeyFor(_kNotificationPreferences, scopedUserKey));
    await prefs.remove(_scopedKeyFor(_kCertificates, scopedUserKey));

    final normalizedUserId = userId?.trim() ?? '';
    if (normalizedUserId.isNotEmpty) {
      await FCMService.instance.clearFCMTokensForUser(normalizedUserId);
    }

    if (_localStateUserKey != scopedUserKey) {
      return;
    }

    await _notificationsSubscription?.cancel();
    _notificationsSubscription = null;
    await _fcmTokenRefreshSubscription?.cancel();
    _fcmTokenRefreshSubscription = null;

    _recentSearches = <String>[];
    _notifications = <AppNotification>[];
    _notificationPreferences = const NotificationPreferences();
    _certificates = <Certificate>[];
    _hasHydratedNotificationStream = false;
    _notifyIfActive();
  }

  Future<void> _startNotificationSync(
    String userId,
    AppUserRole role,
  ) async {
    try {
      await FCMService.instance.generateAndSaveFCMToken(userId);
      _fcmTokenRefreshSubscription = FCMService.instance.listenForTokenRefresh(
        userId,
      );
    } catch (_) {
      _fcmTokenRefreshSubscription = null;
    }

    try {
      _notificationsSubscription = FirestoreService.instance
          .streamNotificationsForUser(userId: userId, role: role)
          .listen(
            _handleRemoteNotifications,
            onError: (_) {
              _hasHydratedNotificationStream = true;
            },
          );
    } catch (_) {
      _notificationsSubscription = null;
      _hasHydratedNotificationStream = true;
    }
  }

  void _handleForegroundNotification(AppNotification notification) {
    if (!_notificationPreferences.allows(notification.type)) {
      return;
    }

    _addNotificationIfMissing(notification, notify: true);
  }

  void _handleOpenedNotification(AppNotification notification) {
    _addNotificationIfMissing(notification, notify: true);
    AppNavigator.openNotificationsScreen();
  }

  void _handleRemoteNotifications(List<AppNotification> remoteNotifications) {
    final previousNotifications = List<AppNotification>.from(_notifications);
    final previousIds = previousNotifications
        .map((notification) => notification.id)
        .toSet();
    final readById = <String, bool>{
      for (final notification in previousNotifications)
        notification.id: notification.isRead,
    };

    final merged = <AppNotification>[
      for (final remote in remoteNotifications)
        remote.copyWith(isRead: readById[remote.id] ?? false),
      ...previousNotifications.where(
        (notification) =>
            !remoteNotifications.any((remote) => remote.id == notification.id),
      ),
    ]..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    _notifications = merged;
    _persistNotifications();

    if (_hasHydratedNotificationStream) {
      final hasFreshVisibleNotifications = merged.any(
        (notification) =>
            !previousIds.contains(notification.id) &&
            _notificationPreferences.allows(notification.type),
      );
      if (hasFreshVisibleNotifications) {
        _signalNotificationDelivery();
      }
    } else {
      _hasHydratedNotificationStream = true;
    }

    _notifyIfActive();
  }

  void _addNotificationIfMissing(
    AppNotification notification, {
    required bool notify,
  }) {
    final existingIndex = _notifications.indexWhere(
      (item) => item.id == notification.id,
    );

    if (existingIndex == -1) {
      _notifications.insert(0, notification);
      _notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      _persistNotifications();
      if (notify) {
        _notifyIfActive();
      }
      return;
    }

    final existing = _notifications[existingIndex];
    if (_sameNotification(existing, notification)) {
      return;
    }

    _notifications[existingIndex] = existing.copyWith(
      title: notification.title,
      body: notification.body,
      createdAt: notification.createdAt,
      type: notification.type,
      courseId: notification.courseId,
      isRead: existing.isRead,
    );
    _notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    _persistNotifications();
    if (notify) {
      _notifyIfActive();
    }
  }

  List<AppNotification> _filteredNotifications(
    List<AppNotification> notifications,
  ) {
    final visible = notifications
        .where((notification) => _notificationPreferences.allows(notification.type))
        .toList(growable: false)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return visible;
  }

  List<AppNotification> _defaultNotificationsForScope(String scopeKey) {
    if (scopeKey != _guestUserKey) {
      return <AppNotification>[];
    }

    return <AppNotification>[
      AppNotification(
        id: 'notif_${scopeKey}_1',
        title: 'Welcome to LearnHub',
        body: 'Your learning dashboard is ready to explore.',
        createdAt: DateTime.now().subtract(const Duration(hours: 3)),
        type: AppNotificationType.general,
      ),
      AppNotification(
        id: 'notif_${scopeKey}_2',
        title: 'Keep your streak alive',
        body: 'Come back and continue your enrolled courses today.',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        type: AppNotificationType.general,
        isRead: true,
      ),
    ];
  }

  List<AppNotification>? _decodeNotifications(String? raw) {
    if (raw == null || raw.isEmpty) {
      return null;
    }

    final Object? parsed;
    try {
      parsed = jsonDecode(raw);
    } catch (_) {
      return null;
    }

    if (parsed is! List) {
      return null;
    }

    return parsed
        .map((item) => item is Map ? _notificationFromMap(item) : null)
        .whereType<AppNotification>()
        .toList(growable: false);
  }

  NotificationPreferences? _decodeNotificationPreferences(String? raw) {
    if (raw == null || raw.isEmpty) {
      return null;
    }

    final Object? parsed;
    try {
      parsed = jsonDecode(raw);
    } catch (_) {
      return null;
    }

    if (parsed is! Map) {
      return null;
    }

    return NotificationPreferences.fromMap(
      parsed.map<String, dynamic>((key, value) {
        return MapEntry(key.toString(), value);
      }),
    );
  }

  List<Certificate>? _decodeCertificates(String? raw) {
    if (raw == null || raw.isEmpty) {
      return null;
    }

    final Object? parsed;
    try {
      parsed = jsonDecode(raw);
    } catch (_) {
      return null;
    }

    if (parsed is! List) {
      return null;
    }

    return parsed
        .map((item) => item is Map ? _certificateFromMap(item) : null)
        .whereType<Certificate>()
        .toList(growable: false);
  }

  AppNotification? _notificationFromMap(Map<dynamic, dynamic> item) {
    final id = item['id']?.toString() ?? '';
    final title = item['title']?.toString() ?? '';
    final body = item['body']?.toString() ?? '';

    if (id.isEmpty || title.isEmpty || body.isEmpty) {
      return null;
    }

    return AppNotification(
      id: id,
      title: title,
      body: body,
      createdAt:
          DateTime.tryParse(item['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      type: AppNotificationTypeX.fromValue(item['type']?.toString()),
      courseId: item['courseId']?.toString(),
      isRead: item['isRead'] as bool? ?? false,
    );
  }

  Certificate? _certificateFromMap(Map<dynamic, dynamic> item) {
    final id = item['id']?.toString() ?? '';
    final courseTitle = item['courseTitle']?.toString() ?? '';
    if (id.isEmpty || courseTitle.isEmpty) {
      return null;
    }

    return Certificate(
      id: id,
      courseTitle: courseTitle,
      issueDate:
          DateTime.tryParse(item['issueDate']?.toString() ?? '') ??
          DateTime.now(),
      grade: item['grade']?.toString() ?? 'Completed',
    );
  }

  void _persistRecentSearches() {
    _prefs?.setStringList(_scopedKey(_kRecentSearches), _recentSearches);
  }

  void _persistNotifications() {
    _prefs?.setString(
      _scopedKey(_kNotifications),
      jsonEncode(
        _notifications
            .map(
              (notification) => <String, dynamic>{
                'id': notification.id,
                'title': notification.title,
                'body': notification.body,
                'createdAt': notification.createdAt.toIso8601String(),
                'type': notification.type.value,
                'courseId': notification.courseId,
                'isRead': notification.isRead,
              },
            )
            .toList(growable: false),
      ),
    );
  }

  void _persistNotificationPreferences() {
    _prefs?.setString(
      _scopedKey(_kNotificationPreferences),
      jsonEncode(_notificationPreferences.toMap()),
    );
  }

  void _persistCertificates() {
    _prefs?.setString(
      _scopedKey(_kCertificates),
      jsonEncode(
        _certificates
            .map(
              (certificate) => <String, dynamic>{
                'id': certificate.id,
                'courseTitle': certificate.courseTitle,
                'issueDate': certificate.issueDate.toIso8601String(),
                'grade': certificate.grade,
              },
            )
            .toList(growable: false),
      ),
    );
  }

  void _signalNotificationDelivery() {
    if (_notificationPreferences.soundEnabled) {
      SystemSound.play(SystemSoundType.alert);
    }
    if (_notificationPreferences.vibrateEnabled) {
      HapticFeedback.mediumImpact();
    }
  }

  String _normalizeUserStorageKey(String? userId) {
    final trimmed = userId?.trim() ?? '';
    return trimmed.isEmpty ? _guestUserKey : trimmed;
  }

  String _scopedKey(String baseKey) => _scopedKeyFor(baseKey, _localStateUserKey);

  String _scopedKeyFor(String baseKey, String scopeKey) {
    return '${baseKey}_$scopeKey';
  }

  bool _sameNotification(AppNotification a, AppNotification b) {
    return a.id == b.id &&
        a.title == b.title &&
        a.body == b.body &&
        a.createdAt == b.createdAt &&
        a.type == b.type &&
        a.courseId == b.courseId &&
        a.isRead == b.isRead;
  }

  bool _sameCertificates(List<Certificate> a, List<Certificate> b) {
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
          left.courseTitle != right.courseTitle ||
          left.issueDate != right.issueDate ||
          left.grade != right.grade) {
        return false;
      }
    }

    return true;
  }

  bool _sameNotificationPreferences(
    NotificationPreferences a,
    NotificationPreferences b,
  ) {
    return a.generalEnabled == b.generalEnabled &&
        a.soundEnabled == b.soundEnabled &&
        a.vibrateEnabled == b.vibrateEnabled &&
        a.offersEnabled == b.offersEnabled &&
        a.appUpdatesEnabled == b.appUpdatesEnabled;
  }

  void _notifyIfActive() {
    if (!_isDisposed) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _notificationsSubscription?.cancel();
    _fcmTokenRefreshSubscription?.cancel();
    super.dispose();
  }
}
