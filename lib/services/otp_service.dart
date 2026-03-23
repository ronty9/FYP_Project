// Copyright © 2026 TY Chew. All rights reserved.
// Licensed under the MIT License. See LICENSE file in the project root.

import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

/// Service for handling OTP generation, verification, and email sending
/// via a Firebase Cloud Function (which uses SendGrid server-side).
class OtpService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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

      // 3. Send email via Cloud Function (SendGrid is handled server-side)
      final emailSent = await _sendEmailViaCloudFunction(email, userName, otp);

      if (!emailSent) {
        debugPrint('Failed to send OTP email via Cloud Function');
        return null;
      }

      return otp; // Return OTP for development/testing purposes
    } catch (e) {
      debugPrint('Error sending OTP: $e');
      return null;
    }
  }

  /// Sends email via the sendOtp Firebase Cloud Function.
  /// The Cloud Function handles SendGrid integration server-side,
  /// so no API keys are needed in the client code.
  Future<bool> _sendEmailViaCloudFunction(
    String toEmail,
    String userName,
    String otp,
  ) async {
    try {
      final callable = FirebaseFunctions.instanceFor(
        region: 'asia-southeast1',
      ).httpsCallable('sendOtp');

      await callable.call<dynamic>({
        'email': toEmail,
        'userName': userName,
        'otp': otp,
      });

      debugPrint('✅ OTP email sent successfully to $toEmail');
      return true;
    } on FirebaseFunctionsException catch (e) {
      debugPrint('❌ Cloud Function error: ${e.code} - ${e.message}');
      return false;
    } catch (e) {
      debugPrint('❌ Error calling sendOtp Cloud Function: $e');
      return false;
    }
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
