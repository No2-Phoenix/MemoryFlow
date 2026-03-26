import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/gradient_themes.dart';
import 'experience_models.dart';
import 'experience_preferences_store.dart';
import 'story_library_controller.dart';
import 'story_moment_data.dart';

export 'experience_models.dart';

class ExperienceController extends Notifier<ExperienceState> {
  final _preferencesStore = ExperiencePreferencesStore();
  bool _hydrated = false;

  @override
  ExperienceState build() {
    ref.listen<List<StoryMoment>>(storiesProvider, (previous, next) {
      if (next.isEmpty) {
        return;
      }
      final safeIndex = state.storyIndex.clamp(0, next.length - 1);
      if (safeIndex != state.storyIndex) {
        _setState(state.copyWith(storyIndex: safeIndex));
      }
    });

    if (!_hydrated) {
      _hydrated = true;
      Future.microtask(_hydrate);
    }

    return const ExperienceState(
      themeIndex: 0,
      storyIndex: 0,
      textMode: StoryTextMode.lyrics,
      overviewMode: OverviewMode.timeline,
      isDrawerOpen: false,
      isOverviewOpen: false,
      ambientPreset: '自动匹配',
      globalMusicPath: null,
      localDataEnabled: true,
      showDate: true,
      showLocation: true,
      showTitle: true,
      showCaption: true,
      showAmbient: true,
      showSidePreviews: true,
    );
  }

  Future<void> _hydrate() async {
    final restored = await _preferencesStore.load();
    if (restored == null) {
      return;
    }
    final stories = ref.read(storiesProvider);
    final safeIndex = stories.isEmpty
        ? 0
        : restored.storyIndex.clamp(0, stories.length - 1);
    state = restored.copyWith(storyIndex: safeIndex);
  }

  void selectStory(int index) {
    final total = _storyCount;
    if (total == 0) {
      return;
    }
    final normalized = index.clamp(0, total - 1);
    _setState(state.copyWith(storyIndex: normalized, isOverviewOpen: false));
  }

  void nextStory() {
    final total = _storyCount;
    if (total == 0) {
      return;
    }
    _setState(state.copyWith(storyIndex: (state.storyIndex + 1) % total));
  }

  void previousStory() {
    final total = _storyCount;
    if (total == 0) {
      return;
    }
    final previous = (state.storyIndex - 1 + total) % total;
    _setState(state.copyWith(storyIndex: previous));
  }

  void setThemeIndex(int index) {
    final safeIndex = index.clamp(0, GradientThemes.all.length - 1).toInt();
    _setState(state.copyWith(themeIndex: safeIndex));
  }

  void setTextMode(StoryTextMode mode) {
    _setState(state.copyWith(textMode: mode));
  }

  void setAmbientPreset(String preset) {
    _setState(state.copyWith(ambientPreset: preset));
  }

  void setGlobalMusicPath(String? path) {
    final trimmed = path?.trim();
    _setState(
      state.copyWith(
        globalMusicPath: (trimmed == null || trimmed.isEmpty) ? null : trimmed,
      ),
    );
  }

  void setLocalDataEnabled(bool enabled) {
    _setState(state.copyWith(localDataEnabled: enabled));
  }

  void setShowDate(bool enabled) {
    _setState(state.copyWith(showDate: enabled));
  }

  void setShowLocation(bool enabled) {
    _setState(state.copyWith(showLocation: enabled));
  }

  void setShowTitle(bool enabled) {
    _setState(state.copyWith(showTitle: enabled));
  }

  void setShowCaption(bool enabled) {
    _setState(state.copyWith(showCaption: enabled));
  }

  void setShowAmbient(bool enabled) {
    _setState(state.copyWith(showAmbient: enabled));
  }

  void setShowSidePreviews(bool enabled) {
    _setState(state.copyWith(showSidePreviews: enabled));
  }

  void openDrawer() {
    _setState(state.copyWith(isDrawerOpen: true, isOverviewOpen: false));
  }

  void closeDrawer() {
    _setState(state.copyWith(isDrawerOpen: false));
  }

  void toggleDrawer() {
    _setState(
      state.copyWith(isDrawerOpen: !state.isDrawerOpen, isOverviewOpen: false),
    );
  }

  void openOverview() {
    _setState(state.copyWith(isOverviewOpen: true, isDrawerOpen: false));
  }

  void closeOverview() {
    _setState(state.copyWith(isOverviewOpen: false));
  }

  void toggleOverview() {
    _setState(
      state.copyWith(
        isOverviewOpen: !state.isOverviewOpen,
        isDrawerOpen: false,
      ),
    );
  }

  void setOverviewMode(OverviewMode mode) {
    _setState(state.copyWith(overviewMode: mode));
  }

  int get _storyCount {
    final stories = ref.read(storiesProvider);
    return stories.isEmpty ? 0 : stories.length;
  }

  void _setState(ExperienceState next) {
    state = next;
    unawaited(
      _preferencesStore.save(
        next.copyWith(isDrawerOpen: false, isOverviewOpen: false),
      ),
    );
  }
}

final experienceControllerProvider =
    NotifierProvider<ExperienceController, ExperienceState>(
      ExperienceController.new,
    );

final currentStoryProvider = Provider<StoryMoment>((ref) {
  final stories = ref.watch(storiesProvider);
  final index = ref.watch(
    experienceControllerProvider.select((state) => state.storyIndex),
  );

  if (stories.isEmpty) {
    return StoryMomentFallback.empty;
  }
  return stories[index.clamp(0, stories.length - 1)];
});

final currentThemeProvider = Provider<GradientThemeData>((ref) {
  final themeIndex = ref.watch(
    experienceControllerProvider.select((state) => state.themeIndex),
  );
  return GradientThemes.byIndex(themeIndex);
});

final ambientPresetsProvider = Provider<List<String>>((ref) {
  return const ['自动匹配', '雨声', '海浪', 'Lo-fi', '壁炉', '城市低频'];
});
