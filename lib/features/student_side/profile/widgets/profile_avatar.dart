import 'dart:convert';
import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../domain/entities/app_user.dart';

class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({
    super.key,
    required this.user,
    this.textColor = Colors.white,
    this.iconColor = Colors.white,
    this.fontSize = 28,
    this.iconSize = 28,
  });

  final AppUser user;
  final Color textColor;
  final Color iconColor;
  final double fontSize;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
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
        errorWidget: (context, url, error) {
          return Icon(Icons.person_rounded, color: iconColor, size: iconSize);
        },
        placeholder: (context, url) {
          return Icon(Icons.person_rounded, color: iconColor, size: iconSize);
        },
      );
    }

    if (user.name.trim().isNotEmpty) {
      return Center(
        child: Text(
          user.name.trim()[0].toUpperCase(),
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w900,
            color: textColor,
          ),
        ),
      );
    }

    return Icon(Icons.person_rounded, color: iconColor, size: iconSize);
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
