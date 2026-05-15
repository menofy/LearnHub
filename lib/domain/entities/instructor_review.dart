class InstructorReview {
  const InstructorReview({
    required this.id,
    required this.instructorId,
    required this.studentId,
    required this.studentName,
    required this.studentAvatar,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  final String id;
  final String instructorId;
  final String studentId;
  final String studentName;
  final String studentAvatar;
  final double rating;
  final String comment;
  final DateTime createdAt;

  InstructorReview copyWith({
    String? id,
    String? instructorId,
    String? studentId,
    String? studentName,
    String? studentAvatar,
    double? rating,
    String? comment,
    DateTime? createdAt,
  }) {
    return InstructorReview(
      id: id ?? this.id,
      instructorId: instructorId ?? this.instructorId,
      studentId: studentId ?? this.studentId,
      studentName: studentName ?? this.studentName,
      studentAvatar: studentAvatar ?? this.studentAvatar,
      rating: rating ?? this.rating,
      comment: comment ?? this.comment,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
