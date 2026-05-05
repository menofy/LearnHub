import 'package:flutter/material.dart';

class NotificationsHeader extends StatelessWidget {
  const NotificationsHeader({
    super.key,
    required this.embedded,
    required this.title,
  });

  final bool embedded;
  final String title;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        if (!embedded)
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back_rounded),
          ),
        Text(
          title,
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w900,
            color: colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}
