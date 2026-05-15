import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:learnhub/core/utils/app_error_mapper.dart';
import 'package:learnhub/data/services/firestore_service.dart';
import 'package:learnhub/domain/entities/instructor.dart';
import 'package:learnhub/features/shared/auth/providers/auth_provider.dart';
import 'package:provider/provider.dart';

const double _kTopMentorsStripHeight = 286;
const double _kTopMentorsEmptyHeight = 252;

class HomeTopMentorsStrip extends StatefulWidget {
  const HomeTopMentorsStrip({
    super.key,
    required this.mentors,
    required this.secondaryTextColor,
    required this.onTap,
  });

  final List<Instructor> mentors;
  final Color secondaryTextColor;
  final ValueChanged<Instructor> onTap;

  @override
  State<HomeTopMentorsStrip> createState() => _HomeTopMentorsStripState();
}

class _HomeTopMentorsStripState extends State<HomeTopMentorsStrip> {
  final Map<String, bool> _followStates = <String, bool>{};
  final Map<String, int> _followerCounts = <String, int>{};
  final Set<String> _pendingFollowIds = <String>{};
  final Set<String> _loadingFollowerIds = <String>{};
  String? _syncedUserId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncFollowStates();
      _syncFollowerCounts();
    });
  }

  @override
  void didUpdateWidget(covariant HomeTopMentorsStrip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_sameMentorIds(oldWidget.mentors, widget.mentors)) {
      _syncFollowStates();
      _syncFollowerCounts(resetMissingMentors: true);
    }
  }

  Future<void> _syncFollowerCounts({bool resetMissingMentors = false}) async {
    final mentorIds = widget.mentors
        .map((mentor) => mentor.id.trim())
        .where((id) => id.isNotEmpty)
        .toSet();

    if (resetMissingMentors && mounted) {
      setState(() {
        _followerCounts.removeWhere((key, value) => !mentorIds.contains(key));
        _loadingFollowerIds.removeWhere((id) => !mentorIds.contains(id));
      });
    }

    final mentorsToResolve = widget.mentors
        .where((mentor) => mentor.id.trim().isNotEmpty)
        .where(
          (mentor) =>
              !_followerCounts.containsKey(mentor.id) &&
              !_loadingFollowerIds.contains(mentor.id),
        )
        .toList(growable: false);
    if (mentorsToResolve.isEmpty) {
      return;
    }

    if (mounted) {
      setState(() {
        for (final mentor in mentorsToResolve) {
          _loadingFollowerIds.add(mentor.id);
        }
      });
    }

    try {
      final counts = await Future.wait<int>(
        mentorsToResolve.map(
          (mentor) => FirestoreService.instance.getFollowersCount(mentor.id),
        ),
      );

      if (!mounted) {
        return;
      }

      setState(() {
        for (var index = 0; index < mentorsToResolve.length; index++) {
          _followerCounts[mentorsToResolve[index].id] = counts[index];
          _loadingFollowerIds.remove(mentorsToResolve[index].id);
        }
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        for (final mentor in mentorsToResolve) {
          _followerCounts.putIfAbsent(mentor.id, () => 0);
          _loadingFollowerIds.remove(mentor.id);
        }
      });
    }
  }

  Future<void> _syncFollowStates() async {
    final currentUser = context.read<AuthProvider>().currentUser;
    if (currentUser == null) {
      if (!mounted) {
        return;
      }
      setState(() {
        _syncedUserId = null;
        _followStates.clear();
        _pendingFollowIds.clear();
      });
      return;
    }

    final didUserChange = _syncedUserId != null && _syncedUserId != currentUser.id;
    if (didUserChange) {
      _followStates.clear();
      _pendingFollowIds.clear();
    }
    _syncedUserId = currentUser.id;
    final mentorsToResolve = widget.mentors
        .where((mentor) => mentor.id != currentUser.id)
        .where((mentor) => !_followStates.containsKey(mentor.id))
        .toList(growable: false);
    if (mentorsToResolve.isEmpty) {
      return;
    }

    try {
      final resolvedStates = await Future.wait<bool>(
        mentorsToResolve.map((mentor) {
          return FirestoreService.instance.isFollowingInstructor(
            currentUserId: currentUser.id,
            instructorId: mentor.id,
          );
        }),
      );

      if (!mounted || _syncedUserId != currentUser.id) {
        return;
      }

      setState(() {
        for (var index = 0; index < mentorsToResolve.length; index++) {
          _followStates[mentorsToResolve[index].id] = resolvedStates[index];
        }
      });
    } catch (_) {
      if (!mounted || _syncedUserId != currentUser.id) {
        return;
      }

      setState(() {
        for (final mentor in mentorsToResolve) {
          _followStates.putIfAbsent(mentor.id, () => false);
        }
      });
    }
  }

  Future<void> _toggleFollow(Instructor mentor) async {
    final currentUser = context.read<AuthProvider>().currentUser;
    if (currentUser == null) {
      _showSnackBar('Login to follow mentors.');
      return;
    }
    if (currentUser.id == mentor.id || _pendingFollowIds.contains(mentor.id)) {
      return;
    }

    final isFollowing = _followStates[mentor.id] ?? false;
    setState(() {
      _pendingFollowIds.add(mentor.id);
    });

    try {
      if (isFollowing) {
        await FirestoreService.instance.unfollowInstructor(
          currentUserId: currentUser.id,
          instructorId: mentor.id,
        );
      } else {
        await FirestoreService.instance.followInstructor(
          currentUserId: currentUser.id,
          instructorId: mentor.id,
          followerName: currentUser.name,
        );
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _followStates[mentor.id] = !isFollowing;
        final previousCount = _followerCounts[mentor.id] ?? 0;
        _followerCounts[mentor.id] = isFollowing
            ? (previousCount > 0 ? previousCount - 1 : 0)
            : previousCount + 1;
      });
    } catch (error) {
      _showSnackBar(
        AppErrorMapper.data(
          error,
          fallback: 'Could not update follow status. Please try again.',
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _pendingFollowIds.remove(mentor.id);
        });
      }
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = context.select<AuthProvider, String?>(
      (authProvider) => authProvider.currentUser?.id,
    );
    if (_syncedUserId != currentUserId) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _syncFollowStates();
      });
    }

    if (widget.mentors.isEmpty) {
      return SizedBox(
        height: _kTopMentorsEmptyHeight,
        child: Center(
          child: Text(
            'No mentor profiles ready yet.',
            style: TextStyle(color: widget.secondaryTextColor, fontSize: 12),
          ),
        ),
      );
    }

    return SizedBox(
      height: _kTopMentorsStripHeight,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: widget.mentors.length,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final mentor = widget.mentors[index];
          final isOwnProfile = mentor.id == currentUserId;
          return _TopMentorCard(
            rank: index + 1,
            mentor: mentor,
            followersCount: _followerCounts[mentor.id] ?? 0,
            isLoadingFollowers: _loadingFollowerIds.contains(mentor.id),
            isFollowing: isOwnProfile
                ? true
                : (_followStates[mentor.id] ?? false),
            isOwnProfile: isOwnProfile,
            isBusy: _pendingFollowIds.contains(mentor.id),
            onTap: () => widget.onTap(mentor),
            onFollowTap: () => _toggleFollow(mentor),
          );
        },
      ),
    );
  }

  bool _sameMentorIds(List<Instructor> a, List<Instructor> b) {
    if (a.length != b.length) {
      return false;
    }
    for (var index = 0; index < a.length; index++) {
      if (a[index].id != b[index].id) {
        return false;
      }
    }
    return true;
  }
}

