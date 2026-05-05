import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class HomeGreetingHeader extends StatelessWidget {
  const HomeGreetingHeader({
    super.key,
    required this.userName,
    required this.unreadCount,
    required this.onNotificationsTap,
  });

  final String userName;
  final int unreadCount;
  final VoidCallback onNotificationsTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final secondaryTextColor = onSurface.withValues(alpha: 0.7);

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hello, $userName \u{1F44B}',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'What would you like to learn today?',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: secondaryTextColor,
                ),
              ),
            ],
          ),
        ),
        InkWell(
          onTap: onNotificationsTap,
          borderRadius: BorderRadius.circular(18),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: const Color(AppColors.primary),
                    width: 1.3,
                  ),
                ),
                child: const Icon(
                  Icons.notifications_none_rounded,
                  color: Color(AppColors.primary),
                  size: 20,
                ),
              ),
              if (unreadCount > 0)
                Positioned(
                  top: -4,
                  right: -4,
                  child: Container(
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(AppColors.primary),
                      borderRadius: BorderRadius.circular(9),
                      border: Border.all(
                        color: theme.scaffoldBackgroundColor,
                        width: 1.5,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      unreadCount > 9 ? '9+' : '$unreadCount',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
