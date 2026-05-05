import 'package:flutter/material.dart';

import '../../../../domain/entities/app_notification.dart';
import 'notification_list_tile.dart';

class NotificationsSection extends StatelessWidget {
  const NotificationsSection({
    super.key,
    required this.title,
    required this.items,
    required this.onTap,
    this.onDelete,
  });

  final String title;
  final List<AppNotification> items;
  final ValueChanged<AppNotification> onTap;
  final ValueChanged<AppNotification>? onDelete;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: NotificationListTile(
                item: item,
                onTap: () => onTap(item),
                onDelete: onDelete != null ? () => onDelete!(item) : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
