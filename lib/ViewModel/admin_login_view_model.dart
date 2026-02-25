import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'base_view_model.dart';

class AdminLoginViewModel extends BaseViewModel {
  final TextEditingController adminIdController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;

  bool get obscurePassword => _obscurePassword;
  @override
  bool get isLoading => _isLoading;

  @override
  String? get errorMessage => message;

  String? _message;
  MessageType? _messageType;

  String? get message => _message;
  MessageType? get messageType => _messageType;

  void setMessage(String? msg, [MessageType? type]) {
    _message = msg;
    _messageType = type;
    notifyListeners();
  }

  void clearMessage() {
    if (_message == null && _messageType == null) return;
    _message = null;
    _messageType = null;
    notifyListeners();
  }

  void togglePasswordVisibility() {
    _obscurePassword = !_obscurePassword;
    notifyListeners();
  }

  // --- Main Login Logic ---
  Future<void> loginAdmin(BuildContext context) async {
    if (adminIdController.text.trim().isEmpty ||
        passwordController.text.isEmpty) {
      setMessage('Please enter Username and Password.', MessageType.error);
      return;
    }

    _isLoading = true;
    clearMessage();
    notifyListeners();

    try {
      final usernameInput = adminIdController.text.trim();

      // DEBUG PRINT 1: Check what the user typed
      debugPrint("DEBUG: User typed username: $usernameInput");

      // 1. Find Email associated with this Username
      final emailToLogin = await _getEmailFromUsername(usernameInput);

      // DEBUG PRINT 2: Check what email we found
      debugPrint("DEBUG: Found email from database: $emailToLogin");

      if (emailToLogin == null) {
        throw FirebaseAuthException(
          code: 'user-not-found',
          message: 'Username "$usernameInput" not found in database.',
        );
      }

      // 2. Authenticate with Firebase Auth (MUST USE EMAIL)
      // We pass 'emailToLogin' (the email), NOT 'usernameInput'
      final userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(
            email: emailToLogin,
            password: passwordController.text,
          );

      // 3. SECURITY CHECK: Verify 'Admin' Role
      if (userCredential.user != null) {
        final isAuthorized = await _verifyAdminRole(userCredential.user!.uid);

        if (!isAuthorized) {
          await FirebaseAuth.instance.signOut();
          setMessage(
            'Access Denied: You do not have Admin privileges.',
            MessageType.error,
          );
          _isLoading = false;
          notifyListeners();
          return;
        }

        // Success
        setMessage('Login Successful', MessageType.success);
        _isLoading = false;
        notifyListeners();

        await Future.delayed(const Duration(milliseconds: 500));

        if (context.mounted) {
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/admin_dashboard',
            (route) => false,
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      _isLoading = false;
      debugPrint("DEBUG: Firebase Auth Error: ${e.code} - ${e.message}");

      String msg = 'Login failed.';
      if (e.code == 'user-not-found') {
        msg = 'Username not found.';
      } else if (e.code == 'wrong-password') {
        msg = 'Incorrect password.';
      } else if (e.code == 'invalid-email') {
        msg = 'System Error: Invalid email format retrieved.';
      } else if (e.code == 'invalid-credential') {
        msg = 'Invalid credentials.';
      } else if (e.message != null) {
        msg = e.message!;
      }

      setMessage(msg, MessageType.error);
    } catch (e) {
      _isLoading = false;
      debugPrint("DEBUG: General Error: $e");
      setMessage('An error occurred: $e', MessageType.error);
    }
  }

  // --- Helper: Get Email from Username ---
  Future<String?> _getEmailFromUsername(String username) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('user')
          .where('userName', isEqualTo: username)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        // ADD .trim() HERE to fix the trailing space issue automatically
        String email = snapshot.docs.first.get('userEmail');
        return email.trim();
      }
    } catch (e) {
      debugPrint("DEBUG: Error in _getEmailFromUsername: $e");
    }
    return null;
  }

  // --- Helper: Verify Role ---
  Future<bool> _verifyAdminRole(String authUid) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('user')
          .where('providerId', isEqualTo: authUid)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final role = snapshot.docs.first.get('userRole');
        return role == 'Admin';
      }
    } catch (e) {
      debugPrint("DEBUG: Error verifying role: $e");
    }
    return false;
  }

  @override
  void dispose() {
    adminIdController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}
