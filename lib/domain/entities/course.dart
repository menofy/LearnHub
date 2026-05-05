import '../../core/utils/cloudinary_video_thumbnail_helper.dart';

class Course {
  static const String linkMediaSource = 'link';
  static const String uploadMediaSource = 'upload';

  static bool isNetworkVideoUrl(String value) {
    final uri = Uri.tryParse(value.trim());
    if (uri == null) {
      return false;
    }
    final scheme = uri.scheme.toLowerCase();
    return scheme == 'http' || scheme == 'https';
  }

  static bool isSecureHostedVideoUrl(String value) {
    final uri = Uri.tryParse(value.trim());
    return uri != null && uri.scheme.toLowerCase() == 'https';
  }

  const Course({
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
    this.mediaSourceType = linkMediaSource,
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

  String get instructorName => instructor;

  bool get usesUploadedVideos => mediaSourceType == uploadMediaSource;

  bool get hasUploadedVideoUrls {
    for (final value in uploadedVideoUrls) {
      if (isSecureHostedVideoUrl(value)) {
        return true;
      }
    }
    return false;
  }

  List<String> get playableUploadedVideoUrls {
    final urls = <String>[];
    final seen = <String>{};
    for (final value in uploadedVideoUrls) {
      final trimmed = value.trim();
      if (!isSecureHostedVideoUrl(trimmed) || !seen.add(trimmed)) {
        continue;
      }
      urls.add(trimmed);
    }
    return urls;
  }

  String get primaryUploadedVideoUrl {
    for (final value in playableUploadedVideoUrls) {
      return value;
    }
    return '';
  }

  String get primaryPlayableVideoUrl {
    if (usesUploadedVideos) {
      if (primaryUploadedVideoUrl.isNotEmpty) {
        return primaryUploadedVideoUrl;
      }
      final trimmedVideoUrl = videoUrl.trim();
      return isSecureHostedVideoUrl(trimmedVideoUrl) ? trimmedVideoUrl : '';
    }
    return videoUrl;
  }

  String get generatedUploadThumbnailUrl {
    if (!usesUploadedVideos) {
      return '';
    }

    final sourceVideoUrl = primaryUploadedVideoUrl.isNotEmpty
        ? primaryUploadedVideoUrl
        : primaryPlayableVideoUrl.trim();
    return CloudinaryVideoThumbnailHelper.thumbnailUrlFromVideoUrl(
          sourceVideoUrl,
          second: 1,
        ) ??
        '';
  }

  String get preferredPreviewImageUrl {
    final generatedThumbnailUrl = generatedUploadThumbnailUrl.trim();
    if (generatedThumbnailUrl.isNotEmpty) {
      return generatedThumbnailUrl;
    }
    return imageUrl.trim();
  }

  bool get hasMedia {
    return playlistId.trim().isNotEmpty ||
        primaryPlayableVideoUrl.trim().isNotEmpty ||
        hasUploadedVideoUrls;
  }

  Course copyWith({
    String? id,
    String? title,
    String? description,
    String? instructor,
    String? imageUrl,
    String? videoUrl,
    String? category,
    bool? isPopular,
    String? playlistId,
    String? instructorId,
    bool? isAdminCourse,
    DateTime? createdAt,
    double? rating,
    int? studentCount,
    int? totalHours,
    int? lessonCount,
    bool? isFree,
    double? price,
    String? level,
    List<String>? tags,
    List<String>? requirements,
    List<String>? outcomes,
    String? mediaSourceType,
    List<String>? uploadedVideoUrls,
    bool? isPublished,
    DateTime? lastUpdatedAt,
  }) {
    return Course(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      instructor: instructor ?? this.instructor,
      imageUrl: imageUrl ?? this.imageUrl,
      videoUrl: videoUrl ?? this.videoUrl,
      category: category ?? this.category,
      isPopular: isPopular ?? this.isPopular,
      playlistId: playlistId ?? this.playlistId,
      instructorId: instructorId ?? this.instructorId,
      isAdminCourse: isAdminCourse ?? this.isAdminCourse,
      createdAt: createdAt ?? this.createdAt,
      rating: rating ?? this.rating,
      studentCount: studentCount ?? this.studentCount,
      totalHours: totalHours ?? this.totalHours,
      lessonCount: lessonCount ?? this.lessonCount,
      isFree: isFree ?? this.isFree,
      price: price ?? this.price,
      level: level ?? this.level,
      tags: tags ?? this.tags,
      requirements: requirements ?? this.requirements,
      outcomes: outcomes ?? this.outcomes,
      mediaSourceType: mediaSourceType ?? this.mediaSourceType,
      uploadedVideoUrls: uploadedVideoUrls ?? this.uploadedVideoUrls,
      isPublished: isPublished ?? this.isPublished,
      lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
    );
  }
}
