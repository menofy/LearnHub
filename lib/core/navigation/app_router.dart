import 'package:flutter/material.dart';
import 'package:learnhub/features/common/info/terms_screen.dart';
import 'package:learnhub/features/common/instructor_public/screens/instructors_screen.dart';
import 'package:learnhub/features/common/notifications/notification_details_screen.dart';
import 'package:learnhub/features/common/notifications/notifications_screen.dart';
import 'package:learnhub/features/course/screens/course_details_screen.dart';
import 'package:learnhub/features/course/screens/course_reviews_screen.dart';
import 'package:learnhub/features/course/screens/lesson_notes_screen.dart';
import 'package:learnhub/features/course/screens/lesson_resources_screen.dart';
import 'package:learnhub/features/course/screens/video_player_screen.dart';
import 'package:learnhub/features/course/screens/write_review_screen.dart';
import 'package:learnhub/features/course/screens/youtube_fullscreen_player_screen.dart';
import 'package:learnhub/features/course/screens/youtube_playlist_screen.dart';
import 'package:learnhub/features/home/screens/popular_courses_screen.dart';
import 'package:learnhub/features/instructor/screens/instructor_add_course_screen.dart';
import 'package:learnhub/features/instructor/screens/instructor_my_courses_screen.dart';
import 'package:learnhub/features/instructor/screens/instructor_shell_screen.dart';
import 'package:learnhub/features/instructor_public/screens/instructor_details_screen.dart';
import 'package:learnhub/features/onboarding/onboarding_screen.dart';
import 'package:learnhub/features/onboarding/splash_screen.dart';
import 'package:learnhub/features/settings/screens/change_password_screen.dart';
import 'package:learnhub/features/settings/screens/language_settings_screen.dart';
import 'package:learnhub/features/shared/auth/screens/account_ready_screen.dart';
import 'package:learnhub/features/shared/auth/screens/create_new_password_screen.dart';
import 'package:learnhub/features/shared/auth/screens/create_pin_screen.dart';
import 'package:learnhub/features/shared/auth/screens/fill_profile_screen.dart';
import 'package:learnhub/features/shared/auth/screens/forgot_password_screen.dart';
import 'package:learnhub/features/shared/auth/screens/login_screen.dart';
import 'package:learnhub/features/shared/auth/screens/otp_verification_screen.dart';
import 'package:learnhub/features/shared/auth/screens/register_screen.dart';
import 'package:learnhub/features/shared/auth/screens/reset_password_success_screen.dart';
import 'package:learnhub/features/shared/auth/screens/set_fingerprint_screen.dart';
import 'package:learnhub/features/shared/auth/screens/signup_otp_screen.dart';
import 'package:learnhub/features/shared/root/app_entry_gate.dart';
import 'package:learnhub/features/shared/root/root_screen.dart';
import 'package:learnhub/features/student_side/categories/categories_screen.dart';
import 'package:learnhub/features/student_side/categories/category_courses_screen.dart';
import 'package:learnhub/features/student_side/learning/screens/my_learning_screen.dart';
import 'package:learnhub/features/student_side/profile/screens/certificate_details_screen.dart';
import 'package:learnhub/features/student_side/profile/screens/certificates_screen.dart';
import 'package:learnhub/features/student_side/profile/screens/edit_profile_screen.dart';
import 'package:learnhub/features/student_side/search/search_screen.dart';
import 'package:learnhub/features/student_side/settings/screens/notification_settings_screen.dart';
import 'package:learnhub/features/student_side/student/screens/student_shell_screen.dart';
import 'package:learnhub/features/student_side/wishlist/wishlist_screen.dart';
import 'app_routes.dart';
import 'route_args.dart';

