// Copyright © 2026 TY Chew. All rights reserved.
// Licensed under the MIT License. See LICENSE file in the project root.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../ViewModel/add_pet_view_model.dart';

class AddPetView extends StatelessWidget {
  const AddPetView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AddPetViewModel(),
      child: const _AddPetBody(),
    );
  }
}

class _AddPetBody extends StatelessWidget {
  const _AddPetBody();

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<AddPetViewModel>();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Add New Pet',
          style: textTheme.titleMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
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
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Image picker area (below the solid AppBar)
            GestureDetector(
              onTap: () => viewModel.pickImage(context),
              child: Container(
                width: double.infinity,
                height: 280,
                color: Colors.white,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (viewModel.selectedImage != null)
                      Image.file(viewModel.selectedImage!, fit: BoxFit.contain)
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
                            child: Icon(
                              viewModel.selectedImage != null
                                  ? Icons.edit
                                  : Icons.camera_alt_rounded,
                              color: Colors.white,
                              size: 36,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            viewModel.selectedImage != null
                                ? 'Tap to change photo'
                                : 'Add a photo',
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

            // Form body
            Form(
              key: viewModel.formKey,
              child: Padding(
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
                          hint: 'e.g. Buddy',
                          icon: Icons.badge_outlined,
                          validator: (v) => v == null || v.trim().isEmpty
                              ? 'Please enter your pet\u2019s name'
                              : null,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _StyledDropdown(
                                label: 'Species',
                                icon: Icons.pets_outlined,
                                value: viewModel.species,
                                options: viewModel.speciesOptions,
                                onChanged: viewModel.selectSpecies,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: _StyledDropdown(
                                label: 'Gender',
                                icon: Icons.wc_outlined,
                                value: viewModel.gender,
                                options: viewModel.genderOptions,
                                onChanged: viewModel.selectGender,
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
                                hint: 'e.g. Golden',
                                icon: Icons.palette_outlined,
                                validator: (v) => v == null || v.trim().isEmpty
                                    ? 'Please enter colour'
                                    : null,
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
                                validator: (v) {
                                  final p = double.tryParse(v?.trim() ?? '');
                                  if (p == null || p <= 0) {
                                    return 'Enter valid weight';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _DateField(viewModel: viewModel),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Section: Gallery
                    _SectionCard(
                      title: 'Gallery photos',
                      icon: Icons.photo_library_outlined,
                      children: [_GalleryPicker(viewModel: viewModel)],
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
                        ),
                        onPressed: viewModel.isLoading
                            ? null
                            : () => viewModel.savePet(context),
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
                                    'Save Pet',
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
            ),
          ],
        ),
      ),
    );
  }
}

// Reusable internal widgets

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
  final String? Function(String?)? validator;

  const _StyledTextField({
    required this.controller,
    required this.label,
    required this.icon,
    this.hint,
    this.keyboardType,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return TextFormField(
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
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: colorScheme.error, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: colorScheme.error, width: 1.5),
        ),
      ),
      validator: validator,
    );
  }
}

class _StyledDropdown extends StatelessWidget {
  final String label;
  final IconData icon;
  final String value;
  final List<String> options;
  final Function(String) onChanged;

  const _StyledDropdown({
    required this.label,
    required this.icon,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

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
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F7FA),
            borderRadius: BorderRadius.circular(14),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              icon: Icon(
                Icons.keyboard_arrow_down_rounded,
                color: colorScheme.primary,
                size: 22,
              ),
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: Color(0xFF1A1A1A),
              ),
              items: options
                  .map((o) => DropdownMenuItem(value: o, child: Text(o)))
                  .toList(),
              onChanged: (v) => onChanged(v!),
            ),
          ),
        ),
      ],
    );
  }
}

class _BreedDropdown extends StatelessWidget {
  final AddPetViewModel viewModel;
  const _BreedDropdown({required this.viewModel});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final breeds = viewModel.filteredBreeds;

    return DropdownButtonFormField<BreedOption>(
      // ignore: deprecated_member_use
      value: viewModel.selectedBreed,
      decoration: InputDecoration(
        labelText: viewModel.isBreedsLoading ? 'Loading breeds...' : 'Breed',
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
      onChanged: viewModel.isBreedsLoading
          ? null
          : (v) => viewModel.selectBreed(v),
      validator: (v) => v == null ? 'Please select a breed' : null,
    );
  }
}

class _DateField extends StatelessWidget {
  final AddPetViewModel viewModel;
  const _DateField({required this.viewModel});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return TextFormField(
      controller: viewModel.dateOfBirthController,
      readOnly: true,
      onTap: () => viewModel.pickDateOfBirth(context),
      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
      decoration: InputDecoration(
        labelText: 'Date of Birth',
        hintText: 'Tap to select',
        labelStyle: TextStyle(
          color: Colors.grey.shade500,
          fontWeight: FontWeight.w500,
          fontSize: 13,
        ),
        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
        prefixIcon: Icon(
          Icons.cake_outlined,
          color: Colors.grey.shade400,
          size: 20,
        ),
        suffixIcon: Icon(
          Icons.calendar_today_rounded,
          color: colorScheme.primary,
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
      ),
      validator: (v) =>
          v == null || v.trim().isEmpty ? 'Please select date of birth' : null,
    );
  }
}

class _GalleryPicker extends StatelessWidget {
  final AddPetViewModel viewModel;
  const _GalleryPicker({required this.viewModel});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final count = viewModel.galleryImages.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => viewModel.pickGalleryImages(context),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 18),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F7FA),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: colorScheme.primary.withValues(alpha: 0.25),
                width: 1.5,
                strokeAlign: BorderSide.strokeAlignInside,
              ),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.add_photo_alternate_outlined,
                  color: colorScheme.primary,
                  size: 28,
                ),
                const SizedBox(height: 6),
                Text(
                  count == 0
                      ? 'Tap to select photos'
                      : '$count photo${count == 1 ? "" : "s"} selected \u2014 Tap to change',
                  style: TextStyle(
                    color: colorScheme.primary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (viewModel.galleryImages.isNotEmpty) ...[
          const SizedBox(height: 14),
          SizedBox(
            height: 76,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: count,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                return ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    viewModel.galleryImages[index],
                    width: 76,
                    height: 76,
                    fit: BoxFit.cover,
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }
}
