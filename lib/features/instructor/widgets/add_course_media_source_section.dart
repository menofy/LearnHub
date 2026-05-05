import 'package:flutter/material.dart';
import 'package:learnhub/features/instructor/screens/instructor_shared.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../domain/entities/course.dart';

enum InstructorManagedVideoOrigin { existing, local, recorded }

class InstructorManagedVideoItem {
  const InstructorManagedVideoItem({
    required this.origin,
    required this.storageValue,
    required this.displayName,
    required this.sourceBadgeLabel,
    this.durationLabel,
  });

  final InstructorManagedVideoOrigin origin;
  final String storageValue;
  final String displayName;
  final String sourceBadgeLabel;
  final String? durationLabel;
}

class AddCourseMediaSourceSection extends StatelessWidget {
  const AddCourseMediaSourceSection({
    super.key,
    required this.videoUrlController,
    required this.mediaSourceType,
    required this.sourceLabel,
    required this.playlistId,
    required this.selectedCategory,
    required this.selectedLevel,
    required this.managedVideos,
    required this.onChanged,
    required this.onMediaSourceTypeChanged,
    required this.onPickFromDevice,
    required this.onRecordVideo,
    required this.onRemoveVideo,
    this.mediaActionsEnabled = true,
  });

  final TextEditingController videoUrlController;
  final String mediaSourceType;
  final String sourceLabel;
  final String playlistId;
  final String selectedCategory;
  final String selectedLevel;
  final List<InstructorManagedVideoItem> managedVideos;
  final VoidCallback onChanged;
  final ValueChanged<String> onMediaSourceTypeChanged;
  final VoidCallback onPickFromDevice;
  final VoidCallback onRecordVideo;
  final ValueChanged<InstructorManagedVideoItem> onRemoveVideo;
  final bool mediaActionsEnabled;

  bool get _isLinkSource => mediaSourceType == Course.linkMediaSource;

