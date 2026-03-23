// Copyright © 2026 TY Chew. All rights reserved.
// Licensed under the MIT License. See LICENSE file in the project root.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../ViewModel/admin_manage_community_tips_view_model.dart';

class AdminManageCommunityTipsView extends StatelessWidget {
  const AdminManageCommunityTipsView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AdminManageCommunityTipsViewModel(),
      child: const _ManageCommunityTipsContent(),
    );
  }
}

class _ManageCommunityTipsContent extends StatelessWidget {
  const _ManageCommunityTipsContent();

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<AdminManageCommunityTipsViewModel>();

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
                  const Color(0xFF9C27B0),
                  const Color(0xFF9C27B0).withValues(alpha: 0.8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(32),
                bottomRight: Radius.circular(32),
              ),
            ),
            child: Column(
              children: [
                Row(
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
                      'Manage Community Tips',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const Spacer(),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.local_library_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Educational Content',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${viewModel.tips.length} tips published',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // --- Content ---
          Expanded(
            child: viewModel.isLoading
                ? const Center(child: CircularProgressIndicator())
                : viewModel.tips.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.local_library_outlined,
                          size: 64,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No tips added yet',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade500,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tap + to create your first tip',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade400,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: viewModel.tips.length,
                    itemBuilder: (context, index) {
                      final tip = viewModel.tips[index];
                      return _TipCard(
                        tip: tip,
                        onEdit: () => _showTipDialog(
                          context,
                          viewModel,
                          existingTip: tip,
                        ),
                        onDelete: () => _confirmDelete(context, viewModel, tip),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showTipDialog(context, viewModel),
        backgroundColor: const Color(0xFF9C27B0),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Add Tip',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  // --- Confirm Delete Dialog ---
  void _confirmDelete(
    BuildContext context,
    AdminManageCommunityTipsViewModel viewModel,
    CommunityTip tip,
  ) {
    showDialog(
      context: context,
      useRootNavigator: true,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.delete_outline_rounded,
                color: Colors.red,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Text('Delete Tip'),
          ],
        ),
        content: Text(
          'Are you sure you want to delete "${tip.title}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop(); // Close Alert
              viewModel.deleteTip(context, tip.id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  // --- Add/Edit Bottom Sheet ---
  void _showTipDialog(
    BuildContext context,
    AdminManageCommunityTipsViewModel viewModel, {
    CommunityTip? existingTip,
  }) {
    final isEditing = existingTip != null;
    final titleController = TextEditingController(
      text: existingTip?.title ?? '',
    );
    final descriptionController = TextEditingController(
      text: existingTip?.description ?? '',
    );

    // Categories
    final categories = [
      'Hydration',
      'Exercise',
      'Health Check',
      'Grooming',
      'Nutrition',
      'Safety',
      'Training',
      'General',
    ];

    // Colors mapping
    final categoryColors = {
      'Hydration': const Color(0xFF00ACC1),
      'Exercise': const Color(0xFFFF9800),
      'Health Check': const Color(0xFFE91E63),
      'Grooming': const Color(0xFF9C27B0),
      'Nutrition': const Color(0xFF4CAF50),
      'Safety': const Color(0xFFF44336),
      'Training': const Color(0xFF3F51B5),
      'General': const Color(0xFF607D8B),
    };

    final categoryIcons = {
      'Hydration': Icons.water_drop_rounded,
      'Exercise': Icons.directions_run_rounded,
      'Health Check': Icons.health_and_safety_rounded,
      'Grooming': Icons.content_cut_rounded,
      'Nutrition': Icons.restaurant_rounded,
      'Safety': Icons.shield_rounded,
      'Training': Icons.psychology_rounded,
      'General': Icons.lightbulb_rounded,
    };

    String selectedCategory = existingTip?.category ?? categories.first;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          final selectedColor =
              categoryColors[selectedCategory] ?? const Color(0xFF9C27B0);
          final selectedIcon =
              categoryIcons[selectedCategory] ?? Icons.lightbulb_rounded;

          return GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            child: Container(
              margin: const EdgeInsets.only(top: 12),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // --- Header ---
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            selectedColor,
                            selectedColor.withValues(alpha: 0.8),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(28),
                          topRight: Radius.circular(28),
                        ),
                      ),
                      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                      child: Column(
                        children: [
                          // Drag handle
                          Container(
                            width: 40,
                            height: 4,
                            margin: const EdgeInsets.only(bottom: 20),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.4),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.25),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Icon(
                                  selectedIcon,
                                  color: Colors.white,
                                  size: 28,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      isEditing ? 'Edit Tip' : 'Add New Tip',
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      isEditing
                                          ? 'Update your community tip'
                                          : 'Share helpful advice',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.white.withValues(
                                          alpha: 0.85,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // --- Form Content ---
                    Padding(
                      padding: EdgeInsets.only(
                        left: 24,
                        right: 24,
                        top: 24,
                        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Category Dropdown
                          const Text(
                            'Category',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            decoration: BoxDecoration(
                              color: selectedColor.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: selectedColor.withValues(alpha: 0.3),
                                width: 1.5,
                              ),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: selectedCategory,
                                isExpanded: true,
                                icon: Padding(
                                  padding: const EdgeInsets.only(right: 16),
                                  child: Icon(
                                    Icons.keyboard_arrow_down_rounded,
                                    color: selectedColor,
                                  ),
                                ),
                                borderRadius: BorderRadius.circular(16),
                                items: categories.map((cat) {
                                  final color =
                                      categoryColors[cat] ??
                                      const Color(0xFF9C27B0);
                                  final icon =
                                      categoryIcons[cat] ??
                                      Icons.lightbulb_rounded;
                                  return DropdownMenuItem<String>(
                                    value: cat,
                                    child: Row(
                                      children: [
                                        const SizedBox(width: 12),
                                        Icon(icon, color: color, size: 18),
                                        const SizedBox(width: 12),
                                        Text(
                                          cat,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                                onChanged: (newValue) {
                                  if (newValue != null) {
                                    setState(() => selectedCategory = newValue);
                                  }
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          // Title Input
                          const Text(
                            'Title',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 10),
                          _buildTextField(
                            titleController,
                            'Enter tip title...',
                            Icons.title_rounded,
                          ),
                          const SizedBox(height: 20),
                          // Description Input
                          const Text(
                            'Description',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 10),
                          _buildTextField(
                            descriptionController,
                            'Share your helpful tip...',
                            Icons.description_outlined,
                            maxLines: 4,
                          ),
                          const SizedBox(height: 28),
                          // Buttons
                          Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => Navigator.pop(ctx),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: const Center(
                                      child: Text(
                                        'Cancel',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                flex: 2,
                                child: GestureDetector(
                                  onTap: () {
                                    if (isEditing) {
                                      viewModel.updateTip(
                                        context,
                                        existingTip.id,
                                        selectedCategory,
                                        titleController.text.trim(),
                                        descriptionController.text.trim(),
                                      );
                                    } else {
                                      viewModel.addTip(
                                        context,
                                        selectedCategory,
                                        titleController.text.trim(),
                                        descriptionController.text.trim(),
                                      );
                                    }
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          selectedColor,
                                          selectedColor.withValues(alpha: 0.8),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: [
                                        BoxShadow(
                                          color: selectedColor.withValues(
                                            alpha: 0.3,
                                          ),
                                          blurRadius: 12,
                                          offset: const Offset(0, 6),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          isEditing
                                              ? Icons.check_rounded
                                              : Icons.add_rounded,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          isEditing
                                              ? 'Save Changes'
                                              : 'Add Tip',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String hint,
    IconData icon, {
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(16),
          prefixIcon: Padding(
            padding: EdgeInsets.only(
              left: 12,
              right: 8,
              bottom: maxLines > 1 ? 60 : 0,
            ),
            child: Icon(icon, color: Colors.grey.shade400, size: 22),
          ),
        ),
      ),
    );
  }
}

// --- Card Widget ---
class _TipCard extends StatelessWidget {
  final CommunityTip tip;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _TipCard({
    required this.tip,
    required this.onEdit,
    required this.onDelete,
  });

  Color _getCategoryColor(String category) {
    const colors = {
      'Hydration': Color(0xFF00ACC1),
      'Exercise': Color(0xFFFF9800),
      'Health Check': Color(0xFFE91E63),
      'Grooming': Color(0xFF9C27B0),
      'Nutrition': Color(0xFF4CAF50),
      'Safety': Color(0xFFF44336),
      'Training': Color(0xFF3F51B5),
      'General': Color(0xFF607D8B),
    };
    return colors[category] ?? const Color(0xFF9C27B0);
  }

  IconData _getCategoryIcon(String category) {
    const icons = {
      'Hydration': Icons.water_drop_rounded,
      'Exercise': Icons.directions_run_rounded,
      'Health Check': Icons.health_and_safety_rounded,
      'Grooming': Icons.content_cut_rounded,
      'Nutrition': Icons.restaurant_rounded,
      'Safety': Icons.shield_rounded,
      'Training': Icons.psychology_rounded,
      'General': Icons.lightbulb_rounded,
    };
    return icons[category] ?? Icons.lightbulb_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final categoryColor = _getCategoryColor(tip.category);
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: categoryColor.withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  categoryColor.withValues(alpha: 0.15),
                  categoryColor.withValues(alpha: 0.05),
                ],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getCategoryIcon(tip.category),
                    color: categoryColor,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          tip.category,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: categoryColor,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        tip.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2D3142),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tip.description,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade700,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: onEdit,
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      label: const Text('Edit'),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF667EEA),
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      onPressed: onDelete,
                      icon: const Icon(Icons.delete_outline, size: 18),
                      label: const Text('Delete'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.red.shade400,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
