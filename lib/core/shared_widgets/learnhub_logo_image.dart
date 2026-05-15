import 'package:flutter/material.dart';

class LearnHubLogoImage extends StatelessWidget {
  const LearnHubLogoImage({
    super.key,
    this.size = 120,
  });

  final double size;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/icon/Logo_final.jpeg',
      width: size,
      height: size,
      fit: BoxFit.contain,
    );
  }
}
