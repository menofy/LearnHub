class Certificate {
  final String id;
  final String studentId;
  final String studentName;
  final String courseId;
  final String courseName;
  final String instructorName;
  final DateTime issuedDate;
  final double completionPercentage;
  final String certificateUrl;
  final String? certificateName;

  Certificate({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.courseId,
    required this.courseName,
    required this.instructorName,
    required this.issuedDate,
    required this.completionPercentage,
    required this.certificateUrl,
    this.certificateName,
  });

  Certificate copyWith({
    String? id,
    String? studentId,
    String? studentName,
    String? courseId,
    String? courseName,
    String? instructorName,
    DateTime? issuedDate,
    double? completionPercentage,
    String? certificateUrl,
    String? certificateName,
  }) {
    return Certificate(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      studentName: studentName ?? this.studentName,
      courseId: courseId ?? this.courseId,
      courseName: courseName ?? this.courseName,
      instructorName: instructorName ?? this.instructorName,
      issuedDate: issuedDate ?? this.issuedDate,
      completionPercentage: completionPercentage ?? this.completionPercentage,
      certificateUrl: certificateUrl ?? this.certificateUrl,
      certificateName: certificateName ?? this.certificateName,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'studentId': studentId,
      'studentName': studentName,
      'courseId': courseId,
      'courseName': courseName,
      'instructorName': instructorName,
      'issuedDate': issuedDate.toIso8601String(),
      'completionPercentage': completionPercentage,
      'certificateUrl': certificateUrl,
      'certificateName': certificateName,
    };
  }

  factory Certificate.fromMap(Map<String, dynamic> map) {
    return Certificate(
      id: map['id'] ?? '',
      studentId: map['studentId'] ?? '',
      studentName: map['studentName'] ?? '',
      courseId: map['courseId'] ?? '',
      courseName: map['courseName'] ?? '',
      instructorName: map['instructorName'] ?? '',
      issuedDate: DateTime.parse(map['issuedDate'] ?? DateTime.now().toIso8601String()),
      completionPercentage: (map['completionPercentage'] as num?)?.toDouble() ?? 0.0,
      certificateUrl: map['certificateUrl'] ?? '',
      certificateName: map['certificateName'],
    );
  }
}
