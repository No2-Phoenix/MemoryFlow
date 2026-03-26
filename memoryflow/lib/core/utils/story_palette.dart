import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:palette_generator/palette_generator.dart';

import 'color_utils.dart';

class StoryPalette {
  static const List<Color> defaultPalette = [
    Color(0xFF101824),
    Color(0xFF365C84),
    Color(0xFFD7E6F7),
  ];

  static Future<List<Color>> fromImage(
    String imagePath, {
    List<Color>? fallback,
  }) async {
    final file = File(imagePath);
    if (!await file.exists()) {
      return fallback ?? defaultPalette;
    }

    try {
      final generator = await PaletteGenerator.fromImageProvider(
        FileImage(file),
        size: const Size(360, 360),
        maximumColorCount: 18,
      );

      final candidates = <Color>[
        if (generator.darkMutedColor != null) generator.darkMutedColor!.color,
        if (generator.darkVibrantColor != null)
          generator.darkVibrantColor!.color,
        if (generator.dominantColor != null) generator.dominantColor!.color,
        if (generator.mutedColor != null) generator.mutedColor!.color,
        if (generator.vibrantColor != null) generator.vibrantColor!.color,
        if (generator.lightVibrantColor != null)
          generator.lightVibrantColor!.color,
        if (generator.lightMutedColor != null) generator.lightMutedColor!.color,
        ...generator.paletteColors.map((swatch) => swatch.color),
      ];

      final palette = _buildPalette(candidates);
      if (palette.length == 3) {
        return palette;
      }
    } catch (_) {
      // Fall through to the provided fallback palette.
    }

    return fallback ?? defaultPalette;
  }

  static List<Color> _buildPalette(List<Color> colors) {
    final unique = <Color>[];
    for (final color in colors) {
      if (unique.any(
        (existing) =>
            ColorUtils.colorsAreSimilar(existing, color, threshold: 22),
      )) {
        continue;
      }
      unique.add(color.withAlpha(0xFF));
    }

    if (unique.isEmpty) {
      return defaultPalette;
    }

    unique.sort((left, right) {
      return left.computeLuminance().compareTo(right.computeLuminance());
    });

    final darkest = unique.first;
    final middle = unique[unique.length ~/ 2];
    final brightest = unique.last;

    if (ColorUtils.colorsAreSimilar(darkest, brightest, threshold: 28)) {
      return [
        ColorUtils.darken(middle, 0.42),
        middle,
        ColorUtils.lighten(middle, 0.36),
      ];
    }

    return [
      _enrich(darkest, targetLightness: 0.14),
      _enrich(middle, targetLightness: 0.34),
      _enrich(brightest, targetLightness: 0.78),
    ];
  }

  static Color _enrich(Color color, {required double targetLightness}) {
    final hsl = HSLColor.fromColor(color);
    final saturated = hsl.withSaturation(
      math.max(hsl.saturation, 0.28).clamp(0.0, 1.0),
    );
    return saturated
        .withLightness(targetLightness.clamp(0.0, 1.0))
        .toColor()
        .withAlpha(0xFF);
  }
}
