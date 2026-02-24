/// A single label + confidence score returned by the AI model.
class ScanPrediction {
  const ScanPrediction({required this.label, required this.confidence});

  final String label;

  /// Value in [0, 1].
  final double confidence;
}
