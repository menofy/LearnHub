import 'package:flutter/material.dart';

Future<bool> showDiscardChangesDialog(
  BuildContext context, {
  String title = 'Discard changes?',
  String message =
      'You have unsaved changes on this screen. If you leave now, they will be lost.',
  String confirmLabel = 'Discard',
  String cancelLabel = 'Keep Editing',
}) async {
  final shouldDiscard = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(cancelLabel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(confirmLabel),
          ),
        ],
      );
    },
  );

  return shouldDiscard ?? false;
}
