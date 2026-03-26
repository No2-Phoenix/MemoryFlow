import 'dart:ui';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/gradient_themes.dart';
import '../../core/utils/color_utils.dart';
import '../../shared/glass_button.dart';
import '../../shared/gradient_background.dart';
import '../../shared/story_artwork.dart';
import 'experience_controller_v2.dart';
import 'home_text_modes.dart';
import 'story_moment_data.dart';

class HomePlayerStage extends StatelessWidget {
  const HomePlayerStage({
    super.key,
    required this.isCompact,
    required this.lowEffects,
    required this.currentStory,
    required this.storyDirection,
    required this.ambientLabel,
    required this.experience,
    required this.theme,
    required this.onOpenDrawer,
    required this.onOpenCreator,
    required this.onEditCurrent,
    required this.onSelectPrevious,
    required this.onSelectNext,
    required this.onOpenOverview,
  });

  final bool isCompact;
  final bool lowEffects;
  final StoryMoment currentStory;
  final int storyDirection;
  final String ambientLabel;
  final ExperienceState experience;
  final GradientThemeData theme;
  final VoidCallback onOpenDrawer;
  final VoidCallback onOpenCreator;
  final VoidCallback onEditCurrent;
  final VoidCallback onSelectPrevious;
  final VoidCallback onSelectNext;
  final VoidCallback onOpenOverview;

  @override
  Widget build(BuildContext context) {
    final metaLine = buildMetaLine(
      story: currentStory,
      showDate: currentStory.showDate,
      showLocation: currentStory.showLocation,
      fallback: '',
    );

    return Padding(
      padding: EdgeInsets.fromLTRB(
        isCompact ? 12 : 24,
        12,
        isCompact ? 12 : 24,
        isCompact ? 16 : 24,
      ),
      child: Column(
        children: [
          Row(
            children: [
              GlassIconButton(
                icon: Icons.menu_rounded,
                onPressed: onOpenDrawer,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      'MemoryFlow',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    if (metaLine.trim().isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        metaLine,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                    ],
                  ],
                ),
              ),
              GlassIconButton(
                icon: Icons.add_rounded,
                onPressed: onOpenCreator,
                highlightColor: theme.accentColor,
              ),
            ],
          ),
          SizedBox(height: isCompact ? 14 : 20),
          Expanded(
            child: GestureDetector(
              onHorizontalDragEnd: (details) {
                if (details.primaryVelocity == null) {
                  return;
                }
                if (details.primaryVelocity! < -60) {
                  onSelectNext();
                } else if (details.primaryVelocity! > 60) {
                  onSelectPrevious();
                }
              },
              child: isCompact
                  ? _CompactPlayerBody(
                      lowEffects: lowEffects,
                      currentStory: currentStory,
                      storyDirection: storyDirection,
                      ambientLabel: ambientLabel,
                      experience: experience,
                      onEditCurrent: onEditCurrent,
                    )
                  : _WidePlayerBody(
                      lowEffects: lowEffects,
                      currentStory: currentStory,
                      storyDirection: storyDirection,
                      ambientLabel: ambientLabel,
                      experience: experience,
                      onEditCurrent: onEditCurrent,
                    ),
            ),
          ),
          SizedBox(height: isCompact ? 12 : 18),
          _BottomIndicator(
            storyChangeToken: experience.storyIndex,
            storyDirection: storyDirection,
            accentColor: theme.accentColor,
            onLongPress: onOpenOverview,
          ),
        ],
      ),
    );
  }
}

class _CompactPlayerBody extends StatelessWidget {
  const _CompactPlayerBody({
    required this.lowEffects,
    required this.currentStory,
    required this.storyDirection,
    required this.ambientLabel,
    required this.experience,
    required this.onEditCurrent,
  });

  final bool lowEffects;
  final StoryMoment currentStory;
  final int storyDirection;
  final String ambientLabel;
  final ExperienceState experience;
  final VoidCallback onEditCurrent;

  @override
  Widget build(BuildContext context) {
    return _PrimaryStoryFrame(
      lowEffects: lowEffects,
      story: currentStory,
      mode: currentStory.textMode,
      ambientLabel: ambientLabel,
      storyDirection: storyDirection,
      showDate: currentStory.showDate,
      showLocation: currentStory.showLocation,
      showTitle: experience.showTitle,
      showCaption: experience.showCaption,
      showAmbient: false,
      isCompact: true,
      onEditCurrent: onEditCurrent,
    );
  }
}

