import 'dart:convert';
import 'dart:io';

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../models/scan_prediction.dart';

// ---------------------------------------------------------------------------
// Result Classes
// ---------------------------------------------------------------------------

/// Result record returned by [AiService.predictBreed].
class BreedPredictionResult {
  const BreedPredictionResult({
    required this.species,
    required this.breedPredictions,
  });

  /// Detected species: "cat" or "dog".
  final String species;

  /// Top-5 breed predictions, sorted by confidence descending.
  final List<ScanPrediction> breedPredictions;
}

/// Result record returned by [AiService.predictDisease].
class DiseasePredictionResult {
  const DiseasePredictionResult({
    required this.species,
    required this.diseasePredictions,
  });

  /// Detected species: "cat" or "dog".
  final String species;

  /// Top disease predictions, sorted by confidence descending.
  final List<ScanPrediction> diseasePredictions;
}

// ---------------------------------------------------------------------------
// Service Class
// ---------------------------------------------------------------------------

/// Calls the local FastAPI backend to run the two-stage inference pipelines.
class AiService {
  AiService._();

  // ── Base URL ─────────────────────────────────────────────────────────────
  // Android emulator  → 10.0.2.2  (maps to host's 127.0.0.1)
  // iOS simulator     → 127.0.0.1
  // Physical device   → your computer's local-network IP, e.g. 192.168.1.100
  static String baseUrl = 'http://172.22.6.11:8000';

  // ── 1. BREED PREDICTION ──────────────────────────────────────────────────

  /// Send [imageFile] to the backend and return species + breed predictions.
  /// Throws an [Exception] on network error or non-200 response.
  static Future<BreedPredictionResult> predictBreed(File imageFile) async {
    final uri = Uri.parse('$baseUrl/predict');
    final streamedResponse = await _sendMultipartRequest(uri, imageFile);
    final body = await streamedResponse.stream.bytesToString();

    if (streamedResponse.statusCode != 200) {
      throw Exception('Backend returned ${streamedResponse.statusCode}: $body');
    }

    final json = jsonDecode(body) as Map<String, dynamic>;

    final species =
        (json['species'] as Map<String, dynamic>)['label'] as String;

    final breedPredictions = (json['breed_predictions'] as List<dynamic>).map((
      e,
    ) {
      final map = e as Map<String, dynamic>;
      return ScanPrediction(
        label: _formatLabel(map['label'] as String),
        confidence: (map['confidence'] as num).toDouble(),
      );
    }).toList();

    return BreedPredictionResult(
      species: species,
      breedPredictions: breedPredictions,
    );
  }

  // ── 2. SKIN DISEASE PREDICTION ───────────────────────────────────────────

  /// Send [imageFile] to the backend and return species + skin disease predictions.
  /// Throws an [Exception] on network error or non-200 response.
  static Future<DiseasePredictionResult> predictDisease(File imageFile) async {
    final uri = Uri.parse('$baseUrl/predict-disease');
    final streamedResponse = await _sendMultipartRequest(uri, imageFile);
    final body = await streamedResponse.stream.bytesToString();

    if (streamedResponse.statusCode != 200) {
      throw Exception('Backend returned ${streamedResponse.statusCode}: $body');
    }

    final json = jsonDecode(body) as Map<String, dynamic>;

    final species =
        (json['species'] as Map<String, dynamic>)['label'] as String;

    // Map the disease results
    final diseasePredictions = (json['disease_predictions'] as List<dynamic>)
        .map((e) {
          final map = e as Map<String, dynamic>;
          return ScanPrediction(
            label: _formatLabel(map['label'] as String),
            confidence: (map['confidence'] as num).toDouble(),
          );
        })
        .toList();

    return DiseasePredictionResult(
      species: species,
      diseasePredictions: diseasePredictions,
    );
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  /// Helper to compress and send the HTTP Multipart request.
  static Future<http.StreamedResponse> _sendMultipartRequest(
    Uri uri,
    File imageFile,
  ) async {
    final compressedBytes = await _compressImage(imageFile);

    final request = http.MultipartRequest('POST', uri)
      ..files.add(
        http.MultipartFile.fromBytes(
          'file',
          compressedBytes,
          filename: 'image.jpg',
          contentType: MediaType('image', 'jpeg'),
        ),
      );

    try {
      return await request.send().timeout(const Duration(seconds: 60));
    } on SocketException catch (e) {
      throw Exception(
        'Cannot reach the AI server at $baseUrl. '
        'Make sure your phone and computer are on the same Wi-Fi network. '
        'Details: $e',
      );
    } on http.ClientException catch (e) {
      throw Exception(
        'Network error while contacting the AI server. '
        'Details: $e',
      );
    }
  }

  /// Converts "golden_retriever" → "Golden Retriever".
  static String _formatLabel(String raw) => raw
      .split('_')
      .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
      .join(' ');

  /// Resize and JPEG-compress the image before uploading.
  static Future<List<int>> _compressImage(File file) async {
    final result = await FlutterImageCompress.compressWithFile(
      file.absolute.path,
      minWidth: 600,
      minHeight: 600,
      quality: 85,
      format: CompressFormat.jpeg,
    );
    // Fall back to original bytes if compression fails.
    return result ?? await file.readAsBytes();
  }
}
