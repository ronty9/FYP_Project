// Copyright © 2026 TY Chew. All rights reserved.
// Licensed under the MIT License. See LICENSE file in the project root.

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../ViewModel/custom_camera_view_model.dart';

class CustomCameraView extends StatelessWidget {
  const CustomCameraView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CustomCameraViewModel(),
      child: const _CustomCameraBody(),
    );
  }
}

class _CustomCameraBody extends StatelessWidget {
  const _CustomCameraBody();

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<CustomCameraViewModel>();
    final controller = viewModel.controller;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: Colors.black,
      body: controller == null || !controller.value.isInitialized
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : Stack(
              children: [
                // 1. Camera Preview (Full Screen)
                Center(child: CameraPreview(controller)),

                // 2. Central Guide Box (Crosshair)
                Center(
                  child: Container(
                    width: 250,
                    height: 250,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.5),
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.add, // Simple crosshair center
                        color: Colors.white.withValues(alpha: 0.3),
                        size: 40,
                      ),
                    ),
                  ),
                ),

                // 3. Top Bar (Only Close Button now)
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        // Close Button
                        _CameraCircleButton(
                          icon: Icons.close,
                          onTap: () => viewModel.onCloseCameraPressed(context),
                        ),
                      ],
                    ),
                  ),
                ),

                // 4. Bottom Controls (Capture Paw & Flash)
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    height: 150,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.8),
                          Colors.transparent,
                        ],
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // Placeholder to balance layout
                        const SizedBox(width: 48),

                        // --- Redesigned Capture Button (Paw with White Background) ---
                        GestureDetector(
                          onTap: () => viewModel.capturePhoto(context),
                          child: Container(
                            width: 90,
                            height: 90,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              // Changed color to solid white
                              color: Colors.white,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.2),
                                  blurRadius: 10,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            // Paw Icon
                            child: Center(
                              child: Icon(
                                Icons.pets, // Paw icon
                                color: colorScheme.primary, // App Theme Color
                                size: 50,
                              ),
                            ),
                          ),
                        ),

                        // --- Flash Toggle ---
                        _CameraCircleButton(
                          icon: viewModel.flashMode == FlashMode.off
                              ? Icons.flash_off
                              : Icons.flash_on,
                          color: viewModel.flashMode == FlashMode.off
                              ? Colors.white
                              : Colors.yellowAccent,
                          onTap: viewModel.toggleFlash,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

// --- Helper Widget for Camera Buttons ---
class _CameraCircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color color;

  const _CameraCircleButton({
    required this.icon,
    required this.onTap,
    this.color = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.4),
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Icon(icon, color: color, size: 24),
      ),
    );
  }
}