  @override
  Widget build(BuildContext context) {
    final titleColor = instructorTitleColor(context);
    final secondaryText = instructorMutedColor(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const InstructorSectionHeader(
          title: 'Media Source',
          subtitle:
              'Choose whether this course runs from an external video link or a managed library of uploaded videos.',
        ),
        const SizedBox(height: 12),
        InstructorSurfaceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _MediaSourceSelector(
                selectedValue: mediaSourceType,
                onChanged: onMediaSourceTypeChanged,
              ),
              const SizedBox(height: 16),
              if (_isLinkSource) ...[
                TextFormField(
                  controller: videoUrlController,
                  onChanged: (_) => onChanged(),
                  decoration: instructorInputDecoration(
                    context: context,
                    label: 'Video URL',
                    hint: 'https://www.youtube.com/playlist?list=...',
                    icon: Icons.link_rounded,
                    helperText:
                        'Playlist links create a richer curriculum automatically.',
                  ),
                  validator: (value) {
                    final text = (value ?? '').trim();
                    if (text.isEmpty) {
                      return 'Video URL is required.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                _SourcePreviewCard(
                  titleColor: titleColor,
                  secondaryText: secondaryText,
                  sourceLabel: sourceLabel,
                  playlistId: playlistId,
                  selectedCategory: selectedCategory,
                  selectedLevel: selectedLevel,
                ),
              ] else ...[
                _UploadActionRow(
                  enabled: mediaActionsEnabled,
                  onPickFromDevice: onPickFromDevice,
                  onRecordVideo: onRecordVideo,
                ),
                const SizedBox(height: 12),
                _CloudUploadHint(secondaryText: secondaryText),
                const SizedBox(height: 16),
                _UploadSummaryCard(
                  titleColor: titleColor,
                  secondaryText: secondaryText,
                  sourceLabel: sourceLabel,
                  selectedCategory: selectedCategory,
                  selectedLevel: selectedLevel,
                  totalVideos: managedVideos.length,
                ),
                const SizedBox(height: 16),
                _ManagedVideosList(
                  items: managedVideos,
                  titleColor: titleColor,
                  secondaryText: secondaryText,
                  onRemoveVideo: onRemoveVideo,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _CloudUploadHint extends StatelessWidget {
  const _CloudUploadHint({required this.secondaryText});

  final Color secondaryText;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F7FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD9E4FF)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 1),
            child: Icon(
              Icons.cloud_upload_rounded,
              size: 18,
              color: Color(AppColors.primary),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Selected videos stay on this device until you publish or save. We then upload them securely to cloud hosting and store only hosted HTTPS links for students.',
              style: TextStyle(
                fontSize: 11,
                height: 1.5,
                fontWeight: FontWeight.w700,
                color: secondaryText,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MediaSourceSelector extends StatelessWidget {
  const _MediaSourceSelector({
    required this.selectedValue,
    required this.onChanged,
  });

  final String selectedValue;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: instructorInsetColor(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: instructorBorderColor(context)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _SelectorOption(
              label: 'External Video Link',
              icon: Icons.link_rounded,
              selected: selectedValue == Course.linkMediaSource,
              onTap: () => onChanged(Course.linkMediaSource),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _SelectorOption(
              label: 'Upload Videos',
              icon: Icons.video_library_rounded,
              selected: selectedValue == Course.uploadMediaSource,
              onTap: () => onChanged(Course.uploadMediaSource),
            ),
          ),
        ],
      ),
    );
  }
}

class _SelectorOption extends StatelessWidget {
  const _SelectorOption({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final foregroundColor = selected
        ? Colors.white
        : instructorTitleColor(context);

    return Material(
      color: selected ? const Color(AppColors.primary) : Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            children: [
              Icon(icon, size: 18, color: foregroundColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: foregroundColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SourcePreviewCard extends StatelessWidget {
  const _SourcePreviewCard({
    required this.titleColor,
    required this.secondaryText,
    required this.sourceLabel,
    required this.playlistId,
    required this.selectedCategory,
    required this.selectedLevel,
  });

  final Color titleColor;
  final Color secondaryText;
  final String sourceLabel;
  final String playlistId;
  final String selectedCategory;
  final String selectedLevel;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: instructorInsetColor(context),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.insights_outlined,
                color: Color(AppColors.primary),
              ),
              const SizedBox(width: 8),
              Text(
                'Source Preview',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: titleColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              InstructorPill(
                label: selectedCategory,
                icon: Icons.grid_view_rounded,
              ),
              InstructorPill(
                label: selectedLevel,
                icon: Icons.school_outlined,
                backgroundColor: const Color(0xFFF3ECFF),
                foregroundColor: const Color(0xFF6C47D9),
              ),
              InstructorPill(
                label: sourceLabel,
                icon: Icons.smart_display_outlined,
                backgroundColor: const Color(0xFFEFF2FF),
                foregroundColor: const Color(0xFF4153F4),
              ),
            ],
          ),
          if (playlistId.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Playlist ID: $playlistId',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: secondaryText,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _UploadActionRow extends StatelessWidget {
  const _UploadActionRow({
    required this.enabled,
    required this.onPickFromDevice,
    required this.onRecordVideo,
  });

  final bool enabled;
  final VoidCallback onPickFromDevice;
  final VoidCallback onRecordVideo;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: FilledButton.icon(
            onPressed: enabled ? onPickFromDevice : null,
            icon: const Icon(Icons.folder_open_rounded),
            label: const Text('Choose From Device'),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: enabled ? onRecordVideo : null,
            icon: const Icon(Icons.videocam_rounded),
            label: const Text('Record New Video'),
          ),
        ),
      ],
    );
  }
}

class _UploadSummaryCard extends StatelessWidget {
  const _UploadSummaryCard({
    required this.titleColor,
    required this.secondaryText,
    required this.sourceLabel,
    required this.selectedCategory,
    required this.selectedLevel,
    required this.totalVideos,
  });

  final Color titleColor;
  final Color secondaryText;
  final String sourceLabel;
  final String selectedCategory;
  final String selectedLevel;
  final int totalVideos;

  @override
  Widget build(BuildContext context) {
    final totalLabel = totalVideos == 1 ? '1 video' : '$totalVideos videos';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: instructorInsetColor(context),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.video_collection_rounded,
                color: Color(AppColors.primary),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Smart Media Manager',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: titleColor,
                  ),
                ),
              ),
              Text(
                totalLabel,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  color: secondaryText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              InstructorPill(
                label: selectedCategory,
                icon: Icons.grid_view_rounded,
              ),
              InstructorPill(
                label: selectedLevel,
                icon: Icons.school_outlined,
                backgroundColor: const Color(0xFFF3ECFF),
                foregroundColor: const Color(0xFF6C47D9),
              ),
              InstructorPill(
                label: sourceLabel,
                icon: Icons.video_library_rounded,
                backgroundColor: const Color(0xFFEAF8F7),
                foregroundColor: const Color(AppColors.primary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ManagedVideosList extends StatelessWidget {
  const _ManagedVideosList({
    required this.items,
    required this.titleColor,
    required this.secondaryText,
    required this.onRemoveVideo,
  });

  final List<InstructorManagedVideoItem> items;
  final Color titleColor;
  final Color secondaryText;
  final ValueChanged<InstructorManagedVideoItem> onRemoveVideo;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: instructorInsetColor(context),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.play_lesson_rounded,
                color: Color(AppColors.primary),
              ),
              const SizedBox(width: 8),
              Text(
                'Uploaded Videos',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: titleColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (items.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(AppColors.primary).withValues(alpha: 0.15),
                ),
              ),
              child: Text(
                'No videos selected yet. Add at least one lesson video before you publish.',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: secondaryText,
                ),
              ),
            )
          else
            Column(
              children: items
                  .map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _ManagedVideoTile(
                        item: item,
                        titleColor: titleColor,
                        secondaryText: secondaryText,
                        onRemove: () => onRemoveVideo(item),
                      ),
                    ),
                  )
                  .toList(growable: false),
            ),
        ],
      ),
    );
  }
}

