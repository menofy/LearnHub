import '../../domain/entities/lesson.dart';

class LessonModel {
  const LessonModel({
    required this.id,
    required this.courseId,
    required this.title,
    required this.videoUrl,
    required this.duration,
    this.order = 0,
    this.sectionTitle = '',
    this.isPreview = false,
  });

  final String id;
  final String courseId;
  final String title;
  final String videoUrl;
  final String duration;
  final int order;
  final String sectionTitle;
  final bool isPreview;

  factory LessonModel.fromMap(Map<String, dynamic> map) {
    return LessonModel(
      id: map['id'] as String,
      courseId: map['course_id'] as String,
      title: map['title'] as String,
      videoUrl: map['video_url'] as String,
      duration: map['duration'] as String? ?? '10 min',
      order: (map['order'] as num?)?.toInt() ?? 0,
      sectionTitle: (map['section_title'] as String?) ?? '',
      isPreview: map['isPreview'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'course_id': courseId,
      'title': title,
      'video_url': videoUrl,
      'duration': duration,
      'order': order,
      'section_title': sectionTitle,
      'isPreview': isPreview,
    };
  }

  Lesson toEntity() {
    return Lesson(
      id: id,
      courseId: courseId,
      title: title,
      videoUrl: videoUrl,
      duration: duration,
      order: order,
      sectionTitle: sectionTitle,
      isPreview: isPreview,
    );
  }
}
