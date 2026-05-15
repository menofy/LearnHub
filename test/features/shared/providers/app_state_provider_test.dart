import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:learnhub/domain/entities/course.dart';
import 'package:learnhub/domain/entities/notification_preferences.dart';
import 'package:learnhub/features/shared/providers/app_state_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('restores default local state and marks itself initialized', () async {
    final provider = AppStateProvider();
    await _waitUntilInitialized(provider);

    expect(provider.isInitialized, isTrue);
    expect(provider.hasSeenOnboarding, isFalse);
    expect(provider.language, 'English');
    expect(provider.locale, const Locale('en'));
    expect(provider.notifications, isNotEmpty);
    expect(provider.unreadNotificationsCount, 1);

    provider.dispose();
  });

  test('persists onboarding, language, theme, and recent searches', () async {
    final provider = AppStateProvider();
    await _waitUntilInitialized(provider);

    provider.completeOnboarding();
    provider.setLanguage('Arabic');
    provider.setThemeMode(ThemeMode.dark);
    provider.addRecentSearch('flutter');
    provider.addRecentSearch('firebase');
    provider.addRecentSearch('flutter');

    expect(provider.hasSeenOnboarding, isTrue);
    expect(provider.language, 'Arabic');
    expect(provider.locale, const Locale('ar'));
    expect(provider.themeMode, ThemeMode.dark);
    expect(provider.recentSearches, <String>['flutter', 'firebase']);

    provider.dispose();

    final restored = AppStateProvider();
    await _waitUntilInitialized(restored);

    expect(restored.hasSeenOnboarding, isTrue);
    expect(restored.language, 'Arabic');
    expect(restored.themeMode, ThemeMode.dark);
    expect(restored.recentSearches, <String>['flutter', 'firebase']);

    restored.dispose();
  });

  test('scopes recent searches per user and can clear user data', () async {
    final provider = AppStateProvider();
    await _waitUntilInitialized(provider);

    provider.addRecentSearch('guest search');
    await provider.loadForUser('user-1');
    provider.addRecentSearch('user search');

    expect(provider.recentSearches, <String>['user search']);

    await provider.loadForUser(null);
    expect(provider.recentSearches, <String>['guest search']);

    await provider.loadForUser('user-1');
    await provider.clearUserData(userId: 'user-1');
    expect(provider.recentSearches, isEmpty);
    expect(provider.notifications, isEmpty);

    provider.dispose();
  });

  test('syncs certificates from completed courses', () async {
    final provider = AppStateProvider();
    await _waitUntilInitialized(provider);

    provider.syncCertificatesFromCompletedCourses(const <Course>[
      Course(id: 'flutter-101', title: 'Flutter 101', category: 'Flutter'),
    ]);

    expect(provider.certificates, hasLength(1));
    expect(provider.certificates.first.id, 'cert_flutter-101');
    expect(provider.certificates.first.courseTitle, 'Flutter 101');
    expect(provider.certificateForCourseId('flutter-101'), isNotNull);
    expect(provider.certificateForCourseId('missing'), isNull);

    provider.dispose();
  });

  test('persists notification preferences per user', () async {
    final provider = AppStateProvider();
    await _waitUntilInitialized(provider);

    provider.updateNotificationPreferences(
      const NotificationPreferences(
        generalEnabled: true,
        soundEnabled: false,
        vibrateEnabled: true,
        offersEnabled: false,
        appUpdatesEnabled: true,
      ),
    );

    expect(provider.notificationPreferences.soundEnabled, isFalse);
    expect(provider.notificationPreferences.vibrateEnabled, isTrue);
    expect(provider.notificationPreferences.offersEnabled, isFalse);

    provider.dispose();

    final restored = AppStateProvider();
    await _waitUntilInitialized(restored);

    expect(restored.notificationPreferences.soundEnabled, isFalse);
    expect(restored.notificationPreferences.vibrateEnabled, isTrue);
    expect(restored.notificationPreferences.offersEnabled, isFalse);

    restored.dispose();
  });

  test('hides notifications from disabled categories', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'app_notifications_guest':
          '[{"id":"1","title":"Promo","body":"Promo body","createdAt":"2026-01-01T00:00:00.000","type":"offers","isRead":false},{"id":"2","title":"Update","body":"Update body","createdAt":"2026-01-02T00:00:00.000","type":"app_update","isRead":false}]',
    });

    final provider = AppStateProvider();
    await _waitUntilInitialized(provider);

    provider.updateNotificationPreferences(
      const NotificationPreferences(
        offersEnabled: false,
        appUpdatesEnabled: true,
      ),
    );

    expect(provider.notifications, hasLength(1));
    expect(provider.notifications.first.title, 'Update');
    expect(provider.unreadNotificationsCount, 1);

    provider.dispose();
  });
}

Future<void> _waitUntilInitialized(AppStateProvider provider) async {
  for (var i = 0; i < 20; i++) {
    if (provider.isInitialized) {
      return;
    }
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
  fail('AppStateProvider did not initialize.');
}
