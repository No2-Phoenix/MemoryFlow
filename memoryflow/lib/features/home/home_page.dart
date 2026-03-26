import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/gradient_themes.dart';
import 'experience_controller_v2.dart';
import 'home_ambient_audio_controller.dart';
import 'home_overview_layer.dart';
import 'home_player_stage.dart';
import 'home_settings_drawer.dart';
import 'story_library_controller.dart';
import 'story_moment_data.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _overviewController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  );
  int _lastStoryIndex = 0;
  int _storyDirection = 1;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final selection = ref.read(ambientPlaybackSelectionProvider);
      unawaited(ref.read(homeAmbientAudioControllerProvider).sync(selection));
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    unawaited(
      ref.read(homeAmbientAudioControllerProvider).handleLifecycleState(state),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _overviewController.dispose();
    super.dispose();
  }

  void _syncOverview(bool isOpen) {
    if (isOpen &&
        _overviewController.status != AnimationStatus.forward &&
        _overviewController.value != 1) {
      _overviewController.forward();
    } else if (!isOpen &&
        _overviewController.status != AnimationStatus.reverse &&
        _overviewController.value != 0) {
      _overviewController.reverse();
    }
  }

  void _updateStoryDirection(int nextIndex, int total) {
    if (nextIndex == _lastStoryIndex || total <= 1) {
      return;
    }

    final rawDiff = nextIndex - _lastStoryIndex;
    final wrappedForward = rawDiff == -(total - 1);
    final wrappedBackward = rawDiff == total - 1;

    _storyDirection = wrappedForward
        ? 1
        : wrappedBackward
        ? -1
        : (rawDiff >= 0 ? 1 : -1);
    _lastStoryIndex = nextIndex;
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AmbientPlaybackSelection>(ambientPlaybackSelectionProvider, (
      previous,
      next,
    ) {
      unawaited(ref.read(homeAmbientAudioControllerProvider).sync(next));
    });

    final experience = ref.watch(experienceControllerProvider);
    final stories = ref.watch(storiesProvider);
    final displayStories = stories.isEmpty
        ? [StoryMomentFallback.empty]
        : stories;
    final theme = ref.watch(currentThemeProvider);
    final controller = ref.read(experienceControllerProvider.notifier);

    _syncOverview(experience.isOverviewOpen);

    final safeIndex = experience.storyIndex
        .clamp(0, displayStories.length - 1)
        .toInt();
    _updateStoryDirection(safeIndex, displayStories.length);

    final currentStory = displayStories[safeIndex];
    final ambientLabel = experience.ambientPreset == '自动匹配'
        ? currentStory.ambientLabel
        : experience.ambientPreset;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isCompact = constraints.maxWidth < 980;
            final lowEffects = constraints.maxWidth < 430;

            return Stack(
              children: [
                Positioned.fill(
                  child: _HomeImmersiveBackdrop(
                    theme: theme,
                    storyColor: currentStory.dominantColor,
                    overviewProgress: _overviewController.value,
                    lowEffects: lowEffects,
                  ),
                ),
                AnimatedBuilder(
                  animation: _overviewController,
                  builder: (context, child) {
                    final progress = Curves.easeInOutCubic.transform(
                      _overviewController.value,
                    );
                    final scale = lerpDouble(1, 0.88, progress)!;
                    final opacity = lerpDouble(1, 0.42, progress)!;
                    final translateY = lerpDouble(0, 18, progress)!;
                    final stageTransform = Matrix4.identity()
                      ..scaleByDouble(scale, scale, scale, 1.0);
                    if (lowEffects) {
                      stageTransform.translateByDouble(
                        0.0,
                        translateY,
                        0.0,
                        1.0,
                      );
                    } else {
                      stageTransform
                        ..setEntry(3, 2, 0.0012)
                        ..translateByDouble(
                          0.0,
                          translateY,
                          lerpDouble(0, -120, progress)!,
                          1.0,
                        );
                    }

                    return Transform(
                      alignment: Alignment.center,
                      transform: stageTransform,
                      child: Opacity(
                        opacity: opacity,
                        child: RepaintBoundary(
                          child: HomePlayerStage(
                            isCompact: isCompact,
                            lowEffects: lowEffects,
                            currentStory: currentStory,
                            storyDirection: _storyDirection,
                            ambientLabel: ambientLabel,
                            experience: experience,
                            theme: theme,
                            onOpenDrawer: controller.toggleDrawer,
                            onOpenCreator: () =>
                                context.push('${AppRoutes.creator}?mode=new'),
                            onEditCurrent: () =>
                                context.push(AppRoutes.creator),
                            onSelectPrevious: controller.previousStory,
                            onSelectNext: controller.nextStory,
                            onOpenOverview: controller.openOverview,
                          ),
                        ),
                      ),
                    );
                  },
                ),
                if (!lowEffects && !experience.isOverviewOpen)
                  Positioned.fill(
                    child: _HomeDepthShadowLayer(
                      theme: theme,
                      storyColor: currentStory.dominantColor,
                      overviewProgress: _overviewController.value,
                      lowEffects: lowEffects,
                    ),
                  ),
                if (!experience.isOverviewOpen)
                  Positioned.fill(
                    child: _HomeImmersiveForeground(
                      storyColor: currentStory.dominantColor,
                      overviewProgress: _overviewController.value,
                      lowEffects: lowEffects,
                    ),
                  ),
                Positioned.fill(
                  child: IgnorePointer(
                    ignoring: !experience.isOverviewOpen,
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOutCubic,
                      opacity: experience.isOverviewOpen ? 1 : 0,
                      child: HomeOverviewLayer(
                        isCompact: isCompact,
                        stories: stories,
                        selectedIndex: safeIndex,
                        onClose: controller.closeOverview,
                        onSelectStory: controller.selectStory,
                      ),
                    ),
                  ),
                ),
                HomeSettingsDrawer(
                  isCompact: isCompact,
                  maxWidth: constraints.maxWidth,
                  isOpen: experience.isDrawerOpen,
                  state: experience,
                  onClose: controller.closeDrawer,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _HomeImmersiveBackdrop extends StatelessWidget {
  const _HomeImmersiveBackdrop({
    required this.theme,
    required this.storyColor,
    required this.overviewProgress,
    required this.lowEffects,
  });

  final GradientThemeData theme;
  final Color storyColor;
  final double overviewProgress;
  final bool lowEffects;

  @override
  Widget build(BuildContext context) {
    final overviewDim = Curves.easeOutCubic.transform(overviewProgress);
    final isBright = theme.isBright;
    final vignetteAlpha = lerpDouble(
      isBright ? 0.08 : 0.12,
      isBright ? 0.16 : 0.24,
      overviewDim,
    )!;
    final size = MediaQuery.sizeOf(context);
    final minDimension = math.min(size.width, size.height);
    final scale = (minDimension / 900).clamp(0.7, 1.3);

    return IgnorePointer(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colors.first.withValues(
                alpha: lerpDouble(0.96, 0.88, overviewDim)!,
              ),
              theme.colors[1].withValues(
                alpha: lerpDouble(0.92, 0.82, overviewDim)!,
              ),
              theme.colors.last.withValues(
                alpha: lerpDouble(0.98, 0.9, overviewDim)!,
              ),
            ],
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Align(
              alignment: const Alignment(-0.88, -0.64),
              child: _BackdropOrb(
                size: (lowEffects ? 220 : 320) * scale,
                color: Colors.white.withValues(alpha: 0.12),
                blur: (lowEffects ? 34 : 84) * scale,
              ),
            ),
            if (!lowEffects)
              Align(
                alignment: const Alignment(0.92, 0.74),
                child: _BackdropOrb(
                  size: 360 * scale,
                  color: storyColor.withValues(alpha: 0.22),
                  blur: 104 * scale,
                ),
              ),
            if (!lowEffects)
              Align(
                alignment: const Alignment(0.28, -0.86),
                child: _BackdropOrb(
                  size: 240 * scale,
                  color: theme.accentColor.withValues(alpha: 0.18),
                  blur: 72 * scale,
                ),
              ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0, -0.15),
                  radius: 1.02,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: vignetteAlpha),
                  ],
                  stops: const [0.64, 1.0],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeImmersiveForeground extends StatelessWidget {
  const _HomeImmersiveForeground({
    required this.storyColor,
    required this.overviewProgress,
    required this.lowEffects,
  });

  final Color storyColor;
  final double overviewProgress;
  final bool lowEffects;

  @override
  Widget build(BuildContext context) {
    final dim = Curves.easeOutCubic.transform(overviewProgress);
    final size = MediaQuery.sizeOf(context);
    final minDimension = math.min(size.width, size.height);
    final scale = (minDimension / 900).clamp(0.7, 1.3);

    return IgnorePointer(
      child: Opacity(
        opacity: lerpDouble(1.0, 0.72, dim)!,
        child: Stack(
          fit: StackFit.expand,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.06),
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.12),
                  ],
                  stops: const [0.0, 0.4, 1.0],
                ),
              ),
            ),
            if (!lowEffects)
              Align(
                alignment: const Alignment(0.86, -0.22),
                child: _BackdropOrb(
                  size: 140 * scale,
                  color: Colors.white.withValues(alpha: 0.16),
                  blur: 38 * scale,
                ),
              ),
            if (!lowEffects)
              Align(
                alignment: const Alignment(-0.82, 0.32),
                child: _BackdropOrb(
                  size: 160 * scale,
                  color: storyColor.withValues(alpha: 0.18),
                  blur: 46 * scale,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _HomeDepthShadowLayer extends StatelessWidget {
  const _HomeDepthShadowLayer({
    required this.theme,
    required this.storyColor,
    required this.overviewProgress,
    required this.lowEffects,
  });

  final GradientThemeData theme;
  final Color storyColor;
  final double overviewProgress;
  final bool lowEffects;

  @override
  Widget build(BuildContext context) {
    final dim = Curves.easeOutCubic.transform(overviewProgress);
    final edgeAlpha =
        lerpDouble(
          theme.isBright ? 0.08 : 0.12,
          theme.isBright ? 0.16 : 0.22,
          dim,
        )! *
        (lowEffects ? 0.75 : 1.0);
    final centerTintAlpha = lerpDouble(0.03, 0.07, dim)!;

    return IgnorePointer(
      child: Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.14,
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: edgeAlpha * 0.65),
                  Colors.black.withValues(alpha: edgeAlpha),
                ],
                stops: const [0.52, 0.8, 1.0],
              ),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  Colors.black.withValues(alpha: edgeAlpha * 0.82),
                  storyColor.withValues(alpha: centerTintAlpha),
                  Colors.black.withValues(alpha: edgeAlpha * 0.82),
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BackdropOrb extends StatelessWidget {
  const _BackdropOrb({
    required this.size,
    required this.color,
    required this.blur,
  });

  final double size;
  final Color color;
  final double blur;

  @override
  Widget build(BuildContext context) {
    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [color, Colors.transparent]),
        ),
      ),
    );
  }
}
