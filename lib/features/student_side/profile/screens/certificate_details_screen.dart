import 'package:flutter/material.dart';
import 'package:learnhub/domain/entities/certificate.dart';
import 'package:learnhub/features/student_side/profile/screens/certificate_detail_screen.dart';

class CertificateDetailsScreen extends StatelessWidget {
  const CertificateDetailsScreen({super.key, required this.certificate});

  final Certificate certificate;

  @override
  Widget build(BuildContext context) {
    if (certificate.completionPercentage < 100) {
      return Scaffold(
        appBar: AppBar(title: const Text('Certificate')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Complete the course 100% to view and download your certificate.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
        ),
      );
    }

    return CertificateDetailScreen(certificate: certificate);
  }
}
