import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'dart:typed_data';
import '../../domain/entities/certificate.dart';

class PDFCertificateGenerator {
  static Future<List<int>> generateCertificatePdf(
    Certificate certificate, {
    String? qrCodeImageBase64,
  }) async {
    final pdf = pw.Document();

    // Certificate colors
    const accentColor = PdfColor.fromInt(0xFF6366F1);
    const goldColor = PdfColor.fromInt(0xFFD4AF37);
    const darkColor = PdfColor.fromInt(0xFF1F2937);
    const lightColor = PdfColor.fromInt(0xFFF3F4F6);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4.landscape,
        build: (pw.Context context) {
          return pw.Container(
            width: double.infinity,
            height: double.infinity,
            decoration: pw.BoxDecoration(
              border: pw.Border.all(
                color: goldColor,
                width: 3,
              ),
            ),
            child: pw.Stack(
              children: [
                // Background gradient effect
                pw.Container(
                  decoration: pw.BoxDecoration(
                    color: lightColor,
                  ),
                ),

                // Content
                pw.Padding(
                  padding: const pw.EdgeInsets.all(40),
                  child: pw.Column(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      // Header
                      pw.Column(
                        children: [
                          pw.Text(
                            'LEARNHUB ACADEMY',
                            style: pw.TextStyle(
                              fontSize: 28,
                              fontWeight: pw.FontWeight.bold,
                              color: accentColor,
                            ),
                          ),
                          pw.SizedBox(height: 5),
                          pw.Container(
                            width: 200,
                            height: 2,
                            color: goldColor,
                          ),
                          pw.SizedBox(height: 20),
                          pw.Text(
                            'Certificate of Completion',
                            style: pw.TextStyle(
                              fontSize: 24,
                              fontWeight: pw.FontWeight.bold,
                              color: darkColor,
                            ),
                          ),
                        ],
                      ),

                      // Main content
                      pw.Column(
                        children: [
                          pw.Text(
                            'This certificate is proudly presented to',
                            style: pw.TextStyle(
                              fontSize: 14,
                              color: darkColor,
                            ),
                          ),
                          pw.SizedBox(height: 15),
                          pw.Text(
                            certificate.studentName.toUpperCase(),
                            style: pw.TextStyle(
                              fontSize: 32,
                              fontWeight: pw.FontWeight.bold,
                              color: accentColor,
                            ),
                          ),
                          pw.SizedBox(height: 20),
                          pw.Text(
                            'for successfully completing the course',
                            style: pw.TextStyle(
                              fontSize: 14,
                              color: darkColor,
                            ),
                          ),
                          pw.SizedBox(height: 10),
                          pw.Text(
                            certificate.courseName,
                            style: pw.TextStyle(
                              fontSize: 20,
                              fontWeight: pw.FontWeight.bold,
                              color: darkColor,
                            ),
                          ),
                          pw.SizedBox(height: 15),
                          pw.Text(
                            'Instructed by ${certificate.instructorName}',
                            style: pw.TextStyle(
                              fontSize: 12,
                              color: darkColor,
                              fontStyle: pw.FontStyle.italic,
                            ),
                          ),
                        ],
                      ),

                      // Footer with date and QR code
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: pw.CrossAxisAlignment.end,
                        children: [
                          pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text(
                                'Date Issued:',
                                style: pw.TextStyle(
                                  fontSize: 11,
                                  color: darkColor,
                                ),
                              ),
                              pw.Text(
                                _formatDate(certificate.issuedDate),
                                style: pw.TextStyle(
                                  fontSize: 12,
                                  fontWeight: pw.FontWeight.bold,
                                  color: darkColor,
                                ),
                              ),
                            ],
                          ),
                          if (qrCodeImageBase64 != null)
                            pw.Image(
                              pw.MemoryImage(
                                Uint8List.fromList(_base64Decode(qrCodeImageBase64)),
                              ),
                              width: 80,
                              height: 80,
                            ),
                          pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.end,
                            children: [
                              pw.Text(
                                'Certificate ID:',
                                style: pw.TextStyle(
                                  fontSize: 11,
                                  color: darkColor,
                                ),
                              ),
                              pw.Text(
                                certificate.id.substring(0, 8),
                                style: pw.TextStyle(
                                  fontSize: 10,
                                  color: darkColor,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    return pdf.save();
  }

  static String _formatDate(DateTime date) {
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  static List<int> _base64Decode(String input) {
    // Simple base64 decoder
    const String chars =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
    
    final output = <int>[];
    var bits = 0;
    var value = 0;

    for (int i = 0; i < input.length; i++) {
      final index = chars.indexOf(input[i]);
      if (index == -1) continue;
      
      value = (value << 6) | index;
      bits += 6;

      if (bits >= 8) {
        bits -= 8;
        output.add((value >> bits) & 255);
        value &= (1 << bits) - 1;
      }
    }

    return output;
  }
}
