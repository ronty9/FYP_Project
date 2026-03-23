// Copyright © 2026 TY Chew. All rights reserved.
// Licensed under the MIT License. See LICENSE file in the project root.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../ViewModel/analysis_record_view_model.dart'; // Import to access AnalysisRecord class

class AnalysisRecordDetailView extends StatelessWidget {
  const AnalysisRecordDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    // Capture the record passed from the list
    final record = ModalRoute.of(context)!.settings.arguments as AnalysisRecord;

    // We reuse the same ViewModel logic for deletion
    return ChangeNotifierProvider(
      create: (_) => AnalysisRecordViewModel(),
      child: _DetailBody(record: record),
    );
  }
}

class _DetailBody extends StatelessWidget {
  final AnalysisRecord record;

  const _DetailBody({required this.record});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.read<AnalysisRecordViewModel>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Record Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: () {
              viewModel.deleteRecord(context, record);
              // In a real app, after delete, we'd probably pop:
              // Navigator.pop(context);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. The Scanned Image Area
            Container(
              width: double.infinity,
              height: 250,
              color: Colors.grey.shade300,
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.pets, size: 64, color: Colors.white),
                    SizedBox(height: 8),
                    Text(
                      'Original Scanned Image',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 2. Result Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'AI Prediction',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: Colors.grey,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          record.scanType,
                          style: TextStyle(
                            color: theme.colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    record.result,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: Colors.black,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // 3. Confidence Meter
                  Text('Confidence Score', style: theme.textTheme.labelMedium),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: record.confidence,
                            minHeight: 12,
                            backgroundColor: Colors.grey.shade200,
                            color: record.confidence > 0.8
                                ? Colors.green
                                : (record.confidence > 0.5
                                      ? Colors.orange
                                      : Colors.red),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        '${(record.confidence * 100).toInt()}%',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),
                  const Divider(),
                  const SizedBox(height: 16),

                  // 4. User Information
                  _InfoRow(
                    icon: Icons.person_outline,
                    label: 'User',
                    value: record.userName,
                  ),
                  const SizedBox(height: 16),
                  _InfoRow(
                    icon: Icons.email_outlined,
                    label: 'Email',
                    value: record.userEmail,
                  ),
                  const SizedBox(height: 16),
                  _InfoRow(
                    icon: Icons.calendar_today_outlined,
                    label: 'Date',
                    value: record.date,
                  ),
                  const SizedBox(height: 16),
                  _InfoRow(
                    icon: Icons.tag,
                    label: 'Record ID',
                    value: record.id,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey.shade500),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            Text(
              value,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ],
    );
  }
}
