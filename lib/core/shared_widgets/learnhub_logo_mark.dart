import 'package:flutter/material.dart';

class LearnHubLogoMark extends StatelessWidget {
  const LearnHubLogoMark({
    super.key,
    this.size = 78,
    this.showText = true,
    this.textColor = const Color(0xFFDCE5E6),
  });

  final double size;
  final bool showText;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    final squareSize = size * 0.44;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Transform.rotate(
            angle: 0.785398,
            child: Container(
              width: squareSize,
              height: squareSize,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFF18C6BC), width: 2),
              ),
            ),
          ),
          if (showText)
            Text(
              'LearnHub',
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.w900,
                fontSize: size * 0.18,
                shadows: [
                  Shadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 2,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
