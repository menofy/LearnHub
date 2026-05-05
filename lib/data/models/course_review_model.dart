import '../../domain/entities/course_review.dart';

class CourseReviewModel {
  const CourseReviewModel({
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

  CourseReview toEntity() {
    return CourseReview(
      id: id,
      courseId: courseId,
      userName: userName,
      comment: comment,
      rating: rating,
      createdAt: createdAt,
    );
  }

  factory CourseReviewModel.fromEntity(CourseReview review) {
    return CourseReviewModel(
      id: review.id,
      courseId: review.courseId,
      userName: review.userName,
      comment: review.comment,
      rating: review.rating,
      createdAt: review.createdAt,
    );
  }
}
