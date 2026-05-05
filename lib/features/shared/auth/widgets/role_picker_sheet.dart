import 'package:flutter/material.dart';

import '../../../../domain/entities/app_user.dart';

class RolePickerSheet extends StatelessWidget {
  const RolePickerSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Select Your Role',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => Navigator.of(context).pop(AppUserRole.student),
              child: const Text('Student'),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () => Navigator.of(context).pop(AppUserRole.instructor),
              child: const Text('Instructor'),
            ),
          ],
        ),
      ),
    );
  }
}
