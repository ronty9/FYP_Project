// Copyright © 2026 TY Chew, Jimmy Kee. All rights reserved.
// Licensed under the MIT License. See LICENSE file in the project root.

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../View/home_view.dart';
import '../View/register_view.dart';
import '../View/admin_login_view.dart';
import '../View/forgot_password_view.dart';
import 'base_view_model.dart';

class LoginViewModel extends ChangeNotifier {
  final TextEditingController emailOrUsernameController =
      TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _isTermsAccepted = false;

  String? _message;
  MessageType? _messageType;

  // Getters
  bool get obscurePassword => _obscurePassword;
  bool get isLoading => _isLoading;
  bool get isTermsAccepted => _isTermsAccepted;
  String? get errorMessage => _message;
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

  void onTogglePasswordPressed() {
    _obscurePassword = !_obscurePassword;
    notifyListeners();
  }

  void toggleTerms(bool? value) {
    _isTermsAccepted = value ?? false;
    notifyListeners();
  }

  // --- Email/Password Login ---
  Future<void> onLoginPressed(BuildContext context) async {
    setMessage(null, null);

    if (emailOrUsernameController.text.isEmpty ||
        passwordController.text.isEmpty) {
      setMessage('Please provide both email and password.', MessageType.error);
      return;
    }

    if (!_isTermsAccepted) {
      setMessage(
        'Please accept the Terms & Conditions to login.',
        MessageType.error,
      );
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      final input = emailOrUsernameController.text.trim();
      String emailToUse = input;

      // Check if input is an email or username
      final isEmail = RegExp(
        r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
      ).hasMatch(input);

      if (!isEmail) {
        // It's a username, look up the email in Firestore
        final userQuery = await FirebaseFirestore.instance
            .collection('user')
            .where('userName', isEqualTo: input)
            .limit(1)
            .get();

        if (userQuery.docs.isEmpty) {
          _isLoading = false;
          setMessage('No user found with that username.', MessageType.error);
          return;
        }

        // Get the email from Firestore
        emailToUse = userQuery.docs.first.data()['userEmail'] as String;
      }

      // Now authenticate with Firebase using the email
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailToUse,
        password: passwordController.text,
      );

      _isLoading = false;
      notifyListeners();

      if (context.mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeView()),
        );
      }
    } on FirebaseAuthException catch (e) {
      _isLoading = false;
      String errorMsg = 'Login failed. Please try again.';
      if (e.code == 'user-not-found') {
        errorMsg = 'No user found for that email.';
      } else if (e.code == 'wrong-password') {
        errorMsg = 'Wrong password provided.';
      } else if (e.code == 'invalid-credential') {
        errorMsg = 'Invalid email or password.';
      } else if (e.code == 'user-disabled') {
        errorMsg = 'This user account has been disabled.';
      }

      setMessage(errorMsg, MessageType.error);
    } catch (e) {
      _isLoading = false;
      setMessage('An error occurred: ${e.toString()}', MessageType.error);
    }
  }

  // --- GOOGLE SIGN-IN LOGIC ---
  Future<void> onGoogleLoginPressed(BuildContext context) async {
    // Terms Check for Social Login
    if (!_isTermsAccepted) {
      setMessage('Please accept the Terms & Conditions.', MessageType.error);
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      final GoogleSignIn googleSignIn = GoogleSignIn();
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        _isLoading = false;
        notifyListeners();
        return; // User cancelled
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithCredential(credential);

      // --- SAVE TO FIRESTORE & NAVIGATE ---
      if (userCredential.user != null) {
        await _saveSocialUserToFirestore(userCredential.user!, 'google');

        _isLoading = false;
        notifyListeners();

        if (context.mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const HomeView()),
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      _isLoading = false;
      setMessage(e.message ?? 'Google Sign-In failed', MessageType.error);
    } catch (e) {
      _isLoading = false;
      setMessage('An error occurred: $e', MessageType.error);
    }
  }

  // --- Helper: Save Social User to Firestore ---
  Future<void> _saveSocialUserToFirestore(
    User user,
    String providerName,
  ) async {
    final firestore = FirebaseFirestore.instance;

    // Check if user already exists
    final QuerySnapshot result = await firestore
        .collection('user')
        .where('providerId', isEqualTo: user.uid)
        .limit(1)
        .get();

    if (result.docs.isNotEmpty) {
      return; // User exists, do nothing
    }

    // Generate Custom ID (U00000X)
    final counterRef = firestore.collection('counters').doc('userCounter');

    await firestore.runTransaction((transaction) async {
      DocumentSnapshot counterSnapshot = await transaction.get(counterRef);

      int currentCount = 0;
      if (counterSnapshot.exists) {
        currentCount = counterSnapshot.get('count') as int;
      }

      int newCount = currentCount + 1;
      String customUserId = 'U${newCount.toString().padLeft(6, '0')}';
      final userDocRef = firestore.collection('user').doc(customUserId);

      final userData = {
        'userName': user.displayName ?? 'Google User',
        'userEmail': user.email ?? '',
        'password_hash': 'GOOGLE_AUTH',
        'authProvider': providerName,
        'providerId': user.uid,
        'userRole': 'User',
        'accountStatus': 'Active',
        'dateCreated': FieldValue.serverTimestamp(),
        'dateOfBirth': null,
      };

      transaction.set(counterRef, {'count': newCount});
      transaction.set(userDocRef, userData);
    });
  }

  // --- Navigation Helpers ---
  void onRegisterPressed(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const RegisterView()),
    );
  }

  void onAdminLoginPressed(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AdminLoginView()),
    );
  }

  void onForgotPasswordPressed(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ForgotPasswordView()),
    );
  }

  @override
  void dispose() {
    emailOrUsernameController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}
