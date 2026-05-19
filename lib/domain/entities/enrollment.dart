class Enrollment {
  final String id;
  final String studentId;
  final String courseId;
  final DateTime enrollmentDate;
  final double completionPercentage;
  final List<String> completedLessonIds;
  final bool isCompleted;
  final DateTime? completionDate;

  Enrollment({
    required this.id,
    required this.studentId,
    required this.courseId,
    required this.enrollmentDate,
    this.completionPercentage = 0.0,
    this.completedLessonIds = const [],
    this.isCompleted = false,
    this.completionDate,
  });

  Enrollment copyWith({
    String? id,
    String? studentId,
    String? courseId,
    DateTime? enrollmentDate,
    double? completionPercentage,
    List<String>? completedLessonIds,
    bool? isCompleted,
    DateTime? completionDate,
  }) {
    return Enrollment(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      courseId: courseId ?? this.courseId,
      enrollmentDate: enrollmentDate ?? this.enrollmentDate,
      completionPercentage: completionPercentage ?? this.completionPercentage,
      completedLessonIds: completedLessonIds ?? this.completedLessonIds,
      isCompleted: isCompleted ?? this.isCompleted,
      completionDate: completionDate ?? this.completionDate,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'studentId': studentId,
      'courseId': courseId,
      'enrollmentDate': enrollmentDate.toIso8601String(),
      'completionPercentage': completionPercentage,
      'completedLessonIds': completedLessonIds,
      'isCompleted': isCompleted,
      'completionDate': completionDate?.toIso8601String(),
    };
  }

  factory Enrollment.fromMap(Map<String, dynamic> map) {
    return Enrollment(
      id: map['id'] ?? '',
      studentId: map['studentId'] ?? '',
      courseId: map['courseId'] ?? '',
      enrollmentDate: DateTime.parse(
        map['enrollmentDate'] ?? DateTime.now().toIso8601String(),
      ),
      completionPercentage: (map['completionPercentage'] as num?)?.toDouble() ?? 0.0,
      completedLessonIds: List<String>.from(map['completedLessonIds'] ?? []),
      isCompleted: map['isCompleted'] ?? false,
      completionDate: map['completionDate'] != null
          ? DateTime.parse(map['completionDate'])
          : null,
    );
  }
}
