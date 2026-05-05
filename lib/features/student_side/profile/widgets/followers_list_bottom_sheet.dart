import 'package:flutter/material.dart';
import 'package:learnhub/core/theme/app_colors.dart';

class FollowersListBottomSheet extends StatefulWidget {
  const FollowersListBottomSheet({
    super.key,
    required this.instructorId,
    required this.followersFetcher,
    this.title = 'المتابعون',
    this.useThemedColors = false,
  });

  final String instructorId;
  final Future<List<Map<String, dynamic>>> Function(String) followersFetcher;
  final String title;
  final bool useThemedColors;

  @override
  State<FollowersListBottomSheet> createState() =>
      _FollowersListBottomSheetState();
}

class _FollowersListBottomSheetState extends State<FollowersListBottomSheet> {
  late Future<List<Map<String, dynamic>>> _followersFuture;

  @override
  void initState() {
    super.initState();
    _followersFuture = widget.followersFetcher(widget.instructorId);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final surfaceColor = widget.useThemedColors
        ? (isDark ? const Color(0xFF1E1E1E) : Colors.white)
        : Colors.white;
    final titleColor = widget.useThemedColors
        ? theme.colorScheme.onSurface
        : const Color(AppColors.dark);
    final secondaryText = widget.useThemedColors
        ? theme.colorScheme.onSurface.withValues(alpha: 0.6)
        : const Color(AppColors.dark).withValues(alpha: 0.6);

    return DraggableScrollableSheet(
      maxChildSize: 0.9,
      initialChildSize: 0.7,
      minChildSize: 0.5,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      widget.title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: titleColor,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
              ),
              const Divider(),
              Expanded(
                child: FutureBuilder<List<Map<String, dynamic>>>(
                  future: _followersFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            const Color(
                              AppColors.primary,
                            ).withValues(alpha: 0.7),
                          ),
                        ),
                      );
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          'حدثت مشكلة عند تحميل البيانات',
                          style: TextStyle(fontSize: 14, color: secondaryText),
                        ),
                      );
                    }

                    final followers = snapshot.data ?? [];

                    if (followers.isEmpty) {
                      return Center(
                        child: Text(
                          'لا يوجد متابعون حتى الآن',
                          style: TextStyle(fontSize: 14, color: secondaryText),
                        ),
                      );
                    }

                    return ListView.builder(
                      controller: scrollController,
                      itemCount: followers.length,
                      itemBuilder: (context, index) {
                        final follower = followers[index];
                        final followerName =
                            follower['followerName'] ?? 'Unknown User';
                        final followedAtMs = follower['followedAtMs'] ?? 0;

                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: const Color(
                              AppColors.primary,
                            ).withValues(alpha: 0.1),
                            child: Text(
                              followerName.isNotEmpty
                                  ? followerName[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                color: Color(AppColors.primary),
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          title: Text(
                            followerName,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: titleColor,
                            ),
                          ),
                          subtitle: followedAtMs > 0
                              ? Text(
                                  'تابع في ${DateTime.fromMillisecondsSinceEpoch(followedAtMs).toString().split('.')[0]}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: secondaryText,
                                  ),
                                )
                              : null,
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
