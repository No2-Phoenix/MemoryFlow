enum StoryTextMode { lyrics, subtitle, credits, typewriter }

const Object _unsetGlobalMusicPath = Object();

extension StoryTextModeX on StoryTextMode {
  String get label {
    switch (this) {
      case StoryTextMode.lyrics:
        return '歌词滚动式';
      case StoryTextMode.subtitle:
        return '电影字幕式';
      case StoryTextMode.credits:
        return '演职员表式';
      case StoryTextMode.typewriter:
        return '打字机式';
    }
  }

  String get description {
    switch (this) {
      case StoryTextMode.lyrics:
        return '文字从底部进入并逐步聚焦到中心，再向上淡出。';
      case StoryTextMode.subtitle:
        return '像电影字幕一样按节奏切换句子。';
      case StoryTextMode.credits:
        return '像片尾字幕一样纵向滚动。';
      case StoryTextMode.typewriter:
        return '逐字出现并带光标效果。';
    }
  }
}

enum OverviewMode { timeline, location }

extension OverviewModeX on OverviewMode {
  String get label => this == OverviewMode.timeline ? '时间轴' : '地点';
}

class ExperienceState {
  const ExperienceState({
    required this.themeIndex,
    required this.storyIndex,
    required this.textMode,
    required this.overviewMode,
    required this.isDrawerOpen,
    required this.isOverviewOpen,
    required this.ambientPreset,
    required this.globalMusicPath,
    required this.localDataEnabled,
    required this.showDate,
    required this.showLocation,
    required this.showTitle,
    required this.showCaption,
    required this.showAmbient,
    required this.showSidePreviews,
  });

  final int themeIndex;
  final int storyIndex;
  final StoryTextMode textMode;
  final OverviewMode overviewMode;
  final bool isDrawerOpen;
  final bool isOverviewOpen;
  final String ambientPreset;
  final String? globalMusicPath;
  final bool localDataEnabled;
  final bool showDate;
  final bool showLocation;
  final bool showTitle;
  final bool showCaption;
  final bool showAmbient;
  final bool showSidePreviews;

  ExperienceState copyWith({
    int? themeIndex,
    int? storyIndex,
    StoryTextMode? textMode,
    OverviewMode? overviewMode,
    bool? isDrawerOpen,
    bool? isOverviewOpen,
    String? ambientPreset,
    Object? globalMusicPath = _unsetGlobalMusicPath,
    bool? localDataEnabled,
    bool? showDate,
    bool? showLocation,
    bool? showTitle,
    bool? showCaption,
    bool? showAmbient,
    bool? showSidePreviews,
  }) {
    return ExperienceState(
      themeIndex: themeIndex ?? this.themeIndex,
      storyIndex: storyIndex ?? this.storyIndex,
      textMode: textMode ?? this.textMode,
      overviewMode: overviewMode ?? this.overviewMode,
      isDrawerOpen: isDrawerOpen ?? this.isDrawerOpen,
      isOverviewOpen: isOverviewOpen ?? this.isOverviewOpen,
      ambientPreset: ambientPreset ?? this.ambientPreset,
      globalMusicPath: identical(globalMusicPath, _unsetGlobalMusicPath)
          ? this.globalMusicPath
          : globalMusicPath as String?,
      localDataEnabled: localDataEnabled ?? this.localDataEnabled,
      showDate: showDate ?? this.showDate,
      showLocation: showLocation ?? this.showLocation,
      showTitle: showTitle ?? this.showTitle,
      showCaption: showCaption ?? this.showCaption,
      showAmbient: showAmbient ?? this.showAmbient,
      showSidePreviews: showSidePreviews ?? this.showSidePreviews,
    );
  }
}
