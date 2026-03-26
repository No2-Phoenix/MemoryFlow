import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

import 'experience_controller_v2.dart';
import 'story_moment_data.dart';

class StoryTextStage extends StatelessWidget {
  const StoryTextStage({
    super.key,
    required this.story,
    required this.mode,
    required this.lowEffects,
    required this.textColor,
    required this.shadowColor,
  });

  final StoryMoment story;
  final StoryTextMode mode;
  final bool lowEffects;
  final Color textColor;
  final Color shadowColor;

  @override
  Widget build(BuildContext context) {
    switch (mode) {
      case StoryTextMode.lyrics:
        final displayLines = _normalizeDisplayLines(story.lines, maxChars: 12);
        return _LyricFlowText(
          lines: displayLines,
          lowEffects: lowEffects,
          textColor: textColor,
          shadowColor: shadowColor,
        );
      case StoryTextMode.subtitle:
        final displayLines = _normalizeDisplayLines(story.lines);
        return _SubtitleText(
          lines: displayLines,
          lowEffects: lowEffects,
          textColor: textColor,
          shadowColor: shadowColor,
        );
      case StoryTextMode.credits:
        final displayLines = _normalizeDisplayLines(story.lines);
        return _CreditsText(
          lines: displayLines,
          textColor: textColor,
          shadowColor: shadowColor,
        );
      case StoryTextMode.typewriter:
        final displayLines = _normalizeDisplayLines(story.lines);
        return _TypewriterText(
          lines: displayLines,
          textColor: textColor,
          shadowColor: shadowColor,
        );
    }
  }
}

class _LyricFlowText extends StatefulWidget {
  const _LyricFlowText({
    required this.lines,
    required this.lowEffects,
    required this.textColor,
    required this.shadowColor,
  });

  final List<String> lines;
  final bool lowEffects;
  final Color textColor;
  final Color shadowColor;

  @override
  State<_LyricFlowText> createState() => _LyricFlowTextState();
}

class _LyricFlowTextState extends State<_LyricFlowText> {
  Timer? _timer;
  Timer? _resumeTimer;
  double _scrollOffset = 0;
  bool _autoScroll = true;

  double get _lineGap => widget.lowEffects ? 96 : 102;
  double get _autoVelocity => widget.lowEffects ? 0.5 : 0.56;

  @override
  void initState() {
    super.initState();
    _startAutoScroll();
  }

  @override
  void didUpdateWidget(covariant _LyricFlowText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.lines.join() != widget.lines.join()) {
      _scrollOffset = 0;
    }
    if (oldWidget.lowEffects != widget.lowEffects) {
      _startAutoScroll();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _resumeTimer?.cancel();
    super.dispose();
  }

  void _startAutoScroll() {
    _timer?.cancel();
    _timer = Timer.periodic(
      Duration(milliseconds: widget.lowEffects ? 42 : 28),
      (_) {
        if (!_autoScroll || !mounted) {
          return;
        }
        setState(() => _advance(_autoVelocity));
      },
    );
  }

  void _advance(double delta) {
    final totalSpan = math.max(widget.lines.length * _lineGap, _lineGap);
    _scrollOffset = (_scrollOffset + delta) % totalSpan;
    if (_scrollOffset < 0) {
      _scrollOffset += totalSpan;
    }
  }

