class CourseReview {
  const CourseReview({
    required this.id,
    required this.courseId,
    required this.userName,
    required this.comment,
    required this.rating,
    required this.createdAt,
  });

  final String id;
  final String courseId;
  final String userName;
  final String comment;
  final double rating;
  final DateTime createdAt;
}
