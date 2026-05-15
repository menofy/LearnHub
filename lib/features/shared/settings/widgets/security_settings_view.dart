import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:learnhub/core/auth_constants.dart';
import 'package:learnhub/core/shared_widgets/edu_outline_button.dart';
import 'package:learnhub/core/shared_widgets/edu_primary_button.dart';
import 'package:learnhub/features/shared/auth/providers/auth_provider.dart';
import 'package:learnhub/features/student_side/settings/widgets/settings_screen_header.dart';
import 'package:learnhub/features/student_side/settings/widgets/settings_toggle_row.dart';
import 'package:local_auth/local_auth.dart';
import 'package:provider/provider.dart';

class SecuritySettingsView extends StatefulWidget {
  const SecuritySettingsView({super.key});

  @override
  State<SecuritySettingsView> createState() => _SecuritySettingsViewState();
}

class _SecuritySettingsViewState extends State<SecuritySettingsView> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final LocalAuthentication _localAuth = LocalAuthentication();
  bool _showCurrentPassword = false;
  bool _showNewPassword = false;
  bool _showConfirmPassword = false;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_newPasswordController.text != _confirmPasswordController.text) {
      _showMessage('New password and confirmation do not match.');
      return;
    }

    final auth = context.read<AuthProvider>();
    auth.clearError();

    final ok = await auth.changePassword(
      currentPassword: _currentPasswordController.text,
      newPassword: _newPasswordController.text,
    );

    if (!mounted) {
      return;
    }

    if (ok) {
      _currentPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();
      _showMessage(auth.statusMessage ?? 'Password updated successfully.');
      return;
    }

    _showMessage(auth.errorMessage ?? 'Unable to update password right now.');
  }

  Future<void> _handleRememberChanged(bool value) async {
    final auth = context.read<AuthProvider>();
    await auth.setRememberMeEnabled(value);
    if (!mounted) {
      return;
    }
    _showMessage(
      value
          ? 'Your session will be remembered on this device.'
          : 'Your session will end after you close and reopen the app.',
    );
  }

  Future<void> _handleBiometricChanged(bool value) async {
    final auth = context.read<AuthProvider>();
    if (!value) {
      await auth.setBiometricEnabled(false);
      if (!mounted) {
        return;
      }
      _showMessage('Biometric unlock disabled.');
      return;
    }

    final enabled = await _authenticateForSetup(
      requiresFaceOnly: false,
      unsupportedMessage:
          'This device does not support biometric authentication.',
      reason: 'Confirm your biometric to enable biometric unlock',
    );
    if (!enabled || !mounted) {
      return;
    }

    await auth.setBiometricEnabled(true);
    if (!mounted) {
      return;
    }
    _showMessage('Biometric unlock enabled.');
  }

  Future<void> _handleFaceIdChanged(bool value) async {
    final auth = context.read<AuthProvider>();
    if (!value) {
      await auth.setFaceIdEnabled(false);
      if (!mounted) {
        return;
      }
      _showMessage('Face ID disabled.');
      return;
    }

    final enabled = await _authenticateForSetup(
      requiresFaceOnly: true,
      unsupportedMessage: 'Face ID is not available on this device.',
      reason: 'Confirm Face ID to enable face unlock',
    );
    if (!enabled || !mounted) {
      return;
    }

    await auth.setFaceIdEnabled(true);
    if (!mounted) {
      return;
    }
    _showMessage('Face ID enabled.');
  }

  Future<bool> _authenticateForSetup({
    required bool requiresFaceOnly,
    required String unsupportedMessage,
    required String reason,
  }) async {
    try {
      final isSupported = await _localAuth.isDeviceSupported();
      final canCheck = await _localAuth.canCheckBiometrics;
      if (!isSupported || !canCheck) {
        _showMessage(unsupportedMessage);
        return false;
      }

      final available = await _localAuth.getAvailableBiometrics();
      final supportsRequestedMode = requiresFaceOnly
          ? available.contains(BiometricType.face)
          : available.isNotEmpty;
      if (!supportsRequestedMode) {
        _showMessage(unsupportedMessage);
        return false;
      }

      final authenticated = await _localAuth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
          useErrorDialogs: true,
        ),
      );

      if (!authenticated) {
        _showMessage('Biometric verification was canceled.');
      }

      return authenticated;
    } on PlatformException catch (error) {
      _showMessage(error.message ?? 'Unable to verify your biometric.');
      return false;
    } catch (_) {
      _showMessage('Unable to verify your biometric.');
      return false;
    }
  }

  Future<void> _showAuthenticatorInfo() async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        final colorScheme = Theme.of(context).colorScheme;
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Google Authenticator',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'This app build does not include the server-side MFA enrollment and verification needed for Google Authenticator yet. The button now explains the requirement instead of doing nothing silently.',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface.withValues(alpha: 0.72),
                ),
              ),
              const SizedBox(height: 16),
              EduPrimaryButton(
                label: 'Understood',
                expanded: false,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _openPinEditor(bool hasExistingPin) async {
    final updated = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: _PinEditorSheet(hasExistingPin: hasExistingPin),
      ),
    );

    if (updated != true || !mounted) {
      return;
    }

    final auth = context.read<AuthProvider>();
    _showMessage(auth.statusMessage ?? 'PIN saved successfully.');
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final colorScheme = Theme.of(context).colorScheme;
    final secondaryText = colorScheme.onSurface.withValues(alpha: 0.68);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            children: [
              const SettingsScreenHeader(title: 'Security'),
              const SizedBox(height: 12),
              Expanded(
                child: SingleChildScrollView(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (auth.isLoading) ...[
                          const LinearProgressIndicator(minHeight: 3),
                          const SizedBox(height: 14),
                        ],
                        TextFormField(
                          controller: _currentPasswordController,
                          obscureText: !_showCurrentPassword,
                          textInputAction: TextInputAction.next,
                          decoration: InputDecoration(
                            hintText: 'Current Password',
                            prefixIcon: const Icon(Icons.lock_outline_rounded),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _showCurrentPassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                              onPressed: () => setState(
                                () => _showCurrentPassword =
                                    !_showCurrentPassword,
                              ),
                            ),
                          ),
                          validator: (value) {
                            final trimmed = value?.trim() ?? '';
                            if (trimmed.length <
                                AuthConstants.minPasswordLength) {
                              return 'Enter your current password.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _newPasswordController,
                          obscureText: !_showNewPassword,
                          textInputAction: TextInputAction.next,
                          decoration: InputDecoration(
                            hintText: 'New Password',
                            prefixIcon: const Icon(Icons.lock_reset_rounded),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _showNewPassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                              onPressed: () => setState(
                                () => _showNewPassword = !_showNewPassword,
                              ),
                            ),
                          ),
                          validator: (value) {
                            final trimmed = value?.trim() ?? '';
                            if (trimmed.length <
                                AuthConstants.minPasswordLength) {
                              return 'Password must be at least ${AuthConstants.minPasswordLength} characters.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _confirmPasswordController,
                          obscureText: !_showConfirmPassword,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _submit(),
                          decoration: InputDecoration(
                            hintText: 'Confirm Password',
                            prefixIcon: const Icon(
                              Icons.verified_user_outlined,
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _showConfirmPassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                              onPressed: () => setState(
                                () => _showConfirmPassword =
                                    !_showConfirmPassword,
                              ),
                            ),
                          ),
                          validator: (value) {
                            final trimmed = value?.trim() ?? '';
                            if (trimmed.length <
                                AuthConstants.minPasswordLength) {
                              return 'Confirm your new password.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Preferences',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 8),
                        SettingsToggleRow(
                          label: 'Remember Me',
                          value: auth.rememberMeEnabled,
                          onChanged: _handleRememberChanged,
                        ),
                        SettingsToggleRow(
                          label: 'Biometric ID',
                          value: auth.biometricEnabled,
                          onChanged: _handleBiometricChanged,
                        ),
                        SettingsToggleRow(
                          label: 'Face ID',
                          value: auth.faceIdEnabled,
                          onChanged: _handleFaceIdChanged,
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
                          subtitle: Text(
                            'Requires backend MFA enrollment',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: secondaryText,
                            ),
                          ),
                          trailing: Icon(
                            Icons.chevron_right_rounded,
                            color: secondaryText,
                          ),
                          onTap: _showAuthenticatorInfo,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          auth.hasPinConfigured
                              ? 'A security PIN is configured for this device.'
                              : 'Set a 4-digit PIN for an extra local security step.',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: secondaryText,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              EduOutlineButton(
                label: auth.hasPinConfigured ? 'Change PIN' : 'Set PIN',
                onPressed: auth.isLoading
                    ? null
                    : () => _openPinEditor(auth.hasPinConfigured),
              ),
              const SizedBox(height: 10),
              EduPrimaryButton(
                label: 'Change Password',
                isLoading: auth.isLoading,
                onPressed: auth.isLoading ? null : _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PinEditorSheet extends StatefulWidget {
  const _PinEditorSheet({required this.hasExistingPin});

  final bool hasExistingPin;

  @override
  State<_PinEditorSheet> createState() => _PinEditorSheetState();
}

class _PinEditorSheetState extends State<_PinEditorSheet> {
  final _formKey = GlobalKey<FormState>();
  final _currentPinController = TextEditingController();
  final _newPinController = TextEditingController();
  final _confirmPinController = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _currentPinController.dispose();
    _newPinController.dispose();
    _confirmPinController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_newPinController.text.trim() != _confirmPinController.text.trim()) {
      _showMessage('PIN and confirmation do not match.');
      return;
    }

    setState(() => _isSaving = true);
    final auth = context.read<AuthProvider>();
    auth.clearError();

    final saved = await auth.savePin(
      currentPin: widget.hasExistingPin ? _currentPinController.text : null,
      newPin: _newPinController.text,
    );

    if (!mounted) {
      return;
    }

    setState(() => _isSaving = false);

    if (saved) {
      Navigator.of(context).pop(true);
      return;
    }

    _showMessage(auth.errorMessage ?? 'Unable to save your PIN right now.');
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final secondaryText = colorScheme.onSurface.withValues(alpha: 0.68);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.hasExistingPin ? 'Change PIN' : 'Set PIN',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Use a ${AuthConstants.pinLength}-digit PIN for quick local protection on this device.',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: secondaryText,
              ),
            ),
            const SizedBox(height: 16),
            if (widget.hasExistingPin) ...[
              _PinField(
                controller: _currentPinController,
                label: 'Current PIN',
              ),
              const SizedBox(height: 12),
            ],
            _PinField(controller: _newPinController, label: 'New PIN'),
            const SizedBox(height: 12),
            _PinField(controller: _confirmPinController, label: 'Confirm PIN'),
            const SizedBox(height: 18),
            EduPrimaryButton(
              label: widget.hasExistingPin ? 'Update PIN' : 'Save PIN',
              isLoading: _isSaving,
              onPressed: _isSaving ? null : _save,
            ),
          ],
        ),
      ),
    );
  }
}

class _PinField extends StatelessWidget {
  const _PinField({required this.controller, required this.label});

  final TextEditingController controller;
  final String label;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      obscureText: true,
      maxLength: AuthConstants.pinLength,
      inputFormatters: <TextInputFormatter>[
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(AuthConstants.pinLength),
      ],
      decoration: InputDecoration(
        hintText: label,
        counterText: '',
        prefixIcon: const Icon(Icons.pin_outlined),
      ),
      validator: (value) {
        final trimmed = value?.trim() ?? '';
        final regex = RegExp('^\\d{${AuthConstants.pinLength}}\$');
        if (!regex.hasMatch(trimmed)) {
          return 'Enter a ${AuthConstants.pinLength}-digit PIN.';
        }
        return null;
      },
    );
  }
}
