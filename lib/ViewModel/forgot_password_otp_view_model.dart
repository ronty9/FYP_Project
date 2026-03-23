// Copyright © 2026 TY Chew, Jimmy Kee. All rights reserved.
// Licensed under the MIT License. See LICENSE file in the project root.

import 'package:flutter/material.dart';
import '../services/otp_service.dart';
import '../View/reset_password_view.dart';
import 'dart:async';

class ForgotPasswordOtpViewModel extends ChangeNotifier {
  final OtpService _otpService = OtpService();
  final String email;
  final String userName;

  // OTP input controllers (6 digit OTP)
  final List<TextEditingController> otpControllers = List.generate(
    6,
    (index) => TextEditingController(),
  );

  final List<FocusNode> otpFocusNodes = List.generate(
    6,
    (index) => FocusNode(),
  );

  bool _isLoading = false;
  bool _isResending = false;
  String? _errorMessage;
  String? _successMessage;
  int _resendCountdown = 60;
  Timer? _countdownTimer;
  bool _canResend = false;

  bool get isLoading => _isLoading;
  bool get isResending => _isResending;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;
  int get resendCountdown => _resendCountdown;
  bool get canResend => _canResend;

  ForgotPasswordOtpViewModel({required this.email, required this.userName}) {
    _startResendCountdown();
  }

  void _startResendCountdown() {
    _canResend = false;
    _resendCountdown = 60;
    _countdownTimer?.cancel();

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCountdown > 0) {
        _resendCountdown--;
        notifyListeners();
      } else {
        _canResend = true;
        timer.cancel();
        notifyListeners();
      }
    });
  }

  void onOtpChanged(String value, int index) {
    if (value.length == 1 && index < 5) {
      // Move to next field
      otpFocusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      // Move to previous field on backspace
      otpFocusNodes[index - 1].requestFocus();
    }

    // Clear error when user starts typing
    if (_errorMessage != null) {
      _errorMessage = null;
      notifyListeners();
    }
  }

  Future<void> onVerifyPressed(BuildContext context) async {
    // Get complete OTP
    final otp = otpControllers.map((controller) => controller.text).join();

    if (otp.length != 6) {
      _errorMessage = 'Please enter the complete 6-digit code';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      final result = await _otpService.verifyOTP(email, otp);

      _isLoading = false;

      switch (result) {
        case 'success':
          _successMessage = 'Verification successful!';
          notifyListeners();

          if (context.mounted) {
            // Navigate to Reset Password Screen
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => ResetPasswordView(email: email),
              ),
            );
          }
          break;

        case 'invalid':
          _errorMessage = 'Invalid verification code. Please try again.';
          notifyListeners();
          break;

        case 'expired':
          _errorMessage =
              'Verification code has expired. Please request a new one.';
          notifyListeners();
          break;

        case 'too_many_attempts':
          _errorMessage =
              'Too many failed attempts. Please request a new code.';
          notifyListeners();
          break;

        case 'not_found':
          _errorMessage =
              'Verification code not found. Please request a new one.';
          notifyListeners();
          break;

        default:
          _errorMessage = 'Verification failed. Please try again.';
          notifyListeners();
      }
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'An error occurred: $e';
      notifyListeners();
    }
  }

  Future<void> onResendPressed() async {
    if (!_canResend || _isResending) return;

    _isResending = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      final success = await _otpService.resendOTP(email, userName);

      _isResending = false;

      if (success) {
        _successMessage = 'New verification code sent!';
        _startResendCountdown();

        // Clear input fields
        for (var controller in otpControllers) {
          controller.clear();
        }
        otpFocusNodes[0].requestFocus();
      } else {
        _errorMessage = 'Failed to resend code. Please try again.';
      }

      notifyListeners();
    } catch (e) {
      _isResending = false;
      _errorMessage = 'Error resending code: $e';
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    for (var controller in otpControllers) {
      controller.dispose();
    }
    for (var focusNode in otpFocusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }
}