  void _pauseTemporarily([Duration duration = const Duration(seconds: 2)]) {
    _autoScroll = false;
    _resumeTimer?.cancel();
    _resumeTimer = Timer(duration, () {
      if (mounted) {
        setState(() => _autoScroll = true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final viewportHeight = constraints.maxHeight;
        final viewportWidth = constraints.maxWidth;
        final centerY = viewportHeight * 0.52;
        final entryY = viewportHeight * 1.05;
        final focusRange = math.max(viewportHeight * 0.54, 140);
        final totalSpan = math.max(widget.lines.length * _lineGap, _lineGap);
        final widgets = <Widget>[];

        for (int copy = -1; copy <= 1; copy++) {
          for (int index = 0; index < widget.lines.length; index++) {
            final y =
                entryY + index * _lineGap + copy * totalSpan - _scrollOffset;
            if (y < -_lineGap * 1.4 || y > viewportHeight + _lineGap * 1.4) {
              continue;
            }

            final signedDistance = ((y - centerY) / focusRange)
                .clamp(-1.0, 1.0)
                .toDouble();
            final normalized = signedDistance.abs();
            final focus = 1 - Curves.easeOutCubic.transform(normalized);
            final easedFocus = Curves.easeInOutCubic.transform(focus);
            final opacity = lerpDouble(0.24, 1.0, easedFocus)!.clamp(0.0, 1.0);
            final lineWidth = viewportWidth * (widget.lowEffects ? 0.9 : 0.86);

            widgets.add(
              Positioned(
                left: (viewportWidth - lineWidth) / 2,
                top: y - _lineGap / 2,
                width: lineWidth,
                child: Opacity(
                  opacity: opacity,
                  child: Text(
                    widget.lines[index],
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.clip,
                    textAlign: TextAlign.center,
                    strutStyle: const StrutStyle(
                      forceStrutHeight: true,
                      height: 1.42,
                      leading: 0.2,
                    ),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: widget.textColor.withValues(
                        alpha: lerpDouble(0.42, 1.0, easedFocus)!,
                      ),
                      height: 1.42,
                      fontSize: widget.lowEffects ? 17 : 18,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0,
                      shadows: widget.lowEffects
                          ? const []
                          : [
                              Shadow(
                                color: widget.shadowColor.withValues(
                                  alpha: lerpDouble(0.08, 0.2, easedFocus)!,
                                ),
                                blurRadius: 5.5,
                                offset: const Offset(0, 2),
                              ),
                            ],
                    ),
                  ),
                ),
              ),
            );
          }
        }

        return GestureDetector(
          onVerticalDragStart: (_) =>
              _pauseTemporarily(const Duration(seconds: 3)),
          onVerticalDragUpdate: (details) {
            setState(() => _advance(-details.delta.dy * 1.04));
          },
          onVerticalDragEnd: (_) => _pauseTemporarily(),
          child: ClipRect(child: Stack(children: [...widgets])),
        );
      },
    );
  }
}

class _SubtitleText extends StatefulWidget {
  const _SubtitleText({
    required this.lines,
    required this.lowEffects,
    required this.textColor,
    required this.shadowColor,
  });

  final List<String> lines;
  final bool lowEffects;
  final Color textColor;
  final Color shadowColor;

  @override
  State<_SubtitleText> createState() => _SubtitleTextState();
}

class _SubtitleTextState extends State<_SubtitleText> {
  Timer? _timer;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (mounted) {
        setState(() => _index = (_index + 1) % widget.lines.length);
      }
    });
  }

  @override
  void didUpdateWidget(covariant _SubtitleText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.lines.join() != widget.lines.join()) {
      _index = 0;
    } else if (_index >= widget.lines.length) {
      _index = 0;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 680),
        switchInCurve: Curves.easeOutQuart,
        switchOutCurve: Curves.easeInQuart,
        transitionBuilder: (child, animation) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutQuart,
            reverseCurve: Curves.easeInQuart,
          );
          return FadeTransition(
            opacity: curved,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.16),
                end: Offset.zero,
              ).animate(curved),
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.985, end: 1).animate(curved),
                child: child,
              ),
            ),
          );
        },
        child: _TextChip(
          key: ValueKey(_index),
          enableBackdropBlur: !widget.lowEffects,
          text: widget.lines[_index],
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: widget.textColor,
            height: 1.4,
            shadows: [Shadow(color: widget.shadowColor, blurRadius: 16)],
          ),
        ),
      ),
    );
  }
}

class _CreditsText extends StatefulWidget {
  const _CreditsText({
    required this.lines,
    required this.textColor,
    required this.shadowColor,
  });

  final List<String> lines;
  final Color textColor;
  final Color shadowColor;

  @override
  State<_CreditsText> createState() => _CreditsTextState();
}

