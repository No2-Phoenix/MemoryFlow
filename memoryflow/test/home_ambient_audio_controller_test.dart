import 'package:flutter_test/flutter_test.dart';
import 'package:memoryflow/features/home/home_ambient_audio_controller.dart';

void main() {
  test('disabled playback resolves to no source', () {
    final source = HomeAmbientAudioController.resolveSource(
      selection: const AmbientPlaybackSelection(
        globalMusicPath: null,
        enabled: false,
      ),
    );

    expect(source, isNull);
  });

  test('custom global music path wins over defaults', () {
    const customPath = 'assets/audio/paulyudin-piano-music-piano-485929.mp3';
    final source = HomeAmbientAudioController.resolveSource(
      selection: const AmbientPlaybackSelection(
        globalMusicPath: customPath,
        enabled: true,
      ),
      rootTrackExists: false,
    );

    expect(source, isNotNull);
    expect(source!.path, customPath);
    expect(source.isAsset, isFalse);
  });

  test('falls back to bundled asset when root track is unavailable', () {
    final source = HomeAmbientAudioController.resolveSource(
      selection: const AmbientPlaybackSelection(
        globalMusicPath: null,
        enabled: true,
      ),
      rootTrackExists: false,
    );

    expect(source, isNotNull);
    expect(source!.path, HomeAmbientAudioController.bundledDefaultAsset);
    expect(source.isAsset, isTrue);
  });
}
