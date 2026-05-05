import 'package:flutter/material.dart';
import 'package:learnhub/core/shared_widgets/edu_primary_button.dart';
import 'package:learnhub/core/theme/app_colors.dart';
import 'package:learnhub/domain/entities/certificate.dart';

class CertificateDetailsScreen extends StatelessWidget {
  const CertificateDetailsScreen({super.key, required this.certificate});

  final Certificate certificate;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
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
                    '3D Design Illustration',
                    style: TextStyle(
                      fontSize: 23,
                      fontWeight: FontWeight.w900,
                      color: Color(AppColors.dark),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(13),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        '3D Design Illustration',
                        style: TextStyle(
                          color: Color(AppColors.muted),
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: const Color(AppColors.primary),
                      ),
                      child: const Icon(
                        Icons.search_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(18, 20, 18, 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.workspace_premium_rounded,
                        size: 48,
                        color: Color(0xFF2B59C3),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Certificate of Completions',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          color: Color(AppColors.dark),
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'This Certifies that',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(AppColors.muted),
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Alex',
                        style: TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF2E3CBA),
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Has Successfully Completed the Wallace Training\nProgram, Entitled.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(AppColors.muted),
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        certificate.courseTitle,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: Color(AppColors.dark),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Issued on ${certificate.issueDate.day}/${certificate.issueDate.month}/${certificate.issueDate.year}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(AppColors.muted),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'ID: SK24568086',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(AppColors.dark),
                        ),
                      ),
                      const Spacer(),
                      const Text(
                        'Calvin C Mclginins',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF253055),
                        ),
                      ),
                      const Text(
                        'i.e. My Father....',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(AppColors.muted),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Virginia M. Patterson',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Color(AppColors.dark),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              EduPrimaryButton(
                label: 'Download Certificate',
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Certificate downloaded.')),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
