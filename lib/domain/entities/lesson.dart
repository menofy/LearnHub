class Lesson {
  const Lesson({
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

  Lesson copyWith({
    String? id,
    String? courseId,
    String? title,
    String? videoUrl,
    String? duration,
    int? order,
    String? sectionTitle,
    bool? isPreview,
  }) {
    return Lesson(
      id: id ?? this.id,
      courseId: courseId ?? this.courseId,
      title: title ?? this.title,
      videoUrl: videoUrl ?? this.videoUrl,
      duration: duration ?? this.duration,
      order: order ?? this.order,
      sectionTitle: sectionTitle ?? this.sectionTitle,
      isPreview: isPreview ?? this.isPreview,
    );
  }
}
