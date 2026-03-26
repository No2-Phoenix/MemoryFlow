import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../shared/glass_button.dart';
import '../../shared/gradient_background.dart';
import '../../shared/story_artwork.dart';
import '../home/experience_controller_v2.dart';
import '../home/story_library_controller.dart';
import '../home/story_moment_data.dart';
import 'local_exif_map_utils.dart';
import 'mp4_export_service.dart';

enum FeatureSpotlightMode { map, export }

class FeatureSpotlightPage extends ConsumerStatefulWidget {
  const FeatureSpotlightPage.map({super.key}) : mode = FeatureSpotlightMode.map;
  const FeatureSpotlightPage.export({super.key})
    : mode = FeatureSpotlightMode.export;

  final FeatureSpotlightMode mode;

  @override
  ConsumerState<FeatureSpotlightPage> createState() =>
      _FeatureSpotlightPageState();
}

class _FeatureSpotlightPageState extends ConsumerState<FeatureSpotlightPage> {
  static const Mp4ExportService _mp4ExportService = Mp4ExportService();

  Timer? _progressTimer;
  bool _isRendering = false;
  double _progress = 0;
  MapDateFilter _dateFilter = MapDateFilter.all;
  String? _selectedClusterKey;

  @override
  void dispose() {
    _progressTimer?.cancel();
    super.dispose();
  }

