import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/otp_service.dart';
import '../View/forgot_password_otp_view.dart';

class ForgotPasswordViewModel extends ChangeNotifier {
  final TextEditingController emailController = TextEditingController();
  final OtpService _otpService = OtpService();

  bool isLoading = false;
  String? errorMessage;

  Future<void> sendOTP(BuildContext context) async {
    // 1. Reset Error
    errorMessage = null;
    notifyListeners();

    // 2. Input Validation
    final email = emailController.text.trim();
    if (email.isEmpty) {
      errorMessage = 'Please enter your email address.';
      notifyListeners();
      return;
    }

    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      errorMessage = 'Please enter a valid email address.';
      notifyListeners();
      return;
    }

    // 3. Start Loading
    isLoading = true;
    notifyListeners();

    try {
      // 4. Check if User Exists in Firestore
      final userQuery = await FirebaseFirestore.instance
          .collection('user')
          .where('userEmail', isEqualTo: email)
          .limit(1)
          .get();

      if (userQuery.docs.isEmpty) {
        errorMessage = 'No account found with this email.';
        isLoading = false;
        notifyListeners();
        return;
      }

      final userData = userQuery.docs.first.data();
      final userName = userData['userName'] ?? 'User';

      // 5. Send OTP via Email
      final otp = await _otpService.sendOTP(email, userName);

      isLoading = false;
      notifyListeners();

      if (otp == null) {
        errorMessage = 'Failed to send verification code. Please try again.';
        notifyListeners();
        return;
      }

      if (context.mounted) {
        // 6. Navigate to OTP Verification Screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                ForgotPasswordOtpView(email: email, userName: userName),
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      isLoading = false;
      if (e.code == 'user-not-found') {
        errorMessage = 'No user found with this email.';
      } else {
        errorMessage = e.message ?? 'An error occurred.';
      }
      notifyListeners();
    } catch (e) {
      isLoading = false;
      errorMessage = 'Error: $e';
      notifyListeners();
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }
}