class _WidePlayerBody extends StatelessWidget {
  const _WidePlayerBody({
    required this.lowEffects,
    required this.currentStory,
    required this.storyDirection,
    required this.ambientLabel,
    required this.experience,
    required this.onEditCurrent,
  });

  final bool lowEffects;
  final StoryMoment currentStory;
  final int storyDirection;
  final String ambientLabel;
  final ExperienceState experience;
  final VoidCallback onEditCurrent;

  @override
  Widget build(BuildContext context) {
    return _PrimaryStoryFrame(
      lowEffects: lowEffects,
      story: currentStory,
      mode: currentStory.textMode,
      ambientLabel: ambientLabel,
      storyDirection: storyDirection,
      showDate: currentStory.showDate,
      showLocation: currentStory.showLocation,
      showTitle: experience.showTitle,
      showCaption: experience.showCaption,
      showAmbient: false,
      isCompact: false,
      onEditCurrent: onEditCurrent,
    );
  }
}

class _PrimaryStoryFrame extends StatelessWidget {
  const _PrimaryStoryFrame({
    required this.lowEffects,
    required this.story,
    required this.mode,
    required this.ambientLabel,
    required this.storyDirection,
    required this.showDate,
    required this.showLocation,
    required this.showTitle,
    required this.showCaption,
    required this.showAmbient,
    required this.isCompact,
    required this.onEditCurrent,
  });

  final bool lowEffects;
  final StoryMoment story;
  final StoryTextMode mode;
  final String ambientLabel;
  final int storyDirection;
  final bool showDate;
  final bool showLocation;
  final bool showTitle;
  final bool showCaption;
  final bool showAmbient;
  final bool isCompact;
  final VoidCallback onEditCurrent;

  @override
  Widget build(BuildContext context) {
    final insetY = isCompact ? 6.0 : 8.0;

    return Transform.translate(
      offset: Offset(0, insetY),
      child: GlassContainer(
        borderRadius: isCompact ? 36 : 40,
        tintColor: story.dominantColor,
        opacity: 0.1,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.32),
            blurRadius: 56,
            offset: const Offset(0, 34),
          ),
          BoxShadow(
            color: story.dominantColor.withValues(alpha: 0.12),
            blurRadius: 22,
            spreadRadius: 0.8,
          ),
        ],
        padding: const EdgeInsets.all(10),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(isCompact ? 28 : 32),
          child: AnimatedSwitcher(
            duration: Duration(milliseconds: lowEffects ? 360 : 520),
            switchInCurve: Curves.easeInOutCubic,
            switchOutCurve: Curves.easeInOutCubic,
            layoutBuilder: (currentChild, previousChildren) {
              return Stack(
                fit: StackFit.expand,
                children: [...previousChildren, ?currentChild],
              );
            },
            transitionBuilder: (child, animation) {
              final isIncoming = child.key == ValueKey(story.id);
              final direction = isIncoming ? storyDirection : -storyDirection;
              final curved = CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutExpo,
                reverseCurve: Curves.easeInCubic,
              );

              return AnimatedBuilder(
                animation: curved,
                child: child,
                builder: (context, transitionChild) {
                  final progress = curved.value;
                  final motion = Curves.easeInOutCubic.transform(progress);
                  final offset = Tween<Offset>(
                    begin: Offset(
                      direction * (isCompact ? 36 : 54),
                      isIncoming ? 10 : -8,
                    ),
                    end: Offset.zero,
                  ).transform(motion);
                  final scale = Tween<double>(
                    begin: isIncoming ? 0.96 : 1.02,
                    end: 1,
                  ).transform(motion);
                  final opacity = isIncoming
                      ? Interval(
                          0.08,
                          1,
                          curve: Curves.easeOutCubic,
                        ).transform(progress)
                      : Tween<double>(begin: 1, end: 0.14).transform(motion);
                  if (lowEffects) {
                    return Opacity(
                      opacity: opacity,
                      child: Transform.translate(
                        offset: offset,
                        child: Transform(
                          alignment: Alignment.center,
                          transform: Matrix4.identity()
                            ..scaleByDouble(scale, scale, scale, 1),
                          child: transitionChild,
                        ),
                      ),
                    );
                  }

                  final glowAlpha = isIncoming
                      ? lerpDouble(0.12, 0, motion)!
                      : lerpDouble(0.08, 0, motion)!;
                  final shadowAlpha = isIncoming
                      ? lerpDouble(0.1, 0.03, motion)!
                      : lerpDouble(0.06, 0, motion)!;

                  return Opacity(
                    opacity: opacity,
                    child: Transform.translate(
                      offset: offset,
                      child: Transform(
                        alignment: Alignment.center,
                        transform: Matrix4.identity()
                          ..scaleByDouble(scale, scale, scale, 1),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            ?transitionChild,
                            IgnorePointer(
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment(
                                      direction > 0 ? -1.1 : 1.1,
                                      -0.3,
                                    ),
                                    end: Alignment.center,
                                    colors: [
                                      Colors.white.withValues(alpha: glowAlpha),
                                      story.dominantColor.withValues(
                                        alpha: shadowAlpha,
                                      ),
                                      Colors.transparent,
                                    ],
                                    stops: const [0.0, 0.22, 1.0],
                                  ),
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
            },
            child: _StoryCanvas(
              key: ValueKey(story.id),
              lowEffects: lowEffects,
              story: story,
              mode: mode,
              ambientLabel: ambientLabel,
              storyDirection: storyDirection,
              showDate: showDate,
              showLocation: showLocation,
              showTitle: showTitle,
              showCaption: showCaption,
              showAmbient: showAmbient,
              isCompact: isCompact,
              onEditCurrent: onEditCurrent,
            ),
          ),
        ),
      ),
    );
  }
}

