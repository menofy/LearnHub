import 'app_notification.dart';

class NotificationPreferences {
  const NotificationPreferences({
    this.generalEnabled = true,
    this.soundEnabled = true,
    this.vibrateEnabled = false,
    this.offersEnabled = true,
    this.appUpdatesEnabled = true,
  });

  final bool generalEnabled;
  final bool soundEnabled;
  final bool vibrateEnabled;
  final bool offersEnabled;
  final bool appUpdatesEnabled;

  NotificationPreferences copyWith({
    bool? generalEnabled,
    bool? soundEnabled,
    bool? vibrateEnabled,
    bool? offersEnabled,
    bool? appUpdatesEnabled,
  }) {
    return NotificationPreferences(
      generalEnabled: generalEnabled ?? this.generalEnabled,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      vibrateEnabled: vibrateEnabled ?? this.vibrateEnabled,
      offersEnabled: offersEnabled ?? this.offersEnabled,
      appUpdatesEnabled: appUpdatesEnabled ?? this.appUpdatesEnabled,
    );
  }

  bool allows(AppNotificationType type) {
    if (!generalEnabled) {
      return false;
    }

    switch (type) {
      case AppNotificationType.general:
        return true;
      case AppNotificationType.offers:
        return offersEnabled;
      case AppNotificationType.appUpdate:
        return appUpdatesEnabled;
    }
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'generalEnabled': generalEnabled,
      'soundEnabled': soundEnabled,
      'vibrateEnabled': vibrateEnabled,
      'offersEnabled': offersEnabled,
      'appUpdatesEnabled': appUpdatesEnabled,
    };
  }

  static NotificationPreferences fromMap(Map<String, dynamic>? map) {
    if (map == null) {
      return const NotificationPreferences();
    }

    return NotificationPreferences(
      generalEnabled: map['generalEnabled'] as bool? ?? true,
      soundEnabled: map['soundEnabled'] as bool? ?? true,
      vibrateEnabled: map['vibrateEnabled'] as bool? ?? false,
      offersEnabled: map['offersEnabled'] as bool? ?? true,
      appUpdatesEnabled: map['appUpdatesEnabled'] as bool? ?? true,
    );
  }
}
