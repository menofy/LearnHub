import 'dart:convert';
import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../data/services/video_thumbnail_service.dart';

class EduCourseThumb extends StatefulWidget {
  const EduCourseThumb({
    super.key,
    required this.imageUrl,
    required this.width,
    required this.height,
    this.videoUrl = '',
    this.playlistId = '',
    this.borderRadius = const BorderRadius.all(Radius.circular(12)),
  });

  final String imageUrl;
  final double width;
  final double height;
  final String videoUrl;
  final String playlistId;
  final BorderRadius borderRadius;

  @override
  State<EduCourseThumb> createState() => _EduCourseThumbState();
}

class _EduCourseThumbState extends State<EduCourseThumb> {
  Future<String?>? _resolvedThumbFuture;

  @override
  void initState() {
    super.initState();
    _syncResolvedThumbFuture();
  }

  @override
  void didUpdateWidget(covariant EduCourseThumb oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl ||
        oldWidget.videoUrl != widget.videoUrl ||
        oldWidget.playlistId != widget.playlistId) {
      _syncResolvedThumbFuture();
    }
  }

  void _syncResolvedThumbFuture() {
    final trimmedImageUrl = widget.imageUrl.trim();
    if (trimmedImageUrl.isNotEmpty) {
      _resolvedThumbFuture = null;
      return;
    }

    _resolvedThumbFuture = VideoThumbnailService.instance.resolve(
      imageUrl: trimmedImageUrl,
      videoUrl: widget.videoUrl,
      playlistId: widget.playlistId,
    );
  }

  @override
  Widget build(BuildContext context) {
    final trimmedImageUrl = widget.imageUrl.trim();

    return ClipRRect(
      borderRadius: widget.borderRadius,
      child: SizedBox(
        width: widget.width,
        height: widget.height,
        child: trimmedImageUrl.isNotEmpty
            ? _NetworkCourseThumb(imageUrl: trimmedImageUrl)
            : FutureBuilder<String?>(
                future: _resolvedThumbFuture,
                builder: (context, snapshot) {
                  final resolvedUrl = snapshot.data?.trim() ?? '';
                  if (resolvedUrl.isEmpty) {
                    return const _MediaPlaceholder();
                  }
                  return _NetworkCourseThumb(imageUrl: resolvedUrl);
                },
              ),
      ),
    );
  }
}

class _NetworkCourseThumb extends StatelessWidget {
  const _NetworkCourseThumb({required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      imageUrl: imageUrl,
      fit: BoxFit.cover,
      fadeInDuration: const Duration(milliseconds: 120),
      placeholder: (context, url) => const _MediaPlaceholder(),
      errorWidget: (context, url, error) => const _MediaPlaceholder(),
    );
  }
}

class EduAvatar extends StatelessWidget {
  const EduAvatar({super.key, required this.imageUrl, this.size = 42});

  final String imageUrl;
  final double size;

  @override
  Widget build(BuildContext context) {
    final trimmedImageUrl = imageUrl.trim();
    if (trimmedImageUrl.isEmpty) {
      return _defaultAvatarShell(
        size: size,
        child: const Icon(Icons.person_rounded, color: Colors.white, size: 20),
      );
    }

    final bytes = _decodeDataUrl(trimmedImageUrl);
    if (bytes != null) {
      return ClipOval(
        child: SizedBox(
          width: size,
          height: size,
          child: Image.memory(
            bytes,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return const _MediaPlaceholder(isCircle: true);
            },
          ),
        ),
      );
    }

    return ClipOval(
      child: SizedBox(
        width: size,
        height: size,
        child: CachedNetworkImage(
          imageUrl: trimmedImageUrl,
          fit: BoxFit.cover,
          fadeInDuration: const Duration(milliseconds: 120),
          placeholder: (context, url) =>
              const _MediaPlaceholder(isCircle: true),
          errorWidget: (context, url, error) =>
              const _MediaPlaceholder(isCircle: true),
        ),
      ),
    );
  }
}

class InstructorAvatar extends StatelessWidget {
  const InstructorAvatar({
    super.key,
    required this.imageUrl,
    required this.instructorName,
    this.size = 44,
  });

  final String imageUrl;
  final String instructorName;
  final double size;

  String get initials {
    return instructorName
        .split(' ')
        .where((part) => part.isNotEmpty)
        .map((part) => part[0].toUpperCase())
        .join()
        .substring(0, 1);
  }

  @override
  Widget build(BuildContext context) {
    final trimmedImageUrl = imageUrl.trim();
    if (trimmedImageUrl.isEmpty) {
      return _defaultAvatarShell(
        size: size,
        child: Center(
          child: Text(
            initials,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: size * 0.4,
            ),
          ),
        ),
      );
    }

    final bytes = _decodeDataUrl(trimmedImageUrl);
    if (bytes != null) {
      return ClipOval(
        child: SizedBox(
          width: size,
          height: size,
          child: Image.memory(
            bytes,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return _instructorInitialFallback();
            },
          ),
        ),
      );
    }

    return ClipOval(
      child: SizedBox(
        width: size,
        height: size,
        child: CachedNetworkImage(
          imageUrl: trimmedImageUrl,
          fit: BoxFit.cover,
          fadeInDuration: const Duration(milliseconds: 120),
          placeholder: (context, url) =>
              const _MediaPlaceholder(isCircle: true),
          errorWidget: (context, url, error) => _instructorInitialFallback(),
        ),
      ),
    );
  }

  Widget _instructorInitialFallback() {
    return _defaultAvatarShell(
      size: size,
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: size * 0.4,
          ),
        ),
      ),
    );
  }
}

Container _defaultAvatarShell({
  required double size,
  required Widget child,
}) {
  return Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: const LinearGradient(
        colors: [Color(0xFF1BCCE0), Color(0xFF12BDBA)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
    child: child,
  );
}

Uint8List? _decodeDataUrl(String raw) {
  final trimmed = raw.trim();
  if (!trimmed.startsWith('data:image')) {
    return null;
  }

  final commaIndex = trimmed.indexOf(',');
  if (commaIndex < 0 || commaIndex + 1 >= trimmed.length) {
    return null;
  }

  try {
    return base64Decode(trimmed.substring(commaIndex + 1));
  } catch (_) {
    return null;
  }
}

class _MediaPlaceholder extends StatelessWidget {
  const _MediaPlaceholder({this.isCircle = false});

  final bool isCircle;

  @override
  Widget build(BuildContext context) {
    final box = Container(
      decoration: BoxDecoration(
        shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1BCCE0).withValues(alpha: 0.1),
            const Color(0xFF0FB9AD).withValues(alpha: 0.15),
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF1BCCE0).withValues(alpha: 0.2),
              ),
              child: const Icon(
                Icons.play_arrow_rounded,
                color: Color(0xFF1BCCE0),
                size: 26,
              ),
            ),
          ],
        ),
      ),
    );
    return box;
  }
}
