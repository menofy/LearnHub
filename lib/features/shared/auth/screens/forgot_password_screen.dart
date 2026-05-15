import 'package:flutter/material.dart';
import 'package:learnhub/core/shared_widgets/edu_primary_button.dart';
import 'package:learnhub/core/shared_widgets/learnhub_logo_mark.dart';
import 'package:learnhub/features/shared/auth/providers/auth_provider.dart';
import 'package:provider/provider.dart';

import 'package:learnhub/core/navigation/app_routes.dart';
import 'package:learnhub/core/navigation/route_args.dart';
import 'package:learnhub/core/theme/app_colors.dart';
import 'package:learnhub/core/utils/auth_validators.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  AutovalidateMode _autovalidateMode = AutovalidateMode.disabled;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final isValid = _formKey.currentState!.validate();
    if (!isValid) {
      setState(() {
        _autovalidateMode = AutovalidateMode.onUserInteraction;
      });
      return;
    }

    final authProvider = context.read<AuthProvider>();
    authProvider.clearError();

    final email = _emailController.text.trim();
    final success = await authProvider.sendPasswordResetOtp(email);

    if (!mounted) return;

    if (success) {
      Navigator.of(context).pushNamed(
        AppRoutes.otpVerification,
        arguments: PasswordResetOtpArgs(email: email),
      );
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(content: Text(authProvider.errorMessage ?? 'Request failed.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final colorScheme = Theme.of(context).colorScheme;
    final titleColor = colorScheme.onSurface;
    final secondaryColor = colorScheme.onSurface.withValues(alpha: 0.68);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Forgot Password',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            autovalidateMode: _autovalidateMode,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (authProvider.isLoading) ...[
                  const LinearProgressIndicator(
                    minHeight: 3,
                    color: Color(AppColors.primary),
                  ),
                  const SizedBox(height: 10),
                ],
                const SizedBox(height: 20),
                const Center(child: LearnHubLogoMark(size: 80)),
                const SizedBox(height: 24),
                Text(
                  'Verify Your Email',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: titleColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Enter your email address to receive a 6-digit verification code before resetting your password.',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: secondaryColor,
                  ),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _emailController,
                  validator: AuthValidators.validateEmail,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _submit(),
                  enabled: !authProvider.isLoading,
                  decoration: const InputDecoration(
                    hintText: 'Email Address',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                ),
                const SizedBox(height: 20),
                EduPrimaryButton(
                  label: 'Send Verification Code',
                  isLoading: authProvider.isLoading,
                  onPressed: authProvider.isLoading ? null : _submit,
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Remember your password? ',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: secondaryColor,
                      ),
                    ),
                    InkWell(
                      onTap: () => Navigator.of(
                        context,
                      ).pushReplacementNamed(AppRoutes.login),
                      child: const Text(
                        'SIGN IN',
                        style: TextStyle(
                          color: Color(AppColors.primary),
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
