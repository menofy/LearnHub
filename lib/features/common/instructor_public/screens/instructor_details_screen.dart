import 'package:flutter/material.dart';
import 'package:learnhub/data/services/firestore_service.dart';
import 'package:learnhub/domain/entities/instructor.dart';
import 'package:learnhub/features/common/instructor_public/widgets/instructor_courses_section.dart';
import 'package:learnhub/features/common/instructor_public/widgets/instructor_details_action_row.dart';
import 'package:learnhub/features/common/instructor_public/widgets/instructor_details_header.dart';
import 'package:learnhub/features/common/instructor_public/widgets/instructor_profile_card.dart';
import 'package:learnhub/features/common/instructor_public/widgets/instructor_ratings_section.dart';
import 'package:learnhub/features/common/instructor_public/widgets/instructor_tab_navigation.dart';
import 'package:learnhub/features/profile/widgets/followers_list_bottom_sheet.dart';
import 'package:learnhub/features/shared/auth/providers/auth_provider.dart';
import 'package:provider/provider.dart';

class InstructorDetailsScreen extends StatefulWidget {
  const InstructorDetailsScreen({super.key, required this.instructor});

  final Instructor instructor;

  @override
  State<InstructorDetailsScreen> createState() =>
      _InstructorDetailsScreenState();
}

class _InstructorDetailsScreenState extends State<InstructorDetailsScreen> {
  late int _selectedTabIndex = 0;
  bool _isFollowing = false;
  int _followersCount = 0;
  bool _isLoadingFollowStatus = true;
  bool _isLoadingFollowersCount = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadFollowData();
    });
  }

  Future<void> _loadFollowData() async {
    try {
      final currentUser = context.read<AuthProvider>().currentUser;
      if (currentUser == null) return;

      final results = await Future.wait<Object>([
        FirestoreService.instance.isFollowingInstructor(
          currentUserId: currentUser.id,
          instructorId: widget.instructor.id,
        ),
        FirestoreService.instance.getFollowersCount(widget.instructor.id),
      ]);

      if (mounted) {
        setState(() {
          _isFollowing = results[0] as bool;
          _followersCount = results[1] as int;
          _isLoadingFollowStatus = false;
          _isLoadingFollowersCount = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingFollowStatus = false;
          _isLoadingFollowersCount = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = context.watch<AuthProvider>().currentUser;
    final isOwnProfile = currentUser?.id == widget.instructor.id;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            InstructorDetailsHeader(
              isOwnProfile: isOwnProfile,
              onBack: () => Navigator.of(context).pop(),
              onSettingsTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Settings coming soon')),
                );
              },
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                children: [
                  InstructorProfileCard(
                    instructor: widget.instructor,
                    followersCount: _followersCount,
                    isLoadingFollowersCount: _isLoadingFollowersCount,
                    onShowFollowersList: _showFollowersList,
                  ),
                  const SizedBox(height: 16),
                  InstructorDetailsActionRow(
                    instructor: widget.instructor,
                    currentUser: currentUser,
                    isOwnProfile: isOwnProfile,
                    isFollowing: _isFollowing,
                    isLoadingFollowStatus: _isLoadingFollowStatus,
                    onFollowStateChanged: (newState) {
                      setState(() => _isFollowing = newState);
                      _loadFollowersCount();
                    },
                    onMessageTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Chat with ${widget.instructor.name}'),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 14),
                  InstructorTabNavigation(
                    selectedIndex: _selectedTabIndex,
                    onTabChanged: (index) =>
                        setState(() => _selectedTabIndex = index),
                  ),
                  const SizedBox(height: 12),
                  if (_selectedTabIndex == 0)
                    InstructorCoursesSection(instructorId: widget.instructor.id)
                  else
                    const InstructorRatingsSection(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _loadFollowersCount() async {
    try {
      final count = await FirestoreService.instance.getFollowersCount(
        widget.instructor.id,
      );
      if (mounted) {
        setState(() => _followersCount = count);
      }
    } catch (e) {
      // Silently handle error
    }
  }

  void _showFollowersList() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => FollowersListBottomSheet(
        instructorId: widget.instructor.id,
        followersFetcher: FirestoreService.instance.getFollowersList,
      ),
    );
  }
}
