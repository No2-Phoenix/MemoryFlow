import 'dart:ui';

class ColorUtils {
  static Color blendColors(Color color1, Color color2, double factor) {
    final clampedFactor = factor.clamp(0.0, 1.0);
    return Color.fromARGB(
      (_alpha(color1) * (1 - clampedFactor) + _alpha(color2) * clampedFactor)
          .round(),
      (_red(color1) * (1 - clampedFactor) + _red(color2) * clampedFactor)
          .round(),
      (_green(color1) * (1 - clampedFactor) + _green(color2) * clampedFactor)
          .round(),
      (_blue(color1) * (1 - clampedFactor) + _blue(color2) * clampedFactor)
          .round(),
    );
  }

  static Color withOpacity(Color color, double opacity) {
    return color.withValues(alpha: opacity.clamp(0.0, 1.0));
  }

  static Color darken(Color color, [double amount = 0.1]) {
    final clampedAmount = amount.clamp(0.0, 1.0);
    return Color.fromARGB(
      _alpha(color),
      (_red(color) * (1 - clampedAmount)).round(),
      (_green(color) * (1 - clampedAmount)).round(),
      (_blue(color) * (1 - clampedAmount)).round(),
    );
  }

  static Color lighten(Color color, [double amount = 0.1]) {
    final clampedAmount = amount.clamp(0.0, 1.0);
    return Color.fromARGB(
      _alpha(color),
      (_red(color) + (255 - _red(color)) * clampedAmount).round(),
      (_green(color) + (255 - _green(color)) * clampedAmount).round(),
      (_blue(color) + (255 - _blue(color)) * clampedAmount).round(),
    );
  }

  static double calculateLuminance(Color color) {
    return (0.299 * _red(color) +
            0.587 * _green(color) +
            0.114 * _blue(color)) /
        255;
  }

  static Color getContrastingColor(Color color) {
    final luminance = calculateLuminance(color);
    return luminance > 0.5 ? const Color(0xFF000000) : const Color(0xFFFFFFFF);
  }

  static bool isColorLight(Color color) {
    return calculateLuminance(color) > 0.5;
  }

  static bool isColorDark(Color color) {
    return calculateLuminance(color) < 0.5;
  }

  static String toHex(Color color, {bool includeAlpha = false}) {
    if (includeAlpha) {
      return '#${_alpha(color).toRadixString(16).padLeft(2, '0')}'
          '${_red(color).toRadixString(16).padLeft(2, '0')}'
          '${_green(color).toRadixString(16).padLeft(2, '0')}'
          '${_blue(color).toRadixString(16).padLeft(2, '0')}';
    }
    return '#${_red(color).toRadixString(16).padLeft(2, '0')}'
        '${_green(color).toRadixString(16).padLeft(2, '0')}'
        '${_blue(color).toRadixString(16).padLeft(2, '0')}';
  }

  static Color fromHex(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  static Color averageColor(List<Color> colors) {
    if (colors.isEmpty) {
      throw ArgumentError('Colors list cannot be empty');
    }

    int r = 0, g = 0, b = 0, a = 0;
    for (final color in colors) {
      r += _red(color);
      g += _green(color);
      b += _blue(color);
      a += _alpha(color);
    }

    final count = colors.length;
    return Color.fromARGB(a ~/ count, r ~/ count, g ~/ count, b ~/ count);
  }

  static int colorDistance(Color color1, Color color2) {
    final rMean = (_red(color1) + _red(color2)) / 2;
    final rDiff = _red(color1) - _red(color2);
    final gDiff = _green(color1) - _green(color2);
    final bDiff = _blue(color1) - _blue(color2);

    return ((2 + rMean / 256) * rDiff * rDiff +
            4 * gDiff * gDiff +
            (2 + (255 - rMean) / 256) * bDiff * bDiff)
        .round();
  }

  static bool colorsAreSimilar(
    Color color1,
    Color color2, {
    double threshold = 30.0,
  }) {
    return colorDistance(color1, color2) < threshold * threshold;
  }

  static int _alpha(Color color) => (color.a * 255.0).round().clamp(0, 255);

  static int _red(Color color) => (color.r * 255.0).round().clamp(0, 255);

  static int _green(Color color) => (color.g * 255.0).round().clamp(0, 255);

  static int _blue(Color color) => (color.b * 255.0).round().clamp(0, 255);
}
