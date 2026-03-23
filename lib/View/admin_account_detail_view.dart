// Copyright © 2026 TY Chew, Jimmy Kee. All rights reserved.
// Licensed under the MIT License. See LICENSE file in the project root.

  import 'package:flutter/material.dart';
  import 'package:provider/provider.dart';
  import '../ViewModel/admin_account_detail_view_model.dart';
  import '../models/user_account.dart';

  class AdminAccountDetailView extends StatelessWidget {
    const AdminAccountDetailView({super.key});

    @override
    Widget build(BuildContext context) {
      final user = ModalRoute.of(context)!.settings.arguments as UserAccount;

      return ChangeNotifierProvider(
        create: (_) => AdminAccountDetailViewModel()..initialize(user),
        child: const _AdminAccountDetailBody(),
      );
    }
  }

  class _AdminAccountDetailBody extends StatelessWidget {
    const _AdminAccountDetailBody();

    @override
    Widget build(BuildContext context) {
      final viewModel = context.watch<AdminAccountDetailViewModel>();
      final user = viewModel.user;

      if (user == null) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }

      final colorScheme = Theme.of(context).colorScheme;
      final textTheme = Theme.of(context).textTheme;

      return Scaffold(
        backgroundColor: const Color(0xFFF5F6FA),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Icon(Icons.arrow_back, color: colorScheme.onSurface),
            ),
            onPressed: () => viewModel.onBackPressed(context),
          ),
          title: Text(
            'Account Details',
            style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          centerTitle: true,
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.more_vert, color: Colors.grey),
                ),
                onPressed: () => viewModel.showOptionsMenu(context),
              ),
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Profile Header Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      colorScheme.primary,
                      colorScheme.primary.withValues(alpha: 0.8),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.primary.withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Avatar
                    Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                          style: textTheme.headlineLarge?.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Name
                    Text(
                      user.name,
                      style: textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Email
                    Text(
                      user.email,
                      style: textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Status Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Colors.greenAccent,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Active',
                            style: textTheme.labelMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Account Information Card
              _buildInfoCard(
                context,
                title: 'Account Information',
                icon: Icons.person_outline,
                children: [
                  _buildInfoRow(
                    context,
                    icon: Icons.badge_outlined,
                    label: 'User ID',
                    value: '#${user.id}',
                  ),
                  _buildDivider(),
                  _buildInfoRow(
                    context,
                    icon: Icons.email_outlined,
                    label: 'Email Address',
                    value: user.email,
                  ),
                  _buildDivider(),
                  _buildInfoRow(
                    context,
                    icon: Icons.calendar_today_outlined,
                    label: 'Join Date',
                    value: user.joinDate,
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Activity Stats Card
              _buildInfoCard(
                context,
                title: 'Activity Stats',
                icon: Icons.analytics_outlined,
                children: [
                  _buildInfoRow(
                    context,
                    icon: Icons.pets_outlined,
                    label: 'Pets Registered',
                    value: '3',
                  ),
                  _buildDivider(),
                  _buildInfoRow(
                    context,
                    icon: Icons.event_outlined,
                    label: 'Scheduled Events',
                    value: '12',
                  ),
                  _buildDivider(),
                  _buildInfoRow(
                    context,
                    icon: Icons.access_time,
                    label: 'Last Active',
                    value: 'Today, 2:30 PM',
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => viewModel.showLockConfirmation(context),
                      icon: Icon(
                        viewModel.isAccountLocked
                            ? Icons.lock_open
                            : Icons.block_outlined,
                      ),
                      label: Text(
                        viewModel.isAccountLocked ? 'Unlock' : 'Suspend',
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(
                          color: viewModel.isAccountLocked
                              ? Colors.green
                              : Colors.orange,
                        ),
                        foregroundColor: viewModel.isAccountLocked
                            ? Colors.green
                            : Colors.orange,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => viewModel.showDeleteConfirmation(context),
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('Delete'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: Colors.red,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    Widget _buildInfoCard(
      BuildContext context, {
      required String title,
      required IconData icon,
      required List<Widget> children,
    }) {
      final colorScheme = Theme.of(context).colorScheme;
      final textTheme = Theme.of(context).textTheme;

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      );
    }

    Widget _buildInfoRow(
      BuildContext context, {
      required IconData icon,
      required String label,
      required String value,
    }) {
      final textTheme = Theme.of(context).textTheme;

      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(icon, size: 20, color: Colors.grey.shade500),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    Widget _buildDivider() {
      return Divider(color: Colors.grey.shade100, height: 1);
    }
  }
