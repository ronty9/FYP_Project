import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../ViewModel/notifications_view_model.dart';

class NotificationsView extends StatelessWidget {
  const NotificationsView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => NotificationsViewModel(),
      child: const _NotificationsBody(),
    );
  }
}

class _NotificationsBody extends StatelessWidget {
  const _NotificationsBody();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final viewModel = context.watch<NotificationsViewModel>();

    final todayNotifications = viewModel.todayNotifications;
    final earlierNotifications = viewModel.earlierNotifications;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Column(
        children: [
          // --- Gradient Header ---
          Container(
            width: double.infinity,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 12,
              left: 20,
              right: 20,
              bottom: 24,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  colorScheme.primary,
                  colorScheme.primary.withValues(alpha: 0.75),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(32),
                bottomRight: Radius.circular(32),
              ),
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.arrow_back_ios_new,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                const Text(
                  'Notifications',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const Spacer(),
                if (viewModel.hasUnread) ...[
                  Container(
                    margin: const EdgeInsets.only(right: 10),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red.shade400,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${viewModel.unreadCount}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: viewModel.markAllAsRead,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.done_all_rounded,
                            color: Colors.white,
                            size: 15,
                          ),
                          SizedBox(width: 5),
                          Text(
                            'Read all',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // --- Notification List ---
          Expanded(
            child: viewModel.isLoading
                ? const Center(child: CircularProgressIndicator())
                : todayNotifications.isEmpty && earlierNotifications.isEmpty
                ? const _EmptyState()
                : RefreshIndicator(
                    onRefresh: () => viewModel.refreshNotifications(),
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (todayNotifications.isNotEmpty) ...[
                            const _SectionLabel(label: 'Upcoming'),
                            const SizedBox(height: 10),
                            ...todayNotifications.map(
                              (item) => _NotificationTileCard(
                                item: item,
                                onTap: () => viewModel.openNotificationDetail(
                                  context,
                                  item,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                          if (earlierNotifications.isNotEmpty) ...[
                            const _SectionLabel(label: 'Earlier'),
                            const SizedBox(height: 10),
                            ...earlierNotifications.map(
                              (item) => _NotificationTileCard(
                                item: item,
                                onTap: () => viewModel.openNotificationDetail(
                                  context,
                                  item,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

// --- Section Label ---
class _SectionLabel extends StatelessWidget {
  final String label;

  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Container(
          width: 4,
          height: 16,
          decoration: BoxDecoration(
            color: colorScheme.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Colors.grey.shade700,
          ),
        ),
      ],
    );
  }
}

// --- Notification Tile Card ---
class _NotificationTileCard extends StatelessWidget {
  final NotificationItem item;
  final VoidCallback onTap;

  const _NotificationTileCard({required this.item, required this.onTap});

  static (IconData, Color) _iconForType(NotificationType type) {
    switch (type) {
      case NotificationType.vaccination:
        return (Icons.vaccines_rounded, const Color(0xFFFF6B6B));
      case NotificationType.medication:
        return (Icons.medication_rounded, const Color(0xFFFFBE0B));
      case NotificationType.vet:
        return (Icons.local_hospital_rounded, const Color(0xFFFF6B6B));
      case NotificationType.grooming:
        return (Icons.content_cut_rounded, const Color(0xFF4ECDC4));
      case NotificationType.walk:
        return (Icons.directions_walk_rounded, const Color(0xFF45B7D1));
      case NotificationType.scan:
        return (Icons.document_scanner_rounded, const Color(0xFF45B7D1));
      case NotificationType.appUpdate:
        return (Icons.new_releases_rounded, const Color(0xFF667EEA));
      case NotificationType.welcome:
        return (Icons.pets_rounded, const Color(0xFF4ECDC4));
      case NotificationType.general:
        return (Icons.notifications_rounded, const Color(0xFF667EEA));
      case NotificationType.checkUp:
        return (Icons.local_hospital_rounded, const Color(0xFFFF6B6B));
      case NotificationType.exercise:
        return (Icons.directions_walk_rounded, const Color(0xFF45B7D1));
      case NotificationType.feeding:
        return (Icons.restaurant_rounded, const Color(0xFF26DE81));
      case NotificationType.note:
        return (Icons.note_alt_rounded, const Color(0xFF667EEA));
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final (icon, iconColor) = _iconForType(item.type);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(
                alpha: item.isUnread ? 0.07 : 0.03,
              ),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: IntrinsicHeight(
          child: Row(
            children: [
              // Unread accent bar on the left
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 4,
                decoration: BoxDecoration(
                  color: item.isUnread
                      ? colorScheme.primary
                      : Colors.transparent,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    bottomLeft: Radius.circular(20),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Category icon with unread dot
                      Stack(
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: iconColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Icon(icon, color: iconColor, size: 26),
                          ),
                          if (item.isUnread)
                            Positioned(
                              right: 0,
                              top: 0,
                              child: Container(
                                width: 11,
                                height: 11,
                                decoration: BoxDecoration(
                                  color: colorScheme.error,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(width: 14),

                      // Title + time + message
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Text(
                                    item.title,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: item.isUnread
                                          ? FontWeight.w700
                                          : FontWeight.w600,
                                      color: item.isUnread
                                          ? const Color(0xFF1A1A1A)
                                          : Colors.grey.shade600,
                                      height: 1.3,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: item.isUnread
                                        ? colorScheme.primary.withValues(
                                            alpha: 0.1,
                                          )
                                        : Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    item.timeLabel,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: item.isUnread
                                          ? colorScheme.primary
                                          : Colors.grey.shade400,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              item.message,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade500,
                                height: 1.45,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- Empty State ---
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    colorScheme.primary.withValues(alpha: 0.15),
                    colorScheme.primary.withValues(alpha: 0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.notifications_off_outlined,
                color: colorScheme.primary,
                size: 40,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'All Caught Up!',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D3142),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'No new reminders or updates\nabout your pets.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade400,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
