import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

import '../core/theme/gradient_themes.dart';

class GradientBackground extends StatelessWidget {
  const GradientBackground({
    super.key,
    required this.theme,
    required this.child,
    this.animate = true,
    this.showNoise = true,
  });

  final GradientThemeData theme;
  final Widget child;
  final bool animate;
  final bool showNoise;

  @override
  Widget build(BuildContext context) {
    final shortestSide = MediaQuery.maybeSizeOf(context)?.shortestSide ?? 600;
    final reducedEffects = shortestSide < 430;
    final effectiveShowNoise = showNoise && !reducedEffects;
    final orbBlur = reducedEffects ? 22.0 : 46.0;
    final veilTop = theme.isBright
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.04);
    final veilBottom = theme.isBright
        ? Colors.white.withValues(alpha: 0.14)
        : Colors.black.withValues(alpha: 0.18);

    return Stack(
      children: [
        Positioned.fill(
          child: AnimatedContainer(
            duration: animate
                ? const Duration(milliseconds: 900)
                : Duration.zero,
            curve: Curves.easeInOutCubic,
            decoration: BoxDecoration(gradient: theme.backgroundGradient),
          ),
        ),
        Positioned(
          top: -140,
          left: -90,
          child: _GlowOrb(color: theme.glowColor, size: 320, blur: orbBlur),
        ),
        Positioned(
          bottom: -180,
          right: -120,
          child: _GlowOrb(
            color: theme.accentColor.withValues(alpha: 0.22),
            size: 360,
            blur: orbBlur,
          ),
        ),
        Positioned(
          top: 180,
          right: 60,
          child: _GlowOrb(
            color: theme.glassTint.withValues(alpha: 0.12),
            size: 180,
            blur: orbBlur,
          ),
        ),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [veilTop, Colors.transparent, veilBottom],
              ),
            ),
          ),
        ),
        if (effectiveShowNoise)
          const Positioned.fill(
            child: IgnorePointer(child: CustomPaint(painter: NoisePainter())),
          ),
        Positioned.fill(child: child),
      ],
    );
  }
}

class GlassContainer extends StatelessWidget {
  const GlassContainer({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius = 28,
    this.blurSigma = 18,
    this.tintColor,
    this.opacity = 0.14,
    this.borderColor,
    this.onTap,
    this.boxShadow,
    this.alignment,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final double blurSigma;
  final Color? tintColor;
  final double opacity;
  final Color? borderColor;
  final VoidCallback? onTap;
  final List<BoxShadow>? boxShadow;
  final AlignmentGeometry? alignment;

  @override
  Widget build(BuildContext context) {
    final baseTint = tintColor ?? Colors.white;
    final theme = Theme.of(context);
    final shortestSide = MediaQuery.maybeSizeOf(context)?.shortestSide ?? 600;
    final effectiveBlur = shortestSide < 360
        ? math.min(blurSigma, 2.8)
        : shortestSide < 430
        ? math.min(blurSigma, 4.2)
        : blurSigma;
    final highlight =
        borderColor ??
        (theme.brightness == Brightness.light
            ? Colors.white.withValues(alpha: 0.54)
            : Colors.white.withValues(alpha: 0.2));

    final decoratedBody = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: highlight, width: 1.1),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            baseTint.withValues(
              alpha:
                  opacity +
                  (theme.brightness == Brightness.light ? 0.12 : 0.08),
            ),
            baseTint.withValues(alpha: opacity),
            Colors.white.withValues(
              alpha:
                  opacity * (theme.brightness == Brightness.light ? 0.7 : 0.45),
            ),
          ],
        ),
        boxShadow:
            boxShadow ??
            [
              BoxShadow(
                color: theme.brightness == Brightness.light
                    ? Colors.black.withValues(alpha: 0.08)
                    : Colors.black.withValues(alpha: 0.18),
                blurRadius: 30,
                offset: const Offset(0, 20),
              ),
            ],
      ),
      child: Align(
        alignment: alignment ?? Alignment.center,
        child: Padding(padding: padding ?? EdgeInsets.zero, child: child),
      ),
    );

    final body = ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: effectiveBlur <= 0.1
          ? decoratedBody
          : BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: effectiveBlur,
                sigmaY: effectiveBlur,
              ),
              child: decoratedBody,
            ),
    );

    return Container(
      margin: margin,
      child: Material(
        color: Colors.transparent,
        child: onTap == null
            ? body
            : InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(borderRadius),
                child: body,
              ),
      ),
    );
  }
}

class NoisePainter extends CustomPainter {
  const NoisePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(13);
    final paint = Paint();
    for (int index = 0; index < 2800; index++) {
      paint.color = Colors.white.withValues(alpha: random.nextDouble() * 0.035);
      canvas.drawRect(
        Rect.fromLTWH(
          random.nextDouble() * size.width,
          random.nextDouble() * size.height,
          1,
          1,
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({required this.color, required this.size, required this.blur});

  final Color color;
  final double size;
  final double blur;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: ImageFiltered(
        imageFilter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                color,
                color.withValues(alpha: 0.16),
                Colors.transparent,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
