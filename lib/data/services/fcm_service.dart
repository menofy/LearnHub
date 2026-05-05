import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../domain/entities/app_notification.dart';
import 'firestore_service.dart';

/// Firebase Cloud Messaging service for handling push notifications.
///
/// This service manages:
/// - FCM token generation, storage, and refresh
/// - Foreground notification display
/// - Background notification handling
/// - Terminated app notification tap handling
/// - Integration with local notification system
class FCMService {
  FCMService._();
  static final FCMService _instance = FCMService._();
  factory FCMService() => _instance;

  static FCMService get instance => _instance;

  late final FirebaseMessaging _messaging;
  late final FlutterLocalNotificationsPlugin _localNotifications;

  static const String _highImportanceChannelId = 'learnhub_notifications';
  static const String _highImportanceChannelName = 'LearnHub Notifications';
  static const String _highImportanceChannelDescription =
      'Notifications from LearnHub';
  static const AndroidNotificationChannel _highImportanceChannel =
      AndroidNotificationChannel(
        _highImportanceChannelId,
        _highImportanceChannelName,
        description: _highImportanceChannelDescription,
        importance: Importance.max,
      );

  bool _isInitialized = false;
  String? _currentFcmToken;

  /// Callback for handling foreground notifications
  Function(AppNotification)? _onForegroundNotification;
  Function(AppNotification)? _onNotificationOpened;
  final List<AppNotification> _pendingOpenedNotifications =
      <AppNotification>[];

  Future<void> initialize() async {
    if (_isInitialized) {
      return;
    }

    _messaging = FirebaseMessaging.instance;
    _localNotifications = FlutterLocalNotificationsPlugin();

    await _initializeLocalNotifications();
    await _requestNotificationPermission();
    await _setupMessageHandlers();

    _isInitialized = true;
  }

  /// Generate and store FCM token for current user
  Future<String?> generateAndSaveFCMToken(String userId) async {
    try {
      final token = await _messaging.getToken();
      if (token == null || token.isEmpty) {
        developer.log('FCM token is null or empty', name: 'FCMService');
        return null;
      }

      _currentFcmToken = token;

      // Save to users collection
      await FirestoreService.instance.updateUserFCMToken(
        userId: userId,
        fcmToken: token,
      );

      // Save to fcm_tokens collection
      await FirestoreService.instance.saveFCMTokenRecord(
        userId: userId,
        token: token,
      );

      developer.log(
        'FCM token saved: ${token.substring(0, 20)}...',
        name: 'FCMService',
      );
      return token;
    } catch (e) {
      developer.log('Error generating FCM token: $e', name: 'FCMService');
      return null;
    }
  }

  /// Listen for FCM token refresh events
  StreamSubscription<String> listenForTokenRefresh(String userId) {
    return _messaging.onTokenRefresh.listen((newToken) {
      developer.log('FCM token refreshed', name: 'FCMService');
      generateAndSaveFCMToken(userId).ignore();
    });
  }

  /// Set callback for foreground notifications
  void setForegroundNotificationCallback(Function(AppNotification) callback) {
    _onForegroundNotification = callback;
  }

  /// Set callback for opened notifications from local/remote taps
  void setNotificationOpenedCallback(Function(AppNotification) callback) {
    _onNotificationOpened = callback;
    _flushPendingOpenedNotifications();
  }

  /// Get handler for background messages (must be top-level function)
  /// Usage: FirebaseMessaging.onBackgroundMessage(FCMService.handleBackgroundMessage)
  static Future<void> handleBackgroundMessage(RemoteMessage message) async {
    developer.log(
      'Handling background message: ${message.messageId}',
      name: 'FCMService',
    );
    // Background notifications are automatically handled by the system
    // Additional processing can be added here if needed
  }

  Future<void> _setupMessageHandlers() async {
    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle background message tap
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

    await _handleInitialMessage();
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    developer.log(
      'Foreground message received: ${message.messageId}',
      name: 'FCMService',
    );

    final notification = _parseNotification(message);
    if (notification != null) {
      // Display local notification banner
      await _displayLocalNotification(notification);

      // Trigger callback for app to sync
      _onForegroundNotification?.call(notification);
    }
  }

  void _handleMessageOpenedApp(RemoteMessage message) {
    developer.log(
      'Message opened app: ${message.messageId}',
      name: 'FCMService',
    );

    final notification = _parseNotification(message);
    if (notification != null) {
      _emitNotificationOpened(notification);
    }
  }

  Future<void> _initializeLocalNotifications() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const initSettings = InitializationSettings(android: android, iOS: ios);

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _handleLocalNotificationTap,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(_highImportanceChannel);

