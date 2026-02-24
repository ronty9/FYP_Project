import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../ViewModel/edit_pet_view_model.dart';
import '../models/pet_info.dart';
import '../View/pet_gallery_view.dart';

class EditPetView extends StatelessWidget {
  const EditPetView({super.key, required this.pet});

  final PetInfo pet;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => EditPetViewModel(pet),
      child: const _EditPetBody(),
    );
  }
}

class _EditPetBody extends StatelessWidget {
  const _EditPetBody();

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<EditPetViewModel>();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8),
          child: CircleAvatar(
            backgroundColor: Colors.white.withValues(alpha: 0.2),
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
        title: Text(
          'Edit Pet Details',
          style: textTheme.titleMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton(
              onPressed: viewModel.hasChanges
                  ? () => viewModel.saveChanges(context)
                  : null,
              child: Text(
                'Save',
                style: TextStyle(
                  color: viewModel.hasChanges
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.45),
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // --- Profile Image Section ---
            GestureDetector(
              onTap: () => _showPhotoOptions(context, viewModel),
              child: Container(
                width: double.infinity,
                height: 280,
                color: Colors.white,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (viewModel.profilePhotoFile != null)
                      Image.file(
                        viewModel.profilePhotoFile!,
                        fit: BoxFit.contain,
                      )
                    else if (viewModel.selectedGalleryUrl != null &&
                        viewModel.selectedGalleryUrl!.isNotEmpty)
                      Image.network(
                        viewModel.selectedGalleryUrl!,
                        fit: BoxFit.contain,
                      )
                    else if (viewModel.pet.photoUrl != null &&
                        viewModel.pet.photoUrl!.isNotEmpty)
                      Image.network(
                        viewModel.pet.photoUrl!,
                        fit: BoxFit.contain,
                      )
                    else
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              colorScheme.primary,
                              colorScheme.primary.withValues(alpha: 0.7),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                    // Overlay scrim
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.35),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                    // Edit icon + text
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.edit,
                              color: Colors.white,
                              size: 36,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Tap to change photo',
                            style: textTheme.bodyLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // --- Form body ---
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Section: Basic Info
                  _SectionCard(
                    title: 'Basic information',
                    icon: Icons.info_outline_rounded,
                    children: [
                      _StyledTextField(
                        controller: viewModel.nameController,
                        label: 'Pet name',
                        hint: viewModel.pet.name,
                        icon: Icons.badge_outlined,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _ReadOnlyField(
                              label: 'Species',
                              value: viewModel.species,
                              icon: Icons.pets_outlined,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: _ReadOnlyField(
                              label: 'Gender',
                              value: viewModel.gender,
                              icon: Icons.wc_outlined,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _BreedDropdown(viewModel: viewModel),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Section: Appearance & Health
                  _SectionCard(
                    title: 'Appearance & Health',
                    icon: Icons.monitor_heart_outlined,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _StyledTextField(
                              controller: viewModel.colourController,
                              label: 'Colour',
                              hint: viewModel.pet.colour ?? 'e.g. Golden',
                              icon: Icons.palette_outlined,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: _StyledTextField(
                              controller: viewModel.weightController,
                              label: 'Weight (kg)',
                              hint: 'e.g. 12.5',
                              icon: Icons.monitor_weight_outlined,
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: Colors.white,
                        elevation: 4,
                        shadowColor: colorScheme.primary.withValues(
                          alpha: 0.35,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        disabledBackgroundColor: Colors.grey.shade300,
                      ),
                      onPressed: viewModel.hasChanges
                          ? () => viewModel.saveChanges(context)
                          : null,
                      child: viewModel.isLoading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.check_rounded, size: 22),
                                const SizedBox(width: 8),
                                Text(
                                  'Save Changes',
                                  style: textTheme.titleMedium?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPhotoOptions(BuildContext context, EditPetViewModel viewModel) {
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
              'Update Photo',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 24),
            _buildActionOption(
              context: ctx,
              icon: Icons.camera_alt_outlined,
              label: 'Take a Photo',
              color: const Color(0xFFFF9F59),
              onTap: () {
                Navigator.pop(ctx);
                viewModel.pickProfilePhotoFromCamera();
              },
            ),
            const SizedBox(height: 12),
            _buildActionOption(
              context: ctx,
              icon: Icons.photo_library_outlined,
              label: 'Choose from Local Gallery',
              color: const Color(0xFF7165E3),
              onTap: () {
                Navigator.pop(ctx);
                viewModel.pickProfilePhotoFromLocal();
              },
            ),
            const SizedBox(height: 12),
            _buildActionOption(
              context: ctx,
              icon: Icons.collections_outlined,
              label: 'Choose from Pet Gallery',
              color: const Color(0xFF4CAF50),
              onTap: () async {
                Navigator.pop(ctx);
                final selectedUrl = await Navigator.push<String?>(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        PetGalleryView(pet: viewModel.pet, selectionMode: true),
                  ),
                );
                if (selectedUrl != null && selectedUrl.isNotEmpty) {
                  viewModel.setProfilePhotoFromGallery(selectedUrl);
                }
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildActionOption({
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
}

// ────────────────────────────────────────────────────────────────
// Reusable internal widgets – mirrors add_pet_view.dart styling
// ────────────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: colorScheme.primary),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          ...children,
        ],
      ),
    );
  }
}

class _StyledTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final IconData icon;
  final TextInputType? keyboardType;

  const _StyledTextField({
    required this.controller,
    required this.label,
    required this.icon,
    this.hint,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: TextStyle(
          color: Colors.grey.shade500,
          fontWeight: FontWeight.w500,
          fontSize: 13,
        ),
        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
        prefixIcon: Icon(icon, color: Colors.grey.shade400, size: 20),
        filled: true,
        fillColor: const Color(0xFFF5F7FA),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
        ),
      ),
    );
  }
}

class _ReadOnlyField extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _ReadOnlyField({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFFEEEFF2),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Icon(icon, color: Colors.grey.shade400, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  value,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BreedDropdown extends StatelessWidget {
  final EditPetViewModel viewModel;
  const _BreedDropdown({required this.viewModel});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final breeds = viewModel.breeds;

    return DropdownButtonFormField<BreedOption>(
      // ignore: deprecated_member_use
      initialValue: viewModel.selectedBreed,
      decoration: InputDecoration(
        labelText: 'Breed',
        labelStyle: TextStyle(
          color: Colors.grey.shade500,
          fontWeight: FontWeight.w500,
          fontSize: 13,
        ),
        prefixIcon: Icon(
          Icons.category_outlined,
          color: Colors.grey.shade400,
          size: 20,
        ),
        filled: true,
        fillColor: const Color(0xFFF5F7FA),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: colorScheme.error, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: colorScheme.error, width: 1.5),
        ),
      ),
      isExpanded: true,
      icon: Icon(
        Icons.keyboard_arrow_down_rounded,
        color: colorScheme.primary,
        size: 22,
      ),
      items: breeds
          .map((b) => DropdownMenuItem(value: b, child: Text(b.name)))
          .toList(),
      onChanged: viewModel.setSelectedBreed,
    );
  }
}
