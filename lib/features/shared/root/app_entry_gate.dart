import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:learnhub/core/shared_widgets/learnhub_logo_mark.dart';
import 'package:learnhub/features/onboarding/onboarding_screen.dart';
import 'package:learnhub/features/shared/auth/providers/auth_provider.dart';
import 'package:learnhub/features/instructor/screens/instructor_shell_screen.dart';
import 'package:learnhub/features/shared/auth/screens/login_screen.dart';
import 'package:learnhub/features/shared/providers/app_state_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/auth_constants.dart';
import '../../../domain/entities/app_user.dart';
import '../main/main_shell_screen.dart';

class AppEntryGate extends StatefulWidget {
  const AppEntryGate({super.key});

  @override
  State<AppEntryGate> createState() => _AppEntryGateState();
}

class _AppEntryGateState extends State<AppEntryGate> {
  bool _hasLoadedPersistedSession = false;
  bool _isClearingStaleSession = false;
  String _persistedToken = '';
  String _persistedUserId = '';
  AppUserRole? _persistedRole;
  String? _lastScopedUserId;
  AppUserRole? _lastScopedRole;

  @override
  void initState() {
    super.initState();
    _loadPersistedSession();
  }

  Future<void> _loadPersistedSession() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(AuthConstants.tokenKey)?.trim() ?? '';
    final userRaw = prefs.getString(AuthConstants.userKey)?.trim() ?? '';

    String userId = '';
    AppUserRole? role;

    if (userRaw.isNotEmpty) {
      try {
        final decoded = jsonDecode(userRaw);
        if (decoded is Map) {
          final map = decoded.map<String, dynamic>(
            (key, value) => MapEntry(key.toString(), value),
          );
          userId = map['id']?.toString().trim() ?? '';
          final roleValue = map['role']?.toString().trim() ?? '';
          if (roleValue.isNotEmpty) {
            role = AppUserRoleX.fromValue(roleValue);
          }
        }
      } catch (_) {
        // Ignore malformed cached data and fall back to the auth stream.
      }
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _persistedToken = token;
      _persistedUserId = userId;
      _persistedRole = role;
      _hasLoadedPersistedSession = true;
    });
  }

  Future<void> _clearStalePersistedSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AuthConstants.tokenKey);
    await prefs.remove(AuthConstants.refreshTokenKey);
    await prefs.remove(AuthConstants.userKey);

    if (!mounted) {
      return;
    }

    setState(() {
      _persistedToken = '';
      _persistedUserId = '';
      _persistedRole = null;
      _isClearingStaleSession = false;
    });
  }

  void _syncUserScopedState(AppUser? user) {
    final nextUserId = user?.id;
    final nextRole = user?.role;

    if (_lastScopedUserId == nextUserId && _lastScopedRole == nextRole) {
      return;
    }

    _lastScopedUserId = nextUserId;
    _lastScopedRole = nextRole;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      context.read<AppStateProvider>().loadForUser(nextUserId, role: nextRole);
    });
  }

  void _scheduleStaleSessionCleanup() {
    if (_isClearingStaleSession) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _isClearingStaleSession) {
        return;
      }

      setState(() => _isClearingStaleSession = true);
      _clearStalePersistedSession();
    });
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppStateProvider>();
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.currentUser;

    _syncUserScopedState(user);

    final hasPersistedSession =
        _persistedToken.isNotEmpty &&
        _persistedUserId.isNotEmpty &&
        _persistedRole != null;

    if (!appState.isInitialized ||
        !_hasLoadedPersistedSession ||
        authProvider.isSessionBootstrapping ||
        _isClearingStaleSession) {
      return const _AppEntryGateLoadingView();
    }

    if (user != null) {
      if (user.role == AppUserRole.instructor) {
        return const InstructorShellScreen();
      }
      return const MainShellScreen();
    }

    if (hasPersistedSession) {
      _scheduleStaleSessionCleanup();
      return const _AppEntryGateLoadingView();
    }

    if (!appState.hasSeenOnboarding) {
      return const OnboardingScreen();
    }

    return const LoginScreen();
  }
}

class _AppEntryGateLoadingView extends StatelessWidget {
  const _AppEntryGateLoadingView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF17C7BE),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 220,
              height: 220,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 186,
                    height: 186,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFF2FCFC),
                        width: 2,
                      ),
                    ),
                  ),
                  const Positioned(
                    left: 36,
                    top: 54,
                    child: CircleAvatar(
                      radius: 7,
                      backgroundColor: Color(0x9AF2FCFC),
                    ),
                  ),
                  const Positioned(
                    left: 56,
                    top: 65,
                    child: CircleAvatar(
                      radius: 5,
                      backgroundColor: Color(0x9AF2FCFC),
                    ),
                  ),
                  const Positioned(
                    right: 52,
                    top: 84,
                    child: CircleAvatar(
                      radius: 6,
                      backgroundColor: Color(0x9AF2FCFC),
                    ),
                  ),
                  const Positioned(
                    right: 38,
                    top: 96,
                    child: CircleAvatar(
                      radius: 8,
                      backgroundColor: Color(0x9AF2FCFC),
                    ),
                  ),
                  const LearnHubLogoMark(size: 118, textColor: Colors.white),
                ],
              ),
            ),
            const SizedBox(height: 18),
            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
