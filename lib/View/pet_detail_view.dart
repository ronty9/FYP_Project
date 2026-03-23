// Copyright © 2026 TY Chew, Jimmy Kee. All rights reserved.
// Licensed under the MIT License. See LICENSE file in the project root.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../ViewModel/pet_detail_view_model.dart';
import '../models/pet_info.dart';

class PetDetailView extends StatelessWidget {
  const PetDetailView({super.key, required this.pet});

  final PetInfo pet;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => PetDetailViewModel(pet),
      child: const _PetDetailBody(),
    );
  }
}

class _PetDetailBody extends StatefulWidget {
  const _PetDetailBody();

  @override
  State<_PetDetailBody> createState() => _PetDetailBodyState();
}

class _PetDetailBodyState extends State<_PetDetailBody> {
  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<PetDetailViewModel>();
    final pet = viewModel.pet;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final bool isDog = viewModel.isDog;

    // --- Image Logic ---
    String? petImagePath;
    if (pet.name == 'Milo') {
      petImagePath = 'images/assets/shiba.jpeg';
    } else if (pet.name == 'Luna') {
      petImagePath = 'images/assets/british_sh.jpeg';
    } else if (pet.name == 'Coco') {
      petImagePath = 'images/assets/poodle.jpeg';
    }
    final String? petPhotoUrl = pet.photoUrl?.trim();
    final bool hasRemotePhoto = petPhotoUrl != null && petPhotoUrl.isNotEmpty;
    final List<String> allGalleryImages = [
      ...pet.galleryImages,
      ...pet.photoUrls,
    ];

