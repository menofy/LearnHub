import 'package:flutter/material.dart';
import 'package:learnhub/core/shared_widgets/empty_state.dart';
import 'package:learnhub/features/shared/providers/app_state_provider.dart';
import 'package:provider/provider.dart';

import 'package:learnhub/core/navigation/app_routes.dart';
import '../../../core/navigation/route_args.dart';
import '../../../domain/entities/app_notification.dart';
import 'widgets/notifications_header.dart';
import 'widgets/notifications_section.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppStateProvider>();
    final notifications = appState.notifications;
    final notificationsEnabled =
        appState.notificationPreferences.generalEnabled;
    final hasUnread = appState.unreadNotificationsCount > 0;

    final todayItems = notifications
        .where((item) => _isToday(item.createdAt))
        .toList(growable: false);
    final yesterdayItems = notifications
        .where((item) => _isYesterday(item.createdAt))
        .toList(growable: false);
    final olderItems = notifications
        .where(
          (item) => !_isToday(item.createdAt) && !_isYesterday(item.createdAt),
        )
        .toList(growable: false);

    final content = SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: NotificationsHeader(
                    embedded: embedded,
                    title: 'Notifications',
                  ),
                ),
                if (hasUnread && notifications.isNotEmpty)
                  TextButton(
                    onPressed: () {
                      context
                          .read<AppStateProvider>()
                          .markAllNotificationsAsRead();
                    },
                    child: const Text(
                      'Mark all as read',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: notifications.isEmpty
                  ? EmptyState(
                      icon: Icons.notifications_none_rounded,
                      title: notificationsEnabled
                          ? 'No notifications'
                          : 'Notifications are paused',
                      subtitle: notificationsEnabled
                          ? 'You are all caught up.'
                          : 'Turn General Notifications back on from settings to see new alerts.',
                    )
                  : ListView(
                      children: [
                        NotificationsSection(
                          title: 'Today',
                          items: todayItems,
                          onTap: (item) => _open(context, item),
                          onDelete: (item) => context
                              .read<AppStateProvider>()
                              .deleteNotification(item.id),
                        ),
                        NotificationsSection(
                          title: 'Yesterday',
                          items: yesterdayItems,
                          onTap: (item) => _open(context, item),
                          onDelete: (item) => context
                              .read<AppStateProvider>()
                              .deleteNotification(item.id),
                        ),
                        NotificationsSection(
                          title: 'Older',
                          items: olderItems,
                          onTap: (item) => _open(context, item),
                          onDelete: (item) => context
                              .read<AppStateProvider>()
                              .deleteNotification(item.id),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );

    if (embedded) {
      return content;
    }

    return Scaffold(body: content);
  }

  void _open(BuildContext context, AppNotification item) {
    context.read<AppStateProvider>().markNotificationRead(item.id);
    Navigator.of(context).pushNamed(
      AppRoutes.notificationDetails,
      arguments: NotificationDetailsArgs(notification: item),
    );
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  bool _isYesterday(DateTime date) {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return date.year == yesterday.year &&
        date.month == yesterday.month &&
        date.day == yesterday.day;
  }
}
