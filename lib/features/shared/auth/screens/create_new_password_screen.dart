import 'package:flutter/material.dart';
import 'package:learnhub/core/shared_widgets/edu_primary_button.dart';
import 'package:learnhub/core/shared_widgets/learnhub_logo_mark.dart';
import 'package:learnhub/core/theme/app_colors.dart';
import 'package:learnhub/core/utils/auth_validators.dart';
import 'package:learnhub/features/shared/auth/providers/auth_provider.dart';
import 'package:provider/provider.dart';

import 'package:learnhub/core/navigation/app_routes.dart';

class CreateNewPasswordScreen extends StatefulWidget {
  const CreateNewPasswordScreen({super.key, this.oobCode = ''});

  final String oobCode;

  @override
  State<CreateNewPasswordScreen> createState() =>
      _CreateNewPasswordScreenState();
}

class _CreateNewPasswordScreenState extends State<CreateNewPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _showPassword = false;
  bool _showConfirmPassword = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // تحقق من تطابق كلمات المرور
    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Passwords do not match')));
      return;
    }

    final authProvider = context.read<AuthProvider>();
    authProvider.clearError();

    final success = await authProvider.resetPasswordWithCode(
      oobCode: widget.oobCode,
      newPassword: _passwordController.text,
    );

    if (!mounted) return;

    if (success) {
      Navigator.of(
        context,
      ).pushReplacementNamed(AppRoutes.resetPasswordSuccess);
      return;
    }

    // عرض الخطأ
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(authProvider.errorMessage ?? 'Failed to reset password.'),
      ),
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
          'Create New Password',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
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
                  'Create Your New Password',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: titleColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Enter a strong password to secure your account.',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: secondaryColor,
                  ),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _passwordController,
                  validator: AuthValidators.validatePassword,
                  obscureText: !_showPassword,
                  enabled: !authProvider.isLoading,
                  decoration: InputDecoration(
                    hintText: 'New Password',
                    prefixIcon: const Icon(Icons.lock_outline_rounded),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _showPassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: () =>
                          setState(() => _showPassword = !_showPassword),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _confirmPasswordController,
                  validator: (value) =>
                      AuthValidators.validatePasswordConfirmation(
                        value,
                        _passwordController.text,
                      ),
                  obscureText: !_showConfirmPassword,
                  enabled: !authProvider.isLoading,
                  decoration: InputDecoration(
                    hintText: 'Confirm Password',
                    prefixIcon: const Icon(Icons.lock_outline_rounded),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _showConfirmPassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: () => setState(
                        () => _showConfirmPassword = !_showConfirmPassword,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                EduPrimaryButton(
                  label: 'Reset Password',
                  isLoading: authProvider.isLoading,
                  onPressed: authProvider.isLoading ? null : _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