  Future<void> _startRender() async {
    if (_isRendering) {
      return;
    }

    final stories = ref.read(storiesProvider);
    final musicPath = ref.read(experienceControllerProvider).globalMusicPath;

    _progressTimer?.cancel();
    setState(() {
      _isRendering = true;
      _progress = 0;
    });
    _progressTimer = Timer.periodic(const Duration(milliseconds: 220), (_) {
      if (!mounted || !_isRendering) {
        return;
      }
      setState(() => _progress = (_progress + 0.04).clamp(0, 0.9));
    });

    try {
      final result = await _mp4ExportService.exportStoriesToAlbum(
        stories: stories,
        globalMusicPath: musicPath,
      );
      _progressTimer?.cancel();
      if (!mounted) {
        return;
      }
      setState(() {
        _isRendering = false;
        _progress = 1;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'MP4 saved to Photos (${result.storyCount} images, '
            '${result.hasAudio ? 'with music' : 'silent'}).',
          ),
        ),
      );
    } catch (error) {
      _progressTimer?.cancel();
      if (!mounted) {
        return;
      }
      setState(() {
        _isRendering = false;
        _progress = 0;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('MP4 export failed: $error')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final stories = ref.watch(storiesProvider);
    final experience = ref.watch(experienceControllerProvider);
    final localDataEnabled = experience.localDataEnabled;
    final isCompact = MediaQuery.sizeOf(context).width < 980;

    final filteredStories = localDataEnabled
        ? filterLocalExifStories(
            stories,
            dateFilter: _dateFilter,
            clusterKey: _selectedClusterKey,
          )
        : const <StoryMoment>[];
    final clusters = localDataEnabled
        ? buildLocalExifClusters(
            filterLocalExifStories(stories, dateFilter: _dateFilter),
          )
        : const <LocalExifCluster>[];

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
          child: Column(
            children: [
              Row(
                children: [
                  GlassIconButton(
                    icon: Icons.arrow_back_ios_new_rounded,
                    onPressed: () => context.pop(),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      widget.mode == FeatureSpotlightMode.map
                          ? 'Map'
                          : 'Export MP4',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                  ),
                  if (widget.mode == FeatureSpotlightMode.export)
                    GlassButton(
                      text: _isRendering
                          ? 'Exporting ${(_progress * 100).round()}%'
                          : 'Export To Photos',
                      icon: Icons.movie_creation_outlined,
                      isActive: true,
                      onPressed: _isRendering ? null : _startRender,
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: widget.mode == FeatureSpotlightMode.map
                    ? _MapModeView(
                        isCompact: isCompact,
                        localDataEnabled: localDataEnabled,
                        dateFilter: _dateFilter,
                        selectedClusterKey: _selectedClusterKey,
                        clusters: clusters,
                        stories: filteredStories,
                        onFilterChanged: (value) {
                          setState(() {
                            _dateFilter = value;
                            _selectedClusterKey = null;
                          });
                        },
                        onClusterTap: (key) {
                          setState(() {
                            _selectedClusterKey = _selectedClusterKey == key
                                ? null
                                : key;
                          });
                        },
                      )
                    : _ExportModeView(
                        isCompact: isCompact,
                        progress: _progress,
                        isRendering: _isRendering,
                        stories: stories,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MapModeView extends StatelessWidget {
  const _MapModeView({
    required this.isCompact,
    required this.localDataEnabled,
    required this.dateFilter,
    required this.selectedClusterKey,
    required this.clusters,
    required this.stories,
    required this.onFilterChanged,
    required this.onClusterTap,
  });

  final bool isCompact;
  final bool localDataEnabled;
  final MapDateFilter dateFilter;
  final String? selectedClusterKey;
  final List<LocalExifCluster> clusters;
  final List<StoryMoment> stories;
  final ValueChanged<MapDateFilter> onFilterChanged;
  final ValueChanged<String> onClusterTap;

  @override
  Widget build(BuildContext context) {
    final board = GlassContainer(
      borderRadius: 28,
      padding: const EdgeInsets.all(12),
      child: _MapBoard(
        localDataEnabled: localDataEnabled,
        clusters: clusters,
        selectedClusterKey: selectedClusterKey,
        onClusterTap: onClusterTap,
      ),
    );

    final clusterList = GlassContainer(
      borderRadius: 28,
      padding: const EdgeInsets.all(18),
      child: ListView(
        children: [
          Text('Date Filter', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: MapDateFilter.values
                .map(
                  (filter) => GlassButton(
                    text: filter.label,
                    isActive: filter == dateFilter,
                    onPressed: localDataEnabled
                        ? () => onFilterChanged(filter)
                        : null,
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 16),
          if (!localDataEnabled)
            const _NoteCard(
              icon: Icons.lock_outline_rounded,
              message: 'Local EXIF reading is disabled in settings.',
            )
          else if (clusters.isEmpty)
            const _NoteCard(
              icon: Icons.location_off_outlined,
              message: 'No local EXIF coordinates found yet.',
            )
          else
            ...clusters.map((cluster) {
              final selected = cluster.key == selectedClusterKey;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: GlassContainer(
                  borderRadius: 22,
                  tintColor: cluster.leadStory.dominantColor,
                  opacity: selected ? 0.2 : 0.1,
                  onTap: () => onClusterTap(cluster.key),
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 56,
                        height: 56,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: StoryArtwork(
                            palette: cluster.leadStory.palette,
                            imagePath: cluster.leadStory.coverImagePath,
                            showAtmosphere: false,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '${cluster.label} · ${cluster.storyCount}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );

    final storyList = GlassContainer(
      borderRadius: 28,
      padding: const EdgeInsets.all(18),
      child: ListView(
        children: [
          Text('Stories', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 10),
          if (!localDataEnabled)
            const _NoteCard(
              icon: Icons.visibility_off_outlined,
              message: 'Enable local data to view map stories.',
            )
          else if (stories.isEmpty)
            const _NoteCard(
              icon: Icons.photo_library_outlined,
              message: 'No matching stories under this filter.',
            )
          else
            ...stories.map((story) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: GlassContainer(
                  borderRadius: 22,
                  tintColor: story.dominantColor,
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 64,
                        height: 64,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: StoryArtwork(
                            palette: story.palette,
                            imagePath: story.coverImagePath,
                            showAtmosphere: false,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '${story.title}\n${story.location} · ${story.dateLabel}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );

    if (isCompact) {
      return ListView(
        children: [
          SizedBox(height: 260, child: board),
          const SizedBox(height: 12),
          SizedBox(height: 360, child: clusterList),
          const SizedBox(height: 12),
          SizedBox(height: 360, child: storyList),
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          flex: 11,
          child: Column(
            children: [
              Expanded(flex: 6, child: board),
              const SizedBox(height: 14),
              Expanded(flex: 8, child: clusterList),
            ],
          ),
        ),
        const SizedBox(width: 14),
        Expanded(flex: 9, child: storyList),
      ],
    );
  }
}

class _ExportModeView extends StatelessWidget {
  const _ExportModeView({
    required this.isCompact,
    required this.progress,
    required this.isRendering,
    required this.stories,
  });

  final bool isCompact;
  final double progress;
  final bool isRendering;
  final List<StoryMoment> stories;

  @override
  Widget build(BuildContext context) {
    final leadStory = stories.isEmpty
        ? StoryMomentFallback.empty
        : stories.first;
    final preview = GlassContainer(
      borderRadius: 28,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: StoryArtwork(
                palette: leadStory.palette,
                imagePath: leadStory.coverImagePath,
                overlayColor: leadStory.dominantColor,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            isRendering ? 'Rendering MP4...' : 'Ready to export MP4 to Photos',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 10,
              value: progress == 0 ? 0.02 : progress,
              backgroundColor: Colors.white.withValues(alpha: 0.08),
            ),
          ),
        ],
      ),
    );
    final config = GlassContainer(
      borderRadius: 28,
      padding: const EdgeInsets.all(16),
      child: ListView(
        children: [
          Text('Export Plan', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 10),
          Text(
            'Uses up to 4 uploaded cover images, each 6s, 1080x1920, H.264.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 10),
          Text(
            'If global music is configured and readable, it will be mixed in.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 14),
          ...stories
              .take(4)
              .map(
                (story) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: GlassContainer(
                    borderRadius: 18,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    child: Text(
                      '${story.title} · 6s',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ),
              ),
        ],
      ),
    );

    if (isCompact) {
      return ListView(
        children: [
          SizedBox(height: 380, child: preview),
          const SizedBox(height: 12),
          SizedBox(height: 300, child: config),
        ],
      );
    }
    return Row(
      children: [
        Expanded(child: preview),
        const SizedBox(width: 14),
        Expanded(child: config),
      ],
    );
  }
}

class _NoteCard extends StatelessWidget {
  const _NoteCard({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      borderRadius: 20,
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.white.withValues(alpha: 0.86)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(message, style: Theme.of(context).textTheme.bodySmall),
          ),
        ],
      ),
    );
  }
}

class _MapBoard extends StatelessWidget {
  const _MapBoard({
    required this.localDataEnabled,
    required this.clusters,
    required this.selectedClusterKey,
    required this.onClusterTap,
  });

  final bool localDataEnabled;
  final List<LocalExifCluster> clusters;
  final String? selectedClusterKey;
  final ValueChanged<String> onClusterTap;

  @override
  Widget build(BuildContext context) {
    if (!localDataEnabled) {
      return const _NoteCard(
        icon: Icons.lock_outline_rounded,
        message: 'Enable local data to map EXIF coordinates.',
      );
    }
    if (clusters.isEmpty) {
      return const _NoteCard(
        icon: Icons.near_me_disabled_outlined,
        message: 'No valid GPS stories are available yet.',
      );
    }

    final minLat = clusters.map((item) => item.centerLatitude).reduce(math.min);
    final maxLat = clusters.map((item) => item.centerLatitude).reduce(math.max);
    final minLng = clusters
        .map((item) => item.centerLongitude)
        .reduce(math.min);
    final maxLng = clusters
        .map((item) => item.centerLongitude)
        .reduce(math.max);

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;
        Offset project(LocalExifCluster cluster) {
          final dx =
              (cluster.centerLongitude - minLng) /
              ((maxLng - minLng).abs() + 0.0001);
          final dy =
              (cluster.centerLatitude - minLat) /
              ((maxLat - minLat).abs() + 0.0001);
          return Offset(
            width * (0.12 + dx * 0.76),
            height * (0.18 + (1 - dy) * 0.64),
          );
        }

        return ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Stack(
            children: [
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withValues(alpha: 0.08),
                        Colors.white.withValues(alpha: 0.02),
                        Colors.black.withValues(alpha: 0.12),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: CustomPaint(
                  painter: _MapBoardPainter(
                    clusters: clusters,
                    selectedClusterKey: selectedClusterKey,
                    projector: project,
                  ),
                ),
              ),
              ...clusters.map((cluster) {
                final point = project(cluster);
                final selected = cluster.key == selectedClusterKey;
                final dotSize = 12.0 + cluster.storyCount * 2.6;
                return Positioned(
                  left: point.dx - dotSize / 2,
                  top: point.dy - dotSize / 2,
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTap: () => onClusterTap(cluster.key),
                    child: Container(
                      width: dotSize,
                      height: dotSize,
                      decoration: BoxDecoration(
                        color: cluster.leadStory.dominantColor,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.86),
                          width: selected ? 2.0 : 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: cluster.leadStory.dominantColor.withValues(
                              alpha: selected ? 0.7 : 0.42,
                            ),
                            blurRadius: selected ? 24 : 14,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }
}

class _MapBoardPainter extends CustomPainter {
  const _MapBoardPainter({
    required this.clusters,
    required this.selectedClusterKey,
    required this.projector,
  });

  final List<LocalExifCluster> clusters;
  final String? selectedClusterKey;
  final Offset Function(LocalExifCluster cluster) projector;

  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..strokeWidth = 1;
    for (int x = 1; x < 6; x++) {
      final dx = size.width * x / 6;
      canvas.drawLine(Offset(dx, 0), Offset(dx, size.height), grid);
    }
    for (int y = 1; y < 5; y++) {
      final dy = size.height * y / 5;
      canvas.drawLine(Offset(0, dy), Offset(size.width, dy), grid);
    }

    if (clusters.length < 2) {
      return;
    }
    final path = Path();
    final ordered = [...clusters]
      ..sort((left, right) => left.startDate.compareTo(right.startDate));
    final first = projector(ordered.first);
    path.moveTo(first.dx, first.dy);
    for (final cluster in ordered.skip(1)) {
      final point = projector(cluster);
      path.lineTo(point.dx, point.dy);
    }
    final route = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..shader = LinearGradient(
        colors: [
          Colors.white.withValues(alpha: 0.12),
          Colors.white.withValues(alpha: 0.34),
          Colors.white.withValues(alpha: 0.12),
        ],
      ).createShader(Offset.zero & size);
    canvas.drawPath(path, route);

    if (selectedClusterKey != null) {
      final selected = ordered.firstWhere(
        (item) => item.key == selectedClusterKey,
        orElse: () => ordered.first,
      );
      final halo = Paint()
        ..color = selected.leadStory.dominantColor.withValues(alpha: 0.24)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 24);
      canvas.drawCircle(projector(selected), 30, halo);
    }
  }

  @override
  bool shouldRepaint(covariant _MapBoardPainter oldDelegate) {
    return oldDelegate.clusters != clusters ||
        oldDelegate.selectedClusterKey != selectedClusterKey;
  }
}
