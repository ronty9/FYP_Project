import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'base_view_model.dart';
import '../models/pet_info.dart';

class PetGalleryViewModel extends BaseViewModel {
  final ImagePicker _picker = ImagePicker();
  final List<String> _uploadedImages = [];
  final Set<String> _removedRemoteUrls = {};
  final List<File> _pendingUploads = [];
  PetInfo? _pet;

  List<String> get uploadedImages => List.unmodifiable(_uploadedImages);
  PetInfo? get pet => _pet;
  List<File> get pendingUploads => List.unmodifiable(_pendingUploads);
  bool get hasPendingUploads => _pendingUploads.isNotEmpty;
  List<String> get pendingImages => _pendingUploads.map((f) => f.path).toList();

  List<dynamic> get allImages {
    final images = <String>[];
    final pet = _pet;
    if (pet != null) {
      images.addAll(
        pet.galleryImages.where((path) => !_removedRemoteUrls.contains(path)),
      );
      images.addAll(
        pet.photoUrls.where((url) => !_removedRemoteUrls.contains(url)),
      );
    }
    images.addAll(
      _uploadedImages.where((url) => !_removedRemoteUrls.contains(url)),
    );
    // Add pending (not-yet-uploaded) local file paths
    images.addAll(_pendingUploads.map((f) => f.path));
    return images;
  }

  void initialize(PetInfo pet) {
    _pet = pet;
    notifyListeners();
  }

  void onBackPressed(BuildContext context) {
    Navigator.pop(context);
  }

  int? _lastTappedIndex;
  int? get lastTappedIndex => _lastTappedIndex;

  void onImageTapped(int index) {
    _lastTappedIndex = index;
    notifyListeners();
  }

  Future<void> pickGalleryImages(BuildContext context) async {
    setLoading(true);
    try {
      final images = await _picker.pickMultiImage(
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );

      if (images.isNotEmpty) {
        _pendingUploads
          ..clear()
          ..addAll(images.map((image) => File(image.path)));
        notifyListeners();
      }
    } catch (e) {
      setError('Failed to pick images: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setLoading(false);
    }
  }

  Future<void> pickCameraImage(BuildContext context) async {
    setLoading(true);
    try {
      final image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );

      if (image != null) {
        _pendingUploads
          ..clear()
          ..add(File(image.path));
        notifyListeners();
      }
    } catch (e) {
      setError('Failed to take photo: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setLoading(false);
    }
  }

  Future<void> confirmUpload(BuildContext context) async {
    if (_pendingUploads.isEmpty) return;
    setLoading(true);
    try {
      final pet = _pet;
      if (pet == null || pet.id == null) {
        throw Exception('Pet not found for upload.');
      }
      final authUid = FirebaseAuth.instance.currentUser?.uid;
      if (authUid == null) {
        throw Exception('User not authenticated for photo upload.');
      }

      final List<String> uploadedUrls = [];
      for (final file in _pendingUploads) {
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('pets')
            .child(authUid)
            .child(pet.id!)
            .child('gallery_${DateTime.now().millisecondsSinceEpoch}.jpg');

        final uploadTask = storageRef.putFile(file);
        await uploadTask.timeout(const Duration(seconds: 60));
        final url = await storageRef.getDownloadURL().timeout(
          const Duration(seconds: 10),
        );
        uploadedUrls.add(url);
      }

      try {
        await FirebaseFirestore.instance.collection('pet').doc(pet.id).update({
          'photoUrls': FieldValue.arrayUnion(uploadedUrls),
        });
      } on FirebaseException catch (error) {
        throw Exception('Firestore update failed: ${error.code}');
      }

      _uploadedImages.addAll(uploadedUrls);
      _pendingUploads.clear();
      notifyListeners();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Photos uploaded successfully!'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } on FirebaseException catch (error) {
      setError('Upload failed: ${error.code}');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload failed: ${error.code}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } on TimeoutException {
      setError('Upload timed out. Please try again.');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Upload timed out. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setError('Upload failed: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setLoading(false);
    }
  }

  void showImageSourceDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Add Photos',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 24),
            _buildSourceOption(
              context: ctx,
              icon: Icons.photo_library_outlined,
              label: 'Choose from Gallery',
              color: const Color(0xFF7165E3),
              onTap: () {
                Navigator.pop(ctx);
                pickGalleryImages(context);
              },
            ),
            const SizedBox(height: 12),
            _buildSourceOption(
              context: ctx,
              icon: Icons.camera_alt_outlined,
              label: 'Take a Photo',
              color: const Color(0xFFFF9F59),
              onTap: () {
                Navigator.pop(ctx);
                pickCameraImage(context);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSourceOption({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 16),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void deleteImage({
    required BuildContext context,
    required String imagePath,
    required bool isAssetImage,
    required bool isNetworkImage,
  }) {
    if (isAssetImage) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Built-in photos cannot be deleted.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.delete_outline, color: Colors.red),
            SizedBox(width: 8),
            Text('Delete Photo'),
          ],
        ),
        content: const Text('Are you sure you want to delete this photo?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              setLoading(true);
              try {
                if (isNetworkImage) {
                  final pet = _pet;
                  if (pet == null || pet.id == null) {
                    throw Exception('Pet not found for deletion.');
                  }
                  final ref = FirebaseStorage.instance.refFromURL(imagePath);
                  await ref.delete();
                  await FirebaseFirestore.instance
                      .collection('pet')
                      .doc(pet.id)
                      .update({
                        'photoUrls': FieldValue.arrayRemove([imagePath]),
                      });
                  _removedRemoteUrls.add(imagePath);
                } else {
                  _uploadedImages.remove(imagePath);
                }

                notifyListeners();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Photo deleted successfully'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              } on FirebaseException catch (error) {
                setError('Delete failed: ${error.code}');
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Delete failed: ${error.code}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              } catch (e) {
                setError('Delete failed: $e');
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Delete failed: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              } finally {
                setLoading(false);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
