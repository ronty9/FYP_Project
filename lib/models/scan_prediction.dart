// Copyright © 2026 TY Chew, Jimmy Kee. All rights reserved.
// Licensed under the MIT License. See LICENSE file in the project root.

/// A single label + confidence score returned by the AI model.
class ScanPrediction {
  const ScanPrediction({required this.label, required this.confidence});

  final String label;

  /// Value in [0, 1].
  final double confidence;
}
