// Copyright © 2026 TY Chew. All rights reserved.
// Licensed under the MIT License. See LICENSE file in the project root.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../ViewModel/analysis_record_view_model.dart';

class AnalysisRecordListView extends StatelessWidget {
  const AnalysisRecordListView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AnalysisRecordViewModel(),
      child: const _RecordListBody(),
    );
  }
}

class _RecordListBody extends StatelessWidget {
  const _RecordListBody();

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<AnalysisRecordViewModel>();
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Analysis Records', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
      ),
      body: viewModel.records.isEmpty
          ? Center(child: Text('No records found.', style: theme.textTheme.bodyLarge))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: viewModel.records.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final record = viewModel.records[index];
                final isBreed = record.scanType == 'Breed';

                return Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => viewModel.openRecordDetail(context, record),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          // Thumbnail Placeholder
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: const Icon(Icons.image, color: Colors.grey),
                          ),
                          const SizedBox(width: 16),
                          
                          // Info Column
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: isBreed ? Colors.purple.shade50 : Colors.orange.shade50,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        record.scanType,
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: isBreed ? Colors.purple : Colors.orange.shade800,
                                        ),
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      record.date.split(' ')[0], // Show Date only
                                      style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  record.result,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'User: ${record.userName}',
                                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right, color: Colors.grey),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}