class _CreditsTextState extends State<_CreditsText>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: Duration(seconds: math.max(18, widget.lines.length * 4)),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final contentHeight = widget.lines.length * 72.0;
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final dy = lerpDouble(
              constraints.maxHeight,
              -contentHeight,
              _controller.value,
            )!;
            return Transform.translate(offset: Offset(0, dy), child: child);
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: widget.lines
                .map(
                  (line) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      line,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontSize: 18,
                        color: widget.textColor,
                        shadows: [
                          Shadow(color: widget.shadowColor, blurRadius: 14),
                        ],
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        );
      },
    );
  }
}

class _TypewriterText extends StatefulWidget {
  const _TypewriterText({
    required this.lines,
    required this.textColor,
    required this.shadowColor,
  });

  final List<String> lines;
  final Color textColor;
  final Color shadowColor;

  @override
  State<_TypewriterText> createState() => _TypewriterTextState();
}

class _TypewriterTextState extends State<_TypewriterText> {
  Timer? _timer;
  int _lineIndex = 0;
  int _charCount = 0;
  int _pauseTicks = 0;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 46), (_) {
      final currentLine = widget.lines[_lineIndex];
      if (_charCount < currentLine.length) {
        setState(() => _charCount++);
      } else if (_pauseTicks < 16) {
        _pauseTicks++;
      } else {
        setState(() {
          _pauseTicks = 0;
          _charCount = 0;
          _lineIndex = (_lineIndex + 1) % widget.lines.length;
        });
      }
    });
  }

  @override
  void didUpdateWidget(covariant _TypewriterText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.lines.join() != widget.lines.join()) {
      _lineIndex = 0;
      _charCount = 0;
      _pauseTicks = 0;
    } else if (_lineIndex >= widget.lines.length) {
      _lineIndex = 0;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentLine = widget.lines[_lineIndex];
    final visible = currentLine.substring(
      0,
      _charCount.clamp(0, currentLine.length),
    );

    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        '$visible${_charCount.isEven ? '|' : ' '}',
        maxLines: 3,
        overflow: TextOverflow.fade,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          fontSize: 18,
          color: widget.textColor,
          height: 1.52,
          shadows: [Shadow(color: widget.shadowColor, blurRadius: 14)],
        ),
      ),
    );
  }
}

class _TextChip extends StatelessWidget {
  const _TextChip({
    super.key,
    required this.text,
    required this.style,
    this.enableBackdropBlur = true,
  });

  final String text;
  final TextStyle? style;
  final bool enableBackdropBlur;

  @override
  Widget build(BuildContext context) {
    final content = Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        color: Colors.white.withValues(alpha: 0.1),
      ),
      child: Text(text, textAlign: TextAlign.center, style: style),
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: enableBackdropBlur
          ? BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: content,
            )
          : content,
    );
  }
}

List<String> _normalizeDisplayLines(
  List<String> rawLines, {
  int maxChars = 18,
}) {
  final normalized = <String>[];
  for (final line in rawLines) {
    final cleaned = line.trim();
    if (cleaned.isEmpty) {
      continue;
    }
    normalized.addAll(_splitLongLine(cleaned, maxChars: maxChars));
  }
  if (normalized.isEmpty) {
    return const [''];
  }
  return normalized;
}

List<String> _splitLongLine(String line, {required int maxChars}) {
  if (line.runes.length <= maxChars) {
    return [line];
  }

  final output = <String>[];
  final runes = line.runes.toList();
  var start = 0;
  while (start < runes.length) {
    var end = math.min(start + maxChars, runes.length);
    if (end < runes.length) {
      for (var cursor = end; cursor > start + 6; cursor--) {
        final ch = String.fromCharCode(runes[cursor - 1]);
        if (RegExp(r'[，。！？；、,\.\!\?;:\s]').hasMatch(ch)) {
          end = cursor;
          break;
        }
      }
    }
    final chunk = String.fromCharCodes(runes.sublist(start, end)).trim();
    if (chunk.isNotEmpty) {
      output.add(chunk);
    }
    start = end;
  }
  return output;
}
