import '../../domain/entities/instructor.dart';

class InstructorModel {
  const InstructorModel({
    required this.id,
    required this.name,
    required this.title,
    required this.bio,
    required this.avatarUrl,
    required this.rating,
    required this.studentCount,
  });

  final String id;
  final String name;
  final String title;
  final String bio;
  final String avatarUrl;
  final double rating;
  final int studentCount;

  Instructor toEntity() {
    return Instructor(
      id: id,
      name: name,
      title: title,
      bio: bio,
      avatarUrl: avatarUrl,
      rating: rating,
      studentCount: studentCount,
    );
  }
}
