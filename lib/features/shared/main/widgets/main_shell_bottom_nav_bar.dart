import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class MainShellBottomNavBar extends StatelessWidget {
  const MainShellBottomNavBar({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
  });

  final List<MainShellNavItemData> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(14, 8, 14, 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? const [Color(0xFF101A2D), Color(0xFF0D1525)]
                : const [Color(0xFFFFFFFF), Color(0xFFF7FBFF)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: isDark
                ? const Color(0xFF24324B)
                : const Color(AppColors.line),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.22 : 0.11),
              blurRadius: 30,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: Row(
          children: List<Widget>.generate(items.length, (index) {
            final item = items[index];
            return Expanded(
              child: _ShellNavItem(
                item: item,
                selected: index == currentIndex,
                baseColor: colorScheme.onSurface,
                onTap: () => onTap(index),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class MainShellNavItemData {
  const MainShellNavItemData({
    required this.label,
    required this.icon,
    required this.outlinedIcon,
  });

  final String label;
  final IconData icon;
  final IconData outlinedIcon;
}

class _ShellNavItem extends StatelessWidget {
  const _ShellNavItem({
    required this.item,
    required this.selected,
    required this.baseColor,
    required this.onTap,
  });

  final MainShellNavItemData item;
  final bool selected;
  final Color baseColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 7),
          decoration: BoxDecoration(
            gradient: selected
                ? const LinearGradient(
                    colors: [Color(0xFF1CCCBF), Color(0xFF13B6C5)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            borderRadius: BorderRadius.circular(22),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: const Color(
                        AppColors.primary,
                      ).withValues(alpha: 0.24),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                selected ? item.icon : item.outlinedIcon,
                size: 20,
                color: selected
                    ? Colors.white
                    : baseColor.withValues(alpha: 0.72),
              ),
              const SizedBox(height: 4),
              Text(
                item.label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: selected
                      ? Colors.white
                      : baseColor.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
