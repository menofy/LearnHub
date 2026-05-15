import 'dart:convert';
import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:learnhub/core/shared_widgets/content_loading_skeleton.dart';
import 'package:learnhub/core/shared_widgets/edu_primary_button.dart';
import 'package:learnhub/features/instructor/widgets/profile_action_row.dart';
import 'package:learnhub/features/instructor/widgets/profile_hero_card.dart';
import 'package:learnhub/features/profile/widgets/followers_list_bottom_sheet.dart';
import 'package:learnhub/features/shared/auth/providers/auth_provider.dart';
import 'package:learnhub/features/shared/providers/app_state_provider.dart';
import 'package:provider/provider.dart';

import 'package:learnhub/core/navigation/app_routes.dart';
import '../../../data/services/firestore_service.dart';
import '../../../domain/entities/app_user.dart';
import '../../../domain/entities/course.dart';
import 'instructor_shared.dart';

class InstructorProfileScreen extends StatefulWidget {
  const InstructorProfileScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<InstructorProfileScreen> createState() =>
      _InstructorProfileScreenState();
}

class _InstructorProfileScreenState extends State<InstructorProfileScreen> {
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final appState = context.watch<AppStateProvider>();
    final user = auth.currentUser;
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
        appBar: AppBar(title: const Text('Instructor Profile')),
        body: Center(
          child: Text(
            'This section is available for instructors only.',
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
      child: StreamBuilder<List<Course>>(
        stream: FirestoreService.instance.streamInstructorCourses(user.id),
        builder: (context, snapshot) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 110),
            children: [
              Text(
                'Instructor Profile',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: titleColor,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Keep your teaching identity polished and easy to trust.',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: secondaryText,
                ),
              ),
              const SizedBox(height: 18),
              InstructorProfileHeroCard(
                user: user,
                avatarWidget: _buildInstructorAvatar(user),
                onFollowersTap: () => _showFollowersDialog(context, user.id),
              ),
              const SizedBox(height: 18),
              const InstructorSectionHeader(
                title: 'Workspace Settings',
                subtitle: 'Tools your instructor account will actually use.',
              ),
              const SizedBox(height: 12),
              InstructorSurfaceCard(
                child: Column(
                  children: [
                    ProfileActionRow(
                      icon: Icons.edit_outlined,
                      title: 'Edit profile',
                      subtitle: 'Update your visible name and basic details.',
                      onTap: () => Navigator.of(
                        context,
                      ).pushNamed(AppRoutes.editProfile),
                    ),
                    ProfileActionRow(
                      icon: Icons.language_rounded,
                      title: 'Language',
                      subtitle: appState.language == 'Arabic'
                          ? 'Arabic'
                          : 'English (US)',
                      onTap: () => Navigator.of(
                        context,
                      ).pushNamed(AppRoutes.languageSettings),
                    ),
                    ProfileActionRow(
                      icon: Icons.lock_outline_rounded,
                      title: 'Security',
                      subtitle: 'Manage password and account access.',
                      onTap: () => Navigator.of(
                        context,
                      ).pushNamed(AppRoutes.changePassword),
                    ),
                    ProfileActionRow(
                      icon: Icons.description_outlined,
                      title: 'Terms & Conditions',
                      subtitle:
                          'Review policies before publishing more courses.',
                      onTap: () =>
                          Navigator.of(context).pushNamed(AppRoutes.terms),
                    ),
                    ProfileActionRow(
                      icon: Icons.dark_mode_outlined,
                      title: 'Theme mode',
                      subtitle: appState.themeMode == ThemeMode.dark
                          ? 'Dark mode enabled'
                          : 'Light mode enabled',
                      onTap: () {
                        final next = appState.themeMode == ThemeMode.dark
                            ? ThemeMode.light
                            : ThemeMode.dark;
                        appState.setThemeMode(next);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              InstructorSurfaceCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Account Snapshot',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: titleColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Role: ${user.role.value}\nUID: ${user.id}',
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.7,
                        fontWeight: FontWeight.w700,
                        color: secondaryText,
                      ),
                    ),
                    const SizedBox(height: 16),
                    EduPrimaryButton(
                      label: auth.isLoading ? 'Signing Out...' : 'Logout',
                      onPressed: auth.isLoading
                          ? null
                          : () => context.read<AuthProvider>().logout(),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );

    if (widget.embedded) {
      return page;
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(title: const Text('Instructor Profile')),
      body: page,
    );
  }

  void _showFollowersDialog(BuildContext context, String instructorId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return FollowersListBottomSheet(
          instructorId: instructorId,
          followersFetcher:
              FirestoreService.instance.getFollowersListWithDetails,
          title: 'My Followers',
          useThemedColors: true,
        );
      },
    );
  }

  Widget _buildInstructorAvatar(AppUser user) {
    final bytes = _decodeDataUrl(user.photoUrl);
    if (bytes != null) {
      return Image.memory(bytes, fit: BoxFit.cover);
    }
    final photo = user.photoUrl.trim();
    if (photo.startsWith('http://') || photo.startsWith('https://')) {
      return CachedNetworkImage(
        imageUrl: photo,
        fit: BoxFit.cover,
        fadeInDuration: const Duration(milliseconds: 120),
        placeholder: (context, url) => _avatarInitial(user.name),
        errorWidget: (context, url, error) {
          return _avatarInitial(user.name);
        },
      );
    }
    return _avatarInitial(user.name);
  }

  Widget _avatarInitial(String name) {
    final initial = name.trim().isEmpty ? 'I' : name.trim()[0].toUpperCase();
    return Center(
      child: Text(
        initial,
        style: const TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w900,
          color: Colors.white,
        ),
      ),
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
}
