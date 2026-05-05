class CloudinaryVideoThumbnailHelper {
  CloudinaryVideoThumbnailHelper._();

  static const String _cloudinaryHost = 'res.cloudinary.com';
  static const String _videoUploadSegment = '/video/upload/';

  static bool canGenerateThumbnail(String videoUrl) {
    final trimmedVideoUrl = videoUrl.trim();
    if (trimmedVideoUrl.isEmpty) {
      return false;
    }

    final uri = Uri.tryParse(trimmedVideoUrl);
    if (uri == null) {
      return false;
    }

    return uri.scheme.toLowerCase() == 'https' &&
        uri.host.toLowerCase().contains(_cloudinaryHost) &&
        uri.path.contains(_videoUploadSegment);
  }

  static String? thumbnailUrlFromVideoUrl(String videoUrl, {int second = 1}) {
    final trimmedVideoUrl = videoUrl.trim();
    if (!canGenerateThumbnail(trimmedVideoUrl)) {
      return null;
    }

    final safeSecond = second < 0 ? 0 : second;
    final transformedUrl = trimmedVideoUrl.replaceFirst(
      _videoUploadSegment,
      '/video/upload/so_$safeSecond/',
    );
    final suffixStartIndex = _suffixStartIndex(transformedUrl);
    final baseUrl = suffixStartIndex >= 0
        ? transformedUrl.substring(0, suffixStartIndex)
        : transformedUrl;
    final suffix = suffixStartIndex >= 0
        ? transformedUrl.substring(suffixStartIndex)
        : '';
    final lastSlashIndex = baseUrl.lastIndexOf('/');
    final lastDotIndex = baseUrl.lastIndexOf('.');
    final normalizedBaseUrl =
        lastDotIndex > lastSlashIndex
            ? '${baseUrl.substring(0, lastDotIndex)}.jpg'
            : '$baseUrl.jpg';

    return '$normalizedBaseUrl$suffix';
  }

  static int _suffixStartIndex(String value) {
    final queryIndex = value.indexOf('?');
    final fragmentIndex = value.indexOf('#');

    if (queryIndex < 0) {
      return fragmentIndex;
    }
    if (fragmentIndex < 0) {
      return queryIndex;
    }
    return queryIndex < fragmentIndex ? queryIndex : fragmentIndex;
  }
}
