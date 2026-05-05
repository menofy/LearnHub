enum AppNotificationType { general, offers, appUpdate }

extension AppNotificationTypeX on AppNotificationType {
  String get value {
    switch (this) {
      case AppNotificationType.general:
        return 'general';
      case AppNotificationType.offers:
        return 'offers';
      case AppNotificationType.appUpdate:
        return 'app_update';
    }
  }

  static AppNotificationType fromValue(String? value) {
    switch ((value ?? '').trim().toLowerCase()) {
      case 'offers':
        return AppNotificationType.offers;
      case 'app_update':
      case 'appupdate':
        return AppNotificationType.appUpdate;
      default:
        return AppNotificationType.general;
    }
  }
}

class AppNotification {
  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.createdAt,
    this.type = AppNotificationType.general,
    this.courseId,
    this.isRead = false,
  });

  final String id;
  final String title;
  final String body;
  final DateTime createdAt;
  final AppNotificationType type;
  final String? courseId;
  final bool isRead;

  AppNotification copyWith({
    String? id,
    String? title,
    String? body,
    DateTime? createdAt,
    AppNotificationType? type,
    String? courseId,
    bool? isRead,
  }) {
    return AppNotification(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      createdAt: createdAt ?? this.createdAt,
      type: type ?? this.type,
      courseId: courseId ?? this.courseId,
      isRead: isRead ?? this.isRead,
    );
  }
}