class _StoryCanvas extends StatelessWidget {
  const _StoryCanvas({
    super.key,
    required this.lowEffects,
    required this.story,
    required this.mode,
    required this.ambientLabel,
    required this.storyDirection,
    required this.showDate,
    required this.showLocation,
    required this.showTitle,
    required this.showCaption,
    required this.showAmbient,
    required this.isCompact,
    required this.onEditCurrent,
  });

  final bool lowEffects;
  final StoryMoment story;
  final StoryTextMode mode;
  final String ambientLabel;
  final int storyDirection;
  final bool showDate;
  final bool showLocation;
  final bool showTitle;
  final bool showCaption;
  final bool showAmbient;
  final bool isCompact;
  final VoidCallback onEditCurrent;

  @override
  Widget build(BuildContext context) {
    final isLight = ColorUtils.isColorLight(story.dominantColor);
    final textColor = isLight
        ? Colors.black.withValues(alpha: 0.9)
        : Colors.white.withValues(alpha: 0.97);
    final shadowColor = isLight
        ? Colors.white.withValues(alpha: 0.24)
        : Colors.black.withValues(alpha: 0.54);
    final hasCaptionCard = showTitle || showCaption;
    final baseTextStageBottomInset = isCompact
        ? (hasCaptionCard
              ? (showAmbient ? 144.0 : 94.0)
              : (showAmbient ? 90.0 : 28.0))
        : (hasCaptionCard
              ? (showAmbient ? 122.0 : 88.0)
              : (showAmbient ? 86.0 : 30.0));
    final subtitleInsetBoost = mode == StoryTextMode.subtitle && hasCaptionCard
        ? (isCompact ? 62.0 : 50.0)
        : 0.0;
    final textStageBottomInset = baseTextStageBottomInset + subtitleInsetBoost;

    return Stack(
      fit: StackFit.expand,
      children: [
        TweenAnimationBuilder<double>(
          key: ValueKey('artwork-motion-${story.id}'),
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 560),
          curve: Curves.easeOutQuart,
          builder: (context, value, child) {
            final shiftX = lerpDouble(
              storyDirection * (isCompact ? 16 : 24),
              0,
              value,
            )!;
            final shiftY = lerpDouble(10, 0, value)!;
            final scale = lerpDouble(1.04, 1, value)!;

            return Transform.translate(
              offset: Offset(shiftX, shiftY),
              child: Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..scaleByDouble(scale, scale, scale, 1),
                child: child,
              ),
            );
          },
          child: RepaintBoundary(
            child: StoryArtwork(
              palette: story.palette,
              imagePath: story.coverImagePath,
              imageBlurSigma: story.coverBlurSigma,
              overlayColor: story.dominantColor,
            ),
          ),
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withValues(alpha: 0.14),
                    story.dominantColor.withValues(alpha: 0.08),
                    Colors.black.withValues(alpha: 0.34),
                  ],
                  stops: const [0.0, 0.36, 1.0],
                ),
              ),
            ),
          ),
        ),
        if (!lowEffects)
          Positioned.fill(
            child: IgnorePointer(
              child: TweenAnimationBuilder<double>(
                key: ValueKey('story-sheen-${story.id}'),
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 760),
                curve: Curves.easeOutCubic,
                builder: (context, value, child) {
                  final opacity = lerpDouble(0.28, 0, value)!;
                  final dx = lerpDouble(-180, 220, value)!;
                  final dy = lerpDouble(90, -60, value)!;

                  return Opacity(
                    opacity: opacity,
                    child: Transform.translate(
                      offset: Offset(dx, dy),
                      child: child,
                    ),
                  );
                },
                child: Transform.rotate(
                  angle: -0.58,
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: SizedBox(
                      width: isCompact ? 170 : 220,
                      height: isCompact ? 420 : 540,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.white.withValues(alpha: 0.34),
                              Colors.white.withValues(alpha: 0.14),
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
            ),
          ),
        Positioned(
          left: isCompact ? 18 : 24,
          right: isCompact ? 18 : 24,
          top: 22,
          bottom: textStageBottomInset,
          child: TweenAnimationBuilder<double>(
            key: ValueKey('text-stage-${story.id}'),
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 720),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              final opacity = Interval(
                0.14,
                1,
                curve: Curves.easeOutCubic,
              ).transform(value);
              final dx = lerpDouble(
                storyDirection * (isCompact ? 18 : 28),
                0,
                value,
              )!;
              final dy = lerpDouble(18, 0, value)!;

              return Opacity(
                opacity: opacity,
                child: Transform.translate(
                  offset: Offset(dx, dy),
                  child: child,
                ),
              );
            },
            child: StoryTextStage(
              story: story,
              mode: mode,
              textColor: textColor,
              shadowColor: shadowColor,
            ),
          ),
        ),
        Positioned(
          left: isCompact ? 14 : 18,
          right: isCompact ? 14 : 18,
          bottom: isCompact ? 14 : 18,
          child: isCompact
              ? Column(
                  children: [
                    if (hasCaptionCard)
                      TweenAnimationBuilder<double>(
                        key: ValueKey(
                          'caption-card-${story.id}-$showTitle-$showCaption',
                        ),
                        tween: Tween(begin: 0, end: 1),
                        duration: const Duration(milliseconds: 780),
                        curve: Curves.easeOutCubic,
                        builder: (context, value, child) {
                          final opacity = Interval(
                            0.1,
                            1,
                            curve: Curves.easeOutCubic,
                          ).transform(value);
                          final dy = lerpDouble(28, 0, value)!;

                          return Opacity(
                            opacity: opacity,
                            child: Transform.translate(
                              offset: Offset(0, dy),
                              child: child,
                            ),
                          );
                        },
                        child: _StoryCaptionCard(
                          story: story,
                          showTitle: showTitle,
                          showCaption: showCaption,
                        ),
                      ),
                    if (showAmbient) ...[
                      SizedBox(height: hasCaptionCard ? 10 : 0),
                      Row(
                        children: [
                          Expanded(
                            child: _AmbientChip(
                              story: story,
                              label: '氛围声场 · $ambientLabel',
                            ),
                          ),
                          const SizedBox(width: 10),
                          GlassIconButton(
                            icon: Icons.edit_outlined,
                            size: 46,
                            onPressed: onEditCurrent,
                          ),
                        ],
                      ),
                    ] else
                      Align(
                        alignment: Alignment.centerRight,
                        child: GlassIconButton(
                          icon: Icons.edit_outlined,
                          size: 46,
                          onPressed: onEditCurrent,
                        ),
                      ),
                  ],
                )
              : Row(
                  children: hasCaptionCard
                      ? [
                          Expanded(
                            child: TweenAnimationBuilder<double>(
                              key: ValueKey(
                                'caption-card-wide-${story.id}-$showTitle-$showCaption',
                              ),
                              tween: Tween(begin: 0, end: 1),
                              duration: const Duration(milliseconds: 780),
                              curve: Curves.easeOutCubic,
                              builder: (context, value, child) {
                                final opacity = Interval(
                                  0.1,
                                  1,
                                  curve: Curves.easeOutCubic,
                                ).transform(value);
                                final dx = lerpDouble(
                                  storyDirection * 18,
                                  0,
                                  value,
                                )!;
                                final dy = lerpDouble(18, 0, value)!;

                                return Opacity(
                                  opacity: opacity,
                                  child: Transform.translate(
                                    offset: Offset(dx, dy),
                                    child: child,
                                  ),
                                );
                              },
                              child: _StoryCaptionCard(
                                story: story,
                                showTitle: showTitle,
                                showCaption: showCaption,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (showAmbient)
                                _AmbientChip(
                                  story: story,
                                  label: '氛围声场 · $ambientLabel',
                                ),
                              if (showAmbient) const SizedBox(height: 10),
                              GlassIconButton(
                                icon: Icons.edit_outlined,
                                size: 46,
                                onPressed: onEditCurrent,
                              ),
                            ],
                          ),
                        ]
                      : [
                          const Spacer(),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              if (showAmbient)
                                _AmbientChip(
                                  story: story,
                                  label: '氛围声场 · $ambientLabel',
                                ),
                              if (showAmbient) const SizedBox(height: 10),
                              GlassIconButton(
                                icon: Icons.edit_outlined,
                                size: 46,
                                onPressed: onEditCurrent,
                              ),
                            ],
                          ),
                        ],
                ),
        ),
      ],
    );
  }
}

