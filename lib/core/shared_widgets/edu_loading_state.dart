import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

class EduLoadingState extends StatelessWidget {
  const EduLoadingState({
    super.key,
    this.message = 'Loading...',
    this.subtitle,
    this.compact = false,
  });

  final String message;
  final String? subtitle;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: compact ? 58 : 74,
          height: compact ? 58 : 74,
          decoration: BoxDecoration(
            color: const Color(AppColors.primary).withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Padding(
            padding: EdgeInsets.all(16),
            child: CircularProgressIndicator(
              strokeWidth: 3.2,
              valueColor: AlwaysStoppedAnimation<Color>(
                Color(AppColors.primary),
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: compact ? 15 : 18,
            fontWeight: FontWeight.w900,
            color: colorScheme.onSurface,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 6),
          Text(
            subtitle!,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              height: 1.45,
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface.withValues(alpha: 0.72),
            ),
          ),
        ],
      ],
    );

    return Center(
      child: Padding(padding: const EdgeInsets.all(24), child: content),
    );
  }
}