class AppRouter {
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.splash:
        return MaterialPageRoute<void>(builder: (_) => const SplashScreen());
      case AppRoutes.onboarding:
        return MaterialPageRoute<void>(
          builder: (_) => const OnboardingScreen(),
        );
      case AppRoutes.appEntryGate:
        return MaterialPageRoute<void>(builder: (_) => const AppEntryGate());
      case AppRoutes.root:
        return MaterialPageRoute<void>(builder: (_) => const RootScreen());
      case AppRoutes.login:
        return MaterialPageRoute<void>(builder: (_) => const LoginScreen());
      case AppRoutes.register:
        return MaterialPageRoute<void>(builder: (_) => const RegisterScreen());
      case AppRoutes.signupOtp:
        final args = settings.arguments;
        if (args is SignupOtpArgs) {
          return MaterialPageRoute<void>(
            builder: (_) => SignupOtpScreen(name: args.name, email: args.email),
          );
        }
        return _errorRoute('Invalid signup otp arguments');
      case AppRoutes.fillProfile:
        return MaterialPageRoute<void>(
          builder: (_) => const FillProfileScreen(),
        );
      case AppRoutes.createPin:
        return MaterialPageRoute<void>(builder: (_) => const CreatePinScreen());
      case AppRoutes.setFingerprint:
        return MaterialPageRoute<void>(
          builder: (_) => const SetFingerprintScreen(),
        );
      case AppRoutes.accountReady:
        return MaterialPageRoute<void>(
          builder: (_) => const AccountReadyScreen(),
        );
      case AppRoutes.createNewPassword:
        final args = settings.arguments;
        final oobCode = args is String ? args : '';
        return MaterialPageRoute<void>(
          builder: (_) => CreateNewPasswordScreen(oobCode: oobCode),
        );
      case AppRoutes.otpVerification:
        final args = settings.arguments;
        final oobCode = args is String ? args : '';
        return MaterialPageRoute<void>(
          builder: (_) => OtpVerificationScreen(oobCode: oobCode),
        );
      case AppRoutes.resetPasswordSuccess:
        return MaterialPageRoute<void>(
          builder: (_) => const ResetPasswordSuccessScreen(),
        );
      case AppRoutes.forgotPassword:
        return MaterialPageRoute<void>(
          builder: (_) => const ForgotPasswordScreen(),
        );
      case AppRoutes.search:
        return MaterialPageRoute<void>(builder: (_) => const SearchScreen());
      case AppRoutes.categories:
        return MaterialPageRoute<void>(
          builder: (_) => const CategoriesScreen(),
        );
      case AppRoutes.categoryCourses:
        final args = settings.arguments;
        if (args is CategoryCoursesArgs) {
          return MaterialPageRoute<void>(
            builder: (_) => CategoryCoursesScreen(category: args.category),
          );
        }
        return _errorRoute('Invalid category arguments');
      case AppRoutes.popularCourses:
        final args = settings.arguments;
        if (args is CourseCollectionArgs) {
          return MaterialPageRoute<void>(
            builder: (_) => PopularCoursesScreen(
              initialCategory: args.category,
              collectionType: args.type,
            ),
          );
        }
        return MaterialPageRoute<void>(
          builder: (_) => const PopularCoursesScreen(),
        );
      case AppRoutes.instructors:
        final args = settings.arguments;
        if (args is InstructorsArgs) {
          return MaterialPageRoute<void>(
            builder: (_) => InstructorsScreen(category: args.category),
          );
        }
        return MaterialPageRoute<void>(
          builder: (_) => const InstructorsScreen(),
        );
      case AppRoutes.instructorDetails:
        final args = settings.arguments;
        if (args is InstructorDetailsArgs) {
          return MaterialPageRoute<void>(
            builder: (_) =>
                InstructorDetailsScreen(instructor: args.instructor),
          );
        }
        return _errorRoute('Invalid instructor details arguments');
      case AppRoutes.courseDetails:
        final args = settings.arguments;
        if (args is CourseDetailsArgs) {
          return MaterialPageRoute<void>(
            builder: (_) => CourseDetailsScreen(course: args.course),
          );
        }
        return _errorRoute('Invalid course details arguments');
      case AppRoutes.courseReviews:
        final args = settings.arguments;
        if (args is CourseModuleArgs) {
          return MaterialPageRoute<void>(
            builder: (_) => CourseReviewsScreen(course: args.course),
          );
        }
        return _errorRoute('Invalid reviews arguments');
      case AppRoutes.writeReview:
        final args = settings.arguments;
        if (args is CourseModuleArgs) {
          return MaterialPageRoute<void>(
            builder: (_) => WriteReviewScreen(course: args.course),
          );
        }
        return _errorRoute('Invalid write review arguments');
      case AppRoutes.lessonResources:
        final args = settings.arguments;
        if (args is LessonModuleArgs) {
          return MaterialPageRoute<void>(
            builder: (_) => LessonResourcesScreen(
              lesson: args.lesson,
              courseTitle: args.courseTitle,
            ),
          );
        }
        return _errorRoute('Invalid lesson resource arguments');
      case AppRoutes.lessonNotes:
        final args = settings.arguments;
        if (args is LessonModuleArgs) {
          return MaterialPageRoute<void>(
            builder: (_) => LessonNotesScreen(
              lesson: args.lesson,
              courseTitle: args.courseTitle,
            ),
          );
        }
        return _errorRoute('Invalid lesson notes arguments');
      case AppRoutes.videoPlayer:
        final args = settings.arguments;
        if (args is VideoPlayerArgs) {
          return MaterialPageRoute<void>(
            builder: (_) => VideoPlayerScreen(
              lesson: args.lesson,
              courseId: args.courseId,
              courseTitle: args.courseTitle,
              course: args.course,
            ),
          );
        }
        return _errorRoute('Invalid video player arguments');
      case AppRoutes.youtubePlaylist:
        final args = settings.arguments;
        if (args is YoutubePlaylistArgs) {
          return MaterialPageRoute<void>(
            builder: (_) => YoutubePlaylistScreen(
              courseTitle: args.courseTitle,
              playlistId: args.playlistId,
              courseId: args.courseId,
            ),
          );
        }
        return _errorRoute('Invalid youtube playlist arguments');
      case AppRoutes.youtubeFullscreen:
        final args = settings.arguments;
        if (args is YoutubeFullscreenArgs) {
          return MaterialPageRoute<void>(
            builder: (_) => YoutubeFullscreenPlayerScreen(
              videoId: args.videoId,
              title: args.title,
              courseId: args.courseId,
              lessonId: args.lessonId,
              lessonIndex: args.lessonIndex,
              watchedPercent: args.watchedPercent,
            ),
          );
        }
        return _errorRoute('Invalid youtube fullscreen arguments');
      case AppRoutes.myLearning:
        return MaterialPageRoute<void>(
          builder: (_) => const MyLearningScreen(),
        );
      case AppRoutes.studentShell:
        return MaterialPageRoute<void>(
          builder: (_) => const StudentShellScreen(),
        );
      case AppRoutes.instructorDashboard:
        return MaterialPageRoute<void>(
          builder: (_) => const InstructorShellScreen(),
        );
      case AppRoutes.instructorAddCourse:
        return MaterialPageRoute<void>(
          builder: (_) => const InstructorAddCourseScreen(),
        );
      case AppRoutes.instructorEditCourse:
        final args = settings.arguments;
        if (args is InstructorCourseEditorArgs) {
          return MaterialPageRoute<void>(
            builder: (_) =>
                InstructorAddCourseScreen(initialCourse: args.course),
          );
        }
        return _errorRoute('Invalid instructor course editor arguments');
      case AppRoutes.instructorMyCourses:
        return MaterialPageRoute<void>(
          builder: (_) => const InstructorMyCoursesScreen(),
        );
      case AppRoutes.wishlist:
        return MaterialPageRoute<void>(builder: (_) => const WishlistScreen());
      case AppRoutes.notifications:
        return MaterialPageRoute<void>(
          builder: (_) => const NotificationsScreen(),
        );
      case AppRoutes.notificationDetails:
        final args = settings.arguments;
        if (args is NotificationDetailsArgs) {
          return MaterialPageRoute<void>(
            builder: (_) =>
                NotificationDetailsScreen(notification: args.notification),
          );
        }
        return _errorRoute('Invalid notification details arguments');
      case AppRoutes.notificationSettings:
        return MaterialPageRoute<void>(
          builder: (_) => const NotificationSettingsScreen(),
        );
      case AppRoutes.editProfile:
        return MaterialPageRoute<void>(
          builder: (_) => const EditProfileScreen(),
        );
      case AppRoutes.languageSettings:
        return MaterialPageRoute<void>(
          builder: (_) => const LanguageSettingsScreen(),
        );
      case AppRoutes.changePassword:
        return MaterialPageRoute<void>(
          builder: (_) => const ChangePasswordScreen(),
        );
      case AppRoutes.certificates:
        return MaterialPageRoute<void>(
          builder: (_) => const CertificatesScreen(),
        );
      case AppRoutes.certificateDetails:
        final args = settings.arguments;
        if (args is CertificateDetailsArgs) {
          return MaterialPageRoute<void>(
            builder: (_) =>
                CertificateDetailsScreen(certificate: args.certificate),
          );
        }
        return _errorRoute('Invalid certificate details arguments');
      case AppRoutes.terms:
        return MaterialPageRoute<void>(builder: (_) => const TermsScreen());
      default:
        return _errorRoute('Route not found: ${settings.name}');
    }
  }

  static Route<dynamic> _errorRoute(String message) {
    return MaterialPageRoute<void>(
      builder: (_) => Scaffold(
        appBar: AppBar(title: const Text('Navigation Error')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(message),
          ),
        ),
      ),
    );
  }
}