class _TopMentorCard extends StatelessWidget {
  const _TopMentorCard({
    required this.rank,
    required this.mentor,
    required this.followersCount,
    required this.isLoadingFollowers,
    required this.isFollowing,
    required this.isOwnProfile,
    required this.isBusy,
    required this.onTap,
    required this.onFollowTap,
  });

  final int rank;
  final Instructor mentor;
  final int followersCount;
  final bool isLoadingFollowers;
  final bool isFollowing;
  final bool isOwnProfile;
  final bool isBusy;
  final VoidCallback onTap;
  final VoidCallback onFollowTap;

  @override
  Widget build(BuildContext context) {
    final accentColor = _mentorAccent(rank - 1);
    final subtitleColor = const Color(0xFF7EA0C6);

    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: Ink(
        width: 164,
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: BoxDecoration(
          color: const Color(0xFF111A27),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFF22334A)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x22000000),
              blurRadius: 18,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF152433),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '#$rank',
                  style: const TextStyle(
                    color: Color(0xFF1DD6C5),
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            _MentorAvatar(
              name: mentor.name,
              imageUrl: mentor.avatarUrl,
              accentColor: accentColor,
              size: 70,
            ),
            const SizedBox(height: 12),
            Text(
              _displayName(mentor.name),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              _displayTitle(mentor.title),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: subtitleColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _MentorStat(
                    value: '${mentor.rating.toStringAsFixed(1)}★',
                    label: 'Rating',
                  ),
                ),
                Expanded(
                  child: _MentorStat(
                    value: isLoadingFollowers
                        ? '...'
                        : _formatCompactCount(followersCount),
                    label: 'Followers',
                  ),
                ),
              ],
            ),
            const Spacer(),
            _FollowButton(
              label: isOwnProfile
                  ? 'Profile'
                  : (isFollowing ? 'Following' : 'Follow'),
              isBusy: isBusy,
              isActive: isFollowing,
              onTap: isOwnProfile ? onTap : onFollowTap,
            ),
          ],
        ),
      ),
    );
  }

  static String _displayName(String rawName) {
    final trimmed = rawName.trim();
    if (trimmed.isEmpty) {
      return 'Instructor';
    }
    return trimmed;
  }

  static String _displayTitle(String rawTitle) {
    final trimmed = rawTitle.trim();
    if (trimmed.isEmpty) {
      return 'Course Instructor';
    }
    return trimmed;
  }
}

