import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/api_keys.dart';

/// Service for handling OTP generation, verification, and email sending via SendGrid
class OtpService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // SendGrid configuration from separate config file
  static String get _sendGridApiKey => ApiKeys.sendGridApiKey;
  static String get _senderEmail => ApiKeys.senderEmail;
  static String get _senderName => ApiKeys.senderName;

  /// Generates a 6-digit OTP code
  String _generateOTP() {
    final random = Random();
    // Generate number between 100000 and 999999
    return (100000 + random.nextInt(900000)).toString();
  }

  /// Sends OTP to the specified email address
  /// Returns the OTP code if successful, null if failed
  Future<String?> sendOTP(String email, String userName) async {
    try {
      // 1. Generate OTP
      final otp = _generateOTP();

      // 2. Store OTP in Firestore
      await _firestore.collection('otps').add({
        'email': email.toLowerCase().trim(),
        'otp': otp,
        'createdAt': FieldValue.serverTimestamp(),
        'expiresAt': Timestamp.fromDate(
          DateTime.now().add(const Duration(minutes: 10)),
        ),
        'verified': false,
        'attempts': 0,
      });

      // 3. Send email via SendGrid
      final emailSent = await _sendEmailViaSendGrid(email, userName, otp);

      if (!emailSent) {
        debugPrint('Failed to send OTP email via SendGrid');
        return null;
      }

      return otp; // Return OTP for development/testing purposes
    } catch (e) {
      debugPrint('Error sending OTP: $e');
      return null;
    }
  }

  /// Sends email via SendGrid API
  Future<bool> _sendEmailViaSendGrid(
    String toEmail,
    String userName,
    String otp,
  ) async {
    if (_sendGridApiKey == 'YOUR_SENDGRID_API_KEY_HERE') {
      debugPrint('⚠️ WARNING: SendGrid API key not configured!');
      debugPrint('OTP Code (for testing): $otp');
      // For development, return true to allow testing without SendGrid
      return true;
    }

    try {
      final response = await http.post(
        Uri.parse('https://api.sendgrid.com/v3/mail/send'),
        headers: {
          'Authorization': 'Bearer $_sendGridApiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'personalizations': [
            {
              'to': [
                {'email': toEmail},
              ],
              'subject': 'Your PawScope Verification Code',
            },
          ],
          'from': {'email': _senderEmail, 'name': _senderName},
          'content': [
            {'type': 'text/html', 'value': _buildEmailHTML(userName, otp)},
          ],
        }),
      );

      if (response.statusCode == 202) {
        debugPrint('✅ Email sent successfully to $toEmail');
        return true;
      } else {
        debugPrint(
          '❌ SendGrid error: ${response.statusCode} - ${response.body}',
        );
        return false;
      }
    } catch (e) {
      debugPrint('❌ Error calling SendGrid API: $e');
      return false;
    }
  }

  /// Builds the HTML email template
  String _buildEmailHTML(String userName, String otp) {
    return '''
<!DOCTYPE html>
<html>
<head>
  <style>
    body {
      font-family: Arial, sans-serif;
      background-color: #f4f4f4;
      margin: 0;
      padding: 20px;
    }
    .container {
      max-width: 600px;
      margin: 0 auto;
      background-color: #ffffff;
      border-radius: 10px;
      overflow: hidden;
      box-shadow: 0 2px 10px rgba(0,0,0,0.1);
    }
    .header {
      background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
      color: white;
      padding: 30px;
      text-align: center;
    }
    .content {
      padding: 40px 30px;
      text-align: center;
    }
    .otp-code {
      font-size: 36px;
      font-weight: bold;
      color: #667eea;
      letter-spacing: 8px;
      margin: 30px 0;
      padding: 20px;
      background-color: #f8f9ff;
      border-radius: 8px;
      display: inline-block;
    }
    .info {
      color: #666;
      font-size: 14px;
      margin-top: 20px;
    }
    .footer {
      background-color: #f8f9fa;
      padding: 20px;
      text-align: center;
      color: #888;
      font-size: 12px;
    }
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <h1>🐾 PawScope</h1>
      <p>Email Verification</p>
    </div>
    <div class="content">
      <h2>Hello ${userName.isNotEmpty ? userName : 'there'}!</h2>
      <p>Thank you for registering with PawScope. Please use the verification code below to complete your registration:</p>
      
      <div class="otp-code">$otp</div>
      
      <div class="info">
        <p><strong>This code will expire in 10 minutes.</strong></p>
        <p>If you didn't request this code, please ignore this email.</p>
      </div>
    </div>
    <div class="footer">
      <p>© 2026 PawScope. All rights reserved.</p>
      <p>This is an automated email, please do not reply.</p>
    </div>
  </div>
</body>
</html>
    ''';
  }

  /// Verifies the OTP code entered by the user
  /// Returns:
  /// - 'success' if OTP is valid
  /// - 'expired' if OTP has expired
  /// - 'invalid' if OTP doesn't match
  /// - 'too_many_attempts' if too many failed attempts
  /// - 'not_found' if no OTP found for this email
  Future<String> verifyOTP(String email, String enteredOTP) async {
    try {
      final query = await _firestore
          .collection('otps')
          .where('email', isEqualTo: email.toLowerCase().trim())
          .where('verified', isEqualTo: false)
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        return 'not_found';
      }

      final doc = query.docs.first;
      final data = doc.data();
      final storedOTP = data['otp'] as String;
      final expiresAt = (data['expiresAt'] as Timestamp).toDate();
      final attempts = (data['attempts'] as int?) ?? 0;

      // Check if too many attempts
      if (attempts >= 5) {
        return 'too_many_attempts';
      }

      // Check if expired
      if (DateTime.now().isAfter(expiresAt)) {
        return 'expired';
      }

      // Check if OTP matches
      if (storedOTP == enteredOTP.trim()) {
        // Mark as verified
        await doc.reference.update({'verified': true});
        return 'success';
      } else {
        // Increment attempts
        await doc.reference.update({'attempts': attempts + 1});
        return 'invalid';
      }
    } catch (e) {
      debugPrint('Error verifying OTP: $e');
      return 'error';
    }
  }

  /// Resends OTP to the specified email
  Future<bool> resendOTP(String email, String userName) async {
    try {
      // Invalidate all previous OTPs for this email
      final oldOTPs = await _firestore
          .collection('otps')
          .where('email', isEqualTo: email.toLowerCase().trim())
          .where('verified', isEqualTo: false)
          .get();

      for (var doc in oldOTPs.docs) {
        await doc.reference.update({'verified': true}); // Mark as used
      }

      // Send new OTP
      final newOTP = await sendOTP(email, userName);
      return newOTP != null;
    } catch (e) {
      debugPrint('Error resending OTP: $e');
      return false;
    }
  }

  /// Cleans up expired OTPs (call this periodically or via Cloud Function)
  Future<void> cleanupExpiredOTPs() async {
    try {
      final expiredOTPs = await _firestore
          .collection('otps')
          .where('expiresAt', isLessThan: Timestamp.fromDate(DateTime.now()))
          .get();

      for (var doc in expiredOTPs.docs) {
        await doc.reference.delete();
      }

      debugPrint('Cleaned up ${expiredOTPs.docs.length} expired OTPs');
    } catch (e) {
      debugPrint('Error cleaning up OTPs: $e');
    }
  }
}
