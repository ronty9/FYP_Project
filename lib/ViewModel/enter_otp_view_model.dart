// Copyright © 2026 TY Chew. All rights reserved.
// Licensed under the MIT License. See LICENSE file in the project root.

import 'package:flutter/material.dart';
import '../services/otp_service.dart';
import '../View/reset_password_view.dart';

class EnterOtpViewModel extends ChangeNotifier {
  final TextEditingController otpController = TextEditingController();
  final OtpService _otpService = OtpService();

  bool isLoading = false;
  String? errorMessage;
  String? successMessage;

  late String _email;
  String _userName = '';

  // Getter for the View to access private _email
  String get email => _email;

  void initialize(String email, {String userName = ''}) {
    _email = email;
    _userName = userName;
  }

  Future<void> verifyOtp(BuildContext context) async {
    errorMessage = null;
    successMessage = null;
    notifyListeners();

    if (otpController.text.length < 6) {
      errorMessage = 'Please enter the valid 6-digit code.';
      notifyListeners();
      return;
    }

    isLoading = true;
    notifyListeners();

    try {
      // Use the new OtpService API
      final result = await _otpService.verifyOTP(
        _email,
        otpController.text.trim(),
      );

      isLoading = false;

      switch (result) {
        case 'success':
          successMessage = 'Code verified!';
          notifyListeners();

          if (context.mounted) {
            // Success: Go to Reset Password
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => ResetPasswordView(email: _email),
              ),
            );
          }
          break;

        case 'expired':
          errorMessage = 'This code has expired. Please request a new one.';
          break;

        case 'invalid':
          errorMessage = 'Invalid code. Please check and try again.';
          otpController.clear();
          break;

        case 'too_many_attempts':
          errorMessage = 'Too many failed attempts. Please request a new code.';
          otpController.clear();
          break;

        case 'not_found':
          errorMessage =
              'No verification code found. Please request a new one.';
          break;

        default:
          errorMessage = 'Verification failed. Please try again.';
      }

      notifyListeners();
    } catch (e) {
      isLoading = false;
      errorMessage = 'An error occurred: $e';
      notifyListeners();
    }
  }

  Future<void> resendCode(BuildContext context) async {
    errorMessage = null;
    successMessage = null;
    notifyListeners();

    isLoading = true;
    notifyListeners();

    try {
      // Use the new OtpService resend API
      final success = await _otpService.resendOTP(_email, _userName);

      isLoading = false;
      notifyListeners();

      if (context.mounted) {
        if (success) {
          successMessage = 'New code sent to your email';
          notifyListeners();

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('New code sent to your email.'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          errorMessage = 'Failed to resend code. Please try again.';
          notifyListeners();

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to resend code.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      isLoading = false;
      errorMessage = 'An error occurred: $e';
      notifyListeners();
    }
  }

  @override
  void dispose() {
    otpController.dispose();
    super.dispose();
  }
}
