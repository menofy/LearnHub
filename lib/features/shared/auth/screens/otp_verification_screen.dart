import 'package:flutter/material.dart';
import 'package:learnhub/core/shared_widgets/edu_primary_button.dart';

import 'package:learnhub/core/navigation/app_routes.dart';
import 'package:learnhub/core/utils/app_error_mapper.dart';

class OtpVerificationScreen extends StatefulWidget {
  const OtpVerificationScreen({super.key, this.oobCode = ''});

  final String oobCode;

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final _otpController = TextEditingController();
  bool _isVerifying = false;

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    final code = _otpController.text.trim();
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the code from your email')),
      );
      return;
    }

    setState(() => _isVerifying = true);

    try {
      if (!mounted) return;

      Navigator.of(
        context,
      ).pushReplacementNamed(AppRoutes.createNewPassword, arguments: code);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(AppErrorMapper.auth(error))));
    } finally {
      if (mounted) {
        setState(() => _isVerifying = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
                'Enter the code sent to your email',
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
                enabled: !_isVerifying,
                decoration: const InputDecoration(
                  hintText: 'Enter verification code from email',
                  prefixIcon: Icon(Icons.code_outlined),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Check your email for the verification code (link from Firebase)',
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
                onPressed: _isVerifying ? null : _verify,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
