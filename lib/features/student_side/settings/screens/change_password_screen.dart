import 'package:flutter/material.dart';
import 'package:learnhub/core/shared_widgets/edu_outline_button.dart';
import 'package:learnhub/core/shared_widgets/edu_primary_button.dart';
import 'package:learnhub/features/shared/auth/providers/auth_provider.dart';
import 'package:learnhub/features/student_side/settings/widgets/settings_screen_header.dart';
import 'package:learnhub/features/student_side/settings/widgets/settings_toggle_row.dart';
import 'package:provider/provider.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  bool _rememberMe = true;
  bool _biometric = true;
  bool _faceId = false;

  Future<void> _submit() async {
    final ok = await context.read<AuthProvider>().changePassword(
      currentPassword: '123456',
      newPassword: '1234567',
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? 'Password updated successfully.'
              : 'Unable to update password now.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            children: [
              const SettingsScreenHeader(title: 'Security'),
              const SizedBox(height: 10),
              SettingsToggleRow(
                label: 'Remember Me',
                value: _rememberMe,
                onChanged: (v) => setState(() => _rememberMe = v),
              ),
              SettingsToggleRow(
                label: 'Biometric ID',
                value: _biometric,
                onChanged: (v) => setState(() => _biometric = v),
              ),
              SettingsToggleRow(
                label: 'Face ID',
                value: _faceId,
                onChanged: (v) => setState(() => _faceId = v),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  'Google Authenticator',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                ),
                trailing: Icon(
                  Icons.chevron_right_rounded,
                  color: colorScheme.onSurface.withValues(alpha: 0.72),
                ),
                onTap: () {},
              ),
              const Spacer(),
              EduOutlineButton(label: 'Change PIN', onPressed: () {}),
              const SizedBox(height: 10),
              EduPrimaryButton(
                label: 'Change Password',
                onPressed: auth.isLoading ? null : _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