class _ManagedVideoTile extends StatelessWidget {
  const _ManagedVideoTile({
    required this.item,
    required this.titleColor,
    required this.secondaryText,
    required this.onRemove,
  });

  final InstructorManagedVideoItem item;
  final Color titleColor;
  final Color secondaryText;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final badgeColors = _badgeColors(item.origin);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: instructorSurfaceColor(context).withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(AppColors.primary).withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: const Color(AppColors.primary).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.play_circle_fill_rounded,
              color: Color(AppColors.primary),
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: titleColor,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: badgeColors.$1,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        item.sourceBadgeLabel,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: badgeColors.$2,
                        ),
                      ),
                    ),
                    if (item.durationLabel != null &&
                        item.durationLabel!.trim().isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Icon(
                        Icons.schedule_rounded,
                        size: 13,
                        color: secondaryText,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          item.durationLabel!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: secondaryText,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Material(
            color: const Color(0xFFFFF2F0),
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: onRemove,
              child: const Padding(
                padding: EdgeInsets.all(10),
                child: Icon(
                  Icons.delete_outline_rounded,
                  color: Color(AppColors.danger),
                  size: 18,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  (Color, Color) _badgeColors(InstructorManagedVideoOrigin origin) {
    switch (origin) {
      case InstructorManagedVideoOrigin.existing:
        return (const Color(0xFFEFF2FF), const Color(0xFF4153F4));
      case InstructorManagedVideoOrigin.recorded:
        return (const Color(0xFFFFF3E6), const Color(0xFFE37A18));
      case InstructorManagedVideoOrigin.local:
        return (const Color(0xFFEAF8F7), const Color(AppColors.primary));
    }
  }
}
