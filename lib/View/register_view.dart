// Copyright © 2026 TY Chew. All rights reserved.
// Licensed under the MIT License. See LICENSE file in the project root.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../ViewModel/register_view_model.dart';

class RegisterView extends StatelessWidget {
  const RegisterView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => RegisterViewModel(),
      child: const _RegisterContent(),
    );
  }
}

class _RegisterContent extends StatelessWidget {
  const _RegisterContent();

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<RegisterViewModel>();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Stack(
          children: [
            // 1. Main Content
            Align(
              alignment: const Alignment(0.0, 0.1),
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 24,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // --- Logo Section ---
                    SizedBox(
                      height: 85,
                      width: 300,
                      child: Image.asset(
                        'images/assets/full_logo.png',
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            Icons.pets,
                            size: 60,
                            color: colorScheme.primary,
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 48),

                    // --- Register Form Card ---
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: colorScheme.shadow.withValues(alpha: 0.08),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Create Account',
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Join PawScope today',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurface.withValues(
                                alpha: 0.6,
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Username
                          TextField(
                            controller: viewModel.usernameController,
                            keyboardType: TextInputType.name,
                            decoration: _inputDecoration(context, 'Username'),
                          ),
                          const SizedBox(height: 16),

                          // Full Name
                          TextField(
                            controller: viewModel.nameController,
                            keyboardType: TextInputType.name,
                            decoration: _inputDecoration(context, 'Full name'),
                          ),
                          const SizedBox(height: 16),

                          // Email
                          TextField(
                            controller: viewModel.emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: _inputDecoration(context, 'Email'),
                          ),
                          const SizedBox(height: 16),

                          // --- NEW: Date of Birth Field ---
                          TextField(
                            controller: viewModel.dateOfBirthController,
                            readOnly: true, // Prevent manual typing to enforce format
                            onTap: () => viewModel.onDateOfBirthPressed(context),
                            decoration: _inputDecoration(
                              context, 
                              'Date of Birth',
                              suffixIcon: Icon(
                                Icons.calendar_today_outlined, 
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          // --------------------------------

                          // Password
                          TextField(
                            controller: viewModel.passwordController,
                            obscureText: viewModel.obscurePassword,
                            decoration: _inputDecoration(
                              context,
                              'Password',
                              suffixIcon: IconButton(
                                icon: Icon(
                                  viewModel.obscurePassword
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  color: Colors.grey.shade600,
                                ),
                                onPressed: viewModel.onTogglePasswordPressed,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Confirm Password
                          TextField(
                            controller: viewModel.confirmPasswordController,
                            obscureText: viewModel.obscureConfirmPassword,
                            decoration: _inputDecoration(
                              context,
                              'Confirm password',
                              suffixIcon: IconButton(
                                icon: Icon(
                                  viewModel.obscureConfirmPassword
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  color: Colors.grey.shade600,
                                ),
                                onPressed: viewModel.onToggleConfirmPressed,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Error Message
                          if (viewModel.errorMessage != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: Text(
                                viewModel.errorMessage!,
                                style: TextStyle(
                                  color: colorScheme.error,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),

                          // Sign Up Button
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: colorScheme.primary,
                                foregroundColor: colorScheme.onPrimary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                              ),
                              onPressed: viewModel.isLoading
                                  ? null
                                  : () => viewModel.onRegisterPressed(context),
                              child: viewModel.isLoading
                                  ? SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        color: colorScheme.onPrimary,
                                      ),
                                    )
                                  : const Text(
                                      'Sign up',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Login Link
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Already have an account? ',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: colorScheme.onSurface.withValues(
                                    alpha: 0.7,
                                  ),
                                ),
                              ),
                              GestureDetector(
                                onTap: () =>
                                    viewModel.onGoToLoginPressed(context),
                                child: Text(
                                  'Log in',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 2. Back Button (Top Left)
            Positioned(
              top: 10,
              left: 16,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.black87),
                  onPressed: () => viewModel.onGoToLoginPressed(context),
                  tooltip: 'Back to Login',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(
    BuildContext context,
    String label, {
    Widget? suffixIcon,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(
        color: colorScheme.onSurface.withValues(alpha: 0.6),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      filled: true,
      fillColor: theme.scaffoldBackgroundColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colorScheme.primary, width: 2),
      ),
      suffixIcon: suffixIcon,
    );
  }
}