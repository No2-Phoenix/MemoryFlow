import 'package:flutter/material.dart';

import '../../shared/glass_button.dart';
import '../../shared/gradient_background.dart';
import '../../shared/story_artwork.dart';
import 'story_moment_data.dart';

class HomeOverviewLayer extends StatelessWidget {
  const HomeOverviewLayer({
    super.key,
    required this.isCompact,
    required this.stories,
    required this.selectedIndex,
    required this.onClose,
    required this.onSelectStory,
  });

  final bool isCompact;
  final List<StoryMoment> stories;
  final int selectedIndex;
  final VoidCallback onClose;
  final ValueChanged<int> onSelectStory;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withValues(alpha: 0.2),
      padding: EdgeInsets.fromLTRB(
        isCompact ? 16 : 24,
        18,
        isCompact ? 16 : 24,
        24,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '故事总览',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ),
              GlassIconButton(icon: Icons.close_rounded, onPressed: onClose),
            ],
          ),
          const SizedBox(height: 22),
          Expanded(
            child: _TimelineOverview(
              key: const ValueKey('timeline'),
              stories: stories,
              selectedIndex: selectedIndex,
              isCompact: isCompact,
              onSelectStory: onSelectStory,
            ),
          ),
        ],
      ),
    );
  }
}

class _TimelineOverview extends StatefulWidget {
  const _TimelineOverview({
    super.key,
    required this.stories,
    required this.selectedIndex,
    required this.isCompact,
    required this.onSelectStory,
  });

  final List<StoryMoment> stories;
  final int selectedIndex;
  final bool isCompact;
  final ValueChanged<int> onSelectStory;

  @override
  State<_TimelineOverview> createState() => _TimelineOverviewState();
}

class _TimelineOverviewState extends State<_TimelineOverview> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: Align(
            alignment: Alignment.center,
            child: Container(
              width: 2,
              color: Colors.white.withValues(alpha: 0.12),
            ),
          ),
        ),
        ListView.builder(
          controller: _scrollController,
          physics: const BouncingScrollPhysics(),
          itemCount: widget.stories.length,
          itemBuilder: (context, index) {
            final story = widget.stories[index];
            final isLeft = !widget.isCompact && index.isEven;

            return SizedBox(
              height: 214,
              child: Stack(
                children: [
                  Align(
                    alignment: Alignment.center,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: story.dominantColor,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                    ),
                  ),
                  Align(
                    alignment: widget.isCompact
                        ? Alignment.center
                        : (isLeft
                              ? Alignment.centerLeft
                              : Alignment.centerRight),
                    child: FractionallySizedBox(
                      widthFactor: widget.isCompact ? 0.84 : 0.44,
                      child: GlassContainer(
                        onTap: () => widget.onSelectStory(index),
                        borderRadius: 30,
                        tintColor: story.dominantColor,
                        opacity: widget.selectedIndex == index ? 0.2 : 0.1,
                        borderColor: widget.selectedIndex == index
                            ? story.dominantColor.withValues(alpha: 0.58)
                            : Colors.white.withValues(alpha: 0.18),
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 110,
                              height: 148,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(18),
                                child: StoryArtwork(
                                  palette: story.palette,
                                  imagePath: story.coverImagePath,
                                  imageBlurSigma: story.coverBlurSigma,
                                  overlayColor: story.dominantColor,
                                  showAtmosphere: false,
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    story.dateLabel,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.labelMedium,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    story.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleLarge,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    story.location,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall,
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    story.caption,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
