import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:learnhub/core/shared_widgets/content_loading_skeleton.dart';
import 'package:learnhub/core/shared_widgets/discard_changes_dialog.dart';
import 'package:learnhub/core/shared_widgets/edu_primary_button.dart';
import 'package:learnhub/features/instructor/widgets/add_course_category_chips.dart';
import 'package:learnhub/features/instructor/widgets/add_course_core_details_form.dart';
import 'package:learnhub/features/instructor/widgets/add_course_hero_banner.dart';
import 'package:learnhub/features/instructor/widgets/add_course_media_source_section.dart';
import 'package:learnhub/features/instructor/widgets/add_course_outcomes_requirements_form.dart';
import 'package:learnhub/features/instructor/widgets/add_course_pricing_visibility_section.dart';
import 'package:learnhub/features/instructor/widgets/add_course_student_preview.dart';
import 'package:learnhub/features/shared/auth/providers/auth_provider.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';

import '../../../core/utils/app_error_mapper.dart';
import '../../../data/services/cloudinary_video_upload_service.dart';
import '../../../data/services/firestore_service.dart';
import '../../../domain/entities/app_user.dart';
import '../../../domain/entities/course.dart';
import 'instructor_shared.dart';

const List<String> instructorLevels = <String>[
  'Beginner',
  'Intermediate',
  'Advanced',
  'All Levels',
];

class InstructorAddCourseScreen extends StatefulWidget {
  const InstructorAddCourseScreen({
    super.key,
    this.embedded = false,
    this.onSaved,
    this.initialCourse,
  });

  final bool embedded;
  final VoidCallback? onSaved;
  final Course? initialCourse;

  @override
  State<InstructorAddCourseScreen> createState() =>
      _InstructorAddCourseScreenState();
}

