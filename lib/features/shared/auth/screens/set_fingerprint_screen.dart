import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:learnhub/core/shared_widgets/edu_outline_button.dart';
import 'package:learnhub/core/shared_widgets/edu_primary_button.dart';
import 'package:local_auth/local_auth.dart';
import 'package:provider/provider.dart';

import 'package:learnhub/core/navigation/app_routes.dart';
import 'package:learnhub/features/shared/auth/providers/auth_provider.dart';

class SetFingerprintScreen extends StatefulWidget {
  const SetFingerprintScreen({super.key});

  @override
  State<SetFingerprintScreen> createState() => _SetFingerprintScreenState();
}

class _SetFingerprintScreenState extends State<SetFingerprintScreen> {
  final LocalAuthentication _localAuth = LocalAuthentication();
  bool _authenticating = false;

  Future<void> _enableBiometric() async {
    if (_authenticating) {
      return;
    }

    setState(() => _authenticating = true);

    try {
      final deviceSupported = await _localAuth.isDeviceSupported();
      final canCheck = await _localAuth.canCheckBiometrics;

      if (!deviceSupported || !canCheck) {
        _showMessage(
          'Your device does not support fingerprint authentication.',
        );
        return;
      }

      final available = await _localAuth.getAvailableBiometrics();
      if (!available.contains(BiometricType.fingerprint) &&
          !available.contains(BiometricType.strong) &&
          !available.contains(BiometricType.weak)) {
        _showMessage('No fingerprint is enrolled on this device.');
        return;
      }

      final didAuthenticate = await _localAuth.authenticate(
        localizedReason: 'Verify your fingerprint to secure your account',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
          useErrorDialogs: true,
        ),
      );

      if (!mounted) {
        return;
      }

      if (didAuthenticate) {
        // Save biometric preference to AuthProvider
        if (!mounted) return;
        await context.read<AuthProvider>().setBiometricEnabled(true);
        
        if (!mounted) return;
        Navigator.of(context).pushNamed(AppRoutes.accountReady);
      } else {
        _showMessage('Fingerprint verification canceled. Try again.');
      }
    } on PlatformException catch (error) {
      _showMessage(error.message ?? 'Failed to verify fingerprint.');
    } catch (_) {
      _showMessage('Failed to verify fingerprint.');
    } finally {
      if (mounted) {
        setState(() => _authenticating = false);
      }
    }
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Set Your Fingerprint',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 40),
            const Text(
              'Add a Fingerprint to Make your Account\nmore Secure',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
            ),
            const SizedBox(height: 36),
            SizedBox(
              width: 210,
              height: 210,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const Icon(
                    Icons.fingerprint_rounded,
                    size: 110,
                    color: Color(0xFF17C7BE),
                  ),
                  const _Corner(
                    top: 24,
                    left: 24,
                    rightSide: false,
                    bottomSide: false,
                  ),
                  const _Corner(
                    top: 24,
                    right: 24,
                    rightSide: true,
                    bottomSide: false,
                  ),
                  const _Corner(
                    bottom: 24,
                    left: 24,
                    rightSide: false,
                    bottomSide: true,
                  ),
                  const _Corner(
                    bottom: 24,
                    right: 24,
                    rightSide: true,
                    bottomSide: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            const Text(
              'Please Put Your Finger on the Fingerprint\nScanner to get Started.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xFF7D88A4),
              ),
            ),
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: EduOutlineButton(
                    label: 'Skip',
                    onPressed: _authenticating
                        ? null
                        : () async {
                            // Skip biometric setup
                            if (!mounted) return;
                            await context.read<AuthProvider>().setBiometricEnabled(false);
                            if (!mounted) return;
                            Navigator.of(context).pushNamedAndRemoveUntil(
                              AppRoutes.root,
                              (route) => false,
                            );
                          },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: EduPrimaryButton(
                    label: _authenticating ? 'Checking...' : 'Continue',
                    onPressed: _authenticating ? null : _enableBiometric,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}

class _Corner extends StatelessWidget {
  const _Corner({
    this.top,
    this.bottom,
    this.left,
    this.right,
    required this.rightSide,
    required this.bottomSide,
  });

  final double? top;
  final double? bottom;
  final double? left;
  final double? right;
  final bool rightSide;
  final bool bottomSide;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: Container(
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          border: Border(
            top: !bottomSide
                ? const BorderSide(color: Color(0xFF232A4A), width: 3)
                : BorderSide.none,
            bottom: bottomSide
                ? const BorderSide(color: Color(0xFF232A4A), width: 3)
                : BorderSide.none,
            left: !rightSide
                ? const BorderSide(color: Color(0xFF232A4A), width: 3)
                : BorderSide.none,
            right: rightSide
                ? const BorderSide(color: Color(0xFF232A4A), width: 3)
                : BorderSide.none,
          ),
          borderRadius: BorderRadius.only(
            topLeft: !rightSide && !bottomSide
                ? const Radius.circular(8)
                : Radius.zero,
            topRight: rightSide && !bottomSide
                ? const Radius.circular(8)
                : Radius.zero,
            bottomLeft: !rightSide && bottomSide
                ? const Radius.circular(8)
                : Radius.zero,
            bottomRight: rightSide && bottomSide
                ? const Radius.circular(8)
                : Radius.zero,
          ),
        ),
      ),
    );
  }
}
