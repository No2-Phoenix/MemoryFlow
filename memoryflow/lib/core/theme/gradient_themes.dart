import 'package:flutter/material.dart';

@immutable
class GradientThemeData {
  const GradientThemeData({
    required this.id,
    required this.name,
    required this.colors,
    required this.textColor,
    required this.secondaryTextColor,
    required this.accentColor,
    required this.glowColor,
    required this.glassTint,
    required this.shadowColor,
    this.isBright = false,
  });

  final String id;
  final String name;
  final List<Color> colors;
  final Color textColor;
  final Color secondaryTextColor;
  final Color accentColor;
  final Color glowColor;
  final Color glassTint;
  final Color shadowColor;
  final bool isBright;

  LinearGradient get backgroundGradient {
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: colors,
      stops: const [0.0, 0.45, 1.0],
    );
  }

  Color glassEdge(double opacity) {
    return isBright
        ? Colors.white.withValues(alpha: opacity * 0.92)
        : Colors.white.withValues(alpha: opacity);
  }
}

class GradientThemes {
  static const GradientThemeData gradientBlack = GradientThemeData(
    id: 'gradient_black',
    name: '渐变黑色简约',
    colors: [Color(0xFF05070D), Color(0xFF111722), Color(0xFF202D3C)],
    textColor: Color(0xFFF8FBFF),
    secondaryTextColor: Color(0xFFA2B1C4),
    accentColor: Color(0xFF79DBFF),
    glowColor: Color(0x664ED8FF),
    glassTint: Color(0xFFBBCDE0),
    shadowColor: Color(0xFF04070C),
  );

  static const GradientThemeData gradientGirlPink = GradientThemeData(
    id: 'gradient_girl_pink',
    name: '渐变少女粉',
    colors: [Color(0xFF170A12), Color(0xFF3B1729), Color(0xFF6A2B48)],
    textColor: Color(0xFFFFF1F6),
    secondaryTextColor: Color(0xFFE6B5C9),
    accentColor: Color(0xFFFF7AAF),
    glowColor: Color(0x66FF8FB8),
    glassTint: Color(0xFFF2C6D7),
    shadowColor: Color(0xFF10040A),
  );

  static const GradientThemeData gradientBluePurple = GradientThemeData(
    id: 'gradient_blue_purple',
    name: '渐变蓝紫',
    colors: [Color(0xFF08111F), Color(0xFF182445), Color(0xFF32366C)],
    textColor: Color(0xFFF3F5FF),
    secondaryTextColor: Color(0xFFAAB2E1),
    accentColor: Color(0xFF8D86FF),
    glowColor: Color(0x66849BFF),
    glassTint: Color(0xFFC7CEFF),
    shadowColor: Color(0xFF050A15),
  );

  static const List<GradientThemeData> all = [
    gradientBlack,
    gradientGirlPink,
    gradientBluePurple,
  ];

  static GradientThemeData byIndex(int index) {
    if (index < 0 || index >= all.length) {
      return gradientBlack;
    }
    return all[index];
  }
}
