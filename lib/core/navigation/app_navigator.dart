import 'package:flutter/material.dart';

import 'app_routes.dart';

class AppNavigator {
  AppNavigator._();

  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();
  static final NavigatorObserver observer = _AppNavigatorObserver();

  static String? _currentRouteName;
  static bool _hasPendingNotificationsOpen = false;
  static bool _isOpeningNotifications = false;

  static String? get currentRouteName => _currentRouteName;

  static void didChangeRoute(String? routeName) {
    _currentRouteName = routeName;
    _flushPendingNotifications();
  }

  static void openNotificationsScreen() {
    if (_currentRouteName == AppRoutes.notifications) {
      _hasPendingNotificationsOpen = false;
      return;
    }

    if (!_canNavigateNow) {
      _hasPendingNotificationsOpen = true;
      return;
    }

    _pushNotificationsScreen();
  }

  static bool get _canNavigateNow {
    return navigatorKey.currentState != null &&
        _currentRouteName != null &&
        _currentRouteName != AppRoutes.splash;
  }

  static void _flushPendingNotifications() {
    if (!_hasPendingNotificationsOpen || !_canNavigateNow) {
      return;
    }

    _pushNotificationsScreen();
  }

  static void _pushNotificationsScreen() {
    if (_isOpeningNotifications) {
      return;
    }

    _isOpeningNotifications = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = navigatorKey.currentState;
      if (state != null && _currentRouteName != AppRoutes.notifications) {
        state.pushNamed(AppRoutes.notifications);
      }
      _hasPendingNotificationsOpen = false;
      _isOpeningNotifications = false;
    });
  }
}

class _AppNavigatorObserver extends NavigatorObserver {
  void _syncRoute(Route<dynamic>? route) {
    AppNavigator.didChangeRoute(route?.settings.name);
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    _syncRoute(route);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    _syncRoute(previousRoute);
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didRemove(route, previousRoute);
    _syncRoute(previousRoute);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    _syncRoute(newRoute);
  }
}
