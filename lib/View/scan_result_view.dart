// Copyright © 2026 TY Chew. All rights reserved.
// Licensed under the MIT License. See LICENSE file in the project root.

import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../scan_type.dart';
import '../ViewModel/scan_result_view_model.dart';

class ScanResultView extends StatelessWidget {
  const ScanResultView({
    super.key,
    required this.scanType,
    required this.imageFile,
  });

  final ScanType scanType;
  final File imageFile;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) =>
          ScanResultViewModel(scanType: scanType, imageFile: imageFile),
      child: const _ScanResultBody(),
    );
  }
}

class _ScanResultBody extends StatelessWidget {
  const _ScanResultBody();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final viewModel = context.watch<ScanResultViewModel>();
    final bool isDisease = viewModel.scanType == ScanType.skinDisease;
    final Color accentColor = isDisease
        ? const Color(0xFFFF6B6B)
        : const Color(0xFF4ECDC4);
    final IconData typeIcon = isDisease
        ? Icons.healing_rounded
        : Icons.pets_rounded;
    final String typeLabel = isDisease
        ? 'Skin Disease Scan'
        : 'Breed Identification';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Column(
        children: [
          // ── Gradient Header (nav only) ──
          _ResultHeader(accentColor: accentColor),

          // ── Content ──
          if (viewModel.isLoading)
            _LoadingState(accentColor: accentColor)
          else if (viewModel.errorMessage != null)
            _ErrorState(errorMessage: viewModel.errorMessage!)
          else
            _ResultContent(
              viewModel: viewModel,
              colorScheme: colorScheme,
              accentColor: accentColor,
              isDisease: isDisease,
              typeIcon: typeIcon,
              typeLabel: typeLabel,
            ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Result Header (nav bar only — no image)
// ═══════════════════════════════════════════════════════════════════════════
class _ResultHeader extends StatelessWidget {
  const _ResultHeader({required this.accentColor});
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Container(
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
            accentColor,
            accentColor.withValues(alpha: 0.8),
            accentColor.withValues(alpha: 0.65),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          _HeaderIconButton(
            icon: Icons.arrow_back_ios_new_rounded,
            onTap: () =>
                context.read<ScanResultViewModel>().onScanAgainPressed(context),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Text(
              'Scan Result',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: -0.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Scanned Image Card (standalone, below header)
// ═══════════════════════════════════════════════════════════════════════════
class _ImageDisplayCard extends StatelessWidget {
  const _ImageDisplayCard({
    required this.imageFile,
    required this.accentColor,
    required this.typeIcon,
    required this.typeLabel,
  });
  final File imageFile;
  final Color accentColor;
  final IconData typeIcon;
  final String typeLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 0),
      transform: Matrix4.translationValues(0, -16, 0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Container(
              width: double.infinity,
              height: 200,
              color: Colors.grey.shade50,
              child: Image.file(
                imageFile,
                fit: BoxFit.contain,
                width: double.infinity,
                height: double.infinity,
              ),
            ),
          ),
          // Scan type badge
          Positioned(
            bottom: 12,
            left: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: accentColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: accentColor.withValues(alpha: 0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(typeIcon, size: 14, color: Colors.white),
                  const SizedBox(width: 6),
                  Text(
                    typeLabel,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
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

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
        ),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Loading State
// ═══════════════════════════════════════════════════════════════════════════
class _LoadingState extends StatefulWidget {
  const _LoadingState({required this.accentColor});
  final Color accentColor;

  @override
  State<_LoadingState> createState() => _LoadingStateState();
}

class _LoadingStateState extends State<_LoadingState>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: _controller,
              builder: (_, child) {
                return Transform.rotate(
                  angle: _controller.value * 2 * math.pi,
                  child: child,
                );
              },
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: SweepGradient(
                    colors: [
                      widget.accentColor.withValues(alpha: 0.1),
                      widget.accentColor,
                    ],
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Color(0xFFF5F7FA),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Analysing image…',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'This may take a few seconds',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Error State
// ═══════════════════════════════════════════════════════════════════════════
class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.errorMessage});
  final String errorMessage;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.error_outline_rounded,
                  size: 48,
                  color: Colors.red.shade400,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Analysis failed',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                errorMessage,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back_rounded),
                  label: const Text('Go back & try again'),
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
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

// ═══════════════════════════════════════════════════════════════════════════
// Result Content
// ═══════════════════════════════════════════════════════════════════════════
class _ResultContent extends StatelessWidget {
  const _ResultContent({
    required this.viewModel,
    required this.colorScheme,
    required this.accentColor,
    required this.isDisease,
    required this.typeIcon,
    required this.typeLabel,
  });
  final ScanResultViewModel viewModel;
  final ColorScheme colorScheme;
  final Color accentColor;
  final bool isDisease;
  final IconData typeIcon;
  final String typeLabel;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Scanned Image Card
            _ImageDisplayCard(
              imageFile: viewModel.imageFile,
              accentColor: accentColor,
              typeIcon: typeIcon,
              typeLabel: typeLabel,
            ),
            const SizedBox(height: 4),
            // Top Result with Circular Gauge
            _TopResultCard(
              label: viewModel.topPrediction?.label ?? '',
              confidence: viewModel.topPrediction?.confidence ?? 0,
              accentColor: accentColor,
              isDisease: isDisease,
            ),
            const SizedBox(height: 20),

            // All Predictions
            _SectionCard(
              icon: Icons.analytics_outlined,
              iconColor: colorScheme.primary,
              title: 'Analysis Results',
              child: Column(
                children: viewModel.predictions.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final prediction = entry.value;
                  final isTop = idx == 0;
                  return Padding(
                    padding: EdgeInsets.only(
                      bottom: idx < viewModel.predictions.length - 1 ? 14 : 0,
                    ),
                    child: _PredictionRow(
                      rank: idx + 1,
                      prediction: prediction,
                      accentColor: isTop ? accentColor : Colors.grey,
                      isTop: isTop,
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),

            // Details
            _SectionCard(
              icon: Icons.description_outlined,
              iconColor: accentColor,
              title: viewModel.detailsTitle,
              child: Text(
                viewModel.summaryText,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                  height: 1.6,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Disclaimer
            _DisclaimerCard(warningText: viewModel.warningText),
            const SizedBox(height: 16),

            // Save status indicator
            if (viewModel.isSaving)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: accentColor,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Saving to history...',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              )
            else if (viewModel.hasSaved)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.check_circle_rounded,
                      size: 16,
                      color: Colors.green.shade500,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Saved to history',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.green.shade600,
                      ),
                    ),
                  ],
                ),
              )
            else if (viewModel.saveError != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      size: 16,
                      color: Colors.orange.shade600,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Could not save to history',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.orange.shade600,
                      ),
                    ),
                  ],
                ),
              ),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: _ActionButton(
                    icon: Icons.camera_alt_rounded,
                    label: 'Scan Again',
                    color: colorScheme.primary,
                    onTap: () => viewModel.onScanAgainPressed(context),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _ActionButton(
                    icon: Icons.home_rounded,
                    label: 'Home',
                    color: Colors.grey.shade600,
                    isOutlined: true,
                    onTap: () => viewModel.onHomePressed(context),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Top Result Card with Circular Gauge
// ═══════════════════════════════════════════════════════════════════════════
class _TopResultCard extends StatelessWidget {
  const _TopResultCard({
    required this.label,
    required this.confidence,
    required this.accentColor,
    required this.isDisease,
  });
  final String label;
  final double confidence;
  final Color accentColor;
  final bool isDisease;

  @override
  Widget build(BuildContext context) {
    final percent = (confidence * 100).toStringAsFixed(1);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            accentColor.withValues(alpha: 0.1),
            accentColor.withValues(alpha: 0.04),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Circular Gauge
          SizedBox(
            width: 110,
            height: 110,
            child: CustomPaint(
              painter: _ConfidenceGaugePainter(
                progress: confidence,
                color: accentColor,
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$percent%',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: accentColor,
                        letterSpacing: -0.5,
                      ),
                    ),
                    Text(
                      'confidence',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: accentColor.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Label
          Text(
            label,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: accentColor,
              letterSpacing: -0.3,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),

          // Type badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isDisease ? Icons.check_circle_rounded : Icons.pets_rounded,
                  size: 14,
                  color: accentColor,
                ),
                const SizedBox(width: 6),
                Text(
                  isDisease ? 'Disease Scan' : 'Breed Match',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: accentColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Confidence Gauge Painter
// ═══════════════════════════════════════════════════════════════════════════
class _ConfidenceGaugePainter extends CustomPainter {
  _ConfidenceGaugePainter({required this.progress, required this.color});
  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 6;
    const startAngle = -math.pi / 2;
    final sweepAngle = 2 * math.pi * progress;

    // Background track
    final bgPaint = Paint()
      ..color = color.withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, bgPaint);

    // Progress arc
    final fgPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      fgPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _ConfidenceGaugePainter old) =>
      old.progress != progress || old.color != color;
}

// ═══════════════════════════════════════════════════════════════════════════
// Section Card (generic wrapper)
// ═══════════════════════════════════════════════════════════════════════════
class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.child,
  });
  final IconData icon;
  final Color iconColor;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 14,
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
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 14),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A1A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Prediction Row (with rank number)
// ═══════════════════════════════════════════════════════════════════════════
class _PredictionRow extends StatelessWidget {
  final int rank;
  final ScanPrediction prediction;
  final Color accentColor;
  final bool isTop;

  const _PredictionRow({
    required this.rank,
    required this.prediction,
    required this.accentColor,
    required this.isTop,
  });

  @override
  Widget build(BuildContext context) {
    final percent = prediction.confidence * 100;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Rank badge
        Container(
          width: 28,
          height: 28,
          margin: const EdgeInsets.only(right: 12, top: 1),
          decoration: BoxDecoration(
            color: isTop ? accentColor : Colors.grey.shade200,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              '#$rank',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: isTop ? Colors.white : Colors.grey.shade600,
              ),
            ),
          ),
        ),
        // Label, bar, percentage
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      prediction.label,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: isTop ? FontWeight.w700 : FontWeight.w500,
                        color: isTop
                            ? const Color(0xFF1A1A1A)
                            : Colors.grey.shade600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${percent.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: accentColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: prediction.confidence,
                  backgroundColor: Colors.grey.shade100,
                  valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                  minHeight: 7,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Disclaimer Card
// ═══════════════════════════════════════════════════════════════════════════
class _DisclaimerCard extends StatelessWidget {
  const _DisclaimerCard({required this.warningText});
  final String warningText;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.info_outline_rounded,
              size: 18,
              color: Colors.amber.shade800,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Disclaimer',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.amber.shade900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  warningText,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.amber.shade800,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Action Button
// ═══════════════════════════════════════════════════════════════════════════
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool isOutlined;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    this.isOutlined = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isOutlined ? Colors.white : color,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: isOutlined ? Border.all(color: color, width: 1.5) : null,
            boxShadow: isOutlined
                ? null
                : [
                    BoxShadow(
                      color: color.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: isOutlined ? color : Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: isOutlined ? color : Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
