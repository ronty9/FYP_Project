// Copyright © 2026 TY Chew, Jimmy Kee. All rights reserved.
// Licensed under the MIT License. See LICENSE file in the project root.

import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'base_view_model.dart';

class CustomCameraViewModel extends BaseViewModel {
  CustomCameraViewModel() {
    _initCamera();
  }

  CameraController? _controller;
  Future<void>? _initializeFuture;
  FlashMode _flashMode = FlashMode.off; // Track flash state

  CameraController? get controller => _controller;
  Future<void>? get initializeFuture => _initializeFuture;
  FlashMode get flashMode => _flashMode;

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      // Prefer back camera
      final camera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      _controller = CameraController(
        camera,
        ResolutionPreset.high, // Better resolution for pet photos
        enableAudio: false,
      );

      _initializeFuture = _controller!.initialize();
      await _initializeFuture;

      // Set initial flash mode
      await _controller!.setFlashMode(_flashMode);

      notifyListeners();
    } catch (error) {
      setError('Unable to access camera: $error');
    }
  }

  // --- Toggle Flash Logic ---
  Future<void> toggleFlash() async {
    if (_controller == null) return;

    try {
      if (_flashMode == FlashMode.off) {
        _flashMode = FlashMode.torch; // Use torch for better lighting preview
      } else {
        _flashMode = FlashMode.off;
      }

      await _controller!.setFlashMode(_flashMode);
      notifyListeners();
    } catch (e) {
      debugPrint('Error toggling flash: $e');
    }
  }

  Future<void> capturePhoto(BuildContext context) async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      return;
    }

    try {
      // Capture
      final XFile shot = await controller.takePicture();

      // Turn off flash if it was on (optional UX choice)
      if (_flashMode != FlashMode.off) {
        _flashMode = FlashMode.off;
        await controller.setFlashMode(FlashMode.off);
      }

      if (!context.mounted) return;
      Navigator.pop(context, File(shot.path));
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to capture photo. Please retry.')),
      );
    }
  }

  void onCloseCameraPressed(BuildContext context) {
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }
}
