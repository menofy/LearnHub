import 'package:flutter/material.dart';
import 'package:learnhub/core/shared_widgets/discard_changes_dialog.dart';
import 'package:learnhub/core/shared_widgets/edu_primary_button.dart';
import 'package:learnhub/core/shared_widgets/learnhub_logo_mark.dart';
import 'package:learnhub/core/shared_widgets/social_auth_widgets.dart';
import 'package:learnhub/core/utils/validators.dart';
import 'package:learnhub/domain/entities/app_user.dart';
import 'package:learnhub/features/shared/auth/providers/auth_provider.dart';
import 'package:provider/provider.dart';

import 'package:learnhub/core/navigation/app_routes.dart';
import 'package:learnhub/core/theme/app_colors.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  AppUserRole _selectedRole = AppUserRole.student;
  bool _agree = true;
  bool _isPasswordHidden = true;
  bool _showAgreementError = false;
  AutovalidateMode _autovalidateMode = AutovalidateMode.disabled;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submitEmailRegister() async {
    FocusScope.of(context).unfocus();
    final isValid = _formKey.currentState!.validate();
    if (!isValid || !_agree) {
      setState(() {
        _autovalidateMode = AutovalidateMode.onUserInteraction;
        _showAgreementError = !_agree;
      });
      return;
    }

    final authProvider = context.read<AuthProvider>();
    authProvider.clearError(); // Clear any previous errors

    final ok = await authProvider.register(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
      role: _selectedRole,
    );

    if (!mounted) return;
    if (ok) {
      final messenger = ScaffoldMessenger.of(context);
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Account created successfully. Please sign in.'),
        ),
      );
      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
      return;
    }

    if (mounted) {
      final messenger = ScaffoldMessenger.of(context);
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMessage ?? 'Register failed.'),
        ),
      );
    }
  }

  Future<void> _submitGoogleRegister() async {
    final authProvider = context.read<AuthProvider>();
    authProvider.clearError();

    final ok = await authProvider.loginWithGoogle(
      roleForNewUser: _selectedRole,
    );

    if (!mounted) return;

    // تحقق من النجاح والمستخدم موجود
    if (ok && authProvider.currentUser != null) {
      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil(AppRoutes.root, (_) => false);
      return;
    }

    if (mounted) {
      final messenger = ScaffoldMessenger.of(context);
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            authProvider.errorMessage ??
                (authProvider.currentUser == null
                    ? 'Google sign-up failed. Please try again.'
                    : 'An error occurred. Please try again.'),
          ),
        ),
      );
    }
  }

  bool get _hasUnsavedChanges {
    return _nameController.text.trim().isNotEmpty ||
        _emailController.text.trim().isNotEmpty ||
        _passwordController.text.isNotEmpty ||
        _selectedRole != AppUserRole.student ||
        !_agree;
  }

  Future<bool> _confirmDiscardIfNeeded() async {
    if (!_hasUnsavedChanges) {
      return true;
    }
    return showDiscardChangesDialog(
      context,
      message:
          'Your sign-up details are not saved yet. Leave this screen and lose what you entered?',
    );
  }

  Future<void> _goToLogin() async {
    final shouldLeave = await _confirmDiscardIfNeeded();
    if (!mounted || !shouldLeave) {
      return;
    }
    Navigator.of(context).pushReplacementNamed(AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final titleColor = colorScheme.onSurface;
    final secondaryColor = colorScheme.onSurface.withValues(alpha: 0.68);
    final isDark = theme.brightness == Brightness.dark;

    return PopScope<void>(
      canPop: !authProvider.isLoading && !_hasUnsavedChanges,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop || authProvider.isLoading) {
          return;
        }
        final shouldLeave = await _confirmDiscardIfNeeded();
        if (!mounted || !shouldLeave) {
          return;
        }
        Navigator.of(context).pop();
      },
      child: Scaffold(
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
                  const SizedBox(height: 18),
                  const Center(child: LearnHubLogoMark(size: 88)),
                  const SizedBox(height: 16),
                  Text(
                    'Create Account',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: titleColor,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Choose role, then sign up with email or Google.',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: secondaryColor,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isDark
                            ? colorScheme.outline.withValues(alpha: 0.75)
                            : const Color(AppColors.line),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Select Role',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            color: titleColor,
                          ),
                        ),
                        const SizedBox(height: 10),
                        SegmentedButton<AppUserRole>(
                          showSelectedIcon: false,
                          style: ButtonStyle(
                            visualDensity: VisualDensity.compact,
                            textStyle: WidgetStateProperty.all(
                              const TextStyle(fontWeight: FontWeight.w800),
                            ),
                            foregroundColor: WidgetStateProperty.resolveWith((
                              states,
                            ) {
                              if (states.contains(WidgetState.selected)) {
                                return const Color(0xFF071018);
                              }
                              return titleColor;
                            }),
                            backgroundColor: WidgetStateProperty.resolveWith((
                              states,
                            ) {
                              if (states.contains(WidgetState.selected)) {
                                return const Color(AppColors.primary);
                              }
                              return isDark
                                  ? colorScheme.surface
                                  : Colors.white;
                            }),
                            side: WidgetStateProperty.resolveWith((states) {
                              final color =
                                  states.contains(WidgetState.selected)
                                  ? const Color(AppColors.primary)
                                  : (isDark
                                        ? colorScheme.outline
                                        : const Color(AppColors.line));
                              return BorderSide(color: color);
                            }),
                          ),
                          segments: const [
                            ButtonSegment<AppUserRole>(
                              value: AppUserRole.student,
                              icon: Icon(Icons.school_outlined),
                              label: Text('Student'),
                            ),
                            ButtonSegment<AppUserRole>(
                              value: AppUserRole.instructor,
                              icon: Icon(Icons.workspace_premium_outlined),
                              label: Text('Instructor'),
                            ),
                          ],
                          selected: {_selectedRole},
                          onSelectionChanged: (selection) {
                            if (selection.isEmpty) return;
                            setState(() => _selectedRole = selection.first);
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _nameController,
                    validator: (value) =>
                        Validators.requiredField(value, 'Full Name'),
                    textInputAction: TextInputAction.next,
                    enabled: !authProvider.isLoading,
                    decoration: const InputDecoration(
                      hintText: 'Full Name',
                      prefixIcon: Icon(Icons.person_outline_rounded),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _emailController,
                    validator: Validators.email,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    enabled: !authProvider.isLoading,
                    decoration: const InputDecoration(
                      hintText: 'Email',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _isPasswordHidden,
                    validator: Validators.password,
                    textInputAction: TextInputAction.done,
                    enabled: !authProvider.isLoading,
                    onFieldSubmitted: (_) => _submitEmailRegister(),
                    decoration: InputDecoration(
                      hintText: 'Password',
                      prefixIcon: const Icon(Icons.lock_outline_rounded),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isPasswordHidden
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                        ),
                        onPressed: authProvider.isLoading
                            ? null
                            : () {
                                setState(() {
                                  _isPasswordHidden = !_isPasswordHidden;
                                });
                              },
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Checkbox(
                        value: _agree,
                        onChanged: authProvider.isLoading
                            ? null
                            : (v) => setState(() {
                                _agree = v ?? false;
                                if (_agree) {
                                  _showAgreementError = false;
                                }
                              }),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Agree to Terms & Conditions',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                                color: titleColor,
                              ),
                            ),
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 180),
                              child: _showAgreementError
                                  ? Padding(
                                      key: const ValueKey('agreement-error'),
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Text(
                                        'Please accept the terms before creating your account.',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: colorScheme.error,
                                        ),
                                      ),
                                    )
                                  : const SizedBox.shrink(),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  EduPrimaryButton(
                    label: 'Sign Up',
                    isLoading: authProvider.isLoading,
                    onPressed: authProvider.isLoading
                        ? null
                        : _submitEmailRegister,
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: Text(
                      'Or Continue With',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: secondaryColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SocialCircleButton(
                        brand: SocialBrand.google,
                        onTap: authProvider.isLoading
                            ? null
                            : () => _submitGoogleRegister(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Already have an Account? ',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: secondaryColor,
                        ),
                      ),
                      InkWell(
                        onTap: authProvider.isLoading ? null : _goToLogin,
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
      ),
    );
  }
}
