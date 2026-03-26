import 'dart:async';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

import 'experience_controller_v2.dart';

class AmbientPlaybackSelection {
  const AmbientPlaybackSelection({
    required this.globalMusicPath,
    required this.enabled,
  });

  final String? globalMusicPath;
  final bool enabled;
}

final ambientPlaybackSelectionProvider = Provider<AmbientPlaybackSelection>((
  ref,
) {
  final experience = ref.watch(experienceControllerProvider);

  return AmbientPlaybackSelection(
    globalMusicPath: experience.globalMusicPath,
    enabled: experience.showAmbient,
  );
});

final homeAmbientAudioControllerProvider = Provider<HomeAmbientAudioController>(
  (ref) {
    final controller = HomeAmbientAudioController();
    ref.onDispose(controller.dispose);
    return controller;
  },
);

class HomeAmbientAudioController {
  static const String bundledDefaultAsset =
      'assets/audio/paulyudin-piano-music-piano-485929.mp3';
  static const String preferredRootTrackPath =
      '../Snigellin - When I see the light at that Time.mp3';
  static const double _defaultVolume = 0.42;

  final AudioPlayer _player = AudioPlayer();

  String? _activeSourceKey;
  bool _shouldPlayWhenActive = false;
  bool _isForeground = true;
  int _syncVersion = 0;

  HomeAmbientAudioController() {
    unawaited(_player.setLoopMode(LoopMode.one));
    unawaited(_player.setVolume(_defaultVolume));
  }

  Future<void> sync(AmbientPlaybackSelection selection) async {
    final target = resolveSource(selection: selection);
    final shouldPlay = target != null;

    _shouldPlayWhenActive = shouldPlay;
    final currentVersion = ++_syncVersion;

    if (!shouldPlay) {
      _activeSourceKey = null;
      await _pauseAndRewind();
      return;
    }

    final sourceKey = '${target.isAsset ? 'asset' : 'file'}:${target.path}';
    if (sourceKey != _activeSourceKey) {
      final loaded = await _loadSource(target);
      if (!loaded || currentVersion != _syncVersion) {
        return;
      }
      _activeSourceKey = sourceKey;
    }

    if (currentVersion != _syncVersion || !_isForeground || _player.playing) {
      return;
    }

    await _player.play();
  }

  Future<void> handleLifecycleState(AppLifecycleState state) async {
    final isForeground = state == AppLifecycleState.resumed;
    _isForeground = isForeground;

    if (!isForeground) {
      await _player.pause();
      return;
    }

    if (_shouldPlayWhenActive &&
        _activeSourceKey != null &&
        !_player.playing &&
        _syncVersion > 0) {
      await _player.play();
    }
  }

  Future<void> stop() async {
    _shouldPlayWhenActive = false;
    _activeSourceKey = null;
    await _pauseAndRewind();
  }

  @visibleForTesting
  static ResolvedAmbientSource? resolveSource({
    required AmbientPlaybackSelection selection,
    bool rootTrackExists = true,
  }) {
    if (!selection.enabled) {
      return null;
    }

    final customPath = selection.globalMusicPath?.trim();
    if (customPath != null && customPath.isNotEmpty) {
      return ResolvedAmbientSource(path: customPath, isAsset: false);
    }

    if (rootTrackExists && File(preferredRootTrackPath).existsSync()) {
      return const ResolvedAmbientSource(
        path: preferredRootTrackPath,
        isAsset: false,
      );
    }

    return const ResolvedAmbientSource(
      path: bundledDefaultAsset,
      isAsset: true,
    );
  }

  Future<bool> _loadSource(ResolvedAmbientSource source) async {
    try {
      if (source.isAsset) {
        await _player.setAsset(source.path);
      } else {
        await _player.setFilePath(source.path);
      }
      return true;
    } catch (error, stackTrace) {
      debugPrint('Ambient source load failed: $error');
      debugPrint('$stackTrace');

      if (source.isAsset) {
        _shouldPlayWhenActive = false;
        await _pauseAndRewind();
        return false;
      }
    }

    try {
      await _player.setAsset(bundledDefaultAsset);
      _activeSourceKey = 'asset:$bundledDefaultAsset';
      return true;
    } catch (error, stackTrace) {
      debugPrint('Fallback ambient asset load failed: $error');
      debugPrint('$stackTrace');
      _shouldPlayWhenActive = false;
      await _pauseAndRewind();
      return false;
    }
  }

  Future<void> _pauseAndRewind() async {
    await _player.pause();
    await _player.seek(Duration.zero);
  }

  void dispose() {
    unawaited(_player.dispose());
  }
}

class ResolvedAmbientSource {
  const ResolvedAmbientSource({required this.path, required this.isAsset});

  final String path;
  final bool isAsset;
}
