import 'package:flutter/foundation.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:ui' as ui;
import '../../domain/entities/certificate.dart';

class QRCodeGenerator {
  /// Generate QR code data for certificate verification
  /// Returns a JSON string that can be embedded in QR code
  static String generateQRData(Certificate certificate) {
    // Create a verification string with certificate details
    return 'https://learnhub.app/verify?cert=${certificate.id}&student=${certificate.studentId}&course=${certificate.courseId}';
  }

  /// Generate QR code image as base64 string
  static Future<String> generateQRCodeBase64(Certificate certificate) async {
    final qrData = generateQRData(certificate);
    
    try {
      // Create a QR code painter
      final qrPainter = QrPainter(
        data: qrData,
        version: QrVersions.auto,
        gapless: true,
      );

      // Create an image
      final image = await _captureImage(qrPainter);
      if (image == null) return '';

      // Convert to bytes
      final pngBytes = await image.toByteData(format: ui.ImageByteFormat.png);
      if (pngBytes == null) return '';

      // Convert to base64
      return _bytesToBase64(Uint8List.fromList(pngBytes.buffer.asUint8List()));
    } catch (e) {
      debugPrint('Error generating QR code: $e');
      return '';
    }
  }

  static Future<ui.Image?> _captureImage(QrPainter painter) async {
    try {
      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);
      final size = const ui.Size(200, 200);

      painter.paint(canvas, size);
      final picture = recorder.endRecording();
      return await picture.toImage(
        200,
        200,
      );
    } catch (e) {
      debugPrint('Error capturing QR code image: $e');
      return null;
    }
  }

  static String _bytesToBase64(Uint8List bytes) {
    const chars =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
    
    StringBuffer result = StringBuffer();
    int i = 0;

    while (i < bytes.length) {
      int a = bytes[i];
      int b = (i + 1 < bytes.length) ? bytes[i + 1] : 0;
      int c = (i + 2 < bytes.length) ? bytes[i + 2] : 0;

      int bitmap = (a << 16) | (b << 8) | c;

      result.write(chars[(bitmap >> 18) & 63]);
      result.write(chars[(bitmap >> 12) & 63]);
      result.write((i + 1 < bytes.length) ? chars[(bitmap >> 6) & 63] : '=');
      result.write((i + 2 < bytes.length) ? chars[bitmap & 63] : '=');

      i += 3;
    }

    return result.toString();
  }

  /// Verify certificate from QR code data
  static Map<String, String>? verifyQRData(String qrData) {
    try {
      final uri = Uri.parse(qrData);
      if (!uri.path.contains('verify')) return null;

      return {
        'certificateId': uri.queryParameters['cert'] ?? '',
        'studentId': uri.queryParameters['student'] ?? '',
        'courseId': uri.queryParameters['course'] ?? '',
      };
    } catch (e) {
      debugPrint('Error verifying QR data: $e');
      return null;
    }
  }
}