    final launchDetails = await _localNotifications
        .getNotificationAppLaunchDetails();
    if (launchDetails?.didNotificationLaunchApp ?? false) {
      final notification = _parseLocalNotificationPayload(
        launchDetails?.notificationResponse?.payload,
      );
      if (notification != null) {
        _emitNotificationOpened(notification);
      }
    }
  }

  Future<void> _displayLocalNotification(AppNotification notification) async {
    const android = AndroidNotificationDetails(
      _highImportanceChannelId,
      _highImportanceChannelName,
      channelDescription: _highImportanceChannelDescription,
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      enableLights: true,
    );

    const ios = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(android: android, iOS: ios);

    await _localNotifications.show(
      notification.id.hashCode,
      notification.title,
      notification.body,
      details,
      payload: _encodeNotificationPayload(notification),
    );
  }

  void _handleLocalNotificationTap(NotificationResponse response) {
    developer.log(
      'Local notification tapped: ${response.payload}',
      name: 'FCMService',
    );

    final notification = _parseLocalNotificationPayload(response.payload);
    if (notification != null) {
      _emitNotificationOpened(notification);
    }
  }

  Future<void> _requestNotificationPermission() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      announcement: true,
      badge: true,
      criticalAlert: false,
      provisional: true,
      sound: true,
    );

    developer.log(
      'Notification permission status: ${settings.authorizationStatus}',
      name: 'FCMService',
    );
  }

  /// Parse RemoteMessage into AppNotification
  AppNotification? _parseNotification(RemoteMessage message) {
    try {
      final data = message.data;
      final notification = message.notification;

      final title = data['title'] ?? notification?.title ?? '';
      final body = data['body'] ?? notification?.body ?? '';
      final typeValue = data['type'] ?? 'general';
      final courseId = data['courseId'];

      if (title.isEmpty || body.isEmpty) {
        return null;
      }

      return AppNotification(
        id: message.messageId ?? 'fcm_${DateTime.now().millisecondsSinceEpoch}',
        title: title,
        body: body,
        createdAt: DateTime.now(),
        type: AppNotificationTypeX.fromValue(typeValue),
        courseId: courseId,
        isRead: false,
      );
    } catch (e) {
      developer.log('Error parsing notification: $e', name: 'FCMService');
      return null;
    }
  }

  Future<void> _handleInitialMessage() async {
    final message = await _messaging.getInitialMessage();
    if (message == null) {
      return;
    }

    developer.log(
      'Initial message opened app: ${message.messageId}',
      name: 'FCMService',
    );

    final notification = _parseNotification(message);
    if (notification != null) {
      _emitNotificationOpened(notification);
    }
  }

  void _emitNotificationOpened(AppNotification notification) {
    if (_onNotificationOpened != null) {
      _onNotificationOpened!.call(notification);
      return;
    }

    _pendingOpenedNotifications.removeWhere((item) => item.id == notification.id);
    _pendingOpenedNotifications.add(notification);
  }

  void _flushPendingOpenedNotifications() {
    final callback = _onNotificationOpened;
    if (callback == null || _pendingOpenedNotifications.isEmpty) {
      return;
    }

    final pending = List<AppNotification>.from(_pendingOpenedNotifications);
    _pendingOpenedNotifications.clear();
    for (final notification in pending) {
      callback(notification);
    }
  }

  String _encodeNotificationPayload(AppNotification notification) {
    return jsonEncode(<String, dynamic>{
      'id': notification.id,
      'title': notification.title,
      'body': notification.body,
      'createdAt': notification.createdAt.toIso8601String(),
      'type': notification.type.value,
      'courseId': notification.courseId,
      'isRead': notification.isRead,
    });
  }

  AppNotification? _parseLocalNotificationPayload(String? payload) {
    if (payload == null || payload.isEmpty) {
      return null;
    }

    try {
      final decoded = jsonDecode(payload);
      if (decoded is! Map<String, dynamic>) {
        return null;
      }

      return AppNotification(
        id: decoded['id']?.toString() ?? '',
        title: decoded['title']?.toString() ?? '',
        body: decoded['body']?.toString() ?? '',
        createdAt:
            DateTime.tryParse(decoded['createdAt']?.toString() ?? '') ??
            DateTime.now(),
        type: AppNotificationTypeX.fromValue(decoded['type']?.toString()),
        courseId: decoded['courseId']?.toString(),
        isRead: decoded['isRead'] as bool? ?? false,
      );
    } catch (e) {
      developer.log(
        'Error parsing local notification payload: $e',
        name: 'FCMService',
      );
      return null;
    }
  }

  /// Cleanup FCM tokens for user (on logout)
  Future<void> clearFCMTokensForUser(String userId) async {
    try {
      await FirestoreService.instance.removeFCMToken(
        userId: userId,
        token: _currentFcmToken,
      );
      _currentFcmToken = null;
      developer.log('FCM tokens cleared for user', name: 'FCMService');
    } catch (e) {
      developer.log('Error clearing FCM tokens: $e', name: 'FCMService');
    }
  }

  /// Get current FCM token
  String? getCurrentToken() => _currentFcmToken;
}
