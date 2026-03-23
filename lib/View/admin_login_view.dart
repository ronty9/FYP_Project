// Copyright © 2026 TY Chew, Jimmy Kee. All rights reserved.
// Licensed under the MIT License. See LICENSE file in the project root.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../ViewModel/admin_login_view_model.dart';
import '../ViewModel/base_view_model.dart';

class AdminLoginView extends StatelessWidget {
  const AdminLoginView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AdminLoginViewModel(),
      child: const _AdminLoginContent(),
    );
  }
}

class _AdminLoginContent extends StatefulWidget {
  const _AdminLoginContent();

  @override
  State<_AdminLoginContent> createState() => _AdminLoginContentState();
}

class _AdminLoginContentState extends State<_AdminLoginContent> {
  Timer? _dismissTimer;
  String? _lastMessage;
  late AdminLoginViewModel _vm;
  bool _isListening = false;

  void _onVmChanged() {
    final msg = _vm.message;
    if (msg != null && msg.isNotEmpty) {
      if (_lastMessage != msg) {
        _dismissTimer?.cancel();
        _dismissTimer = Timer(const Duration(seconds: 4), () {
          if (mounted) _vm.clearMessage();
        });
        _lastMessage = msg;
      }
    } else {
      _dismissTimer?.cancel();
      _dismissTimer = null;
      _lastMessage = null;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isListening) {
      _vm = context.read<AdminLoginViewModel>();
      _vm.addListener(_onVmChanged);
      _isListening = true;
    }
  }

  @override
  void dispose() {
    if (_isListening) {
      _vm.removeListener(_onVmChanged);
      _isListening = false;
    }
    _dismissTimer?.cancel();
    super.dispose();
  }

  Widget _displayMessage(
    String? msg,
    MessageType? type,
    AdminLoginViewModel viewModel,
  ) {
    if (msg == null || msg.isEmpty) return const SizedBox.shrink();

    Color bgColor = Colors.red.shade50;
    Color textColor = Colors.red.shade700;
    IconData icon = Icons.error_outline;

    switch (type) {
      case MessageType.success:
        bgColor = Colors.green.shade50;
        textColor = Colors.green.shade700;
        icon = Icons.check_circle_outline;
        break;
      case MessageType.info:
        bgColor = Colors.blue.shade50;
        textColor = Colors.blue.shade700;
        icon = Icons.info_outline;
        break;
      case MessageType.warning:
        bgColor = Colors.orange.shade50;
        textColor = Colors.orange.shade700;
        icon = Icons.warning_amber_outlined;
        break;
      case MessageType.error:
      default:
        bgColor = Colors.red.shade50;
        textColor = Colors.red.shade700;
        icon = Icons.error_outline;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: bgColor.withValues(alpha: 0.6)),
      ),
      child: Row(
        children: [
          Icon(icon, color: textColor, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              msg,
              style: TextStyle(
                color: textColor,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          IconButton(
            onPressed: () => viewModel.clearMessage(),
            icon: Icon(Icons.close, color: textColor, size: 18),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<AdminLoginViewModel>();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD), // App Theme Background
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16.0),
          child: CircleAvatar(
            backgroundColor: Colors.white,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black87),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),

              // --- 1. Header Section (Centered) ---
              Center(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.admin_panel_settings_rounded,
                    size: 40,
                    color: colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Center(
                child: Text(
                  'Admin Access',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF1A1A1A),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  'Log in to manage the application dashboard.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade600,
                    height: 1.5,
                  ),
                ),
              ),

              const SizedBox(height: 40),

              // --- 2. Input Fields ---
              _buildLabel('Admin ID / Email'),
              const SizedBox(height: 8),
              TextField(
                controller: viewModel.adminIdController,
                keyboardType: TextInputType.emailAddress,
                style: const TextStyle(fontWeight: FontWeight.w500),
                decoration: _inputDecoration(
                  hint: 'Enter admin ID',
                  icon: Icons.person_outline_rounded,
                  colorScheme: colorScheme,
                ),
              ),

              const SizedBox(height: 24),

              _buildLabel('Password'),
              const SizedBox(height: 8),
              TextField(
                controller: viewModel.passwordController,
                obscureText: viewModel.obscurePassword,
                style: const TextStyle(fontWeight: FontWeight.w500),
                decoration: _inputDecoration(
                  hint: 'Enter password',
                  icon: Icons.lock_outline_rounded,
                  colorScheme: colorScheme,
                  suffixIcon: IconButton(
                    icon: Icon(
                      viewModel.obscurePassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: Colors.grey.shade500,
                    ),
                    onPressed: viewModel.togglePasswordVisibility,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // --- Message Widget ---
              _displayMessage(
                viewModel.message,
                viewModel.messageType,
                viewModel,
              ),

              const SizedBox(height: 40),

              // --- Action Button ---
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary, // Cobalt Blue
                    foregroundColor: Colors.white,
                    elevation: 8,
                    shadowColor: colorScheme.primary.withValues(alpha: 0.3),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  onPressed: viewModel.isLoading
                      ? null
                      : () => viewModel.loginAdmin(context),
                  child: viewModel.isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Access Dashboard',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Color(0xFF1A1A1A),
      ),
    );
  }

  // --- Fixed Method: Removed duplicate 'enabledBorder' ---
  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
    required ColorScheme colorScheme,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
      prefixIcon: Icon(icon, color: Colors.grey.shade500, size: 22),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
      ),
    );
  }
}