class _MentorStat extends StatelessWidget {
  const _MentorStat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Color(0xFF7EA0C6),
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _FollowButton extends StatelessWidget {
  const _FollowButton({
    required this.label,
    required this.isBusy,
    required this.isActive,
    required this.onTap,
  });

  final String label;
  final bool isBusy;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 40,
      child: OutlinedButton(
        onPressed: isBusy ? null : onTap,
        style: OutlinedButton.styleFrom(
          backgroundColor: isActive
              ? const Color(0xFF17314B)
              : const Color(0xFF152231),
          side: BorderSide(
            color: isActive
                ? const Color(0xFF1DD6C5)
                : const Color(0xFF42556E),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          foregroundColor: Colors.white,
          padding: EdgeInsets.zero,
        ),
        child: isBusy
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
      ),
    );
  }
}

class _MentorAvatar extends StatelessWidget {
  const _MentorAvatar({
    required this.name,
    required this.imageUrl,
    required this.accentColor,
    required this.size,
  });

  final String name;
  final String imageUrl;
  final Color accentColor;
  final double size;

  String get _initial {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      return 'I';
    }
    return trimmed[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final trimmedImageUrl = imageUrl.trim();
    if (trimmedImageUrl.isEmpty) {
      return _fallbackAvatar();
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
            errorBuilder: (context, error, stackTrace) => _fallbackAvatar(),
          ),
        ),
      );
    }

    return ClipOval(
      child: SizedBox(
        width: size,
        height: size,
        child: Image.network(
          trimmedImageUrl,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _fallbackAvatar(),
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) {
              return child;
            }
            return _fallbackAvatar();
          },
        ),
      ),
    );
  }

  Widget _fallbackAvatar() {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: accentColor,
      ),
      alignment: Alignment.center,
      child: Text(
        _initial,
        style: TextStyle(
          color: Colors.white,
          fontSize: size * 0.42,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

Color _mentorAccent(int index) {
  const palette = <Color>[
    Color(0xFF244B7B),
    Color(0xFF4C2667),
    Color(0xFF214C31),
    Color(0xFF6A471F),
    Color(0xFF324F78),
    Color(0xFF54335F),
  ];
  return palette[index % palette.length];
}

String _formatCompactCount(int value) {
  if (value >= 1000000) {
    final compact = (value / 1000000).toStringAsFixed(value % 1000000 == 0 ? 0 : 1);
    return '${compact.replaceAll('.0', '')}m';
  }
  if (value >= 1000) {
    final compact = (value / 1000).toStringAsFixed(value % 1000 == 0 ? 0 : 1);
    return '${compact.replaceAll('.0', '')}k';
  }
  return value.toString();
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
