// Copyright © 2026 TY Chew. All rights reserved.
// Licensed under the MIT License. See LICENSE file in the project root.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../ViewModel/pet_profile_view_model.dart';
import '../models/pet_info.dart';

class PetProfileView extends StatelessWidget {
  const PetProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    return const _PetProfileBody();
  }
}

class _PetProfileBody extends StatelessWidget {
  const _PetProfileBody();

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<PetProfileViewModel>();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      color: const Color(0xFFF5F7FA),
      child: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            RefreshIndicator(
              onRefresh: viewModel.refreshPets,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  // Header
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'My Pets',
                                    style: theme.textTheme.headlineMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.w800,
                                          color: const Color(0xFF2D3142),
                                          letterSpacing: -0.5,
                                        ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Manage your furry friends',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: Colors.grey.shade600,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.05,
                                      ),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Text(
                                  '${viewModel.pets.length}',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const SizedBox(height: 30),
                        ],
                      ),
                    ),
                  ),

                  // Grid
                  if (!viewModel.hasPets)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: _EmptyPetsState(
                        onAddPet: () => viewModel.openAddPet(context),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                      sliver: SliverGrid(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 0.75,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                            ),
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final pet = viewModel.pets[index];
                          return _PetGridCard(
                            pet: pet,
                            index: index,
                            onTap: () => viewModel.openPetDetail(context, pet),
                          );
                        }, childCount: viewModel.pets.length),
                      ),
                    ),
                ],
              ),
            ),

            // Floating Add Button
            Positioned(
              bottom: 30,
              right: 24,
              child: _FloatingAddButton(
                onTap: () => viewModel.openAddPet(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FloatingAddButton extends StatelessWidget {
  final VoidCallback onTap;

  const _FloatingAddButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      height: 60,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.primary,
            colorScheme.primary.withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(30),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.add, color: Colors.white, size: 24),
                const SizedBox(width: 8),
                const Text(
                  'Add Pet',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PetGridCard extends StatelessWidget {
  final PetInfo pet;
  final int index;
  final VoidCallback onTap;

  const _PetGridCard({
    required this.pet,
    required this.index,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDog = pet.species.toLowerCase() == 'dog';

    // Dynamic colors based on index/species
    final List<Color> bgColors = isDog
        ? [const Color(0xFFE3F2FD), const Color(0xFFBBDEFB)]
        : [const Color(0xFFF3E5F5), const Color(0xFFE1BEE7)];

    // Image Logic
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

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Section
            Expanded(
              flex: 4,
              child: Hero(
                tag: 'pet_${pet.name}',
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: petImagePath == null
                        ? LinearGradient(
                            colors: bgColors,
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                      bottomRight: Radius.circular(60),
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
                  ),
                  child: Stack(
                    children: [
                      if (!hasRemotePhoto && petImagePath == null)
                        Center(
                          child: Icon(
                            isDog ? Icons.pets : Icons.pets_outlined,
                            size: 50,
                            color: Colors.white.withValues(alpha: 0.5),
                          ),
                        ),
                      Positioned(
                        top: 12,
                        right: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            pet.age,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade800,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Info Section
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      pet.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF2D3142),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          isDog ? Icons.pets : Icons.pets_outlined,
                          size: 12,
                          color: Colors.grey.shade500,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            pet.breed,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
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

class _EmptyPetsState extends StatelessWidget {
  final VoidCallback onAddPet;
  const _EmptyPetsState({required this.onAddPet});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Icon(Icons.pets, size: 60, color: Colors.grey.shade300),
          ),
          const SizedBox(height: 24),
          Text(
            'No pets yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add your first pet to start tracking.',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
          ),
          const SizedBox(height: 32),
          OutlinedButton.icon(
            onPressed: onAddPet,
            icon: const Icon(Icons.add),
            label: const Text('Add Pet'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
