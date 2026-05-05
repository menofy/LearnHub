import 'package:flutter/material.dart';

import '../../../../core/navigation/app_routes.dart';
import '../../../../core/utils/validators.dart';

class LoginCredentialsForm extends StatelessWidget {
  const LoginCredentialsForm({
    super.key,
    required this.emailController,
    required this.passwordController,
    required this.isPasswordHidden,
    required this.rememberMe,
    required this.titleColor,
    required this.secondaryColor,
    required this.onTogglePasswordVisibility,
    required this.onRememberChanged,
    required this.enabled,
    this.onSubmit,
  });

  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool isPasswordHidden;
  final bool rememberMe;
  final Color titleColor;
  final Color secondaryColor;
  final VoidCallback onTogglePasswordVisibility;
  final ValueChanged<bool> onRememberChanged;
  final bool enabled;
  final VoidCallback? onSubmit;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextFormField(
          controller: emailController,
          validator: Validators.email,
          enabled: enabled,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(
            hintText: 'Email',
            prefixIcon: Icon(Icons.email_outlined),
          ),
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: passwordController,
          obscureText: isPasswordHidden,
          validator: Validators.password,
          enabled: enabled,
          textInputAction: TextInputAction.done,
          onFieldSubmitted: (_) => onSubmit?.call(),
          decoration: InputDecoration(
            hintText: 'Password',
            prefixIcon: const Icon(Icons.lock_outline_rounded),
            suffixIcon: IconButton(
              icon: Icon(
                isPasswordHidden
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
              ),
              onPressed: enabled ? onTogglePasswordVisibility : null,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Checkbox(
              value: rememberMe,
              onChanged: enabled
                  ? (value) => onRememberChanged(value ?? false)
                  : null,
            ),
            Text(
              'Remember Me',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 12,
                color: titleColor,
              ),
            ),
            const Spacer(),
            InkWell(
              onTap: enabled
                  ? () => Navigator.of(
                      context,
                    ).pushNamed(AppRoutes.forgotPassword)
                  : null,
              child: Text(
                'Forgot Password?',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                  color: secondaryColor,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
