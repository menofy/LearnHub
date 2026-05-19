import 'package:flutter/foundation.dart';
import 'package:share_plus/share_plus.dart';
import '../../domain/entities/certificate.dart';

class CertificateSharingService {
  /// Share certificate via system share dialog
  static Future<void> shareCertificate(
    Certificate certificate, {
    required String pdfPath,
  }) async {
    try {
      final message = '''
🎓 I just completed the "${certificate.courseName}" course on LearnHub Academy!

Instructor: ${certificate.instructorName}
Completion Date: ${_formatDate(certificate.issuedDate)}
Completion Percentage: ${certificate.completionPercentage.toInt()}%

Check out LearnHub Academy to start learning today! 📚
      ''';

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(pdfPath)],
          text: message,
          subject: 'LearnHub Academy - Certificate of Completion',
        ),
      );
    } catch (e) {
      debugPrint('Error sharing certificate: $e');
      rethrow;
    }
  }

  /// Share certificate link to social media (WhatsApp)
  static Future<void> shareToWhatsApp(Certificate certificate) async {
    try {
      final message = '''
🎓 I just completed the "${certificate.courseName}" course on LearnHub Academy!

Instructor: ${certificate.instructorName}
Completion Date: ${_formatDate(certificate.issuedDate)}
Completion Percentage: ${certificate.completionPercentage.toInt()}%

#LearnHubAcademy #Learning #Certificate #CourseCompletion
      ''';

      await SharePlus.instance.share(ShareParams(text: message));
    } catch (e) {
      debugPrint('Error sharing to WhatsApp: $e');
      rethrow;
    }
  }

  /// Share certificate link to social media (Twitter/X)
  static Future<void> shareToTwitter(Certificate certificate) async {
    try {
      final message = '''
🎓 Just completed "${certificate.courseName}" on @LearnHubAcademy!

Instructor: ${certificate.instructorName}
Completion: ${_formatDate(certificate.issuedDate)}
Progress: ${certificate.completionPercentage.toInt()}%

Join me in learning! #LearnHub #Education #Learning
      ''';

      await SharePlus.instance.share(ShareParams(text: message));
    } catch (e) {
      debugPrint('Error sharing to Twitter: $e');
      rethrow;
    }
  }

  /// Share certificate link to social media (Facebook)
  static Future<void> shareToFacebook(
    Certificate certificate, {
    required String certificateUrl,
  }) async {
    try {
      final message = '''
🎓 I just completed the "${certificate.courseName}" course on LearnHub Academy!

Instructor: ${certificate.instructorName}
Completion Date: ${_formatDate(certificate.issuedDate)}
      ''';

      await SharePlus.instance.share(
        ShareParams(
          text: '$message\n\n$certificateUrl',
        ),
      );
    } catch (e) {
      debugPrint('Error sharing to Facebook: $e');
      rethrow;
    }
  }

  /// Share certificate link to email
  static Future<void> shareViaEmail(
    Certificate certificate, {
    required String recipientEmail,
  }) async {
    try {
      final subject = 'Certificate of Completion - ${certificate.courseName}';
      final message = '''
Hi,

I'm sharing my certificate of completion for the "${certificate.courseName}" course from LearnHub Academy.

Course Details:
- Instructor: ${certificate.instructorName}
- Completion Date: ${_formatDate(certificate.issuedDate)}
- Completion Percentage: ${certificate.completionPercentage.toInt()}%

You can also download the PDF version of my certificate from the attachment.

Best regards!
      ''';

      await SharePlus.instance.share(
        ShareParams(
          subject: subject,
          text: 'To: $recipientEmail\n\n$message',
        ),
      );
    } catch (e) {
      debugPrint('Error sharing via email: $e');
      rethrow;
    }
  }

  static String _formatDate(DateTime date) {
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}
