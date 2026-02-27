import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../ViewModel/activity_log_view_model.dart';

class ActivityLogView extends StatelessWidget {
  const ActivityLogView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ActivityLogViewModel(),
      child: const _ActivityLogContent(),
    );
  }
}

class _ActivityLogContent extends StatelessWidget {
  const _ActivityLogContent();

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<ActivityLogViewModel>();
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Color(0xFF1A1A1A),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Activity Log',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: Color(0xFF1A1A1A),
            fontSize: 20,
          ),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- Filter Section ---
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 10, 24, 16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: viewModel.filters.map((filter) {
                  final isSelected = viewModel.selectedFilter == filter;
                  return Padding(
                    padding: const EdgeInsets.only(right: 10.0),
                    child: ChoiceChip(
                      label: Text(
                        filter,
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : Colors.grey.shade700,
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                      ),
                      selected: isSelected,
                      selectedColor: colorScheme.primary,
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color: isSelected
                              ? colorScheme.primary
                              : Colors.grey.shade300,
                        ),
                      ),
                      onSelected: (_) => viewModel.setFilter(filter),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // --- List Section ---
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              // UPDATED: Now uses List<DocumentSnapshot> instead of QuerySnapshot
              child: StreamBuilder<List<DocumentSnapshot>>(
                stream: viewModel.activityStream,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Center(child: Text('Error loading logs'));
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(
                      child: Text('No activity found for this filter.'),
                    );
                  }

                  final logs = snapshot.data!;

                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    itemCount: logs.length,
                    separatorBuilder: (_, __) =>
                        Divider(height: 1, color: Colors.grey.shade100),
                    itemBuilder: (context, index) {
                      final log = logs[index].data() as Map<String, dynamic>;

                      final timestamp = log['timestamp'] as Timestamp?;
                      final timeStr = _formatTimestamp(timestamp);

                      Color dotColor = const Color(0xFF6C63FF);
                      final type = log['type']?.toString() ?? 'INFO';
                      if (type == 'WARNING') dotColor = const Color(0xFFFF7043);
                      if (type == 'CRITICAL') dotColor = Colors.red;

                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              margin: const EdgeInsets.only(top: 5),
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: dotColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                log['description'] ?? 'Unknown activity',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF333333),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              timeStr,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade400,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return '';
    final now = DateTime.now();
    final date = timestamp.toDate();
    final diff = now.difference(date);

    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
