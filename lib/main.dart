import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:learnhub/features/course/providers/course_provider.dart';
import 'package:learnhub/features/shared/auth/providers/auth_provider.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'data/repositories/auth_repository_impl.dart';
import 'data/repositories/course_repository_impl.dart';
import 'data/services/fcm_service.dart';
import 'firebase_options.dart';
import 'features/course/providers/youtube_playlist_provider.dart';
import 'features/shared/providers/app_state_provider.dart';

Future<void> _handleBackgroundMessage(RemoteMessage message) async {
  await FCMService.handleBackgroundMessage(message);
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize FCM Service and register background message handler
  await FCMService.instance.initialize();
  FirebaseMessaging.onBackgroundMessage(_handleBackgroundMessage);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>(
          create: (_) => AuthProvider(AuthRepositoryImpl()),
        ),
        ChangeNotifierProvider<CourseProvider>(
          create: (_) => CourseProvider(CourseRepositoryImpl()),
        ),
        ChangeNotifierProvider<AppStateProvider>(
          create: (_) => AppStateProvider(),
        ),
        ChangeNotifierProvider<YoutubePlaylistProvider>(
          create: (_) => YoutubePlaylistProvider(),
        ),
      ],
      child: const LearnHubApp(),
    ),
  );
}
