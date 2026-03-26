import 'dart:io';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

class StoryArtwork extends StatelessWidget {
  const StoryArtwork({
    super.key,
    required this.palette,
    this.overlayColor,
    this.showAtmosphere = true,
    this.imagePath,
    this.imageBlurSigma = 0,
  });

  final List<Color> palette;
  final Color? overlayColor;
  final bool showAtmosphere;
  final String? imagePath;
  final double imageBlurSigma;

  @override
  Widget build(BuildContext context) {
    final backdrop = _ArtworkBackdrop(palette: palette, imagePath: imagePath);

    return Stack(
      fit: StackFit.expand,
      children: [
        if (imageBlurSigma <= 0)
          backdrop
        else
          ImageFiltered(
            imageFilter: ImageFilter.blur(
              sigmaX: imageBlurSigma,
              sigmaY: imageBlurSigma,
            ),
            child: backdrop,
          ),
        if (showAtmosphere)
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white.withValues(alpha: 0.08),
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.24),
                ],
              ),
            ),
          ),
        if (overlayColor != null)
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  overlayColor!.withValues(alpha: 0.12),
                  overlayColor!.withValues(alpha: 0.26),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _ArtworkBackdrop extends StatelessWidget {
  const _ArtworkBackdrop({required this.palette, required this.imagePath});

  final List<Color> palette;
  final String? imagePath;

  @override
  Widget build(BuildContext context) {
    final trimmedPath = imagePath?.trim();
    if (trimmedPath == null || trimmedPath.isEmpty) {
      return _GeneratedArtwork(palette: palette);
    }

    final file = File(trimmedPath);
    final pixelRatio = MediaQuery.maybeDevicePixelRatioOf(context) ?? 2.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.hasBoundedWidth
            ? constraints.maxWidth
            : MediaQuery.maybeSizeOf(context)?.width;
        final height = constraints.hasBoundedHeight
            ? constraints.maxHeight
            : MediaQuery.maybeSizeOf(context)?.height;
        final cacheWidth = width == null
            ? null
            : (width * pixelRatio * 1.05).round().clamp(320, 1500);
        final cacheHeight = height == null
            ? null
            : (height * pixelRatio * 1.05).round().clamp(420, 2400);
        final imageProvider = ResizeImage.resizeIfNeeded(
          cacheWidth,
          cacheHeight,
          FileImage(file),
        );

        return Image(
          image: imageProvider,
          fit: BoxFit.cover,
          filterQuality: FilterQuality.none,
          gaplessPlayback: true,
          errorBuilder: (context, error, stackTrace) {
            return _GeneratedArtwork(palette: palette);
          },
        );
      },
    );
  }
}

class _GeneratedArtwork extends StatelessWidget {
  const _GeneratedArtwork({required this.palette});

  final List<Color> palette;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: palette,
        ),
      ),
      child: CustomPaint(painter: _StoryArtworkPainter(palette)),
    );
  }
}

class _StoryArtworkPainter extends CustomPainter {
  const _StoryArtworkPainter(this.palette);

  final List<Color> palette;

  @override
  void paint(Canvas canvas, Size size) {
    final glowPaint = Paint()
      ..shader =
          RadialGradient(
            colors: [palette.last.withValues(alpha: 0.38), Colors.transparent],
          ).createShader(
            Rect.fromCircle(
              center: Offset(size.width * 0.68, size.height * 0.26),
              radius: size.width * 0.46,
            ),
          );
    canvas.drawCircle(
      Offset(size.width * 0.68, size.height * 0.26),
      size.width * 0.46,
      glowPaint,
    );

    final wavePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(2.4, size.width * 0.008)
      ..color = Colors.white.withValues(alpha: 0.1);
    for (int layer = 0; layer < 4; layer++) {
      final path = Path()..moveTo(-20, size.height * (0.52 + layer * 0.08));
      for (double x = 0; x <= size.width + 20; x += 24) {
        path.quadraticBezierTo(
          x + 12,
          size.height * (0.45 + layer * 0.06) +
              math.sin((x / size.width) * math.pi * 2 + layer) * 18,
          x + 24,
          size.height * (0.52 + layer * 0.08),
        );
      }
      canvas.drawPath(path, wavePaint);
    }

    final ridgePaint = Paint()
      ..shader =
          LinearGradient(
            colors: [
              Colors.black.withValues(alpha: 0.0),
              Colors.black.withValues(alpha: 0.28),
            ],
          ).createShader(
            Rect.fromLTWH(0, size.height * 0.6, size.width, size.height * 0.4),
          );

    final ridge = Path()
      ..moveTo(0, size.height * 0.78)
      ..quadraticBezierTo(
        size.width * 0.24,
        size.height * 0.66,
        size.width * 0.48,
        size.height * 0.82,
      )
      ..quadraticBezierTo(
        size.width * 0.74,
        size.height * 0.9,
        size.width,
        size.height * 0.7,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(ridge, ridgePaint);
  }

  @override
  bool shouldRepaint(covariant _StoryArtworkPainter oldDelegate) {
    return oldDelegate.palette != palette;
  }
}
