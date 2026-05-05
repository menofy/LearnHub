import 'dart:async';

import 'package:flutter/material.dart';
import 'package:learnhub/core/shared_widgets/edu_primary_button.dart';
import 'package:learnhub/features/shared/auth/providers/auth_provider.dart';
import 'package:learnhub/features/shared/auth/widgets/signup_otp_code_boxes.dart';
import 'package:learnhub/features/shared/auth/widgets/signup_otp_intro_section.dart';
import 'package:learnhub/features/shared/auth/widgets/signup_otp_pin_pad.dart';
import 'package:learnhub/features/shared/auth/widgets/signup_otp_resend_section.dart';
import 'package:provider/provider.dart';

import 'package:learnhub/core/navigation/app_routes.dart';

class SignupOtpScreen extends StatefulWidget {
  const SignupOtpScreen({super.key, required this.name, required this.email});

  final String name;
  final String email;

  @override
  State<SignupOtpScreen> createState() => _SignupOtpScreenState();
}

class _SignupOtpScreenState extends State<SignupOtpScreen> {
  static const int _otpLength = 4;

  final List<String> _digits = <String>[];
  int _seconds = 59;
  Timer? _timer;

  bool get _isCodeComplete => _digits.length == _otpLength;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    _seconds = 59;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_seconds == 0) {
        timer.cancel();
        return;
      }
      setState(() => _seconds -= 1);
    });
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _handleKeyTap(String value) {
    setState(() {
      if (value == SignupOtpPinPad.backspaceValue) {
        if (_digits.isNotEmpty) {
          _digits.removeLast();
        }
        return;
      }

      if (_digits.length < _otpLength) {
        _digits.add(value);
      }
    });
  }

  Future<void> _verify() async {
    if (!_isCodeComplete) {
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.verifySignupOtp(_digits.join());
    if (!mounted) {
      return;
    }

    if (success) {
      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil(AppRoutes.root, (route) => false);
      return;
    }

    _showMessage(authProvider.errorMessage ?? 'Verification failed.');
  }

  Future<void> _resend() async {
    if (_seconds > 0) {
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.resendSignupOtp();
    if (!mounted) {
      return;
    }

    if (success) {
      _startTimer();
      _showMessage('A new code has been sent to your email.');
      return;
    }

    _showMessage(authProvider.errorMessage ?? 'Could not resend code.');
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final maskedEmail = authProvider.maskEmail(widget.email);
    final colorScheme = Theme.of(context).colorScheme;
    final secondaryColor = colorScheme.onSurface.withValues(alpha: 0.68);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Verify Your Email',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 8),
                      SignupOtpIntroSection(
                        name: widget.name,
                        maskedEmail: maskedEmail,
                      ),
                      const SizedBox(height: 24),
                      SignupOtpCodeBoxes(digits: _digits, length: _otpLength),
                      const SizedBox(height: 16),
                      Text(
                        'Use the keypad below to enter your code.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: secondaryColor,
                        ),
                      ),
                      const SizedBox(height: 10),
                      SignupOtpResendSection(
                        secondsRemaining: _seconds,
                        onResend: _resend,
                      ),
                      const SizedBox(height: 18),
                      EduPrimaryButton(
                        label: 'Verify & Continue',
                        isLoading: authProvider.isLoading,
                        onPressed: authProvider.isLoading || !_isCodeComplete
                            ? null
                            : _verify,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              SignupOtpPinPad(
                enabled: !authProvider.isLoading,
                onKeyTap: _handleKeyTap,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
