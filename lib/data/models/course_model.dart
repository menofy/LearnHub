import '../../domain/entities/course.dart';

class CourseModel {
  const CourseModel({
    required this.id,
    required this.title,
    this.description = '',
    this.instructor = '',
    this.imageUrl = '',
    this.videoUrl = '',
    required this.category,
    this.isPopular = false,
    this.playlistId = '',
    this.instructorId = 'admin',
    this.isAdminCourse = false,
    this.createdAt,
    this.rating = 4.5,
    this.studentCount = 0,
    this.totalHours = 0,
    this.lessonCount = 0,
    this.isFree = true,
    this.price = 0.0,
    this.level = 'All Levels',
    this.tags = const <String>[],
    this.requirements = const <String>[],
    this.outcomes = const <String>[],
    this.mediaSourceType = Course.linkMediaSource,
    this.uploadedVideoUrls = const <String>[],
    this.isPublished = true,
    this.lastUpdatedAt,
  });

  final String id;
  final String title;
  final String description;
  final String instructor;
  final String imageUrl;
  final String videoUrl;
  final String category;
  final bool isPopular;
  final String playlistId;
  final String instructorId;
  final bool isAdminCourse;
  final DateTime? createdAt;
  final double rating;
  final int studentCount;
  final int totalHours;
  final int lessonCount;
  final bool isFree;
  final double price;
  final String level;
  final List<String> tags;
  final List<String> requirements;
  final List<String> outcomes;
  final String mediaSourceType;
  final List<String> uploadedVideoUrls;
  final bool isPublished;
  final DateTime? lastUpdatedAt;

  factory CourseModel.fromMap(Map<String, dynamic> map) {
    List<String> stringList(Object? raw) {
      if (raw is List) {
        return raw.map((item) => item.toString().trim()).where((item) => item.isNotEmpty).toList(growable: false);
      }
      if (raw is String && raw.trim().isNotEmpty) {
        return raw
            .split(RegExp(r'[\n,]'))
            .map((item) => item.trim())
            .where((item) => item.isNotEmpty)
            .toList(growable: false);
      }
      return const <String>[];
    }

    final uploadedVideoUrls = stringList(map['uploadedVideoUrls']);
    final rawMediaSourceType = (map['mediaSourceType'] ?? '').toString().trim();
    final mediaSourceType = rawMediaSourceType.isNotEmpty
        ? rawMediaSourceType
        : (uploadedVideoUrls.isNotEmpty
              ? Course.uploadMediaSource
              : Course.linkMediaSource);

    return CourseModel(
      id: (map['id'] ?? '') as String,
      title: (map['title'] ?? '') as String,
      description: (map['description'] ?? '') as String,
      instructor: (map['instructorName'] ?? map['instructor'] ?? '') as String,
      imageUrl: (map['image'] ?? '') as String,
      videoUrl: (map['videoUrl'] ?? '') as String,
      category: (map['category'] ?? '') as String,
      isPopular: map['is_popular'] as bool? ?? false,
      playlistId: (map['playlistId'] ?? '') as String,
      instructorId: (map['instructorId'] ?? 'admin') as String,
      isAdminCourse: map['isAdminCourse'] as bool? ?? false,
      createdAt: map['createdAt'] is DateTime
          ? map['createdAt'] as DateTime
          : null,
      rating: (map['rating'] as num?)?.toDouble() ?? 4.5,
      studentCount: (map['studentCount'] as num?)?.toInt() ?? 0,
      totalHours: (map['totalHours'] as num?)?.toInt() ?? 0,
      lessonCount: (map['lessonCount'] as num?)?.toInt() ?? 0,
      isFree: map['isFree'] as bool? ?? true,
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      level: (map['level'] ?? 'All Levels') as String,
      tags: stringList(map['tags']),
      requirements: stringList(map['requirements']),
      outcomes: stringList(map['outcomes']),
      mediaSourceType: mediaSourceType,
      uploadedVideoUrls: uploadedVideoUrls,
      isPublished: map['isPublished'] as bool? ?? true,
      lastUpdatedAt: map['lastUpdatedAt'] is DateTime
          ? map['lastUpdatedAt'] as DateTime
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'instructor': instructor,
      'image': imageUrl,
      'videoUrl': videoUrl,
      'category': category,
      'is_popular': isPopular,
      'playlistId': playlistId,
      'instructorId': instructorId,
      'instructorName': instructor,
      'isAdminCourse': isAdminCourse,
      'createdAt': createdAt,
      'rating': rating,
      'studentCount': studentCount,
      'totalHours': totalHours,
      'lessonCount': lessonCount,
      'isFree': isFree,
      'price': price,
      'level': level,
      'tags': tags,
      'requirements': requirements,
      'outcomes': outcomes,
      'mediaSourceType': mediaSourceType,
      'uploadedVideoUrls': uploadedVideoUrls,
      'isPublished': isPublished,
      'lastUpdatedAt': lastUpdatedAt,
    };
  }

  Course toEntity() {
    return Course(
      id: id,
      title: title,
      description: description,
      instructor: instructor,
      imageUrl: imageUrl,
      videoUrl: videoUrl,
      category: category,
      isPopular: isPopular,
      playlistId: playlistId,
      instructorId: instructorId,
      isAdminCourse: isAdminCourse,
      createdAt: createdAt,
      rating: rating,
      studentCount: studentCount,
      totalHours: totalHours,
      lessonCount: lessonCount,
      isFree: isFree,
      price: price,
      level: level,
      tags: tags,
      requirements: requirements,
      outcomes: outcomes,
      mediaSourceType: mediaSourceType,
      uploadedVideoUrls: uploadedVideoUrls,
      isPublished: isPublished,
      lastUpdatedAt: lastUpdatedAt,
    );
  }
}
