import 'package:flutter/material.dart';
import 'package:learnhub/core/navigation/app_routes.dart';
import 'package:learnhub/core/navigation/route_args.dart';
import 'package:learnhub/core/shared_widgets/edu_primary_button.dart';
import 'package:learnhub/features/shared/auth/providers/auth_provider.dart';
import 'package:provider/provider.dart';

class OtpVerificationScreen extends StatefulWidget {
  const OtpVerificationScreen({super.key, required this.email});

  final String email;

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final _otpController = TextEditingController();
  bool _isVerifying = false;
  bool _isResending = false;

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    final code = _otpController.text.trim();
    if (code.isEmpty) {
      _showMessage('Please enter the 6-digit verification code.');
      return;
    }

    setState(() => _isVerifying = true);
    final auth = context.read<AuthProvider>();
    auth.clearError();

    final verified = await auth.verifyPasswordResetOtp(widget.email, code);

    if (!mounted) {
      return;
    }

    setState(() => _isVerifying = false);

    if (verified) {
      Navigator.of(context).pushReplacementNamed(
        AppRoutes.createNewPassword,
        arguments: CreateNewPasswordArgs(email: widget.email),
      );
      return;
    }

    _showMessage(auth.errorMessage ?? 'Unable to verify the code.');
  }

  Future<void> _resendCode() async {
    setState(() => _isResending = true);
    final auth = context.read<AuthProvider>();
    auth.clearError();

    final sent = await auth.sendPasswordResetOtp(widget.email);

    if (!mounted) {
      return;
    }

    setState(() => _isResending = false);

    _showMessage(
      sent
          ? 'A new verification code has been sent.'
          : (auth.errorMessage ?? 'Unable to resend the code.'),
    );
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
    final secondaryColor = Theme.of(
      context,
    ).colorScheme.onSurface.withValues(alpha: 0.68);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Verify Email',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              Text(
                'Enter the 6-digit code sent to ${auth.maskEmail(widget.email)}',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: secondaryColor,
                ),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _otpController,
                enabled: !_isVerifying && !_isResending,
                keyboardType: TextInputType.number,
                maxLength: 6,
                decoration: const InputDecoration(
                  hintText: 'Enter verification code',
                  counterText: '',
                  prefixIcon: Icon(Icons.code_outlined),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'If the code expires, you can request a new one.',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: secondaryColor,
                ),
              ),
              const SizedBox(height: 24),
              EduPrimaryButton(
                label: 'Verify & Continue',
                isLoading: _isVerifying,
                onPressed: (_isVerifying || _isResending) ? null : _verify,
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: (_isVerifying || _isResending) ? null : _resendCode,
                child: Text(_isResending ? 'Sending...' : 'Resend Code'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
