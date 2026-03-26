import 'dart:async';

import 'package:flutter/material.dart';

import 'gradient_background.dart';

class GlassButton extends StatelessWidget {
  const GlassButton({
    super.key,
    required this.text,
    this.onPressed,
    this.icon,
    this.height = 58,
    this.highlightColor,
    this.isActive = false,
    this.expand = false,
  });

  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;
  final double height;
  final Color? highlightColor;
  final bool isActive;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final accent = highlightColor ?? Theme.of(context).colorScheme.primary;
    final shortestSide = MediaQuery.maybeSizeOf(context)?.shortestSide ?? 600;
    final compactText = shortestSide < 430;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow =
            constraints.hasBoundedWidth && constraints.maxWidth < 168;
        final isVeryNarrow =
            constraints.hasBoundedWidth && constraints.maxWidth < 146;
        final effectiveHeight = compactText && isNarrow
            ? (height < 74 ? 74.0 : height)
            : height;

        return SizedBox(
          height: effectiveHeight,
          width: expand ? double.infinity : null,
          child: _PressResponsiveSurface(
            onPressed: onPressed,
            accentColor: accent,
            borderRadius: BorderRadius.circular(22),
            child: GlassContainer(
              onTap: onPressed,
              borderRadius: 22,
              tintColor: isActive ? accent : Colors.white,
              opacity: isActive ? 0.22 : 0.12,
              borderColor: isActive
                  ? accent.withValues(alpha: 0.55)
                  : Colors.white.withValues(alpha: 0.16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isActive ? 0.22 : 0.14),
                  blurRadius: isActive ? 34 : 26,
                  offset: const Offset(0, 18),
                ),
                BoxShadow(
                  color: accent.withValues(alpha: isActive ? 0.22 : 0.1),
                  blurRadius: isActive ? 30 : 18,
                  spreadRadius: isActive ? 1.4 : 0.0,
                ),
              ],
              padding: EdgeInsets.symmetric(
                horizontal: isNarrow ? 12 : 18,
                vertical: compactText ? 10 : 14,
              ),
              child: Row(
                mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null && !isVeryNarrow) ...[
                    Icon(
                      icon,
                      size: compactText ? 15 : 18,
                      color: Colors.white.withValues(alpha: 0.92),
                    ),
                    SizedBox(width: compactText ? 5 : 8),
                  ],
                  Flexible(
                    child: Text(
                      text,
                      textAlign: TextAlign.center,
                      softWrap: true,
                      maxLines: (compactText || isNarrow) ? 3 : 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: Colors.white.withValues(alpha: 0.94),
                        fontSize: isVeryNarrow
                            ? 10.8
                            : compactText
                            ? 11.8
                            : null,
                        height: 1.16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class GlassIconButton extends StatelessWidget {
  const GlassIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.size = 54,
    this.highlightColor,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final double size;
  final Color? highlightColor;

  @override
  Widget build(BuildContext context) {
    final accent = highlightColor ?? Theme.of(context).colorScheme.primary;

    return SizedBox(
      width: size,
      height: size,
      child: _PressResponsiveSurface(
        onPressed: onPressed,
        accentColor: accent,
        borderRadius: BorderRadius.circular(size / 2),
        child: GlassContainer(
          onTap: onPressed,
          borderRadius: size / 2,
          tintColor: highlightColor ?? Colors.white,
          opacity: highlightColor == null ? 0.1 : 0.18,
          borderColor: highlightColor == null
              ? Colors.white.withValues(alpha: 0.18)
              : accent.withValues(alpha: 0.46),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.16),
              blurRadius: 28,
              offset: const Offset(0, 16),
            ),
            BoxShadow(
              color: accent.withValues(
                alpha: highlightColor == null ? 0.08 : 0.22,
              ),
              blurRadius: 24,
              spreadRadius: highlightColor == null ? 0 : 1.2,
            ),
          ],
          padding: EdgeInsets.zero,
          child: Icon(
            icon,
            color: Colors.white.withValues(alpha: 0.94),
            size: size * 0.42,
          ),
        ),
      ),
    );
  }
}

class _PressResponsiveSurface extends StatefulWidget {
  const _PressResponsiveSurface({
    required this.child,
    required this.onPressed,
    required this.accentColor,
    required this.borderRadius,
  });

  final Widget child;
  final VoidCallback? onPressed;
  final Color accentColor;
  final BorderRadius borderRadius;

  @override
  State<_PressResponsiveSurface> createState() =>
      _PressResponsiveSurfaceState();
}

class _PressResponsiveSurfaceState extends State<_PressResponsiveSurface> {
  Timer? _flashTimer;
  bool _pressed = false;
  bool _flash = false;

  bool get _enabled => widget.onPressed != null;

  @override
  void dispose() {
    _flashTimer?.cancel();
    super.dispose();
  }

  void _setPressed(bool value) {
    if (!_enabled || _pressed == value) {
      return;
    }
    setState(() => _pressed = value);
  }

  void _triggerFlash() {
    if (!_enabled) {
      return;
    }
    _flashTimer?.cancel();
    setState(() => _flash = true);
    _flashTimer = Timer(const Duration(milliseconds: 220), () {
      if (mounted) {
        setState(() => _flash = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: _enabled ? (_) => _setPressed(true) : null,
      onPointerUp: _enabled
          ? (_) {
              _setPressed(false);
              _triggerFlash();
            }
          : null,
      onPointerCancel: _enabled ? (_) => _setPressed(false) : null,
      child: AnimatedScale(
        scale: _pressed ? 0.95 : 1.0,
        duration: Duration(milliseconds: _pressed ? 70 : 220),
        curve: _pressed ? Curves.easeOutCubic : Curves.easeOutBack,
        child: AnimatedSlide(
          offset: _pressed ? const Offset(0, 0.018) : Offset.zero,
          duration: Duration(milliseconds: _pressed ? 70 : 220),
          curve: _pressed ? Curves.easeOutCubic : Curves.easeOutBack,
          child: Stack(
            fit: StackFit.passthrough,
            children: [
              widget.child,
              Positioned.fill(
                child: IgnorePointer(
                  child: AnimatedOpacity(
                    opacity: _flash ? 1 : 0,
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOutCubic,
                    child: ClipRRect(
                      borderRadius: widget.borderRadius,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: RadialGradient(
                            center: const Alignment(0, -0.25),
                            radius: 0.86,
                            colors: [
                              widget.accentColor.withValues(alpha: 0.28),
                              Colors.white.withValues(alpha: 0.12),
                              Colors.transparent,
                            ],
                            stops: const [0.0, 0.32, 1.0],
                          ),
                        ),
                      ),
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
