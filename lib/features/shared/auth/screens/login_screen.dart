import 'dart:async';

import 'package:flutter/material.dart';
import 'package:learnhub/core/navigation/app_routes.dart';
import 'package:learnhub/core/shared_widgets/edu_primary_button.dart';
import 'package:learnhub/domain/entities/app_user.dart';
import 'package:learnhub/features/shared/auth/providers/auth_provider.dart';
import 'package:learnhub/features/shared/auth/widgets/auth_switch_prompt.dart';
import 'package:learnhub/features/shared/auth/widgets/login_credentials_form.dart';
import 'package:learnhub/features/shared/auth/widgets/login_google_button.dart';
import 'package:learnhub/features/shared/auth/widgets/login_intro_section.dart';
import 'package:learnhub/features/shared/auth/widgets/role_picker_sheet.dart';
import 'package:provider/provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _remember = false;
  bool _rememberInitialized = false;
  bool _isPasswordHidden = true;
  AutovalidateMode _autovalidateMode = AutovalidateMode.disabled;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_rememberInitialized) {
      return;
    }
    _remember = context.read<AuthProvider>().rememberMeEnabled;
    _rememberInitialized = true;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _openRoot() {
    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil(AppRoutes.root, (route) => false);
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final isValid = _formKey.currentState!.validate();
    if (!isValid) {
      setState(() {
        _autovalidateMode = AutovalidateMode.onUserInteraction;
      });
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid email and password.'),
        ),
      );
      return;
    }

    final auth = context.read<AuthProvider>();
    auth.clearError();

    final success = await auth.login(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      rememberMe: _remember,
    );

    if (!mounted) return;
    if (success) {
      _openRoot();
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(content: Text(auth.errorMessage ?? 'Login failed.')),
    );
  }

  Future<void> _loginWithGoogle() async {
    final auth = context.read<AuthProvider>();
    auth.clearError();

    if (!mounted) return;

    var success = await auth.loginWithGoogle(rememberMe: _remember);

    if (!mounted) return;

    if (!success && auth.requiresRoleSelection) {
      final role = await _showRolePicker();
      if (!mounted || role == null) return;
      success = await auth.loginWithGoogle(
        roleForNewUser: role,
        rememberMe: _remember,
      );
    }

    if (!mounted) return;

    if (success && auth.currentUser != null) {
      _openRoot();
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          auth.errorMessage ??
              (auth.currentUser == null
                  ? 'Google sign-in failed. Please try again.'
                  : 'An error occurred. Please try again.'),
        ),
      ),
    );
  }

  Future<AppUserRole?> _showRolePicker() {
    return showModalBottomSheet<AppUserRole>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => const RolePickerSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final colorScheme = Theme.of(context).colorScheme;
    final titleColor = colorScheme.onSurface;
    final secondaryColor = colorScheme.onSurface.withValues(alpha: 0.68);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            autovalidateMode: _autovalidateMode,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                LoginIntroSection(
                  isLoading: authProvider.isLoading,
                  titleColor: titleColor,
                  secondaryColor: secondaryColor,
                ),
                const SizedBox(height: 18),
                LoginCredentialsForm(
                  emailController: _emailController,
                  passwordController: _passwordController,
                  isPasswordHidden: _isPasswordHidden,
                  rememberMe: _remember,
                  titleColor: titleColor,
                  secondaryColor: secondaryColor,
                  enabled: !authProvider.isLoading,
                  onSubmit: _submit,
                  onTogglePasswordVisibility: () {
                    setState(() {
                      _isPasswordHidden = !_isPasswordHidden;
                    });
                  },
                  onRememberChanged: (value) {
                    setState(() {
                      _remember = value;
                    });
                    unawaited(
                      context.read<AuthProvider>().setRememberMeEnabled(value),
                    );
                  },
                ),
                const SizedBox(height: 12),
                EduPrimaryButton(
                  label: 'Sign In',
                  isLoading: authProvider.isLoading,
                  onPressed: authProvider.isLoading ? null : _submit,
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
                    LoginGoogleButton(
                      isLoading: authProvider.isLoading,
                      onTap: authProvider.isLoading ? null : _loginWithGoogle,
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                AuthSwitchPrompt(
                  prompt: 'Don\'t have an Account? ',
                  actionLabel: 'SIGN UP',
                  secondaryColor: secondaryColor,
                  onTap: () => Navigator.of(
                    context,
                  ).pushReplacementNamed(AppRoutes.register),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
