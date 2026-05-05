import 'package:flutter/material.dart';

class SearchHeader extends StatelessWidget {
  const SearchHeader({super.key, required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        IconButton(
          onPressed: onBack,
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        Text(
          'Search',
          style: TextStyle(
            fontSize: 31,
            fontWeight: FontWeight.w900,
            color: colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}
