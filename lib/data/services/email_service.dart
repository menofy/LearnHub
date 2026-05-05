import 'package:cloud_firestore/cloud_firestore.dart';

/// Service to handle email sending through Cloud Firestore triggers
///
/// This service creates documents in the 'mail' collection which are then
/// processed by Firebase Extensions (e.g., Firebase Email Extension) or
/// Cloud Functions to send actual emails.
///
/// Setup Instructions:
/// 1. Install Firebase Email Extension from Firebase Console
///    - https://console.firebase.google.com/project/edu-pro-8e259/extensions
/// 2. Configure the extension to use the 'mail' collection
/// 3. Emails will be automatically sent when documents are added
class EmailService {
  EmailService._();

  static final EmailService instance = EmailService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Send OTP code to user email
  ///
  /// This creates a mail document that will be processed by Firebase extensions
  Future<void> sendPasswordResetOtpEmail({
    required String email,
    required String otp,
  }) async {
    try {
      // Create mail document for Firebase Email Extension to process
      await _firestore.collection('mail').add({
        'to': [email],
        'message': {
          'subject': 'Password Reset Code - EduPro',
          'text':
              '''
Dear User,

You requested a password reset for your EduPro account.

Your OTP Code: $otp

This code will expire in 10 minutes.

If you didn't request this, please ignore this email.

Best regards,
EduPro Team
          ''',
          'html':
              '''
<html>
  <body>
    <h2>Password Reset Code - EduPro</h2>
    <p>Dear User,</p>
    <p>You requested a password reset for your EduPro account.</p>
    <div style="background-color: #f0f0f0; padding: 15px; border-radius: 5px; text-align: center;">
      <h1 style="color: #333; letter-spacing: 5px; margin: 0;">$otp</h1>
    </div>
    <p style="color: #666;">This code will expire in <strong>10 minutes</strong>.</p>
    <p style="color: #999;">If you didn't request this, please ignore this email.</p>
    <p>Best regards,<br/>EduPro Team</p>
  </body>
</html>
          ''',
        },
      });
    } catch (e) {
      rethrow;
    }
  }

  /// Send Firebase password reset link to user email
  ///
  /// This creates a mail document with the Firebase password reset link
  Future<void> sendPasswordResetLinkEmail({
    required String email,
    required String resetLink,
  }) async {
    try {
      await _firestore.collection('mail').add({
        'to': [email],
        'message': {
          'subject': 'Password Reset Link - EduPro',
          'text':
              '''
Dear User,

Click the link below to reset your password:

$resetLink

If you didn't request this, please ignore this email.

Best regards,
EduPro Team
          ''',
          'html':
              '''
<html>
  <body>
    <h2>Password Reset Link - EduPro</h2>
    <p>Dear User,</p>
    <p>Click the button below to reset your password:</p>
    <p style="text-align: center; margin: 30px 0;">
      <a href="$resetLink" style="background-color: #4CAF50; color: white; padding: 10px 20px; text-decoration: none; border-radius: 5px; display: inline-block;">Reset Password</a>
    </p>
    <p style="color: #999;">If you didn't request this, please ignore this email.</p>
    <p>Best regards,<br/>EduPro Team</p>
  </body>
</html>
          ''',
        },
      });
    } catch (e) {
      rethrow;
    }
  }

  /// Send both OTP and reset link in a single combined email
  Future<void> sendCombinedPasswordResetEmail({
    required String email,
    required String otp,
    required String resetLink,
  }) async {
    try {
      await _firestore.collection('mail').add({
        'to': [email],
        'message': {
          'subject': 'Password Reset - EduPro',
          'text':
              '''
Dear User,

You requested a password reset for your EduPro account.

Method 1: Using OTP Code
Your OTP Code: $otp
(Expires in 10 minutes)

Method 2: Using Reset Link
$resetLink

If you didn't request this, please ignore this email.

Best regards,
EduPro Team
          ''',
          'html':
              '''
<html>
  <body>
    <h2>Password Reset - EduPro</h2>
    <p>Dear User,</p>
    <p>You requested a password reset for your EduPro account.</p>
    
    <h3>Method 1: Using OTP Code</h3>
    <div style="background-color: #f0f0f0; padding: 15px; border-radius: 5px; text-align: center;">
      <h1 style="color: #333; letter-spacing: 5px; margin: 0;">$otp</h1>
    </div>
    <p style="color: #666;">This code will expire in <strong>10 minutes</strong>.</p>
    
    <h3>Method 2: Using Reset Link</h3>
    <p style="text-align: center; margin: 30px 0;">
      <a href="$resetLink" style="background-color: #4CAF50; color: white; padding: 10px 20px; text-decoration: none; border-radius: 5px; display: inline-block;">Reset Password</a>
    </p>
    
    <p style="color: #999;">If you didn't request this, please ignore this email.</p>
    <p>Best regards,<br/>EduPro Team</p>
  </body>
</html>
          ''',
        },
      });
    } catch (e) {
      rethrow;
    }
  }
}
