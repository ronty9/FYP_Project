import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../services/ai_service.dart';

class ResetPasswordViewModel extends ChangeNotifier {
  final TextEditingController newPasswordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  bool obscureNew = true;
  bool obscureConfirm = true;
  bool isLoading = false;
  String? errorMessage;

  late String _email;

  void initialize(String email) {
    _email = email;
  }

  void toggleNewVisibility() {
    obscureNew = !obscureNew;
    notifyListeners();
  }

  void toggleConfirmVisibility() {
    obscureConfirm = !obscureConfirm;
    notifyListeners();
  }

  Future<void> resetPassword(BuildContext context) async {
    errorMessage = null;
    notifyListeners();

    if (newPasswordController.text.isEmpty ||
        confirmPasswordController.text.isEmpty) {
      errorMessage = 'Please enter all fields.';
      notifyListeners();
      return;
    }

    if (newPasswordController.text != confirmPasswordController.text) {
      errorMessage = 'Passwords do not match.';
      notifyListeners();
      return;
    }

    if (newPasswordController.text.length < 6) {
      errorMessage = 'Password must be at least 6 characters.';
      notifyListeners();
      return;
    }

    isLoading = true;
    notifyListeners();

    try {
      final uri = Uri.parse('${AiService.baseUrl}/reset-password');
      final response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'email': _email,
              'new_password': newPasswordController.text,
            }),
          )
          .timeout(const Duration(seconds: 20));

      isLoading = false;

      if (response.statusCode == 200) {
        notifyListeners();
        if (context.mounted) {
          _showSuccessDialog(context);
        }
      } else {
        // Try to extract a readable error from the response body
        String detail = 'Failed to reset password.';
        try {
          final body = jsonDecode(response.body) as Map<String, dynamic>;
          detail = body['detail']?.toString() ?? detail;
        } catch (_) {}
        errorMessage = detail;
        notifyListeners();
      }
    } catch (e) {
      isLoading = false;
      errorMessage =
          'Could not reach server. Make sure you are on the same '
          'network as the backend.';
      notifyListeners();
    }
  }

  void _showSuccessDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        icon: const Icon(
          Icons.check_circle_outline,
          color: Colors.green,
          size: 64,
        ),
        title: const Text(
          'Password Reset!',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Your password has been updated successfully. '
          'Please sign in with your new password.',
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.of(context).popUntil((route) => route.isFirst),
            child: const Text(
              'Back to Login',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }
}
