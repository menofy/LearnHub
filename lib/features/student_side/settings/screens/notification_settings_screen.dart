import 'package:flutter/material.dart';
import 'package:learnhub/domain/entities/notification_preferences.dart';
import 'package:learnhub/features/student_side/settings/widgets/settings_screen_header.dart';
import 'package:learnhub/features/student_side/settings/widgets/settings_toggle_row.dart';
import 'package:learnhub/features/shared/providers/app_state_provider.dart';
import 'package:provider/provider.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final appState = context.watch<AppStateProvider>();
    final preferences = appState.notificationPreferences;
    final toggles =
        <({String label, bool value, ValueChanged<bool> onChanged})>[
          (
            label: 'General Notifications',
            value: preferences.generalEnabled,
            onChanged: (value) {
              _updatePreferences(
                context,
                preferences.copyWith(generalEnabled: value),
              );
            },
          ),
          (
            label: 'Sound',
            value: preferences.soundEnabled,
            onChanged: (value) {
              _updatePreferences(
                context,
                preferences.copyWith(soundEnabled: value),
              );
            },
          ),
          (
            label: 'Vibrate',
            value: preferences.vibrateEnabled,
            onChanged: (value) {
              _updatePreferences(
                context,
                preferences.copyWith(vibrateEnabled: value),
              );
            },
          ),
          (
            label: 'Offers & Discounts',
            value: preferences.offersEnabled,
            onChanged: (value) {
              _updatePreferences(
                context,
                preferences.copyWith(offersEnabled: value),
              );
            },
          ),
          (
            label: 'App Updates',
            value: preferences.appUpdatesEnabled,
            onChanged: (value) {
              _updatePreferences(
                context,
                preferences.copyWith(appUpdatesEnabled: value),
              );
            },
          ),
        ];

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            children: [
              const SettingsScreenHeader(
                title: 'Notifications',
                subtitle:
                    'Pick the alerts students keep, hear, or feel in real time.',
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: colorScheme.outline.withValues(alpha: 0.45),
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  child: ListView.separated(
                    itemCount: toggles.length,
                    separatorBuilder: (context, index) => Divider(
                      height: 1,
                      color: colorScheme.outline.withValues(alpha: 0.18),
                    ),
                    itemBuilder: (context, index) {
                      final entry = toggles[index];
                      return SettingsToggleRow(
                        label: entry.label,
                        value: entry.value,
                        onChanged: entry.onChanged,
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _updatePreferences(
    BuildContext context,
    NotificationPreferences preferences,
  ) {
    context.read<AppStateProvider>().updateNotificationPreferences(preferences);
  }
}
