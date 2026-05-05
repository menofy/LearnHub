class Certificate {
  const Certificate({
    required this.id,
    required this.courseTitle,
    required this.issueDate,
    required this.grade,
  });

  final String id;
  final String courseTitle;
  final DateTime issueDate;
  final String grade;
}
