import '../entities/course.dart';
import '../entities/course_review.dart';
import '../entities/instructor.dart';
import '../entities/lesson.dart';

abstract class CourseRepository {
  Future<List<Course>> getCourses();
  Future<List<Course>> getCoursesByCategory(String category);
  Future<List<Course>> searchCourses(String query);
  Future<List<Lesson>> getLessonsByCourse(String courseId);
  Future<List<Instructor>> getInstructors();
  Future<List<CourseReview>> getCourseReviews(String courseId);
  Future<void> addCourseReview(CourseReview review);
  Future<void> enrollCourse({required String userId, required String courseId});
  Future<List<Course>> getEnrolledCourses(String userId);
}
