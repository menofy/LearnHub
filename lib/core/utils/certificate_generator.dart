import 'package:intl/intl.dart';
import 'package:learnhub/domain/entities/certificate.dart';

class CertificateGenerator {
  static String generateCertificateHTML(Certificate certificate) {
    return '''
    <!DOCTYPE html>
    <html dir="ltr">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <style>
            * {
                margin: 0;
                padding: 0;
                box-sizing: border-box;
            }
            
            body {
                font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
                background-color: #f5f5f5;
                padding: 20px;
            }
            
            .certificate-container {
                width: 100%;
                max-width: 900px;
                margin: 0 auto;
                background: linear-gradient(135deg, #1a1a2e 0%, #16213e 100%);
                border: 3px solid #14CCC2;
                border-radius: 20px;
                padding: 60px;
                text-align: center;
                box-shadow: 0 10px 40px rgba(20, 204, 194, 0.2);
                color: #ffffff;
                min-height: 600px;
                display: flex;
                flex-direction: column;
                justify-content: center;
                align-items: center;
            }
            
            .badge {
                width: 80px;
                height: 80px;
                border: 3px solid #14CCC2;
                border-radius: 50%;
                display: flex;
                align-items: center;
                justify-content: center;
                margin: 0 auto 30px;
                font-size: 40px;
            }
            
            .academy-name {
                font-size: 14px;
                font-weight: 700;
                letter-spacing: 2px;
                color: #14CCC2;
                margin-bottom: 12px;
                text-transform: uppercase;
            }
            
            .certificate-title {
                font-size: 48px;
                font-weight: bold;
                margin-bottom: 4px;
                color: #ffffff;
            }
            
            .certificate-subtitle {
                font-size: 12px;
                font-weight: 600;
                letter-spacing: 1.5px;
                color: #14CCC2;
                text-transform: uppercase;
                margin-bottom: 28px;
            }
            
            .introduction {
                font-size: 12px;
                font-style: italic;
                color: rgba(255, 255, 255, 0.7);
                margin-bottom: 12px;
            }
            
            .student-name {
                font-size: 36px;
                font-weight: bold;
                color: #ffffff;
                margin-bottom: 20px;
            }
            
            .course-intro {
                font-size: 12px;
                color: rgba(255, 255, 255, 0.7);
                margin-bottom: 12px;
            }
            
            .course-name {
                border: 2px solid #14CCC2;
                padding: 12px 20px;
                display: inline-block;
                border-radius: 12px;
                font-size: 18px;
                font-weight: 700;
                color: #14CCC2;
                margin-bottom: 40px;
            }
            
            .footer-row {
                display: flex;
                justify-content: space-between;
                align-items: center;
                margin-bottom: 30px;
                font-size: 14px;
            }
            
            .footer-section {
                flex: 1;
            }
            
            .footer-label {
                font-size: 10px;
                font-weight: 600;
                letter-spacing: 1px;
                color: rgba(255, 255, 255, 0.5);
                text-transform: uppercase;
                margin-bottom: 4px;
            }
            
            .footer-value {
                font-size: 12px;
                font-weight: 700;
                color: #ffffff;
                font-style: italic;
            }
            
            .star {
                font-size: 28px;
                color: #14CCC2;
                flex: 1;
            }
            
            .certificate-id {
                font-size: 9px;
                font-weight: 600;
                letter-spacing: 1.5px;
                color: rgba(255, 255, 255, 0.5);
                text-transform: uppercase;
            }
        </style>
    </head>
    <body>
        <div class="certificate-container">
            <div class="badge">🏆</div>
            
            <div class="academy-name">LEARNHUB ACADEMY</div>
            
            <div class="certificate-title">Certificate</div>
            <div class="certificate-subtitle">OF COMPLETION</div>
            
            <div class="introduction">This certificate is proudly presented to</div>
            
            <div class="student-name">${certificate.studentName}</div>
            
            <div class="course-intro">for successfully completing with distinction</div>
            
            <div class="course-name">${certificate.courseName}</div>
            
            <div class="footer-row">
                <div class="footer-section">
                    <div class="footer-label">Instructor</div>
                    <div class="footer-value">${certificate.instructorName}</div>
                </div>
                
                <div class="star">⭐</div>
                
                <div class="footer-section" style="text-align: right;">
                    <div class="footer-label">Issue Date</div>
                    <div class="footer-value">${DateFormat('MMM dd, yyyy').format(certificate.issuedDate)}</div>
                </div>
            </div>
            
            <div class="certificate-id">CERT  2026  ${certificate.id.substring(0, 6).toUpperCase()}  LEARNHUB.IO</div>
        </div>
    </body>
    </html>
    ''';
  }
}
