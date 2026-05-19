import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:learnhub/core/shared_widgets/edu_primary_button.dart';
import 'package:learnhub/core/theme/app_colors.dart';

/// Biometric re-authentication screen
class BiometricAuthScreen extends StatefulWidget {
  const BiometricAuthScreen({
    super.key,
    required this.onSuccess,
    required this.onCancel,
  });

  final VoidCallback onSuccess;
  final VoidCallback onCancel;

  @override
  State<BiometricAuthScreen> createState() => _BiometricAuthScreenState();
}

class _BiometricAuthScreenState extends State<BiometricAuthScreen> {
  final LocalAuthentication _localAuth = LocalAuthentication();
  bool _authenticating = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Auto-trigger biometric authentication
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _authenticate();
    });
  }

  Future<void> _authenticate() async {
    if (_authenticating) return;

    setState(() => _authenticating = true);

    try {
      final deviceSupported = await _localAuth.isDeviceSupported();
      final canCheck = await _localAuth.canCheckBiometrics;

      if (!deviceSupported || !canCheck) {
        setState(() {
          _errorMessage =
              'Your device does not support fingerprint authentication.';
        });
        return;
      }

      final available = await _localAuth.getAvailableBiometrics();
      if (!available.contains(BiometricType.fingerprint) &&
          !available.contains(BiometricType.strong) &&
          !available.contains(BiometricType.weak)) {
        setState(() {
          _errorMessage = 'No fingerprint is enrolled on this device.';
        });
        return;
      }

      final didAuthenticate = await _localAuth.authenticate(
        localizedReason: 'Verify your fingerprint to continue',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
          useErrorDialogs: true,
        ),
      );

      if (!mounted) return;

      if (didAuthenticate) {
        widget.onSuccess();
      } else {
        setState(() {
          _errorMessage = 'Fingerprint verification failed. Please try again.';
        });
      }
    } on PlatformException catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.message ?? 'Failed to verify fingerprint.';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Failed to verify fingerprint.';
      });
    } finally {
      if (mounted) {
        setState(() => _authenticating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify Identity'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 150,
              height: 150,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(
                    Icons.fingerprint_rounded,
                    size: 80,
                    color: Color(AppColors.primary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Verify Your Fingerprint',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Place your finger on the sensor to verify your identity',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface.withValues(alpha: 0.65),
              ),
            ),
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 20),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.red,
                    ),
                  ),
                ),
              ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: EduPrimaryButton(
                label: _authenticating ? 'Verifying...' : 'Retry',
                onPressed: _authenticating ? null : _authenticate,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: _authenticating
                    ? null
                    : () {
                        widget.onCancel();
                        Navigator.of(context).pop();
                      },
                child: const Text('Cancel'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
