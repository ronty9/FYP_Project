// Copyright © 2026 TY Chew, Jimmy Kee. All rights reserved.
// Licensed under the MIT License. See LICENSE file in the project root.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../View/custom_camera_view.dart';
import '../View/scan_history_view.dart';
import '../View/scan_result_view.dart';
import '../scan_type.dart';
import 'base_view_model.dart';

class ScanViewModel extends BaseViewModel {
  final ImagePicker _picker = ImagePicker();

  File? _selectedImage;
  ScanType _scanType = ScanType.skinDisease;

  File? get selectedImage => _selectedImage;
  ScanType get scanType => _scanType;

  void clearSelectedImage() {
    if (_selectedImage == null) {
      return;
    }
    _selectedImage = null;
    notifyListeners();
  }

  void selectScanType(ScanType type) {
    if (_scanType == type) {
      return;
    }
    _scanType = type;
    notifyListeners();
  }

  void onHistoryPressed(BuildContext context) {
    goToHistory(context);
  }

  Future<void> pickFromGallery() async {
    final XFile? picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked == null) {
      return;
    }
    _selectedImage = File(picked.path);
    notifyListeners();
  }

  Future<void> pickFromCamera(BuildContext context) async {
    final File? photo = await Navigator.push<File?>(
      context,
      MaterialPageRoute(builder: (_) => const CustomCameraView()),
    );
    if (photo == null) {
      return;
    }
    _selectedImage = photo;
    notifyListeners();
  }

  void goToHistory(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ScanHistoryView()),
    );
  }

  void onAnalysePressed(BuildContext context) {
    analyse(context);
  }

  void analyse(BuildContext context) {
    final image = _selectedImage;
    if (image == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select or capture an image first.'),
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ScanResultView(scanType: _scanType, imageFile: image),
      ),
    );
  }
}
