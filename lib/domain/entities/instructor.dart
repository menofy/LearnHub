class Instructor {
  const Instructor({
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
}
