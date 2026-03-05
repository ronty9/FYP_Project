import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/pet_info.dart';
import '../ViewModel/pet_gallery_view_model.dart';

class PetGalleryView extends StatelessWidget {
  final PetInfo pet;
  final bool selectionMode;

  const PetGalleryView({
    super.key,
    required this.pet,
    this.selectionMode = false,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => PetGalleryViewModel()..initialize(pet),
      child: _PetGalleryBody(selectionMode: selectionMode),
    );
  }
}

class _PetGalleryBody extends StatelessWidget {
  const _PetGalleryBody({required this.selectionMode});

  final bool selectionMode;

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<PetGalleryViewModel>();
    final pet = viewModel.pet!;
    final allImages = viewModel.allImages;
    final colorScheme = Theme.of(context).colorScheme;

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
              bottom: 20,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  colorScheme.primary,
                  colorScheme.primary.withValues(alpha: 0.8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(32),
                bottomRight: Radius.circular(32),
              ),
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => viewModel.onBackPressed(context),
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
                Expanded(
                  child: Text(
                    selectionMode ? 'Select Photo' : '${pet.name}\'s Gallery',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                if (!selectionMode)
                  GestureDetector(
                    onTap: () => viewModel.showImageSourceDialog(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.add_photo_alternate_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // --- Gallery Grid ---
          Expanded(
            child: allImages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.photo_library_outlined,
                            size: 56,
                            color: Colors.grey.shade300,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'No photos yet',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tap + to add photos',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade400,
                          ),
                        ),
                      ],
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.all(16),
                    child: GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 1,
                          ),
                      itemCount: allImages.length,
                      itemBuilder: (context, index) {
                        final imagePath = allImages[index];
                        final isAsset = pet.galleryImages.contains(imagePath);
                        final isNetwork =
                            imagePath is String && imagePath.startsWith('http');
                        // Check if this is a pending (local file) upload
                        final isPending = !isAsset && !isNetwork;

                        return GestureDetector(
                          onTap: () {
                            if (selectionMode) {
                              if (isNetwork) {
                                Navigator.pop(context, imagePath);
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Select a gallery photo only.',
                                    ),
                                  ),
                                );
                              }
                              return;
                            }

                            viewModel.onImageTapped(index);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => _FullScreenImageView(
                                  imagePath: imagePath,
                                  heroTag: 'gallery_${pet.name}_$index',
                                  isAsset: isAsset,
                                  isNetwork: isNetwork,
                                  onDelete: () => viewModel.deleteImage(
                                    context: context,
                                    imagePath: imagePath,
                                    isAssetImage: isAsset,
                                    isNetworkImage: isNetwork,
                                  ),
                                ),
                              ),
                            );
                          },
                          child: Hero(
                            tag: 'gallery_${pet.name}_$index',
                            child: Stack(
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                    border: isPending
                                        ? Border.all(
                                            color: colorScheme.primary
                                                .withValues(alpha: 0.5),
                                            width: 2.5,
                                          )
                                        : null,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: 0.08,
                                        ),
                                        blurRadius: 12,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(16),
                                    child: isNetwork
                                        ? Image.network(
                                            imagePath,
                                            fit: BoxFit.cover,
                                            width: double.infinity,
                                            height: double.infinity,
                                          )
                                        : isAsset
                                        ? Image.asset(
                                            imagePath,
                                            fit: BoxFit.cover,
                                            width: double.infinity,
                                            height: double.infinity,
                                          )
                                        : Image.file(
                                            File(imagePath),
                                            fit: BoxFit.cover,
                                            width: double.infinity,
                                            height: double.infinity,
                                          ),
                                  ),
                                ),
                                // Pending upload badge
                                if (isPending)
                                  Positioned(
                                    top: 6,
                                    right: 6,
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: colorScheme.primary,
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withValues(
                                              alpha: 0.2,
                                            ),
                                            blurRadius: 4,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: const Icon(
                                        Icons.cloud_upload_rounded,
                                        color: Colors.white,
                                        size: 14,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ),

          // --- Upload Bottom Bar ---
          if (viewModel.hasPendingUploads)
            _UploadBottomBar(viewModel: viewModel),
        ],
      ),
    );
  }
}

// --- Upload Bottom Bar ---
class _UploadBottomBar extends StatelessWidget {
  final PetGalleryViewModel viewModel;

  const _UploadBottomBar({required this.viewModel});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final pendingCount = viewModel.pendingImages.length;

    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 14,
        bottom: MediaQuery.of(context).padding.bottom + 14,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: Row(
        children: [
          // Photo count badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.photo_library_rounded,
                  size: 18,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  '$pendingCount ${pendingCount == 1 ? 'photo' : 'photos'}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          // Upload button
          Expanded(
            child: SizedBox(
              height: 50,
              child: ElevatedButton.icon(
                onPressed: viewModel.isLoading
                    ? null
                    : () => viewModel.confirmUpload(context),
                icon: viewModel.isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.cloud_upload_rounded, size: 20),
                label: Text(
                  viewModel.isLoading ? 'Uploading...' : 'Upload Photos',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: colorScheme.primary.withValues(
                    alpha: 0.6,
                  ),
                  disabledForegroundColor: Colors.white70,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// --- Full Screen Image View ---
class _FullScreenImageView extends StatelessWidget {
  final dynamic imagePath;
  final String heroTag;
  final bool isAsset;
  final bool isNetwork;
  final VoidCallback onDelete;

  const _FullScreenImageView({
    required this.imagePath,
    required this.heroTag,
    required this.isAsset,
    required this.isNetwork,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
      body: Center(
        child: Hero(
          tag: heroTag,
          child: InteractiveViewer(
            minScale: 0.5,
            maxScale: 4.0,
            child: isNetwork
                ? Image.network(imagePath, fit: BoxFit.contain)
                : isAsset
                ? Image.asset(imagePath, fit: BoxFit.contain)
                : Image.file(File(imagePath), fit: BoxFit.contain),
          ),
        ),
      ),
    );
  }
}
