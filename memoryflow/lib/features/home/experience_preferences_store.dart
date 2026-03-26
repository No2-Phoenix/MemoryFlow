import 'package:shared_preferences/shared_preferences.dart';

import '../../core/theme/gradient_themes.dart';
import 'experience_models.dart';

class ExperiencePreferencesStore {
  static const _themeIndexKey = 'experience.theme_index';
  static const _storyIndexKey = 'experience.story_index';
  static const _textModeKey = 'experience.text_mode';
  static const _overviewModeKey = 'experience.overview_mode';
  static const _ambientPresetKey = 'experience.ambient_preset';
  static const _globalMusicPathKey = 'experience.global_music_path';
  static const _localDataEnabledKey = 'experience.local_data_enabled';
  static const _showDateKey = 'experience.show_date';
  static const _showLocationKey = 'experience.show_location';
  static const _showTitleKey = 'experience.show_title';
  static const _showCaptionKey = 'experience.show_caption';
  static const _showAmbientKey = 'experience.show_ambient';
  static const _showSidePreviewsKey = 'experience.show_side_previews';

  Future<ExperienceState?> load() async {
    final preferences = await SharedPreferences.getInstance();
    if (!preferences.containsKey(_themeIndexKey)) {
      return null;
    }

    final maxThemeIndex = GradientThemes.all.length - 1;
    final storedThemeIndex = preferences.getInt(_themeIndexKey) ?? 0;
    final safeThemeIndex = storedThemeIndex.clamp(0, maxThemeIndex).toInt();

    return ExperienceState(
      themeIndex: safeThemeIndex,
      storyIndex: preferences.getInt(_storyIndexKey) ?? 0,
      textMode: _parseTextMode(preferences.getString(_textModeKey)),
      overviewMode: _parseOverviewMode(preferences.getString(_overviewModeKey)),
      isDrawerOpen: false,
      isOverviewOpen: false,
      ambientPreset: preferences.getString(_ambientPresetKey) ?? '自动匹配',
      globalMusicPath: preferences.getString(_globalMusicPathKey),
      localDataEnabled: preferences.getBool(_localDataEnabledKey) ?? true,
      showDate: preferences.getBool(_showDateKey) ?? true,
      showLocation: preferences.getBool(_showLocationKey) ?? true,
      showTitle: preferences.getBool(_showTitleKey) ?? true,
      showCaption: preferences.getBool(_showCaptionKey) ?? true,
      showAmbient: preferences.getBool(_showAmbientKey) ?? true,
      showSidePreviews: preferences.getBool(_showSidePreviewsKey) ?? true,
    );
  }

  Future<void> save(ExperienceState state) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setInt(_themeIndexKey, state.themeIndex);
    await preferences.setInt(_storyIndexKey, state.storyIndex);
    await preferences.setString(_textModeKey, state.textMode.name);
    await preferences.setString(_overviewModeKey, state.overviewMode.name);
    await preferences.setString(_ambientPresetKey, state.ambientPreset);

    final globalMusicPath = state.globalMusicPath?.trim();
    if (globalMusicPath == null || globalMusicPath.isEmpty) {
      await preferences.remove(_globalMusicPathKey);
    } else {
      await preferences.setString(_globalMusicPathKey, globalMusicPath);
    }

    await preferences.setBool(_localDataEnabledKey, state.localDataEnabled);
    await preferences.setBool(_showDateKey, state.showDate);
    await preferences.setBool(_showLocationKey, state.showLocation);
    await preferences.setBool(_showTitleKey, state.showTitle);
    await preferences.setBool(_showCaptionKey, state.showCaption);
    await preferences.setBool(_showAmbientKey, state.showAmbient);
    await preferences.setBool(_showSidePreviewsKey, state.showSidePreviews);
  }

  OverviewMode _parseOverviewMode(String? raw) {
    if (raw == OverviewMode.location.name) {
      return OverviewMode.location;
    }
    if (raw == 'grid' || raw == 'timeTree') {
      return OverviewMode.timeline;
    }
    return OverviewMode.timeline;
  }

  StoryTextMode _parseTextMode(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return StoryTextMode.lyrics;
    }
    try {
      return StoryTextMode.values.byName(raw.trim());
    } catch (_) {
      return StoryTextMode.lyrics;
    }
  }
}
