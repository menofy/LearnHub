import 'package:flutter/material.dart';
import 'package:learnhub/core/shared_widgets/learnhub_logo_mark.dart';
import 'package:learnhub/presentation/providers/app_state_provider.dart';
import 'package:provider/provider.dart';

import 'package:learnhub/core/navigation/app_routes.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  static const Duration _minimumSplashDuration = Duration(milliseconds: 350);
  bool _navigationDone = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_navigationDone) {
      _navigationDone = true;
      _checkAuthStatus();
    }
  }

  Future<void> _checkAuthStatus() async {
    final splashTimer = Stopwatch()..start();
    final appState = context.read<AppStateProvider>();
    var attempts = 0;

    // الانتظار حتى اكتمال تحميل البيانات من SharedPreferences
    while (!appState.isInitialized && attempts < 80) {
      await Future.delayed(const Duration(milliseconds: 50));
      attempts++;
    }

    final remaining = _minimumSplashDuration - splashTimer.elapsed;
    if (!mounted) return;
    if (remaining > Duration.zero) {
      await Future.delayed(remaining);
    }
    if (!mounted) return;
    _goNext();
  }

  void _goNext() {
    if (!mounted) return;

    Navigator.of(context).pushReplacementNamed(AppRoutes.appEntryGate);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF17C7BE),
      body: Center(
        child: SizedBox(
          width: 250,
          height: 250,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 210,
                height: 210,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFF2FCFC), width: 2),
                ),
              ),
              const Positioned(
                left: 35,
                top: 54,
                child: CircleAvatar(
                  radius: 7,
                  backgroundColor: Color(0x9AF2FCFC),
                ),
              ),
              const Positioned(
                left: 55,
                top: 64,
                child: CircleAvatar(
                  radius: 5,
                  backgroundColor: Color(0x9AF2FCFC),
                ),
              ),
              const Positioned(
                right: 52,
                top: 86,
                child: CircleAvatar(
                  radius: 6,
                  backgroundColor: Color(0x9AF2FCFC),
                ),
              ),
              const Positioned(
                right: 36,
                top: 95,
                child: CircleAvatar(
                  radius: 8,
                  backgroundColor: Color(0x9AF2FCFC),
                ),
              ),
              const LearnHubLogoMark(size: 130, textColor: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}
