import 'package:flutter/material.dart';

import '../../../../core/utils/app_error_mapper.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/services/firestore_service.dart';

/// Follow Button
class InstructorFollowButton extends StatefulWidget {
  const InstructorFollowButton({
    super.key,
    required this.isFollowing,
    required this.isLoading,
    required this.instructorName,
    required this.instructorId,
    required this.currentUserId,
    required this.currentUserName,
    required this.onFollowStateChanged,
  });

  final bool isFollowing;
  final bool isLoading;
  final String instructorName;
  final String instructorId;
  final String currentUserId;
  final String currentUserName;
  final Function(bool) onFollowStateChanged;

  @override
  State<InstructorFollowButton> createState() => _InstructorFollowButtonState();
}

class _InstructorFollowButtonState extends State<InstructorFollowButton> {
  bool _isProcessing = false;

  Future<void> _handleFollowTap() async {
    if (_isProcessing || widget.currentUserId.isEmpty) return;

    setState(() => _isProcessing = true);

    try {
      if (widget.isFollowing) {
        // Unfollow
        await FirestoreService.instance.unfollowInstructor(
          currentUserId: widget.currentUserId,
          instructorId: widget.instructorId,
        );
        widget.onFollowStateChanged(false);
      } else {
        // Follow
        await FirestoreService.instance.followInstructor(
          currentUserId: widget.currentUserId,
          instructorId: widget.instructorId,
          followerName: widget.currentUserName,
        );
        widget.onFollowStateChanged(true);
        _showFollowSnackBar();
      }
    } catch (error) {
      if (mounted) {
        final message = AppErrorMapper.data(
          error,
          fallback: 'Could not update follow status. Please try again.',
        );
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  void _showFollowSnackBar() {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Following ${widget.instructorName}'),
        backgroundColor: const Color(AppColors.primary),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = _isProcessing || widget.isLoading;

    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: widget.isFollowing
            ? const Color(AppColors.primary)
            : const Color(AppColors.chip),
        borderRadius: BorderRadius.circular(22),
        border: widget.isFollowing
            ? null
            : Border.all(color: const Color(0xFFCFD9EA)),
        boxShadow: widget.isFollowing
            ? [
                BoxShadow(
                  color: const Color(AppColors.primary).withValues(alpha: 0.25),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: isLoading ? null : _handleFollowTap,
          child: Center(
            child: isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(
                    widget.isFollowing ? 'Following' : 'Follow',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      color: widget.isFollowing
                          ? Colors.white
                          : const Color(AppColors.dark),
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