class _StoryCaptionCard extends StatelessWidget {
  const _StoryCaptionCard({
    required this.story,
    required this.showTitle,
    required this.showCaption,
  });

  final StoryMoment story;
  final bool showTitle;
  final bool showCaption;

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      borderRadius: 24,
      tintColor: story.dominantColor,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showTitle)
            Text(
              story.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          if (showTitle && showCaption) const SizedBox(height: 6),
          if (showCaption)
            Text(
              story.caption,
              maxLines: showTitle ? 2 : 3,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
        ],
      ),
    );
  }
}

class _AmbientChip extends StatelessWidget {
  const _AmbientChip({required this.story, required this.label});

  final StoryMoment story;
  final String label;

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      borderRadius: 24,
      tintColor: story.dominantColor,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Text(label, style: Theme.of(context).textTheme.labelLarge),
    );
  }
}

class _BottomIndicator extends StatefulWidget {
  const _BottomIndicator({
    required this.storyChangeToken,
    required this.storyDirection,
    required this.accentColor,
    required this.onLongPress,
  });

  final int storyChangeToken;
  final int storyDirection;
  final Color accentColor;
  final VoidCallback onLongPress;

  @override
  State<_BottomIndicator> createState() => _BottomIndicatorState();
}

class _BottomIndicatorState extends State<_BottomIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 360),
  );

  @override
  void didUpdateWidget(covariant _BottomIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.storyChangeToken != widget.storyChangeToken) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: widget.onLongPress,
      onLongPress: widget.onLongPress,
      onLongPressStart: (_) => widget.onLongPress(),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final pulse = math.sin(math.pi * _controller.value);
          final targetIndex = widget.storyDirection >= 0 ? 2 : 0;

          return SizedBox(
            width: 126,
            height: 44,
            child: Center(
              child: SizedBox(
                width: 72,
                height: 24,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(3, (index) {
                    var size = index == 1 ? 7.0 : 4.4;
                    var alpha = index == 1 ? 0.98 : 0.32;

                    if (index == 1) {
                      size -= 0.9 * pulse;
                    }
                    if (index == targetIndex) {
                      size += 1.8 * pulse;
                      alpha += 0.28 * pulse;
                    }

                    return Container(
                      width: size,
                      height: size,
                      margin: const EdgeInsets.symmetric(horizontal: 7),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(
                          alpha: alpha.clamp(0.0, 1.0),
                        ),
                        shape: BoxShape.circle,
                        boxShadow: index == 1
                            ? [
                                BoxShadow(
                                  color: widget.accentColor.withValues(
                                    alpha: 0.26 + 0.2 * (1 - pulse),
                                  ),
                                  blurRadius: 8 + 4 * (1 - pulse),
                                ),
                              ]
                            : null,
                      ),
                    );
                  }),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

String buildMetaLine({
  required StoryMoment story,
  required bool showDate,
  required bool showLocation,
  String fallback = '',
}) {
  final parts = <String>[
    if (showDate) story.dateLabel,
    if (showLocation) story.location,
  ].where((value) => value.trim().isNotEmpty).toList();
  return parts.isEmpty ? fallback : parts.join(' · ');
}
