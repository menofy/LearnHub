import '../../domain/entities/app_notification.dart';
import '../../domain/entities/certificate.dart';
import '../../domain/entities/course.dart';
import '../../domain/entities/instructor.dart';
import '../../domain/entities/lesson.dart';

class CourseDetailsArgs {
  const CourseDetailsArgs({required this.course});

  final Course course;
}

class SignupOtpArgs {
  const SignupOtpArgs({required this.name, required this.email});

  final String name;
  final String email;
}

class CategoryCoursesArgs {
  const CategoryCoursesArgs({required this.category});

  final String category;
}

class InstructorDetailsArgs {
  const InstructorDetailsArgs({required this.instructor});

  final Instructor instructor;
}

class InstructorsArgs {
  const InstructorsArgs({this.category});

  final String? category;
}

enum CourseCollectionType { popular, instructor }

class CourseCollectionArgs {
  const CourseCollectionArgs({
    this.category,
    this.type = CourseCollectionType.popular,
  });

  final String? category;
  final CourseCollectionType type;
}

class CourseModuleArgs {
  const CourseModuleArgs({required this.course});

  final Course course;
}

class LessonModuleArgs {
  const LessonModuleArgs({
    required this.lesson,
    required this.courseId,
    required this.courseTitle,
  });

  final Lesson lesson;
  final String courseId;
  final String courseTitle;
}

class VideoPlayerArgs {
  const VideoPlayerArgs({
    required this.lesson,
    required this.courseId,
    required this.courseTitle,
    this.course,
  });

  final Lesson lesson;
  final String courseId;
  final String courseTitle;
  final Course? course;
}

class InstructorCourseEditorArgs {
  const InstructorCourseEditorArgs({required this.course});

  final Course course;
}

class YoutubePlaylistArgs {
  const YoutubePlaylistArgs({
    required this.courseTitle,
    required this.playlistId,
    this.courseId,
  });

  final String courseTitle;
  final String playlistId;
  final String? courseId;
}

class YoutubeFullscreenArgs {
  const YoutubeFullscreenArgs({
    required this.videoId,
    required this.title,
    this.courseId,
    this.lessonId,
    this.lessonIndex,
    this.watchedPercent,
  });

  final String videoId;
  final String title;
  final String? courseId;
  final String? lessonId;
  final int? lessonIndex;
  final double? watchedPercent;
}

class NotificationDetailsArgs {
  const NotificationDetailsArgs({required this.notification});

  final AppNotification notification;
}

class CertificateDetailsArgs {
  const CertificateDetailsArgs({required this.certificate});

  final Certificate certificate;
}
