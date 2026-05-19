import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:learnhub/domain/entities/certificate.dart';
import 'package:learnhub/features/shared/auth/providers/auth_provider.dart';
import 'package:learnhub/features/student_side/profile/providers/certificate_provider.dart';
import 'package:provider/provider.dart';

class CertificateDetailScreen extends StatelessWidget {
  final Certificate certificate;

  const CertificateDetailScreen({super.key, required this.certificate});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final authUser = context.watch<AuthProvider>().currentUser;
    final resolvedStudentName = _resolvedStudentName(authUser?.name);
    final resolvedInstructorName = _resolvedInstructorName();
    final shortCertificateId = _shortCertificateId();

    return Scaffold(
      appBar: AppBar(title: const Text('Certificate'), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Certificate Card with Beautiful Design
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [colorScheme.surface, colorScheme.surfaceContainer],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: colorScheme.primary.withValues(alpha: 0.3),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.primary.withValues(alpha: 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Badge Icon
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: colorScheme.primary, width: 2),
                    ),
                    child: Icon(
                      Icons.emoji_events_rounded,
                      size: 40,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Academy Name
                  Text(
                    'LEARNHUB ACADEMY',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Certificate Title
                  Text(
                    'Certificate',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'OF COMPLETION',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.5,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Introduction Text
                  Text(
                    'This certificate is proudly presented to',
                    style: TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      color: colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Student Name
                  Text(
                    resolvedStudentName,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Course Completion Text
                  Text(
                    'for successfully completing with distinction',
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Course Name with Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: colorScheme.primary, width: 2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      certificate.courseName,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: colorScheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Footer Info Row
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'INSTRUCTOR',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1,
                                color: colorScheme.onSurface.withValues(
                                  alpha: 0.5,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              resolvedInstructorName,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: colorScheme.onSurface,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.star_rounded,
                        color: colorScheme.primary,
                        size: 28,
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'ISSUE DATE',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1,
                                color: colorScheme.onSurface.withValues(
                                  alpha: 0.5,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              DateFormat(
                                'MMM dd, yyyy',
                              ).format(certificate.issuedDate),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),

                  // Certificate ID
                  Text(
                    'CERT  2026  $shortCertificateId  LEARNHUB.IO',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.5,
                      color: colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Certificate Info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Certificate Details',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildDetailRow(
                    'Course',
                    certificate.courseName,
                    colorScheme,
                  ),
                  const SizedBox(height: 8),
                  _buildDetailRow(
                    'Instructor',
                    resolvedInstructorName,
                    colorScheme,
                  ),
                  const SizedBox(height: 8),
                  _buildDetailRow(
                    'Completion',
                    '${certificate.completionPercentage.toStringAsFixed(0)}%',
                    colorScheme,
                  ),
                  const SizedBox(height: 8),
                  _buildDetailRow(
                    'Issued Date',
                    DateFormat('dd MMM, yyyy').format(certificate.issuedDate),
                    colorScheme,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => _downloadCertificate(context),
                    icon: const Icon(Icons.download_rounded),
                    label: const Text('Download'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _shareCertificate(context),
                    icon: const Icon(Icons.share_rounded),
                    label: const Text('Share'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, ColorScheme colorScheme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  String _resolvedStudentName(String? fallbackName) {
    final certificateName = certificate.studentName.trim();
    if (certificateName.isNotEmpty) {
      return certificateName;
    }

    final userName = fallbackName?.trim() ?? '';
    if (userName.isNotEmpty) {
      return userName;
    }

    return 'LearnHub Student';
  }

  String _resolvedInstructorName() {
    final instructorName = certificate.instructorName.trim();
    if (instructorName.isNotEmpty && !instructorName.contains('_')) {
      return instructorName;
    }
    return 'LearnHub Instructor';
  }

  String _shortCertificateId() {
    final normalizedId = certificate.id.trim().replaceAll(' ', '');
    if (normalizedId.isEmpty) {
      return 'LEARNHUB';
    }
    return normalizedId.substring(0, math.min(6, normalizedId.length))
        .toUpperCase();
  }

  Future<void> _downloadCertificate(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    messenger
      ..clearSnackBars()
      ..showSnackBar(
        const SnackBar(
          content: Text('Generating certificate PDF...'),
          duration: Duration(seconds: 2),
        ),
      );

    final pdfPath = await context.read<CertificateProvider>().downloadCertificate(
      certificate,
    );
    if (!context.mounted) {
      return;
    }

    messenger
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(
            pdfPath == null
                ? 'Failed to download certificate.'
                : 'Certificate saved to: $pdfPath',
          ),
          duration: const Duration(seconds: 3),
        ),
      );
  }

  Future<void> _shareCertificate(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    messenger
      ..clearSnackBars()
      ..showSnackBar(
        const SnackBar(
          content: Text('Preparing certificate to share...'),
          duration: Duration(seconds: 2),
        ),
      );

    await context.read<CertificateProvider>().shareCertificate(certificate);
    if (!context.mounted) {
      return;
    }

    messenger.clearSnackBars();
  }
}