class _InstructorAddCourseScreenState extends State<InstructorAddCourseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _videoUrlController = TextEditingController();
  final _imageUrlController = TextEditingController();
  final _tagsController = TextEditingController();
  final _requirementsController = TextEditingController();
  final _outcomesController = TextEditingController();
  final _priceController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();
  final CloudinaryVideoUploadService _cloudinaryVideoUploadService =
      CloudinaryVideoUploadService.instance;
  final Map<String, String> _videoDurationLabels = <String, String>{};
  final Set<String> _loadingVideoDurations = <String>{};
  final ValueNotifier<double> _uploadProgressNotifier = ValueNotifier<double>(
    0,
  );
  final ValueNotifier<String> _uploadStatusNotifier = ValueNotifier<String>(
    'Preparing uploads...',
  );

  late final List<TextEditingController> _watchedControllers;
  BuildContext? _uploadDialogContext;
  bool _uploadDialogVisible = false;
  Completer<void>? _uploadDialogReadyCompleter;
  bool _saveInFlight = false;
  bool _isDisposed = false;

  String _selectedCategory = instructorCategories.first;
  String _selectedLevel = instructorLevels.first;
  bool _isPublished = true;
  bool _isFree = true;
  bool _isSaving = false;
  AutovalidateMode _autovalidateMode = AutovalidateMode.disabled;

  String mediaSourceType = Course.linkMediaSource;
  List<PlatformFile> pickedLocalVideos = <PlatformFile>[];
  List<XFile> recordedVideos = <XFile>[];
  List<String> existingUploadedVideoUrls = <String>[];

  bool get _isEditing => widget.initialCourse != null;

  String get _trimmedUrl => _videoUrlController.text.trim();

  String get _playlistId => mediaSourceType == Course.linkMediaSource
      ? FirestoreService.instance.extractPlaylistId(_trimmedUrl)
      : '';

  String get _youtubeVideoId => mediaSourceType == Course.linkMediaSource
      ? FirestoreService.instance.extractYoutubeVideoId(_trimmedUrl)
      : '';

  String get _sourceLabel {
    if (mediaSourceType == Course.uploadMediaSource) {
      final count = _managedVideoItems.length;
      if (count <= 0) {
        return 'Managed video uploads';
      }
      return count == 1 ? '1 uploaded video' : '$count uploaded videos';
    }
    if (_playlistId.isNotEmpty) {
      return 'YouTube playlist';
    }
    if (_youtubeVideoId.isNotEmpty) {
      return 'Single YouTube video';
    }
    if (_trimmedUrl.isNotEmpty) {
      return 'External video link';
    }
    return 'Not selected yet';
  }

  List<InstructorManagedVideoItem> get _managedVideoItems {
    final items = <InstructorManagedVideoItem>[];

    for (final source in _cleanUploadedVideoUrls(existingUploadedVideoUrls)) {
      items.add(
        InstructorManagedVideoItem(
          origin: InstructorManagedVideoOrigin.existing,
          storageValue: source,
          displayName: _displayNameFromStoredValue(
            source,
            fallback: 'Existing video',
          ),
          sourceBadgeLabel: 'Existing',
          durationLabel: _videoDurationLabels[source],
        ),
      );
    }

    for (final file in pickedLocalVideos) {
      final path = file.path?.trim() ?? '';
      if (path.isEmpty) {
        continue;
      }
      final storageValue = _normalizeStoredVideoUrl(path);
      items.add(
        InstructorManagedVideoItem(
          origin: InstructorManagedVideoOrigin.local,
          storageValue: storageValue,
          displayName: file.name.trim().isEmpty
              ? _displayNameFromStoredValue(path, fallback: 'Local video')
              : file.name.trim(),
          sourceBadgeLabel: 'Local',
          durationLabel: _videoDurationLabels[storageValue],
        ),
      );
    }

    for (final file in recordedVideos) {
      final storageValue = _normalizeStoredVideoUrl(file.path);
      items.add(
        InstructorManagedVideoItem(
          origin: InstructorManagedVideoOrigin.recorded,
          storageValue: storageValue,
          displayName: _displayNameFromStoredValue(
            file.path,
            fallback: 'Recorded video',
          ),
          sourceBadgeLabel: 'Recorded',
          durationLabel: _videoDurationLabels[storageValue],
        ),
      );
    }

    return items;
  }

  @override
  void initState() {
    super.initState();
    final course = widget.initialCourse;
    if (course != null) {
      _titleController.text = course.title;
      _descriptionController.text = course.description;
      _videoUrlController.text = course.usesUploadedVideos
          ? ''
          : course.videoUrl;
      _imageUrlController.text = course.imageUrl;
      _tagsController.text = course.tags.join(', ');
      _requirementsController.text = course.requirements.join('\n');
      _outcomesController.text = course.outcomes.join('\n');
      _selectedCategory = course.category;
      _selectedLevel = course.level;
      _isPublished = course.isPublished;
      _isFree = course.isFree;
      _priceController.text = course.price <= 0 ? '' : course.price.toString();
      mediaSourceType = course.mediaSourceType;
      existingUploadedVideoUrls = _seedExistingUploadedVideoUrls(course);
      _primeDurationsForStoredVideos(existingUploadedVideoUrls);
    } else {
      _priceController.text = '';
    }

    _watchedControllers = <TextEditingController>[
      _titleController,
      _descriptionController,
      _videoUrlController,
      _imageUrlController,
      _tagsController,
      _requirementsController,
      _outcomesController,
      _priceController,
    ];
    for (final controller in _watchedControllers) {
      controller.addListener(_handleLiveFieldUpdates);
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _dismissUploadProgressDialogIfNeeded();
    for (final controller in _watchedControllers) {
      controller.removeListener(_handleLiveFieldUpdates);
    }
    _titleController.dispose();
    _descriptionController.dispose();
    _videoUrlController.dispose();
    _imageUrlController.dispose();
    _tagsController.dispose();
    _requirementsController.dispose();
    _outcomesController.dispose();
    _priceController.dispose();
    _uploadProgressNotifier.dispose();
    _uploadStatusNotifier.dispose();
    super.dispose();
  }

  void _handleLiveFieldUpdates() {
    if (!mounted) {
      return;
    }
    setState(() {});
  }

  List<String> _seedExistingUploadedVideoUrls(Course course) {
    final seeded = <String>[
      ...course.uploadedVideoUrls,
      if (course.usesUploadedVideos &&
          course.primaryPlayableVideoUrl.trim().isNotEmpty)
        course.primaryPlayableVideoUrl,
    ];
    return _cleanUploadedVideoUrls(seeded);
  }

  bool _looksLikeLocalPath(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return false;
    }
    return trimmed.startsWith('/') ||
        RegExp(r'^[a-zA-Z]:[\\/]').hasMatch(trimmed);
  }

  bool _isRemoteVideoUrl(String value) {
    final uri = Uri.tryParse(value.trim());
    if (uri == null) {
      return false;
    }
    final scheme = uri.scheme.toLowerCase();
    return scheme == 'http' || scheme == 'https';
  }

  bool _isSecureRemoteVideoUrl(String value) {
    final uri = Uri.tryParse(value.trim());
    return uri != null && uri.scheme.toLowerCase() == 'https';
  }

  String _normalizeStoredVideoUrl(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return '';
    }
    if (_looksLikeLocalPath(trimmed)) {
      return Uri.file(trimmed).toString();
    }
    final uri = Uri.tryParse(trimmed);
    if (uri != null && uri.scheme.isNotEmpty) {
      return uri.toString();
    }
    return trimmed;
  }

  String? _localPathFromStoredVideo(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return null;
    }
    if (_looksLikeLocalPath(trimmed)) {
      return trimmed;
    }
    final uri = Uri.tryParse(trimmed);
    if (uri != null && uri.scheme == 'file') {
      return uri.toFilePath();
    }
    return null;
  }

  List<String> _cleanUploadedVideoUrls(Iterable<String> values) {
    final cleaned = <String>[];
    final seen = <String>{};
    for (final value in values) {
      final normalized = _normalizeStoredVideoUrl(value);
      if (normalized.isEmpty || !seen.add(normalized)) {
        continue;
      }
      cleaned.add(normalized);
    }
    return cleaned;
  }

  List<String> _cleanPersistedUploadedVideoUrls(Iterable<String> values) {
    final cleaned = <String>[];
    final seen = <String>{};
    for (final value in values) {
      final trimmed = value.trim();
      if (!_isSecureRemoteVideoUrl(trimmed) || !seen.add(trimmed)) {
        continue;
      }
      cleaned.add(trimmed);
    }
    return cleaned;
  }

  String _displayNameFromStoredValue(String value, {required String fallback}) {
    final localPath = _localPathFromStoredVideo(value);
    if (localPath != null && localPath.trim().isNotEmpty) {
      final name = p.basename(localPath.trim());
      return name.isEmpty ? fallback : name;
    }

    final uri = Uri.tryParse(value.trim());
    if (uri != null && uri.pathSegments.isNotEmpty) {
      final name = Uri.decodeComponent(uri.pathSegments.last).trim();
      if (name.isNotEmpty) {
        return name;
      }
    }

    return fallback;
  }

  Future<void> _pickVideosFromDevice() async {
    if (_isSaving) {
      return;
    }

    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.video,
        withData: false,
      );
      if (result == null || result.files.isEmpty) {
        return;
      }

      final known = <String>{
        ..._cleanUploadedVideoUrls(existingUploadedVideoUrls),
        ...pickedLocalVideos
            .map((item) => item.path?.trim() ?? '')
            .where((item) => item.isNotEmpty)
            .map(_normalizeStoredVideoUrl),
        ...recordedVideos.map((item) => _normalizeStoredVideoUrl(item.path)),
      };
      final nextVideos = <PlatformFile>[...pickedLocalVideos];

      for (final file in result.files) {
        final path = file.path?.trim() ?? '';
        if (path.isEmpty) {
          continue;
        }
        final storageValue = _normalizeStoredVideoUrl(path);
        if (!known.add(storageValue)) {
          continue;
        }
        nextVideos.add(file);
        unawaited(_cacheVideoDuration(storageValue, path));
      }

      if (!mounted) {
        return;
      }
      setState(() => pickedLocalVideos = nextVideos);
    } catch (_) {
      _showSnackBar(
        'We could not open your device videos right now. Please try again.',
      );
    }
  }

  Future<void> _recordNewVideo() async {
    if (_isSaving) {
      return;
    }

    try {
      final video = await _imagePicker.pickVideo(source: ImageSource.camera);
      if (video == null) {
        return;
      }

      final storageValue = _normalizeStoredVideoUrl(video.path);
      final known = <String>{
        ..._cleanUploadedVideoUrls(existingUploadedVideoUrls),
        ...pickedLocalVideos
            .map((item) => item.path?.trim() ?? '')
            .where((item) => item.isNotEmpty)
            .map(_normalizeStoredVideoUrl),
        ...recordedVideos.map((item) => _normalizeStoredVideoUrl(item.path)),
      };
      if (known.contains(storageValue)) {
        return;
      }

      unawaited(_cacheVideoDuration(storageValue, video.path));

      if (!mounted) {
        return;
      }
      setState(() {
        recordedVideos = <XFile>[...recordedVideos, video];
      });
    } catch (_) {
      _showSnackBar(
        'We could not record a new video right now. Please try again.',
      );
    }
  }

  Future<void> _cacheVideoDuration(String key, String source) async {
    if (key.trim().isEmpty ||
        _videoDurationLabels.containsKey(key) ||
        _loadingVideoDurations.contains(key)) {
      return;
    }

    _loadingVideoDurations.add(key);
    VideoPlayerController? controller;

    try {
      if (_isRemoteVideoUrl(source)) {
        controller = VideoPlayerController.networkUrl(Uri.parse(source));
      } else {
        final localPath = _localPathFromStoredVideo(source);
        if (localPath == null || localPath.trim().isEmpty) {
          return;
        }
        controller = VideoPlayerController.file(File(localPath));
      }

      await controller.initialize().timeout(const Duration(seconds: 10));
      final label = _formatDurationLabel(controller.value.duration);
      if (label == null || !mounted) {
        return;
      }

      setState(() {
        _videoDurationLabels[key] = label;
      });
    } catch (_) {
      // If metadata is unavailable, the tile simply omits the duration.
    } finally {
      await controller?.dispose();
      _loadingVideoDurations.remove(key);
    }
  }

  void _primeDurationsForStoredVideos(Iterable<String> values) {
    for (final value in values) {
      final normalized = _normalizeStoredVideoUrl(value);
      if (normalized.isEmpty) {
        continue;
      }
      final source = _localPathFromStoredVideo(normalized) ?? normalized;
      unawaited(_cacheVideoDuration(normalized, source));
    }
  }

  String? _formatDurationLabel(Duration duration) {
    if (duration <= Duration.zero) {
      return null;
    }

    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${duration.inMinutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Future<void> _showUploadProgressDialog() async {
    if (_uploadDialogVisible || !mounted || _isDisposed) {
      return;
    }

    _uploadDialogVisible = true;
    final readyCompleter = Completer<void>();
    _uploadDialogReadyCompleter = readyCompleter;
    unawaited(
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          _uploadDialogContext = dialogContext;
          if (!readyCompleter.isCompleted) {
            readyCompleter.complete();
          }
          return PopScope<void>(
            canPop: false,
            child: AlertDialog(
              title: const Text('Uploading Course Videos'),
              content: SizedBox(
                width: 320,
                child: ValueListenableBuilder<double>(
                  valueListenable: _uploadProgressNotifier,
                  builder: (context, progress, _) {
                    return ValueListenableBuilder<String>(
                      valueListenable: _uploadStatusNotifier,
                      builder: (context, status, child) {
                        final percent = (progress * 100).clamp(0, 100).round();
                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              status,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 14),
                            LinearProgressIndicator(value: progress),
                            const SizedBox(height: 10),
                            Text(
                              '$percent% complete',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          );
        },
      ).whenComplete(() {
        if (!readyCompleter.isCompleted) {
          readyCompleter.complete();
        }
        _uploadDialogVisible = false;
        _uploadDialogContext = null;
        if (identical(_uploadDialogReadyCompleter, readyCompleter)) {
          _uploadDialogReadyCompleter = null;
        }
      }),
    );

    await readyCompleter.future.timeout(
      const Duration(seconds: 1),
      onTimeout: () {},
    );
  }

  void _dismissUploadProgressDialogIfNeeded() {
    final dialogContext = _uploadDialogContext;
    if (!_uploadDialogVisible ||
        dialogContext == null ||
        !dialogContext.mounted) {
      return;
    }
    Navigator.of(dialogContext).pop();
  }

  void _updateUploadProgress({
    required int completedUploads,
    required int totalUploads,
    required String currentLabel,
    required double fileProgress,
  }) {
    if (totalUploads <= 0 || _isDisposed) {
      return;
    }

    final clampedFileProgress = fileProgress.clamp(0.0, 1.0);
    final overallProgress =
        ((completedUploads + clampedFileProgress) / totalUploads).clamp(
          0.0,
          1.0,
        );
    final currentUploadNumber = completedUploads >= totalUploads
        ? totalUploads
        : completedUploads + 1;

    _uploadProgressNotifier.value = overallProgress;
    _uploadStatusNotifier.value = totalUploads == 1
        ? 'Uploading $currentLabel'
        : 'Uploading video $currentUploadNumber of $totalUploads: $currentLabel';
  }

  File? _localFileFromManagedVideo(InstructorManagedVideoItem item) {
    final localPath = _localPathFromStoredVideo(item.storageValue);
    if (localPath == null || localPath.trim().isEmpty) {
      return null;
    }
    return File(localPath);
  }

  void _applyUploadedVideoUrls(List<String> uploadedUrls) {
    final cleanedUrls = _cleanPersistedUploadedVideoUrls(uploadedUrls);
    if (!mounted) {
      existingUploadedVideoUrls = cleanedUrls;
      pickedLocalVideos = <PlatformFile>[];
      recordedVideos = <XFile>[];
      return;
    }

    setState(() {
      existingUploadedVideoUrls = cleanedUrls;
      pickedLocalVideos = <PlatformFile>[];
      recordedVideos = <XFile>[];
    });
    _primeDurationsForStoredVideos(cleanedUrls);
  }

  Future<List<String>> _resolveUploadedVideoUrlsForSave() async {
    final managedVideos = _managedVideoItems;
    final localItems = managedVideos
        .where((item) => !_isSecureRemoteVideoUrl(item.storageValue))
        .toList(growable: false);
    final resolvedUrls = <String>[];

    if (localItems.isNotEmpty) {
      _uploadProgressNotifier.value = 0;
      _uploadStatusNotifier.value = 'Preparing uploads...';
      await _showUploadProgressDialog();
    }

    var completedUploads = 0;
    for (final item in managedVideos) {
      final currentValue = item.storageValue.trim();
      if (_isSecureRemoteVideoUrl(currentValue)) {
        resolvedUrls.add(currentValue);
        continue;
      }

      final file = _localFileFromManagedVideo(item);
      if (file == null) {
        if (_isRemoteVideoUrl(currentValue)) {
          throw Exception(
            'Only HTTPS hosted uploads can be saved. Remove "${item.displayName}" and add it again.',
          );
        }
        throw Exception(
          'Could not access "${item.displayName}" on this device. Please remove it or select it again before publishing.',
        );
      }
      if (!await file.exists()) {
        throw Exception(
          'Could not find "${item.displayName}" on this device anymore. Please remove it or select it again before publishing.',
        );
      }

      _updateUploadProgress(
        completedUploads: completedUploads,
        totalUploads: localItems.length,
        currentLabel: item.displayName,
        fileProgress: 0,
      );

      final uploadedUrl = await _cloudinaryVideoUploadService.uploadVideo(
        file,
        onProgress: (sentBytes, totalBytes) {
          final progress = totalBytes <= 0 ? 0.0 : sentBytes / totalBytes;
          _updateUploadProgress(
            completedUploads: completedUploads,
            totalUploads: localItems.length,
            currentLabel: item.displayName,
            fileProgress: progress,
          );
        },
      );

      resolvedUrls.add(uploadedUrl);
      completedUploads += 1;
      _updateUploadProgress(
        completedUploads: completedUploads,
        totalUploads: localItems.length,
        currentLabel: item.displayName,
        fileProgress: 0,
      );
    }

    if (localItems.isNotEmpty) {
      _uploadProgressNotifier.value = 1;
      _uploadStatusNotifier.value = 'Uploads complete. Saving course...';
    }

    return _cleanPersistedUploadedVideoUrls(resolvedUrls);
  }

  void _removeManagedVideo(InstructorManagedVideoItem item) {
    setState(() {
      switch (item.origin) {
        case InstructorManagedVideoOrigin.existing:
          existingUploadedVideoUrls = existingUploadedVideoUrls
              .where(
                (value) => _normalizeStoredVideoUrl(value) != item.storageValue,
              )
              .toList(growable: false);
          break;
        case InstructorManagedVideoOrigin.local:
          pickedLocalVideos = pickedLocalVideos
              .where(
                (value) =>
                    _normalizeStoredVideoUrl(value.path?.trim() ?? '') !=
                    item.storageValue,
              )
              .toList(growable: false);
          break;
        case InstructorManagedVideoOrigin.recorded:
          recordedVideos = recordedVideos
              .where(
                (value) =>
                    _normalizeStoredVideoUrl(value.path) != item.storageValue,
              )
              .toList(growable: false);
          break;
      }
    });
  }

  List<String> _parseList(String raw) {
    return raw
        .split(RegExp(r'[\n,]'))
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
  }

  Future<void> _save() async {
    try {
      if (_saveInFlight || _isDisposed) {
        return;
      }
      _saveInFlight = true;

      FocusScope.of(context).unfocus();
      final isValid = _formKey.currentState!.validate();
      if (!isValid) {
        if (mounted) {
          setState(() {
            _autovalidateMode = AutovalidateMode.onUserInteraction;
          });
        }
        return;
      }

      final user = context.read<AuthProvider>().currentUser;
      if (user == null) {
        return;
      }
      if (user.role != AppUserRole.instructor) {
        _showSnackBar('Only instructors can publish courses.');
        return;
      }

      if (mediaSourceType == Course.linkMediaSource) {
        final videoUri = Uri.tryParse(_trimmedUrl);
        final isHttpVideo =
            videoUri != null &&
            (videoUri.scheme.toLowerCase() == 'http' ||
                videoUri.scheme.toLowerCase() == 'https');

        if (!isHttpVideo) {
          _showSnackBar(
            'Add a valid public video URL that starts with http:// or https://.',
          );
          return;
        }
      } else if (_managedVideoItems.isEmpty) {
        _showSnackBar(
          'Add at least one lesson video before saving this course.',
        );
        return;
      }

      final parsedPrice = double.tryParse(_priceController.text.trim()) ?? 0.0;
      if (!_isFree && parsedPrice <= 0) {
        _showSnackBar('Please add a valid price or mark the course as free.');
        return;
      }

      final tags = _parseList(_tagsController.text);
      final requirements = _parseList(_requirementsController.text);
      final outcomes = _parseList(_outcomesController.text);

      if (mounted) {
        setState(() => _isSaving = true);
      }
      try {
        final persistedUploadedVideoUrls =
            mediaSourceType == Course.uploadMediaSource
            ? await _resolveUploadedVideoUrlsForSave()
            : const <String>[];
        if (mediaSourceType == Course.uploadMediaSource &&
            persistedUploadedVideoUrls.isEmpty) {
          throw Exception(
            'Please keep at least one uploaded video before saving this course.',
          );
        }

        if (mediaSourceType == Course.uploadMediaSource) {
          _applyUploadedVideoUrls(persistedUploadedVideoUrls);
        }

        final activeVideoUrl = mediaSourceType == Course.linkMediaSource
            ? _trimmedUrl
            : persistedUploadedVideoUrls.first;

        if (_isEditing) {
          await FirestoreService.instance.updateCourse(
            courseId: widget.initialCourse!.id,
            title: _titleController.text.trim(),
            description: _descriptionController.text.trim(),
            videoUrl: activeVideoUrl,
            imageUrl: _imageUrlController.text.trim(),
            category: _selectedCategory,
            instructorName: user.name,
            playlistId: mediaSourceType == Course.linkMediaSource
                ? _playlistId
                : '',
            level: _selectedLevel,
            tags: tags,
            requirements: requirements,
            outcomes: outcomes,
            mediaSourceType: mediaSourceType,
            uploadedVideoUrls: persistedUploadedVideoUrls,
            isPublished: _isPublished,
            isFree: _isFree,
            price: _isFree ? 0.0 : parsedPrice,
          );
        } else {
          await FirestoreService.instance.addCourse(
            title: _titleController.text.trim(),
            description: _descriptionController.text.trim(),
            videoUrl: activeVideoUrl,
            imageUrl: _imageUrlController.text.trim(),
            category: _selectedCategory,
            playlistId: mediaSourceType == Course.linkMediaSource
                ? _playlistId
                : '',
            instructorId: user.id,
            instructorName: user.name,
            isAdminCourse: false,
            level: _selectedLevel,
            tags: tags,
            requirements: requirements,
            outcomes: outcomes,
            mediaSourceType: mediaSourceType,
            uploadedVideoUrls: persistedUploadedVideoUrls,
            isPublished: _isPublished,
            isFree: _isFree,
            price: _isFree ? 0.0 : parsedPrice,
          );
        }

        if (!mounted) {
          return;
        }

        final messenger = ScaffoldMessenger.of(context);
        messenger.hideCurrentSnackBar();
        final successMessage = _isEditing
            ? (_isPublished
                  ? 'Course updated successfully.'
                  : 'Draft updated successfully.')
            : (_isPublished
                  ? 'Course published successfully.'
                  : 'Draft saved successfully.');
        messenger.showSnackBar(SnackBar(content: Text(successMessage)));

        if (widget.embedded) {
          widget.onSaved?.call();
        } else {
          Navigator.of(context).pop();
        }
      } on TimeoutException {
        if (!mounted) {
          return;
        }
        _showSnackBar(
          mediaSourceType == Course.uploadMediaSource
              ? 'Video upload finished, but saving the course timed out. Please confirm whether the course was saved before retrying.'
              : 'Saving the course timed out. Please confirm whether the course was saved before retrying.',
        );
      } catch (error) {
        if (!mounted) {
          return;
        }
        final fallback = _isEditing
            ? 'Could not update course. Please try again.'
            : 'Could not create course. Please try again.';
        final message = error is CloudinaryVideoUploadException
            ? error.message
            : AppErrorMapper.data(
                error,
                fallback: AppErrorMapper.external(error, fallback: fallback),
              );
        _showSnackBar(message);
      } finally {
        _dismissUploadProgressDialogIfNeeded();
        if (mounted) {
          setState(() => _isSaving = false);
        }
      }
    } finally {
      _saveInFlight = false;
    }
  }

  bool get _hasUnsavedChanges {
    final initialCourse = widget.initialCourse;
    final persistedUploadedVideoUrls = _cleanUploadedVideoUrls(
      existingUploadedVideoUrls,
    );

    if (initialCourse != null) {
      return _titleController.text.trim() != initialCourse.title.trim() ||
          _descriptionController.text.trim() !=
              initialCourse.description.trim() ||
          _videoUrlController.text.trim() !=
              (initialCourse.usesUploadedVideos
                  ? ''
                  : initialCourse.videoUrl.trim()) ||
          _imageUrlController.text.trim() != initialCourse.imageUrl.trim() ||
          _tagsController.text.trim() != initialCourse.tags.join(', ') ||
          _requirementsController.text.trim() !=
              initialCourse.requirements.join('\n') ||
          _outcomesController.text.trim() !=
              initialCourse.outcomes.join('\n') ||
          _selectedCategory != initialCourse.category ||
          _selectedLevel != initialCourse.level ||
          _isPublished != initialCourse.isPublished ||
          _isFree != initialCourse.isFree ||
          mediaSourceType != initialCourse.mediaSourceType ||
          !_sameStringLists(
            persistedUploadedVideoUrls,
            _seedExistingUploadedVideoUrls(initialCourse),
          ) ||
          pickedLocalVideos.isNotEmpty ||
          recordedVideos.isNotEmpty ||
          _priceController.text.trim() !=
              (initialCourse.price <= 0 ? '' : initialCourse.price.toString());
    }

    return _titleController.text.trim().isNotEmpty ||
        _descriptionController.text.trim().isNotEmpty ||
        _videoUrlController.text.trim().isNotEmpty ||
        _imageUrlController.text.trim().isNotEmpty ||
        _tagsController.text.trim().isNotEmpty ||
        _requirementsController.text.trim().isNotEmpty ||
        _outcomesController.text.trim().isNotEmpty ||
        _priceController.text.trim().isNotEmpty ||
        pickedLocalVideos.isNotEmpty ||
        recordedVideos.isNotEmpty ||
        existingUploadedVideoUrls.isNotEmpty ||
        mediaSourceType != Course.linkMediaSource ||
        _selectedCategory != instructorCategories.first ||
        _selectedLevel != instructorLevels.first ||
        !_isPublished ||
        !_isFree;
  }

  bool _sameStringLists(List<String> a, List<String> b) {
    if (a.length != b.length) {
      return false;
    }
    for (var index = 0; index < a.length; index++) {
      if (a[index] != b[index]) {
        return false;
      }
    }
    return true;
  }

  Future<bool> _confirmExit() async {
    if (_isSaving || !_hasUnsavedChanges) {
      return true;
    }

    return showDiscardChangesDialog(
      context,
      message:
          'Your course changes are not saved yet. Leave this editor and lose those edits?',
    );
  }

  Future<void> _handleBack() async {
    final shouldLeave = await _confirmExit();
    if (!mounted || !shouldLeave) {
      return;
    }
    Navigator.of(context).pop();
  }

  void _showSnackBar(String message) {
    if (!mounted || _isDisposed) {
      return;
    }
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) {
      return;
    }
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    final theme = Theme.of(context);
    final titleColor = instructorTitleColor(context);
    final secondaryText = instructorMutedColor(context);
    if (user == null) {
      return const Scaffold(
        body: SafeArea(
          child: ContentLoadingSkeleton(itemCount: 3, tileHeight: 100),
        ),
      );
    }
    if (user.role != AppUserRole.instructor) {
      return Scaffold(
        appBar: AppBar(title: const Text('Course Editor')),
        body: Center(
          child: Text(
            'Only instructors can create courses.',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: secondaryText,
            ),
          ),
        ),
      );
    }

    final page = SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 110),
        child: Form(
          key: _formKey,
          autovalidateMode: _autovalidateMode,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_isSaving) ...[
                const LinearProgressIndicator(minHeight: 3),
                const SizedBox(height: 12),
              ],
              Text(
                _isEditing ? 'Edit Course' : 'Create Course',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: titleColor,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _isEditing
                    ? 'Refine your curriculum, pricing, and publishing state without losing the student-facing polish.'
                    : 'Create a structured course with stronger metadata, learner outcomes, and a cleaner publishing flow.',
                style: TextStyle(
                  fontSize: 12,
                  height: 1.55,
                  fontWeight: FontWeight.w700,
                  color: secondaryText,
                ),
              ),
              const SizedBox(height: 18),
              AddCourseHeroBanner(
                isEditing: _isEditing,
                isPublished: _isPublished,
              ),
              const SizedBox(height: 18),
              AddCourseCoreDetailsForm(
                titleController: _titleController,
                descriptionController: _descriptionController,
                imageUrlController: _imageUrlController,
                tagsController: _tagsController,
                selectedLevel: _selectedLevel,
                onLevelChanged: (value) =>
                    setState(() => _selectedLevel = value),
                levels: instructorLevels,
              ),
              const SizedBox(height: 18),
              AddCourseCategoryChips(
                selectedCategory: _selectedCategory,
                onCategoryChanged: (value) =>
                    setState(() => _selectedCategory = value),
              ),
              const SizedBox(height: 18),
              AddCourseMediaSourceSection(
                videoUrlController: _videoUrlController,
                mediaSourceType: mediaSourceType,
                sourceLabel: _sourceLabel,
                playlistId: _playlistId,
                selectedCategory: _selectedCategory,
                selectedLevel: _selectedLevel,
                managedVideos: _managedVideoItems,
                onChanged: _handleLiveFieldUpdates,
                onMediaSourceTypeChanged: (value) =>
                    setState(() => mediaSourceType = value),
                onPickFromDevice: _pickVideosFromDevice,
                onRecordVideo: _recordNewVideo,
                onRemoveVideo: _removeManagedVideo,
                mediaActionsEnabled: !_isSaving,
              ),
              const SizedBox(height: 18),
              AddCourseOutcomesRequirementsForm(
                outcomesController: _outcomesController,
                requirementsController: _requirementsController,
              ),
              const SizedBox(height: 18),
              AddCoursePricingVisibilitySection(
                isPublished: _isPublished,
                isFree: _isFree,
                priceController: _priceController,
                onPublishedChanged: (value) =>
                    setState(() => _isPublished = value),
                onFreeChanged: (value) => setState(() => _isFree = value),
              ),
              const SizedBox(height: 20),
              AddCourseStudentPreview(
                title: _titleController.text.trim(),
                description: _descriptionController.text.trim(),
                selectedCategory: _selectedCategory,
                selectedLevel: _selectedLevel,
                isPublished: _isPublished,
                isFree: _isFree,
                price: _priceController.text.trim(),
                mediaSourceType: mediaSourceType,
                playlistId: _playlistId,
                uploadedVideoCount: _managedVideoItems.length,
                tags: _parseList(_tagsController.text),
              ),
              const SizedBox(height: 24),
              EduPrimaryButton(
                label: _isEditing ? 'Update Course' : 'Publish Course',
                onPressed: _isSaving ? null : _save,
                isLoading: _isSaving,
              ),
              const SizedBox(height: 10),
              Text(
                _isPublished
                    ? 'Published courses appear automatically in the student experience, search, and recommendations.'
                    : 'Draft courses stay in your instructor library until you publish them.',
                style: TextStyle(
                  fontSize: 11,
                  height: 1.55,
                  fontWeight: FontWeight.w700,
                  color: secondaryText,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (widget.embedded) {
      return page;
    }

    return PopScope<void>(
      canPop: !_isSaving && !_hasUnsavedChanges,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop || _isSaving) {
          return;
        }
        final shouldLeave = await _confirmExit();
        if (!mounted || !shouldLeave) {
          return;
        }
        Navigator.of(context).pop();
      },
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          leading: IconButton(
            onPressed: _isSaving ? null : _handleBack,
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          title: Text(_isEditing ? 'Edit Course' : 'Add Course'),
        ),
        body: page,
      ),
    );
  }
}
