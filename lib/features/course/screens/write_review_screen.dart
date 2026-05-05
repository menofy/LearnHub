import 'package:flutter/material.dart';
import 'package:learnhub/core/shared_widgets/edu_primary_button.dart';
import 'package:learnhub/features/course/providers/course_provider.dart';
import 'package:learnhub/features/shared/auth/providers/auth_provider.dart';
import 'package:provider/provider.dart';

import 'package:learnhub/core/theme/app_colors.dart';
import '../../../domain/entities/course.dart';

class WriteReviewScreen extends StatefulWidget {
  const WriteReviewScreen({super.key, required this.course});

  final Course course;

  @override
  State<WriteReviewScreen> createState() => _WriteReviewScreenState();
}

class _WriteReviewScreenState extends State<WriteReviewScreen> {
  final TextEditingController _reviewController = TextEditingController();
  double _rating = 4.5;

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  Future<void> _submitReview() async {
    final text = _reviewController.text.trim();
    if (text.isEmpty) {
      return;
    }
    final userName =
        context.read<AuthProvider>().currentUser?.name ?? 'Student';
    await context.read<CourseProvider>().addCourseReview(
      courseId: widget.course.id,
      userName: userName,
      comment: text,
      rating: _rating,
    );
    if (!mounted) {
      return;
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
                  const Text(
                    'Write a Reviews',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: Color(AppColors.dark),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 68,
                      height: 68,
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.course.category,
                            style: const TextStyle(
                              color: Color(0xFFFF8A00),
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.course.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: Color(AppColors.dark),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Add Photo (or) Video',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Color(AppColors.dark),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                height: 98,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.cloud_upload_rounded,
                      size: 40,
                      color: Color(AppColors.primary),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Click here to Upload',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(AppColors.muted),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Write you Review',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Color(AppColors.dark),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _reviewController,
                maxLines: 5,
                decoration: const InputDecoration(
                  hintText:
                      'Would you like to write anything about this Product?',
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Text(
                    'Rating',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Slider(
                      value: _rating,
                      min: 1,
                      max: 5,
                      divisions: 8,
                      label: _rating.toStringAsFixed(1),
                      onChanged: (value) => setState(() => _rating = value),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              EduPrimaryButton(
                label: 'Submit Review',
                onPressed: _submitReview,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