    // Gender logic
    final bool isFemale =
        pet.gender?.toLowerCase() == 'female' ||
        pet.gender?.toLowerCase() == 'f';

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
              bottom: 28,
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
            child: Column(
              children: [
                Row(
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
                    const Text(
                      'Pet Profile',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => viewModel.onEditPressed(context),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.edit_outlined,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Pet avatar + name in header
                Row(
                  children: [
                    Hero(
                      tag: 'pet_${pet.name}',
                      child: Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.5),
                            width: 3,
                          ),
                          image: hasRemotePhoto
                              ? DecorationImage(
                                  image: NetworkImage(petPhotoUrl),
                                  fit: BoxFit.cover,
                                )
                              : petImagePath != null
                              ? DecorationImage(
                                  image: AssetImage(petImagePath),
                                  fit: BoxFit.cover,
                                )
                              : null,
                          color: Colors.white.withValues(alpha: 0.2),
                        ),
                        child: !hasRemotePhoto && petImagePath == null
                            ? Icon(
                                isDog ? Icons.pets : Icons.pets_outlined,
                                size: 36,
                                color: Colors.white.withValues(alpha: 0.7),
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            pet.name,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${pet.species} • ${pet.breed}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withValues(alpha: 0.85),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Gender badge
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        isFemale ? Icons.female : Icons.male,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // --- Scrollable Content ---
          Expanded(
            child: RefreshIndicator(
              onRefresh: viewModel.refreshPet,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- Stats Card (Age | Weight) ---
                    _InfoCard(
                      child: IntrinsicHeight(
                        child: Row(
                          children: [
                            Expanded(
                              child: _StatColumn(
                                icon: Icons.cake_rounded,
                                label: 'Age',
                                value: pet.age,
                                color: colorScheme.primary,
                              ),
                            ),
                            Container(width: 1, color: Colors.grey.shade200),
                            Expanded(
                              child: _StatColumn(
                                icon: Icons.monitor_weight_rounded,
                                label: 'Weight',
                                value: pet.weightKg != null
                                    ? '${pet.weightKg!.toStringAsFixed(1)} kg'
                                    : 'Not set',
                                color: const Color(0xFF4ECDC4),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // --- Photo Gallery ---
                    _SectionHeader(
                      title: 'Photo Gallery',
                      icon: Icons.photo_library_rounded,
                      trailing: GestureDetector(
                        onTap: () => viewModel.onViewGalleryPressed(context),
                        child: Text(
                          allGalleryImages.isEmpty ? 'Add photos' : 'See all',
                          style: TextStyle(
                            fontSize: 13,
                            color: colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (allGalleryImages.isEmpty)
                      _InfoCard(
                        child: Row(
                          children: [
                            _IconBox(
                              icon: Icons.photo_library_outlined,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                'No photos yet. Tap Add photos to upload.',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      SizedBox(
                        height: 100,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: allGalleryImages.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(width: 12),
                          itemBuilder: (context, index) {
                            final imagePath = allGalleryImages[index];
                            final isNetwork = imagePath.startsWith('http');
                            return Container(
                              width: 100,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                image: DecorationImage(
                                  image: isNetwork
                                      ? NetworkImage(imagePath)
                                      : AssetImage(imagePath) as ImageProvider,
                                  fit: BoxFit.cover,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.05),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    const SizedBox(height: 24),

                    // --- Health Overview ---
                    _SectionHeader(
                      title: 'Health Overview',
                      icon: Icons.favorite_rounded,
                    ),
                    const SizedBox(height: 12),

                    // Next Schedule Tile
                    _NextScheduleTile(viewModel: viewModel),
                    const SizedBox(height: 12),

                    // Notes Tile
                    _NotesTile(viewModel: viewModel),

                    const SizedBox(height: 32),

                    // --- Remove Button ---
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: OutlinedButton.icon(
                        onPressed: () =>
                            viewModel.onConfirmRemovalPressed(context),
                        icon: Icon(
                          Icons.delete_outline_rounded,
                          color: Colors.red.shade500,
                        ),
                        label: Text(
                          'Remove Pet',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.red.shade500,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.red.shade200),
                          backgroundColor: Colors.red.shade50,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// --- Section Header ---
class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget? trailing;

  const _SectionHeader({
    required this.title,
    required this.icon,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: const Color(0xFF2D3142)),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: const Color(0xFF2D3142),
          ),
        ),
        const Spacer(),
        if (trailing != null) trailing!,
      ],
    );
  }
}

// --- Info Card Container ---
class _InfoCard extends StatelessWidget {
  final Widget child;

  const _InfoCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

// --- Icon Box ---
class _IconBox extends StatelessWidget {
  final IconData icon;
  final Color color;

  const _IconBox({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(icon, color: color, size: 22),
    );
  }
}

// --- Stat Column ---
class _StatColumn extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatColumn({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 22, color: color),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1A1A1A),
          ),
        ),
      ],
    );
  }
}

// --- Next Schedule Tile ---
class _NextScheduleTile extends StatelessWidget {
  final PetDetailViewModel viewModel;

  const _NextScheduleTile({required this.viewModel});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final hasEvent = viewModel.nextScheduleEvent != null;
    final scheduleType = viewModel.nextScheduleEvent?.scheduleType;

    return GestureDetector(
      onTap: hasEvent ? () => viewModel.navigateToSchedule(context) : null,
      child: _InfoCard(
        child: Row(
          children: [
            _IconBox(
              icon: hasEvent
                  ? (scheduleType?.icon ?? Icons.calendar_today_rounded)
                  : Icons.calendar_today_rounded,
              color: hasEvent
                  ? (scheduleType?.color ?? colorScheme.primary)
                  : colorScheme.primary,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Next Schedule',
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                  const SizedBox(height: 4),
                  viewModel.isLoadingSchedule
                      ? SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: colorScheme.primary,
                          ),
                        )
                      : Text(
                          viewModel.nextScheduleLabel,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: hasEvent
                                ? const Color(0xFF1A1A1A)
                                : Colors.grey.shade500,
                          ),
                        ),
                ],
              ),
            ),
            if (hasEvent)
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: colorScheme.primary,
                ),
              )
            else
              Icon(Icons.event_busy_rounded, color: Colors.grey.shade300),
          ],
        ),
      ),
    );
  }
}

// --- Notes Tile ---
class _NotesTile extends StatelessWidget {
  final PetDetailViewModel viewModel;

  const _NotesTile({required this.viewModel});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final hasNotes = viewModel.notes.isNotEmpty;

    return GestureDetector(
      onTap: () => _showNotesEditor(context, viewModel),
      child: _InfoCard(
        child: Row(
          children: [
            _IconBox(
              icon: Icons.sticky_note_2_rounded,
              color: colorScheme.secondary,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Notes',
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                  const SizedBox(height: 4),
                  viewModel.isLoadingNotes
                      ? SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: colorScheme.secondary,
                          ),
                        )
                      : Text(
                          hasNotes ? viewModel.notes : 'Tap to add notes...',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: hasNotes
                                ? FontWeight.w500
                                : FontWeight.w400,
                            color: hasNotes
                                ? Colors.grey.shade800
                                : Colors.grey.shade400,
                            fontStyle: hasNotes
                                ? FontStyle.normal
                                : FontStyle.italic,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                ],
              ),
            ),
            Icon(
              Icons.edit_note_rounded,
              color: colorScheme.secondary.withValues(alpha: 0.6),
              size: 22,
            ),
          ],
        ),
      ),
    );
  }

  void _showNotesEditor(BuildContext context, PetDetailViewModel viewModel) {
    final controller = TextEditingController(text: viewModel.notes);
    final colorScheme = Theme.of(context).colorScheme;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(ctx).size.height * 0.6,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Title row
              Row(
                children: [
                  Icon(
                    Icons.sticky_note_2_rounded,
                    color: colorScheme.secondary,
                    size: 24,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Pet Notes',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Record medical history, allergies, food preferences, and more.',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 16),
              // Text field
              Flexible(
                child: TextField(
                  controller: controller,
                  maxLines: 8,
                  minLines: 4,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    hintText: 'e.g., Allergic to chicken, prefers wet food...',
                    hintStyle: TextStyle(
                      color: Colors.grey.shade400,
                      fontStyle: FontStyle.italic,
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                        color: colorScheme.primary,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Save button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    viewModel.saveNotes(controller.text.trim());
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Notes saved successfully'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 2,
                  ),
                  child: const Text(
                    'Save Notes',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
